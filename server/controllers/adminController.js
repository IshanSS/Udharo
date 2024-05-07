const asyncHandler = require("express-async-handler");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const Admin = require("../models/adminModel");
const User = require("../models/registrationModel");

/*
  @desc Register an admin
  @routes POST /api/admin/register
  @access public
*/
const registerAdmin = asyncHandler(async (req, res) => {
  let { email, password } = req.body;
  email = email.trim();
  password = password.trim();

  if (email == "" || password == "") {
    res.status(400);
    throw new Error("All fields are mandatory");
  } else if (!/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/.test(email)) {
    res
      .status(400)
      .json({ status: "Failed", message: "Invalid Email Entered" });
  }

  const adminAvailable = await Admin.findOne({ email });
  if (adminAvailable) {
    res.status(400);
    throw new Error("Admin already registered");
  }

  const hashedPassword = await bcrypt.hash(password, 10);

  const newAdmin = await Admin.create({
    email,
    password: hashedPassword,
  });

  console.log(`Admin created ${newAdmin}`);
  if (newAdmin) {
    res.status(201).json({ _id: newAdmin._id, email: newAdmin.email });
  } else {
    res.status(400);
    throw new Error("Admin data is not valid");
  }
});

/*
admin login
  @desc Login an admin
  @routes POST /api/admin/login
  @access public
*/
const loginAdmin = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    res.status(400);
    throw new Error("Email and password are required");
  }

  const admin = await Admin.findOne({ email });

  if (!admin) {
    res.status(401);
    throw new Error("Invalid email or password");
  }

  const isMatch = await bcrypt.compare(password, admin.password);

  if (!isMatch) {
    res.status(401);
    throw new Error("Invalid email or password");
  }

  const token = jwt.sign(
    { id: admin._id, email: admin.email },
    process.env.ACCESS_TOKEN_SECRET,
    {
      expiresIn: "1h",
    }
  );

  res.status(200).json({ token });
});

/*
admin details
  @desc admin details
  @routes POST /api/admin/admindetails
  @access private
*/
const getAdminDetails = asyncHandler(async (req, res) => {
  console.log(req.user.email);
  const adminEmail = req.user.email;

  const admin = await Admin.findOne({ email: adminEmail });

  if (!admin) {
    res.status(404).json({ message: "Admin not found" });
    return;
  }

  res.status(200).json({
    email: admin.email,
  });
});

/*
  @desc Get user details
  @route GET /api/admin/userdetails/:id
  @access Private
*/

const getUserById = asyncHandler(async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      res.status(404).json({ message: "User not found" });
      return;
    }

    res.json({
      status: "Success",
      data: {
        userName: user.fullName,
        email: user.email,
        isVerified: user.is_verified,
        riskFactor: user.riskFactor,
      },
    });
  } catch (error) {
    res.status(500).json({ message: "Internal server error" });
  }
});

const admin = (module.exports = {
  registerAdmin,
  loginAdmin,
  getAdminDetails,
  getUserById,
});
