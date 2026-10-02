const mongoose = require('mongoose');

const compendiumSchema = new mongoose.Schema({
  code: {
    type: String,
    required: true,
    unique: true,
  },
  name: {
    type: String,
    required: true,
    index: true,
  },
  aliases: [{
    type: String,
    index: true,
  }],
  category: {
    type: String,
    required: true, // e.g. Conditioning Exercise, Walking, Running, Yoga, Core, Strength
  },
  description: {
    type: String,
    required: true,
  },
  met: {
    type: Number,
    required: true,
  },
  targetMuscle: {
    type: String,
    default: 'General',
  },
  exerciseDbId: {
    type: String,
    default: '',
  },
  gifUrl: {
    type: String,
    required: true, // Direct demo video/GIF link stored in DB
  },
  instructions: {
    type: [String],
    default: [],
  },
  repetitions: {
    type: String,
    default: '3 sets x 12 reps',
  },
  durationMinutes: {
    type: Number,
    default: 15,
  },
  difficulty: {
    type: String,
    default: 'Beginner',
  },
  createdAt: {
    type: Date,
    default: Date.now,
  }
});

// Text index for fast full-text searching by exercise name or alias
compendiumSchema.index({ name: 'text', aliases: 'text', description: 'text', targetMuscle: 'text' });

module.exports = mongoose.model('Compendium', compendiumSchema);

