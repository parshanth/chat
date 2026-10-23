
const Attendance = require("../models/Attendance");
const Member = require("../models/Member");
const mongoose = require("mongoose");

// Accept YYYY-MM-DD and store dates consistently in UTC.
const parseAttendanceDate = (value) => {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return null;
  }

  const date = new Date(`${value}T00:00:00.000Z`);

  if (
    Number.isNaN(date.getTime()) ||
    date.toISOString().slice(0, 10) !== value
  ) {
    return null;
  }

  // Attendance is only recorded for Sundays.
  if (date.getUTCDay() !== 0) {
    return null;
  }

  return date;
};

// Week 1 is the first Sunday on or after January 1.
// The server calculates this; clients must not supply the week number.
const calculateSundayWeek = (date) => {
  const year = date.getUTCFullYear();

  const firstSunday = new Date(Date.UTC(year, 0, 1));
  firstSunday.setUTCDate(
    firstSunday.getUTCDate() + ((7 - firstSunday.getUTCDay()) % 7)
  );

  const weekNumber =
    Math.floor((date.getTime() - firstSunday.getTime()) /
      (7 * 24 * 60 * 60 * 1000)) + 1;

  return { year, weekNumber };
};

const sendError = (res, error) => {
  if (error.code === 11000) {
    return res.status(409).json({
      success: false,
      message: "Attendance for this Sunday is being updated. Please retry.",
    });
  }

  console.error("Attendance error:", error.message);

  return res.status(500).json({
    success: false,
    message: "An error occurred while processing attendance.",
  });
};

// GET /api/v1/attendance?date=YYYY-MM-DD
// Returns every member, including those whose status is unmarked.
const getAttendance = async (req, res) => {
  try {
    const date = parseAttendanceDate(req.query.date);

    if (!date) {
      return res.status(400).json({
        success: false,
        message: "Provide a valid Sunday date using YYYY-MM-DD.",
      });
    }

    const { year, weekNumber } = calculateSundayWeek(date);

    const [members, attendance] = await Promise.all([
      Member.find()
        .select("name dob phoneNumber baptismDate")
        .sort({ name: 1 })
        .lean(),
      Attendance.findOne({ date }).lean(),
    ]);

    const statusByMember = new Map(
      (attendance?.entries ?? []).map((entry) => [
        entry.member.toString(),
        entry.status,
      ])
    );

    const entries = members.map((member) => ({
      ...member,
      status: statusByMember.get(member._id.toString()) ?? "unmarked",
    }));

    return res.status(200).json({
      success: true,
      data: {
        date: date.toISOString().slice(0, 10),
        year,
        weekNumber,
        members: entries,
        summary: {
          total: entries.length,
          present: entries.filter((m) => m.status === "present").length,
          absent: entries.filter((m) => m.status === "absent").length,
          unmarked: entries.filter((m) => m.status === "unmarked").length,
        },
      },
    });
  } catch (error) {
    return sendError(res, error);
  }
};

// PATCH /api/v1/attendance/member
// Body: { date, memberId, status }
// Saves one member immediately, allowing attendance to resume later.
const updateMemberAttendance = async (req, res) => {
  try {
    const { date: dateValue, memberId, status } = req.body;

    const date = parseAttendanceDate(dateValue);

    if (!date) {
      return res.status(400).json({
        success: false,
        message: "Provide a valid Sunday date using YYYY-MM-DD.",
      });
    }

    if (!mongoose.isValidObjectId(memberId)) {
      return res.status(400).json({
        success: false,
        message: "A valid member ID is required.",
      });
    }

    if (!["present", "absent", "unmarked"].includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Status must be present, absent, or unmarked.",
      });
    }

    const member = await Member.findById(memberId).select("_id");

    if (!member) {
      return res.status(404).json({
        success: false,
        message: "Member not found.",
      });
    }

    const { year, weekNumber } = calculateSundayWeek(date);

    let attendance = await Attendance.findOne({ date });

    if (!attendance) {
      try {
        attendance = await Attendance.create({
          date,
          year,
          weekNumber,
          entries: [],
        });
      } catch (error) {
        // Another request may have created this Sunday's record first.
        if (error.code !== 11000) throw error;
        attendance = await Attendance.findOne({ date });
      }
    }

    const existingIndex = attendance.entries.findIndex(
      (entry) => entry.member.toString() === memberId
    );

    if (status === "unmarked") {
      if (existingIndex !== -1) {
        attendance.entries.splice(existingIndex, 1);
      }
    } else if (existingIndex !== -1) {
      attendance.entries[existingIndex].status = status;
    } else {
      attendance.entries.push({ member: memberId, status });
    }

    // Refresh calculated metadata on every update.
    attendance.year = year;
    attendance.weekNumber = weekNumber;

    await attendance.save();

    return res.status(200).json({
      success: true,
      message: "Attendance updated successfully.",
      data: {
        date: date.toISOString().slice(0, 10),
        year,
        weekNumber,
        memberId,
        status,
      },
    });
  } catch (error) {
    return sendError(res, error);
  }
};

