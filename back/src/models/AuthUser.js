
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const authUserSchema = new mongoose.Schema(
  {
    number: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    password: {
      type: String,
      required: true,
    },
    allowed: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

authUserSchema.pre("save", async function () {
  if (!this.isModified("password")) return;

  this.password = await bcrypt.hash(this.password, 12);
});

authUserSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model("AuthUser", authUserSchema);
