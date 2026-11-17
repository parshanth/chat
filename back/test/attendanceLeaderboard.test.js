const { test, mock } = require('node:test');
const assert = require('node:assert/strict');
const Attendance = require('../src/models/Attendance');
const Member = require('../src/models/Member');
const { getAttendanceLeaderboard } = require('../src/controllers/attendanceController');
const queryResult = value => ({ select: () => ({ lean: async () => value }) });
const response = () => ({ status(code) { this.code = code; return this; }, json(body) { this.body = body; return this; } });

test('counts recorded marks, retains zero-count members and filters the selected year', async () => {
  let filter;
  mock.method(Member, 'find', () => queryResult([{ _id: 'a', name: 'Anna' }, { _id: 'b', name: 'Ben' }]));
  mock.method(Attendance, 'find', value => {
    filter = value;
    return queryResult([
      { entries: [{ member: 'a', status: 'present' }, { member: 'b', status: 'unmarked' }] },
      { entries: [{ member: 'a', status: 'absent' }, { member: 'deleted', status: 'present' }] },
      { entries: [{ member: 'a', status: 'present' }] },
    ]);
  });
  try {
    const res = response();
    await getAttendanceLeaderboard({ query: { year: '2026' } }, res);
    assert.equal(res.code, 200);
    assert.equal(filter.date.$gte.toISOString(), '2026-01-01T00:00:00.000Z');
    assert.equal(filter.date.$lt.toISOString(), '2027-01-01T00:00:00.000Z');
    assert.deepEqual(res.body.data.members, [
      { memberId: 'a', name: 'Anna', present: 2, absent: 1 },
      { memberId: 'b', name: 'Ben', present: 0, absent: 0 },
    ]);
  } finally { mock.restoreAll(); }
});

test('rejects invalid years', async () => {
  for (const year of ['bad', '1999', '2101', '2026.5', '']) {
    const res = response();
    await getAttendanceLeaderboard({ query: { year } }, res);
    assert.equal(res.code, 400);
  }
});

test('includes members when no attendance was recorded', async () => {
  mock.method(Member, 'find', () => queryResult([{ _id: 'a', name: 'Anna' }]));
  mock.method(Attendance, 'find', () => queryResult([]));
  try {
    const res = response();
    await getAttendanceLeaderboard({ query: { year: '2025' } }, res);
    assert.equal(res.body.data.attendanceSessions, 0);
    assert.deepEqual(res.body.data.members, [{ memberId: 'a', name: 'Anna', present: 0, absent: 0 }]);
  } finally { mock.restoreAll(); }
});
