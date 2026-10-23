
require("dotenv").config();

const express = require("express");
const cors = require("cors");
const attendanceRoutes = require("./src/routes/attendanceRoutes");
const connectDB = require("./src/database");
const authRoutes = require("./src/routes/authRoutes");
const memberRoutes = require("./src/routes/memberRoutes");

const app = express();

app.use(
  cors({
    origin: process.env.WEB_ORIGIN
      ? process.env.WEB_ORIGIN.split(",").map((origin) => origin.trim())
      : true,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

app.use(express.json());

app.get("/", (req, res) => {
  res.json({ message: "Church Backend is running" });
});
app.use("/api/v1/attendance", attendanceRoutes);
app.use("/api/v1/auth", authRoutes);
app.use("/api/v1/members", memberRoutes);

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  await connectDB();

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on port ${PORT}`);
  });
};

startServer();
