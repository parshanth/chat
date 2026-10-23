const assert = require("node:assert/strict");
const test = require("node:test");

const { parseMarriageDate } = require("../src/controllers/memberController");

test("accepts an omitted or explicitly cleared marriage date", () => {
  assert.equal(parseMarriageDate(undefined), null);
  assert.equal(parseMarriageDate(null), null);
  assert.equal(parseMarriageDate(""), null);
});

test("parses a valid ISO marriage date", () => {
  assert.equal(
    parseMarriageDate("2020-10-23").toISOString(),
    "2020-10-23T00:00:00.000Z"
  );
});

test("rejects invalid and future marriage dates", () => {
  assert.throws(() => parseMarriageDate("2020-02-30"), /Invalid marriage date/);

  const tomorrow = new Date();
  tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
  const futureDate = [
    tomorrow.getUTCFullYear(),
    String(tomorrow.getUTCMonth() + 1).padStart(2, "0"),
    String(tomorrow.getUTCDate()).padStart(2, "0"),
  ].join("-");

  assert.throws(() => parseMarriageDate(futureDate), /cannot be in the future/);
});
