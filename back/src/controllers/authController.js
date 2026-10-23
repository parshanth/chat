
const AuthUser = require("../models/AuthUser");
const jwt = require("jsonwebtoken");

const register = async (req, res) => {
  try {
    const { number, password } = req.body;

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

    const existingUser = await AuthUser.findOne({
      number: normalizedNumber,
    });

    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: "This number is already registered.",
      });
    }

    const user = await AuthUser.create({
      number: normalizedNumber,
      password,
      allowed: false,
    });

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

    console.error("Registration error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to create account.",
    });
  }
};

const login = async (req, res) => {
  try {
    const { number, password } = req.body;

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

    const user = await AuthUser.findOne({
      number: number.trim(),
    });

    if (!user || !(await user.comparePassword(password))) {
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
      console.error("JWT_SECRET is missing from environment variables.");

      return res.status(500).json({
        success: false,
        message: "Authentication is not configured.",
      });
    }

    const token = jwt.sign(
      {
        userId: user._id.toString(),
      },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

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
    console.error("Login error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to log in.",
    });
  }
};

const getMe = async (req, res) => {
  return res.status(200).json({
    success: true,
    user: {
      id: req.user.userId,
      number: req.user.number,
    },
  });
};

module.exports = { register, login, getMe };
