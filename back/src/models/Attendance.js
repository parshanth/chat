
const mongoose = require("mongoose");

const attendanceEntrySchema = new mongoose.Schema(
  {
    member: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Member",
      required: true,
    },
    status: {
      type: String,
      enum: ["present", "absent"],
      required: true,
    },
  },
  { _id: false }
);

const attendanceSchema = new mongoose.Schema(
  {
    date: {
      type: Date,
      required: true,
    },
    year: {
      type: Number,
      required: true,
    },
    weekNumber: {
      type: Number,
      required: true,
      min: 1,
      max: 53,
    },
    entries: {
      type: [attendanceEntrySchema],
      default: [],
    },
  },
  { timestamps: true }
);

// Only one attendance record per Sunday.
attendanceSchema.index({ date: 1 }, { unique: true });

// Quickly find attendance records by year and week.
attendanceSchema.index({ year: 1, weekNumber: 1 });

module.exports = mongoose.model("Attendance", attendanceSchema);
