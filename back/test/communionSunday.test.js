const test = require("node:test");
const assert = require("node:assert/strict");

const { isCommunionSunday } = require("../src/controllers/attendanceController");

test("recognizes only the second Sunday as Communion Sunday", () => {
  assert.equal(isCommunionSunday(new Date("2026-11-01T00:00:00.000Z")), false);
  assert.equal(isCommunionSunday(new Date("2026-11-08T00:00:00.000Z")), true);
  assert.equal(isCommunionSunday(new Date("2026-11-15T00:00:00.000Z")), false);
});

test("does not accept a weekday in the second-week date range", () => {
  assert.equal(isCommunionSunday(new Date("2026-11-09T00:00:00.000Z")), false);
});
