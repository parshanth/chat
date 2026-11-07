
const jwt = require("jsonwebtoken");
const AuthUser = require("../models/AuthUser");
const { logError, safeUrl } = require("../utils/logging");

const authMiddleware = async (req, res, next) => {
  console.log(
    "[AUTH] Middleware execution",
    JSON.stringify({
      method: req.method,
      url: safeUrl(req.originalUrl),
    })
  );
  try {
    const authHeader = req.headers.authorization;
    const tokenReceived =
      typeof authHeader === "string" && authHeader.startsWith("Bearer ");
    console.log(
      "[AUTH] Authorization token received",
      JSON.stringify({ tokenReceived })
    );

    if (!tokenReceived) {
      return res.status(401).json({
        success: false,
        message: "Authentication token is required.",
      });
    }

    if (!process.env.JWT_SECRET) {
      return res.status(500).json({
        success: false,
        message: "Authentication is not configured.",
      });
    }

    const token = authHeader.split(" ")[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    let user;
    try {
      user = await AuthUser.findById(decoded.userId).select(
        "_id number allowed"
      );
    } catch (error) {
      logError("[MONGODB]", "Protected-route user lookup failed", error);
      throw error;
    }

    if (!user || !user.allowed) {
      return res.status(403).json({
        success: false,
        message: "Account access is not approved.",
      });
    }

    req.user = {
      userId: user._id.toString(),
      number: user.number,
    };

    next();
  } catch (error) {
    if (
      error.name === "JsonWebTokenError" ||
      error.name === "TokenExpiredError"
    ) {
      return res.status(401).json({
        success: false,
        message: "Invalid or expired authentication token.",
      });
    }

    logError("[AUTH]", "Authentication failed", error);

    return res.status(500).json({
      success: false,
      message: "Authentication failed.",
    });
  }
};

module.exports = authMiddleware;
