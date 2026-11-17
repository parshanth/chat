
const express = require("express");

const {
  getAttendance,
  updateMemberAttendance,
  saveAttendance,
  updateMemberCommunion,
  getAttendanceSummary,
  getAttendanceLeaderboard,
} = require("../controllers/attendanceController");

const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

// All attendance endpoints require an approved, authenticated user.
router.use(authMiddleware);

// Keep the secret out of URLs and validate it on every history request.
router.post("/logs", async (req, res) => {
  if (req.body.secret !== (process.env.ATTENDANCE_LOG_SECRET || "vethanvn")) {
    return res.status(403).json({ success: false, message: "Incorrect secret code." });
  }
  try {
    const AttendanceLog = require("../models/AttendanceLog");
    const filter = {};
    if (req.body.before) {
      const mongoose = require("mongoose");
      if (!mongoose.isValidObjectId(req.body.before)) {
        return res.status(400).json({ success: false, message: "Invalid history cursor." });
      }
      filter._id = { $lt: req.body.before };
    }
    const logs = await AttendanceLog.find(filter).sort({ _id: -1 }).limit(100).lean();
    return res.json({ success: true, logs, hasMore: logs.length === 100 });
  } catch (error) {
    return res.status(500).json({ success: false, message: "Unable to load activity logs." });
  }
});

// Load members and their attendance statuses for a selected Sunday.
router.get("/", getAttendance);

router.get("/summary", getAttendanceSummary);
router.get("/leaderboard", getAttendanceLeaderboard);

// Save one member's status immediately.
router.patch("/member", updateMemberAttendance);

// Save Communion independently from ordinary attendance.
router.patch("/communion", updateMemberCommunion);

// Save the complete attendance selection.
router.put("/", saveAttendance);

module.exports = router;
