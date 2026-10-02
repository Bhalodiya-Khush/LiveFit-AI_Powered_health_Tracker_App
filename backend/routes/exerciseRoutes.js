const express = require('express');
const router = express.Router();
const Exercise = require('../models/Exercise');
const DailyLog = require('../models/DailyLog');
const Compendium = require('../models/Compendium');
const { protect } = require('../middleware/authMiddleware');
const { getWeather } = require('../services/weatherService');
const { generateTailoredExercises } = require('../services/geminiService');
const { compendiumList } = require('../services/compendiumData');
const { findExerciseDemoInDb, syncExerciseDemosToDatabase } = require('../services/exerciseDemoService');

const getTodayDateString = () => {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

// Seed/Update PA Compendium & Demo GIFs data into DB
router.get('/seed-compendium', async (req, res) => {
  try {
    const count = await syncExerciseDemosToDatabase();
    res.json({ success: true, message: `Exercise demo library synced (${count} exercises)` });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// @route   GET /api/exercises/library
// @desc    Get all demo videos/GIFs and exercise templates from database with search
router.get('/library', protect, async (req, res) => {
  try {
    const { q, category, targetMuscle } = req.query;
    let query = {};
    if (q) {
      query.$or = [
        { name: { $regex: q, $options: 'i' } },
        { aliases: { $regex: q, $options: 'i' } },
        { description: { $regex: q, $options: 'i' } },
      ];
    }
    if (category) query.category = category;
    if (targetMuscle) query.targetMuscle = { $regex: targetMuscle, $options: 'i' };

    const demos = await Compendium.find(query).sort({ name: 1 });
    res.json({ success: true, count: demos.length, demos });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// @route   GET /api/exercises/demo/:name
// @desc    Find best matching demo GIF from DB for any exercise name
router.get('/demo/:name', protect, async (req, res) => {
  try {
    const match = await findExerciseDemoInDb(req.params.name);
    if (!match) {
      return res.status(404).json({ message: 'No demo found' });
    }
    res.json({ success: true, demo: match });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// @route   POST /api/exercises/suggested
// @desc    Generate 5 suggested exercises using Gemini (Weather + Location + Age + Weight + Height + Hurdle)
router.post('/suggested', protect, async (req, res) => {
  try {
    const { lat, lon } = req.body;
    const today = getTodayDateString();

    // 1. Fetch current weather from Open-Meteo (automatically detects location if coordinates omitted)
    const weather = await getWeather(lat ? Number(lat) : null, lon ? Number(lon) : null);

    // 2. Check if user already has suggestions generated for today
    let existingExercises = await Exercise.find({ user: req.user._id, date: today });
    if (existingExercises.length > 0) {
      // Deduplicate by exerciseName in case concurrent calls created duplicate records
      const seen = new Set();
      const unique = [];
      const dupIds = [];
      for (const ex of existingExercises) {
        const key = ex.exerciseName.trim().toLowerCase();
        if (!seen.has(key)) {
          seen.add(key);
          unique.push(ex);
        } else {
          const idx = unique.findIndex(u => u.exerciseName.trim().toLowerCase() === key);
          if (idx !== -1 && !unique[idx].completed && ex.completed) {
            dupIds.push(unique[idx]._id);
            unique[idx] = ex;
          } else {
            dupIds.push(ex._id);
          }
        }
      }

      if (dupIds.length > 0) {
        await Exercise.deleteMany({ _id: { $in: dupIds } });
        console.log(`Cleaned up ${dupIds.length} duplicate exercises for user ${req.user.name}`);
      }

      if (unique.length > 0) {
        return res.json({
          success: true,
          exercises: unique.slice(0, 5),
          weather,
        });
      }
    }

    // 3. User attributes
    const userProfile = {
      age: req.user.age,
      weight: req.user.weight,
      height: req.user.height,
      hurdle: req.user.healthHurdles,
      weather,
    };

    console.log(`Generating 5 exercises for User ${req.user.name} (Age: ${req.user.age}, Weight: ${req.user.weight}kg, Hurdle: ${req.user.healthHurdles})`);

    // 4. Generate with Gemini
    const geminiSuggestions = await generateTailoredExercises(userProfile);

    // Concurrency check: see if parallel request created exercises while waiting for Gemini
    const postCheck = await Exercise.find({ user: req.user._id, date: today });
    if (postCheck.length >= 5) {
      return res.json({
        success: true,
        exercises: postCheck.slice(0, 5),
        weather,
      });
    }

    // 5. Match directly with MongoDB ExerciseDemo database collection
    const createdExercises = [];
    const seenNames = new Set(postCheck.map(e => e.exerciseName.trim().toLowerCase()));

    for (const item of geminiSuggestions) {
      const key = item.exerciseName.trim().toLowerCase();
      if (seenNames.has(key)) continue;
      seenNames.add(key);

      const match = await findExerciseDemoInDb(item.exerciseName, item.targetMuscle, item.category);

      const gifUrl = match ? match.gifUrl : 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/LIlE5Tn.gif';
      const instructions = (match && match.instructions && match.instructions.length > 0)
        ? match.instructions
        : [
            'Perform movement with steady breathing and upright posture.',
            'Keep your core engaged throughout all repetitions.',
            'Rest 45 seconds between sets.',
          ];

      const exerciseDoc = await Exercise.create({
        user: req.user._id,
        date: today,
        exerciseName: item.exerciseName,
        category: item.category || (match ? match.category : 'Conditioning'),
        targetMuscle: item.targetMuscle || (match ? match.targetMuscle : 'Full Body'),
        metValue: item.metValue || (match ? match.met : 5.0),
        durationMinutes: item.durationMinutes || (match ? match.durationMinutes : 15),
        repetitions: item.repetitions || (match ? match.repetitions : '3 sets x 12 reps'),
        gifUrl: gifUrl,
        instructions: instructions,
        reason: item.reason || `Personalized for your ${req.user.age}yr profile in ${weather.condition}`,
        completed: false,
      });

      createdExercises.push(exerciseDoc);
      if (createdExercises.length >= 5) break;
    }

    res.json({
      success: true,
      exercises: createdExercises,
      weather,
    });
  } catch (error) {
    console.error('Error generating exercises:', error);
    res.status(500).json({ message: error.message });
  }
});

// @route   POST /api/exercises/mark-done/:id
// @desc    Mark exercise as completed, calculate calories burned via Compendium MET formula, and update DB
router.post('/mark-done/:id', protect, async (req, res) => {
  try {
    const exercise = await Exercise.findOne({ _id: req.params.id, user: req.user._id });
    if (!exercise) {
      return res.status(404).json({ message: 'Exercise not found' });
    }

    // PA Compendium Formula: Calories Burned = MET * BodyWeight(kg) * (durationMinutes / 60)
    const userWeight = req.user.weight || 70;
    const durationHours = (exercise.durationMinutes || 15) / 60;
    const met = exercise.metValue || 5.0;
    const caloriesBurned = Math.round(met * userWeight * durationHours);

    exercise.completed = true;
    exercise.caloriesBurned = caloriesBurned;
    exercise.completedAt = new Date();
    await exercise.save();

    // Update today's DailyLog
    const today = getTodayDateString();
    const allCompletedToday = await Exercise.find({ user: req.user._id, date: today, completed: true });
    const totalBurnedToday = allCompletedToday.reduce((sum, e) => sum + (e.caloriesBurned || 0), 0);

    await DailyLog.findOneAndUpdate(
      { user: req.user._id, date: today },
      { $set: { caloriesBurned: totalBurnedToday, lastUpdated: new Date() } },
      { upsert: true }
    );

    res.json({
      success: true,
      message: `Great job! You burned ${caloriesBurned} calories!`,
      exercise,
      caloriesBurned,
      totalBurnedToday,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/exercises/today
// @desc    Get all exercises scheduled/completed for today
router.get('/today', protect, async (req, res) => {
  try {
    const today = getTodayDateString();
    let exercises = await Exercise.find({ user: req.user._id, date: today });

    // Deduplicate in case any duplicate entries exist
    const seen = new Set();
    const unique = [];
    const dupIds = [];
    for (const ex of exercises) {
      const key = ex.exerciseName.trim().toLowerCase();
      if (!seen.has(key)) {
        seen.add(key);
        unique.push(ex);
      } else {
        const idx = unique.findIndex(u => u.exerciseName.trim().toLowerCase() === key);
        if (idx !== -1 && !unique[idx].completed && ex.completed) {
          dupIds.push(unique[idx]._id);
          unique[idx] = ex;
        } else {
          dupIds.push(ex._id);
        }
      }
    }

    if (dupIds.length > 0) {
      await Exercise.deleteMany({ _id: { $in: dupIds } });
    }

    const finalExercises = unique.slice(0, 5);
    const totalBurned = finalExercises
      .filter(e => e.completed)
      .reduce((sum, e) => sum + (e.caloriesBurned || 0), 0);

    res.json({
      success: true,
      exercises: finalExercises,
      totalBurned,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