// PUT /api/v1/attendance
// Body: { date, entries: [{ memberId, status }] }
// Saves the submitted attendance selections in one request.
// Existing entries omitted from the request become unmarked.
const saveAttendance = async (req, res) => {
  try {
    const { date: dateValue, entries } = req.body;

    const date = parseAttendanceDate(dateValue);

    if (!date) {
      return res.status(400).json({
        success: false,
        message: "Provide a valid Sunday date using YYYY-MM-DD.",
      });
    }

    if (!Array.isArray(entries)) {
      return res.status(400).json({
        success: false,
        message: "Entries must be an array.",
      });
    }

    const seenIds = new Set();
    const normalizedEntries = [];

    for (const entry of entries) {
      if (
        !entry ||
        !mongoose.isValidObjectId(entry.memberId) ||
        !["present", "absent"].includes(entry.status)
      ) {
        return res.status(400).json({
          success: false,
          message: "Each entry needs a valid memberId and present/absent status.",
        });
      }

      const memberId = entry.memberId.toString();

      if (seenIds.has(memberId)) {
        return res.status(400).json({
          success: false,
          message: "A member can only appear once in attendance entries.",
        });
      }

      seenIds.add(memberId);

      normalizedEntries.push({
        member: memberId,
        status: entry.status,
      });
    }

    const memberIds = normalizedEntries.map((entry) => entry.member);

    const existingMembers = await Member.countDocuments({
      _id: { $in: memberIds },
    });

    if (existingMembers !== memberIds.length) {
      return res.status(400).json({
        success: false,
        message: "One or more submitted members do not exist.",
      });
    }

    const { year, weekNumber } = calculateSundayWeek(date);

    const attendance = await Attendance.findOneAndUpdate(
      { date },
      {
        $set: {
          year,
          weekNumber,
          entries: normalizedEntries,
        },
      },
      {
        new: true,
        upsert: true,
        runValidators: true,
        setDefaultsOnInsert: true,
      }
    );

    return res.status(200).json({
      success: true,
      message: "Attendance saved successfully.",
      data: {
        date: date.toISOString().slice(0, 10),
        year: attendance.year,
        weekNumber: attendance.weekNumber,
        summary: {
          totalMembers: await Member.countDocuments(),
          present: normalizedEntries.filter(
            (entry) => entry.status === "present"
          ).length,
          absent: normalizedEntries.filter(
            (entry) => entry.status === "absent"
          ).length,
          unmarked: await Member.countDocuments() - normalizedEntries.length,
        },
      },
    });
  } catch (error) {
    return sendError(res, error);
  }
};

const getAttendanceSummary = async (req, res) => {
  try {
    const { year, memberId } = req.query;

    const currentYear = new Date().getUTCFullYear();
    const selectedYear = year === undefined ? currentYear : Number(year);

    if (
      !Number.isInteger(selectedYear) ||
      selectedYear < 2000 ||
      selectedYear > 2100
    ) {
      return res.status(400).json({
        success: false,
        message: "Provide a valid year between 2000 and 2100.",
      });
    }

    if (memberId && !mongoose.isValidObjectId(memberId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid member ID.",
      });
    }

    const filter = {
      date: {
        $gte: new Date(Date.UTC(selectedYear, 0, 1)),
        $lt: new Date(Date.UTC(selectedYear + 1, 0, 1)),
      },
    };

    const includeMemberStatus = req.query.includeMemberStatus === "true";

    if (memberId && !includeMemberStatus) {
      filter.entries = {
        $elemMatch: {
          member: new mongoose.Types.ObjectId(memberId),
        },
      };
    }

    const [records, totalMembers] = await Promise.all([
      Attendance.find(filter).sort({ date: -1 }).lean(),
      Member.countDocuments(),
    ]);

    const summaries = records.map((record) => {
      const memberEntry = memberId
        ? record.entries.find(
            (entry) => entry.member.toString() === memberId
          )
        : undefined;
      const entries = memberId
        ? memberEntry ? [memberEntry] : []
        : record.entries;

      const present = entries.filter(
        (entry) => entry.status === "present"
      ).length;

      const absent = entries.filter(
        (entry) => entry.status === "absent"
      ).length;

      return {
        date: record.date.toISOString().slice(0, 10),
        year: record.year,
        weekNumber: record.weekNumber,
        totalMembers,
        present,
        absent,
        unmarked: Math.max(totalMembers - present - absent, 0),
        ...(memberId && includeMemberStatus
          ? { memberStatus: memberEntry?.status ?? "unmarked" }
          : {}),
      };
    });

    return res.status(200).json({
      success: true,
      data: {
        year: selectedYear,
        attendanceSessions: summaries.length,
        records: summaries,
      },
    });
  } catch (error) {
    console.error("Attendance summary error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to load attendance summary.",
    });
  }
};

module.exports = {
  getAttendance,
  updateMemberAttendance,
  saveAttendance,
    getAttendanceSummary,
};
