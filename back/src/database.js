const mongoose = require("mongoose");

const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);

        console.log("✅ MongoDB Connected");
    } catch (error) {
        console.error("❌ MongoDB Connection Failed");
        console.error(error);

        // Keep process running to allow inspecting logs and using nodemon.
        // Consider adding retry/backoff here if required.
    }
};

module.exports = connectDB;