
const express = require("express");

const {
  getAttendance,
  updateMemberAttendance,
  saveAttendance,
    getAttendanceSummary,
} = require("../controllers/attendanceController");

const authMiddleware = require("../middleware/authMiddleware");
const { safeUrl } = require("../utils/logging");

const router = express.Router();

// All attendance endpoints require an approved, authenticated user.
router.use(authMiddleware);
router.use((req, res, next) => {
  console.log(
    "[ATTENDANCE] Route execution",
    JSON.stringify({
      method: req.method,
      url: safeUrl(req.originalUrl),
      timestamp: new Date().toISOString(),
    })
  );
  next();
});

// Load members and their attendance statuses for a selected Sunday.
router.get("/", getAttendance);

router.get("/summary", getAttendanceSummary);

// Save one member's status immediately.
router.patch("/member", updateMemberAttendance);

// Save the complete attendance selection.
router.put("/", saveAttendance);

module.exports = router;
