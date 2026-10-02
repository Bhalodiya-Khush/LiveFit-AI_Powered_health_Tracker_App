const mongoose = require('mongoose');

const dailyLogSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  date: {
    type: String, // Format: YYYY-MM-DD
    required: true,
  },
  todayDate: {
    type: Date, // Real Date object for today
    default: Date.now,
  },
  steps: {
    type: Number,
    default: 0,
  },
  rawSensorSteps: {
    type: Number,
    default: 0,
  },
  stepBaseline: {
    type: Number,
    default: 0,
  },
  sleepHours: {
    type: Number,
    default: 0,
  },
  sleepBedTime: {
    type: String, // e.g. "11:20 PM"
    default: '',
  },
  sleepWakeTime: {
    type: String, // e.g. "07:15 AM"
    default: '',
  },
  sleepCalculationMethod: {
    type: String,
    default: 'usage_stats',
  },
  sleepInterruptions: {
    type: Number,
    default: 0, // Checks under 2 min threshold
  },
  caloriesConsumed: {
    type: Number,
    default: 0,
  },
  caloriesBurned: {
    type: Number,
    default: 0,
  },
  waterMl: {
    type: Number,
    default: 0,
  },
  activeMinutes: {
    type: Number,
    default: 0,
  },
  isFinalized: {
    type: Boolean,
    default: false,
  },
  lastUpdated: {
    type: Date,
    default: Date.now,
  },
});

// Ensure one log per user per date
dailyLogSchema.index({ user: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('DailyLog', dailyLogSchema);
