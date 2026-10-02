const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true,
  },
  password: {
    type: String,
    required: true,
  },
  birthDate: {
    type: Date,
    required: true,
  },
  gender: {
    type: String,
    enum: ['male', 'female', 'other'],
    default: 'male',
  },
  height: {
    type: Number, // in cm
    required: true,
    default: 175,
  },
  weight: {
    type: Number, // in kg
    required: true,
    default: 70,
  },
  healthHurdles: {
    type: String, // e.g. "knee pain", "lower back stiffness", "asthma", "none"
    default: 'none',
  },
  dailyStepGoal: {
    type: Number,
    default: 10000,
  },
  dailyCalorieGoal: {
    type: Number,
    default: 2200,
  },
  dailySleepGoal: {
    type: Number, // in hours
    default: 8,
  },
  lastPedometerReading: {
    type: Number,
    default: -1,
  },
  lastStepDate: {
    type: String,
    default: '',
  },
  lastStepBaseline: {
    type: Number,
    default: 0,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
}, {
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Calculate age from birthDate dynamically
userSchema.virtual('age').get(function () {
  if (!this.birthDate) return 25;
  const today = new Date();
  const birthDate = new Date(this.birthDate);
  let age = today.getFullYear() - birthDate.getFullYear();
  const m = today.getMonth() - birthDate.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
    age--;
  }
  return age > 0 ? age : 18;
});

// Password hashing before saving
userSchema.pre('save', async function () {
  if (!this.isModified('password')) return;
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// Compare password method
userSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
