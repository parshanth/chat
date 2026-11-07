
const AuthUser = require("../models/AuthUser");
const jwt = require("jsonwebtoken");
const { logError } = require("../utils/logging");

const register = async (req, res) => {
  console.log("[REGISTER] Route execution started");
  try {
    const { number, password } = req.body;
    console.log(
      "[REGISTER] Required fields received",
      JSON.stringify({
        numberReceived: typeof number === "string" && Boolean(number.trim()),
        passwordReceived: typeof password === "string" && Boolean(password),
      })
    );

    if (
      typeof number !== "string" ||
      !number.trim() ||
      typeof password !== "string" ||
      !password
    ) {
      return res.status(400).json({
        success: false,
        message: "Number and password are required.",
      });
    }

    const normalizedNumber = number.trim();

    let existingUser;
    try {
      existingUser = await AuthUser.findOne({
        number: normalizedNumber,
      });
    } catch (error) {
      logError("[MONGODB]", "Registration user lookup failed", error);
      throw error;
    }
    console.log(
      "[REGISTER] Existing user lookup completed",
      JSON.stringify({ userAlreadyExists: Boolean(existingUser) })
    );

    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: "This number is already registered.",
      });
    }

    let user;
    try {
      user = await AuthUser.create({
        number: normalizedNumber,
        password,
        allowed: false,
      });
    } catch (error) {
      logError("[MONGODB]", "Registration user creation failed", error);
      throw error;
    }
    console.log("[REGISTER] User record created; awaiting approval");

    return res.status(201).json({
      success: true,
      message: "Account created. Awaiting approval.",
      user: {
        id: user._id,
        number: user.number,
        allowed: user.allowed,
      },
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: "This number is already registered.",
      });
    }

    logError("[REGISTER]", "Registration failed", error);

    return res.status(500).json({
      success: false,
      message: "Unable to create account.",
    });
  }
};

const login = async (req, res) => {
  console.log("[LOGIN] Route execution started");
  try {
    const { number, password } = req.body;
    console.log(
      "[LOGIN] Required fields received",
      JSON.stringify({
        numberReceived: typeof number === "string" && Boolean(number.trim()),
        passwordReceived: typeof password === "string" && Boolean(password),
      })
    );

    if (
      typeof number !== "string" ||
      !number.trim() ||
      typeof password !== "string" ||
      !password
    ) {
      return res.status(400).json({
        success: false,
        message: "Number and password are required.",
      });
    }

    let user;
    try {
      user = await AuthUser.findOne({
        number: number.trim(),
      });
    } catch (error) {
      logError("[MONGODB]", "Login user lookup failed", error);
      throw error;
    }
    console.log(
      "[LOGIN] User lookup completed",
      JSON.stringify({ userFound: Boolean(user) })
    );

    const passwordMatches = user ? await user.comparePassword(password) : false;
    console.log(
      "[LOGIN] Password comparison completed",
      JSON.stringify({
        performed: Boolean(user),
        succeeded: passwordMatches,
      })
    );

    if (!user || !passwordMatches) {
      return res.status(401).json({
        success: false,
        message: "Invalid number or password.",
      });
    }

    if (!user.allowed) {
      return res.status(403).json({
        success: false,
        message: "Your account is awaiting approval.",
      });
    }

    if (!process.env.JWT_SECRET) {
      console.error("[LOGIN] JWT_SECRET is missing from environment variables.");

      return res.status(500).json({
        success: false,
        message: "Authentication is not configured.",
      });
    }

    let token;
    try {
      token = jwt.sign(
        {
          userId: user._id.toString(),
        },
        process.env.JWT_SECRET,
        { expiresIn: "7d" }
      );
      console.log("[LOGIN] JWT generation succeeded");
    } catch (error) {
      logError("[LOGIN]", "JWT generation failed", error);
      throw error;
    }

    return res.status(200).json({
      success: true,
      message: "Login successful.",
      token,
      user: {
        id: user._id,
        number: user.number,
        allowed: user.allowed,
      },
    });
  } catch (error) {
    logError("[LOGIN]", "Login failed", error);

    return res.status(500).json({
      success: false,
      message: "Unable to log in.",
    });
  }
};

const getMe = async (req, res) => {
  console.log("[AUTH] Current-user route execution");
  return res.status(200).json({
    success: true,
    user: {
      id: req.user.userId,
      number: req.user.number,
    },
  });
};

module.exports = { register, login, getMe };
