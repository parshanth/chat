
require("dotenv").config();

const express = require("express");
const cors = require("cors");
const attendanceRoutes = require("./src/routes/attendanceRoutes");
const connectDB = require("./src/database");
const authRoutes = require("./src/routes/authRoutes");
const memberRoutes = require("./src/routes/memberRoutes");
const { logError, safeUrl } = require("./src/utils/logging");

const app = express();

process.on("unhandledRejection", (reason) => {
  logError("[ERROR]", "Unhandled promise rejection", reason);
});

process.on("uncaughtException", (error) => {
  logError("[ERROR]", "Uncaught exception; terminating process", error);
  process.exit(1);
});

app.use((req, res, next) => {
  const requestTimestamp = new Date();
  const startedAt = Date.now();
  const requestUrl = safeUrl(req.originalUrl);

  console.log(
    "[REQUEST] Incoming",
    JSON.stringify({
      method: req.method,
      url: requestUrl,
      timestamp: requestTimestamp.toISOString(),
    })
  );

  res.on("finish", () => {
    console.log(
      "[REQUEST] Completed",
      JSON.stringify({
        method: req.method,
        url: requestUrl,
        timestamp: new Date().toISOString(),
        durationMs: Date.now() - startedAt,
        statusCode: res.statusCode,
      })
    );
  });

  res.on("close", () => {
    if (!res.writableEnded) {
      console.warn(
        "[REQUEST] Client disconnected before response completed",
        JSON.stringify({
          method: req.method,
          url: requestUrl,
          durationMs: Date.now() - startedAt,
        })
      );
    }
  });

  next();
});

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

app.use((error, req, res, next) => {
  logError("[ERROR]", `${req.method} ${safeUrl(req.originalUrl)}`, error);
  next(error);
});

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  console.log("[SERVER] Starting", JSON.stringify({
    timestamp: new Date().toISOString(),
    port: PORT,
  }));
  await connectDB();

  const server = app.listen(PORT, "0.0.0.0", () => {
    console.log(
      "[SERVER] Listening",
      JSON.stringify({
        timestamp: new Date().toISOString(),
        port: PORT,
        host: "0.0.0.0",
      })
    );
  });
  server.on("error", (error) => {
    logError("[ERROR]", "HTTP server startup/runtime error", error);
  });
};

startServer().catch((error) => {
  logError("[ERROR]", "Server startup failed", error);
  process.exitCode = 1;
});
