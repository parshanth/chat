
const Attendance = require("../models/Attendance");
const { logAttendanceChange } = require("../utils/attendanceLog");
const Member = require("../models/Member");
const mongoose = require("mongoose");
const { logError } = require("../utils/logging");

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

// A Sunday is the second Sunday when its day of month is 8 through 14.
const isCommunionSunday = (date) =>
  date.getUTCDay() === 0 && date.getUTCDate() >= 8 && date.getUTCDate() <= 14;

const sendError = (res, error) => {
  if (error.code === 11000) {
    return res.status(409).json({
      success: false,
      message: "Attendance for this Sunday is being updated. Please retry.",
    });
  }

  logError("[MONGODB]", "Attendance query/operation failed", error);

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

    const communionByMember = new Map(
      (attendance?.communionEntries ?? []).map((entry) => [
        entry.member.toString(),
        entry.status,
      ])
    );
    const communionSunday = isCommunionSunday(date);

    const entries = members.map((member) => {
      const communionEligible = communionSunday && Boolean(member.baptismDate);
      return {
        ...member,
        status: statusByMember.get(member._id.toString()) ?? "unmarked",
        communionEligible,
        communionStatus: communionEligible
          ? communionByMember.get(member._id.toString()) ?? "absent"
          : "not_applicable",
      };
    });

    const communionEligible = entries.filter((m) => m.communionEligible);

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
          communion: {
            applicable: communionSunday,
            eligible: communionEligible.length,
            present: communionEligible.filter(
              (m) => m.communionStatus === "present"
            ).length,
            absent: communionEligible.filter(
              (m) => m.communionStatus === "absent"
            ).length,
          },
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

    const member = await Member.findById(memberId).select("_id name");

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

    const previousStatus = existingIndex === -1 ? "unmarked" : attendance.entries[existingIndex].status;
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

    await logAttendanceChange(req, date, memberId, member.name, previousStatus, status);

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

// PATCH /api/v1/attendance/communion
// Body: { date, memberId, status }. Communion never changes normal attendance.
const updateMemberCommunion = async (req, res) => {
  try {
    const { date: dateValue, memberId, status } = req.body;
    const date = parseAttendanceDate(dateValue);

    if (!date) {
      return res.status(400).json({
        success: false,
        message: "Provide a valid Sunday date using YYYY-MM-DD.",
      });
    }
    if (!isCommunionSunday(date)) {
      return res.status(400).json({
        success: false,
        message: "Communion can only be recorded on the second Sunday.",
      });
    }
    if (!mongoose.isValidObjectId(memberId)) {
      return res.status(400).json({
        success: false,
        message: "A valid member ID is required.",
      });
    }
    if (!["present", "absent"].includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Communion status must be present or absent.",
      });
    }

    const member = await Member.findById(memberId).select("_id name baptismDate");
    if (!member) {
      return res
        .status(404)
        .json({ success: false, message: "Member not found." });
    }
    if (!member.baptismDate) {
      return res.status(400).json({
        success: false,
        message: "Communion is only available to members with a baptism date.",
      });
    }

    const { year, weekNumber } = calculateSundayWeek(date);
    const attendance = await Attendance.findOneAndUpdate(
      { date },
      { $setOnInsert: { date, year, weekNumber, entries: [] } },
      { new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true }
    );
    const existingIndex = attendance.communionEntries.findIndex(
      (entry) => entry.member.toString() === memberId
    );
    const previousStatus = existingIndex === -1 ? "absent" : attendance.communionEntries[existingIndex].status;
    if (existingIndex === -1) {
      attendance.communionEntries.push({ member: memberId, status });
    } else {
      attendance.communionEntries[existingIndex].status = status;
    }
    await attendance.save();
    await logAttendanceChange(req, date, memberId, member.name, previousStatus, status, "communion");

    return res.status(200).json({
      success: true,
      message: "Communion attendance updated successfully.",
      data: { date: dateValue, memberId, communionStatus: status },
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

    const previousAttendance = await Attendance.findOne({ date }).lean();
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

    const before = new Map((previousAttendance?.entries ?? []).map(entry => [entry.member.toString(), entry.status]));
    const after = new Map(normalizedEntries.map(entry => [entry.member.toString(), entry.status]));
    const changedMembers = await Member.find({
      _id: { $in: [...new Set([...before.keys(), ...after.keys()])] },
    }).select("_id name").lean();
    const names = new Map(changedMembers.map(member => [member._id.toString(), member.name]));
    for (const id of new Set([...before.keys(), ...after.keys()])) {
      await logAttendanceChange(req, date, id, names.get(id), before.get(id) ?? "unmarked", after.get(id) ?? "unmarked");
    }

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

    const [records, totalMembers, totalBaptizedMembers, selectedMember] =
      await Promise.all([
      Attendance.find(filter).sort({ date: -1 }).lean(),
      Member.countDocuments(),
      Member.countDocuments({ baptismDate: { $ne: null } }),
      memberId
        ? Member.findById(memberId).select("baptismDate").lean()
        : Promise.resolve(null),
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

      const communionApplicable = isCommunionSunday(record.date);
      const communionEntries = record.communionEntries ?? [];
      const communionPresent = communionEntries.filter(
        (entry) => entry.status === "present"
      ).length;
      // Missing Communion marks are absences for eligible members, matching
      // the weekly roster returned by getAttendance.
      const communionAbsent = communionApplicable
        ? Math.max(totalBaptizedMembers - communionPresent, 0)
        : 0;
      const memberCommunionEntry = memberId
        ? communionEntries.find((entry) => entry.member.toString() === memberId)
        : undefined;
      const memberCommunionEligible =
        communionApplicable && Boolean(selectedMember?.baptismDate);

      return {
        date: record.date.toISOString().slice(0, 10),
        year: record.year,
        weekNumber: record.weekNumber,
        totalMembers,
        present,
        absent,
        unmarked: Math.max(totalMembers - present - absent, 0),
        communion: {
          applicable: communionApplicable,
          eligible: communionApplicable ? totalBaptizedMembers : 0,
          present: communionPresent,
          absent: communionAbsent,
        },
        ...(memberId && includeMemberStatus
          ? {
              memberStatus: memberEntry?.status ?? "unmarked",
              memberCommunionStatus: memberCommunionEligible
                ? memberCommunionEntry?.status ?? "absent"
                : "not_applicable",
            }
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
    logError("[MONGODB]", "Attendance summary query failed", error);

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
  updateMemberCommunion,
  getAttendanceSummary,
  // Exported for focused unit tests without weakening route validation.
  isCommunionSunday,
};
