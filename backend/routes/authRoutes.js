const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { protect } = require('../middleware/authMiddleware');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'livefit_jwt_secret', {
    expiresIn: '30d',
  });
};

// @route   POST /api/auth/register
// @desc    Register a new user
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, birthDate, gender, height, weight, healthHurdles } = req.body;

    if (!email || !password || !name || !birthDate) {
      return res.status(400).json({ message: 'Name, email, password, and birthDate are required' });
    }

    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({ message: 'User with this email already exists' });
    }

    const user = await User.create({
      name,
      email,
      password,
      birthDate: new Date(birthDate),
      gender: gender || 'male',
      height: Number(height) || 175,
      weight: Number(weight) || 70,
      healthHurdles: healthHurdles || 'none',
    });

    const token = generateToken(user._id);

    res.status(201).json({
      success: true,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        birthDate: user.birthDate,
        age: user.age,
        gender: user.gender,
        height: user.height,
        weight: user.weight,
        healthHurdles: user.healthHurdles,
        dailyStepGoal: user.dailyStepGoal,
        dailyCalorieGoal: user.dailyCalorieGoal,
        dailySleepGoal: user.dailySleepGoal,
      },
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ message: error.message || 'Server error during registration' });
  }
});

// @route   POST /api/auth/login
// @desc    Authenticate user & get token
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Please provide email and password' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const token = generateToken(user._id);

    res.json({
      success: true,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        birthDate: user.birthDate,
        age: user.age,
        gender: user.gender,
        height: user.height,
        weight: user.weight,
        healthHurdles: user.healthHurdles,
        dailyStepGoal: user.dailyStepGoal,
        dailyCalorieGoal: user.dailyCalorieGoal,
        dailySleepGoal: user.dailySleepGoal,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: error.message || 'Server error during login' });
  }
});

// @route   GET /api/auth/profile
// @desc    Get user profile with calculated age
router.get('/profile', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    res.json({
      success: true,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        birthDate: user.birthDate,
        age: user.age,
        gender: user.gender,
        height: user.height,
        weight: user.weight,
        healthHurdles: user.healthHurdles,
        dailyStepGoal: user.dailyStepGoal,
        dailyCalorieGoal: user.dailyCalorieGoal,
        dailySleepGoal: user.dailySleepGoal,
      },
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   PUT /api/auth/profile
// @desc    Update user profile (weight, height, birthDate, health hurdles)
router.put('/profile', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (req.body.name) user.name = req.body.name;
    if (req.body.height) user.height = Number(req.body.height);
    if (req.body.weight) user.weight = Number(req.body.weight);
    if (req.body.gender) user.gender = req.body.gender;
    if (req.body.healthHurdles !== undefined) user.healthHurdles = req.body.healthHurdles;
    if (req.body.birthDate) user.birthDate = new Date(req.body.birthDate);
    if (req.body.dailyStepGoal) user.dailyStepGoal = Number(req.body.dailyStepGoal);
    if (req.body.dailyCalorieGoal) user.dailyCalorieGoal = Number(req.body.dailyCalorieGoal);
    if (req.body.dailySleepGoal) user.dailySleepGoal = Number(req.body.dailySleepGoal);

    await user.save();

    res.json({
      success: true,
      message: 'Profile updated successfully',
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        birthDate: user.birthDate,
        age: user.age,
        gender: user.gender,
        height: user.height,
        weight: user.weight,
        healthHurdles: user.healthHurdles,
        dailyStepGoal: user.dailyStepGoal,
        dailyCalorieGoal: user.dailyCalorieGoal,
        dailySleepGoal: user.dailySleepGoal,
      },
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
