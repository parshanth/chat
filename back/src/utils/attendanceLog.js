// Log only committed changes; identity comes from the authenticated session.
const logAttendanceChange = (req, date, memberId, memberName, previousStatus, status, type = "attendance") => {
  if (previousStatus === status) return;
  console.log("[ATTENDANCE_CHANGE]", JSON.stringify({
    timestamp: new Date().toISOString(),
    userId: req.user.userId,
    userNumber: req.user.number,
    memberId: memberId.toString(),
    memberName,
    date: date.toISOString().slice(0, 10),
    type,
    previousStatus,
    status,
    message: `${req.user.number} marked ${memberName || memberId} as ${status} (${type})`,
  }));
};

module.exports = { logAttendanceChange };
