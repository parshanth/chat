
const mongoose = require("mongoose");
const Member = require("../models/Member");

const createMember = async (req, res) => {
  try {
    const { name, dob, phoneNumber, baptismDate } = req.body;

    if (typeof name !== "string" || !name.trim()) {
      return res.status(400).json({
        success: false,
        message: "Member name is required.",
      });
    }

    const member = await Member.create({
      name: name.trim(),
      dob: parseOptionalDate(dob),
      phoneNumber:
        typeof phoneNumber === "string" ? phoneNumber.trim() : "",
      baptismDate: parseOptionalDate(baptismDate),
    });

    return res.status(201).json({
      success: true,
      message: "Member created successfully.",
      member,
    });
  } catch (error) {
    if (error instanceof TypeError && error.message.startsWith("Invalid date")) {
      return res.status(400).json({
        success: false,
        message: error.message,
      });
    }

    console.error("Create member error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to create member.",
    });
  }
};

const parseOptionalDate = (value) => {
  if (value === undefined || value === null || value === "") {
    return null;
  }

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    throw new TypeError("Invalid date. Please provide a valid date.");
  }

  return date;
};

const getMembers = async (req, res) => {
  try {
    const members = await Member.find().sort({ name: 1 });

    return res.status(200).json({
      success: true,
      count: members.length,
      members,
    });
  } catch (error) {
    console.error("Get members error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to retrieve members.",
    });
  }
};

const getMemberById = async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid member ID.",
      });
    }

    const member = await Member.findById(req.params.id);

    if (!member) {
      return res.status(404).json({
        success: false,
        message: "Member not found.",
      });
    }

    return res.status(200).json({
      success: true,
      member,
    });
  } catch (error) {
    console.error("Get member error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to retrieve member.",
    });
  }
};

const updateMember = async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid member ID.",
      });
    }

    const allowedFields = ["name", "dob", "phoneNumber", "baptismDate"];
    const updates = {};

    for (const field of allowedFields) {
      if (Object.prototype.hasOwnProperty.call(req.body, field)) {
        if (field === "name") {
          if (typeof req.body.name !== "string" || !req.body.name.trim()) {
            return res.status(400).json({
              success: false,
              message: "Member name cannot be empty.",
            });
          }

          updates.name = req.body.name.trim();
        } else if (field === "phoneNumber") {
          if (typeof req.body.phoneNumber !== "string") {
            return res.status(400).json({
              success: false,
              message: "Phone number must be text.",
            });
          }

          updates.phoneNumber = req.body.phoneNumber.trim();
        } else {
          updates[field] = parseOptionalDate(req.body[field]);
        }
      }
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({
        success: false,
        message: "No valid fields provided to update.",
      });
    }

    const member = await Member.findByIdAndUpdate(
      req.params.id,
      { $set: updates },
      { new: true, runValidators: true }
    );

    if (!member) {
      return res.status(404).json({
        success: false,
        message: "Member not found.",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Member updated successfully.",
      member,
    });
  } catch (error) {
    if (error instanceof TypeError && error.message.startsWith("Invalid date")) {
      return res.status(400).json({
        success: false,
        message: error.message,
      });
    }

    console.error("Update member error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to update member.",
    });
  }
};

const deleteMember = async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid member ID.",
      });
    }

    const member = await Member.findByIdAndDelete(req.params.id);

    if (!member) {
      return res.status(404).json({
        success: false,
        message: "Member not found.",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Member deleted successfully.",
    });
  } catch (error) {
    console.error("Delete member error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to delete member.",
    });
  }
};

module.exports = {
  createMember,
  getMembers,
  getMemberById,
  updateMember,
  deleteMember,
};
