// Log only committed changes; identity comes from the authenticated session.
const logAttendanceChange = (req, date, memberId, memberName, previousStatus, status, type = "attendance") => {
  if (previousStatus === status) return;
  const clean = (value) => String(value).replace(/[\r\n\u2028\u2029]/g, " ");
  const user = clean(req.user.number);
  const member = clean(memberName || memberId);
  const communion = type === "communion" ? " Communion" : "";
  const action = previousStatus === "unmarked"
    ? `marked ${member}${communion} as ${status}`
    : `changed ${member}${communion} from ${previousStatus} to ${status}`;
  console.log(`${user} ${action}`);
};

module.exports = { logAttendanceChange };
