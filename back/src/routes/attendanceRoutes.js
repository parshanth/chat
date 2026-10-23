
const express = require("express");

const {
  getAttendance,
  updateMemberAttendance,
  saveAttendance,
    getAttendanceSummary,
} = require("../controllers/attendanceController");

const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

// All attendance endpoints require an approved, authenticated user.
router.use(authMiddleware);

// Load members and their attendance statuses for a selected Sunday.
router.get("/", getAttendance);

router.get("/summary", getAttendanceSummary);

// Save one member's status immediately.
router.patch("/member", updateMemberAttendance);

// Save the complete attendance selection.
router.put("/", saveAttendance);

module.exports = router;
