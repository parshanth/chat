
const mongoose = require("mongoose");

const memberSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, "Member name is required"],
      trim: true,
    },
    dob: {
      type: Date,
      default: null,
    },
    phoneNumber: {
      type: String,
      trim: true,
      default: "",
    },
    baptismDate: {
      type: Date,
      default: null,
    },
    marriageDate: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Member", memberSchema);
