const mongoose = require("mongoose");
const { logError } = require("./utils/logging");

const connectDB = async () => {
    try {
        console.log("[MONGODB] Connecting");
        await mongoose.connect(process.env.MONGODB_URI);

        console.log("[MONGODB] Connected");
        mongoose.connection.on("disconnected", () => {
            console.warn("[MONGODB] Disconnected");
        });
        mongoose.connection.on("reconnected", () => {
            console.log("[MONGODB] Reconnected");
        });
        mongoose.connection.on("error", (error) => {
            logError("[MONGODB]", "Connection error", error);
        });
    } catch (error) {
        logError("[MONGODB]", "Connection failed", error);

        // Keep process running to allow inspecting logs and using nodemon.
        // Consider adding retry/backoff here if required.
    }
};

module.exports = connectDB;