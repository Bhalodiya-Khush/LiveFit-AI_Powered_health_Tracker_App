const mongoose = require('mongoose');

const exerciseSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  date: {
    type: String, // YYYY-MM-DD
    required: true,
  },
  exerciseName: {
    type: String,
    required: true,
  },
  category: {
    type: String,
    default: 'Conditioning',
  },
  targetMuscle: {
    type: String,
    default: 'Full Body',
  },
  metValue: {
    type: Number,
    required: true,
    default: 5.0, // Compendium MET
  },
  durationMinutes: {
    type: Number,
    required: true,
    default: 15,
  },
  repetitions: {
    type: String,
    default: '3 sets x 12 reps',
  },
  caloriesBurned: {
    type: Number,
    default: 0,
  },
  gifUrl: {
    type: String,
    default: '',
  },
  instructions: {
    type: [String],
    default: [],
  },
  reason: {
    type: String,
    default: 'Recommended based on your daily profile and weather.',
  },
  completed: {
    type: Boolean,
    default: false,
  },
  completedAt: {
    type: Date,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Exercise', exerciseSchema);
