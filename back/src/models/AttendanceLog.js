const mongoose = require("mongoose");

const schema = new mongoose.Schema({
  message: { type: String, required: true },
  date: { type: Date, required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, required: true },
}, { timestamps: true });
schema.index({ createdAt: -1, _id: -1 });
module.exports = mongoose.model("AttendanceLog", schema);
