const express = require('express');
const router = express.Router();
const DailyLog = require('../models/DailyLog');
const Meal = require('../models/Meal');
const Exercise = require('../models/Exercise');
const { protect } = require('../middleware/authMiddleware');

const formatDate = (date) => {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
};

const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

// @route   GET /api/reports/weekly
// @desc    Get 7-day analytics for steps, sleep, calories consumed, calories burned, and exercise counts
router.get('/weekly', protect, async (req, res) => {
  try {
    const days = [];
    const now = new Date();
    // Anchor to noon to prevent midnight/DST shifts from producing duplicate days
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 12, 0, 0);

    // Generate last 7 dates
    for (let i = 6; i >= 0; i--) {
      const d = new Date(today);
      d.setDate(today.getDate() - i);
      days.push({
        dateStr: formatDate(d),
        dayName: dayNames[d.getDay()],
        dayDate: d.getDate(),
      });
    }

    const dateStrings = days.map(d => d.dateStr);

    // Fetch DailyLogs for these 7 days
    const logs = await DailyLog.find({
      user: req.user._id,
      date: { $in: dateStrings },
    });

    // Fetch Exercises completed in these 7 days
    const exercises = await Exercise.find({
      user: req.user._id,
      date: { $in: dateStrings },
      completed: true,
    });

    // Build day-by-day record
    const weeklyData = days.map(day => {
      const log = logs.find(l => l.date === day.dateStr);
      const dayExercises = exercises.filter(e => e.date === day.dateStr);

      return {
        date: day.dateStr,
        day: day.dayName,
        dayNumber: day.dayDate,
        steps: log ? log.steps : 0,
        sleepHours: log ? log.sleepHours : 0,
        caloriesConsumed: log ? log.caloriesConsumed : 0,
        caloriesBurned: log ? log.caloriesBurned : 0,
        exerciseCount: dayExercises.length,
      };
    });

    // Compute weekly summaries
    const totalSteps = weeklyData.reduce((acc, d) => acc + d.steps, 0);
    const avgSteps = Math.round(totalSteps / 7);

    const totalSleep = weeklyData.reduce((acc, d) => acc + d.sleepHours, 0);
    const avgSleep = Math.round((totalSleep / 7) * 10) / 10;

    const totalCaloriesConsumed = weeklyData.reduce((acc, d) => acc + d.caloriesConsumed, 0);
    const avgCaloriesConsumed = Math.round(totalCaloriesConsumed / 7);

    const totalCaloriesBurned = weeklyData.reduce((acc, d) => acc + d.caloriesBurned, 0);
    const avgCaloriesBurned = Math.round(totalCaloriesBurned / 7);

    const totalWorkouts = weeklyData.reduce((acc, d) => acc + d.exerciseCount, 0);

    // Calculate dynamic Health Score (0 - 100)
    const stepScore = Math.min(30, (avgSteps / (req.user.dailyStepGoal || 10000)) * 30);
    const sleepScore = Math.min(30, (avgSleep / (req.user.dailySleepGoal || 8)) * 30);
    const workoutScore = Math.min(25, (totalWorkouts / 5) * 25);
    const calorieScore = 15; // baseline balanced score
    const healthScore = Math.min(100, Math.round(stepScore + sleepScore + workoutScore + calorieScore));

    res.json({
      success: true,
      weeklyData,
      summary: {
        totalSteps,
        avgSteps,
        totalSleep,
        avgSleep,
        totalCaloriesConsumed,
        avgCaloriesConsumed,
        totalCaloriesBurned,
        avgCaloriesBurned,
        totalWorkouts,
        healthScore,
      },
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
