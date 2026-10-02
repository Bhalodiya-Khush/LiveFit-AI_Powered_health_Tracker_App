const express = require('express');
const router = express.Router();
const DailyLog = require('../models/DailyLog');
const Meal = require('../models/Meal');
const Exercise = require('../models/Exercise');
const { protect } = require('../middleware/authMiddleware');

const getTodayDateString = () => {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

// @route   GET /api/stats/today
// @desc    Get or initialize today's stats for dashboard
router.get('/today', protect, async (req, res) => {
  try {
    const today = getTodayDateString();
    let log = await DailyLog.findOne({ user: req.user._id, date: today });

    if (!log) {
      log = await DailyLog.create({
        user: req.user._id,
        date: today,
        steps: 0,
        sleepHours: 0,
        caloriesConsumed: 0,
        caloriesBurned: 0,
        waterMl: 0,
      });
    }

    // Also fetch today's meals sum
    const meals = await Meal.find({ user: req.user._id, date: today });
    const totalConsumed = meals.reduce((sum, m) => sum + (m.totalCalories || 0), 0);

    // Also fetch today's exercises sum
    const exercises = await Exercise.find({ user: req.user._id, date: today, completed: true });
    const totalBurned = exercises.reduce((sum, e) => sum + (e.caloriesBurned || 0), 0);

    // If different, update log
    if (log.caloriesConsumed !== totalConsumed || log.caloriesBurned !== totalBurned) {
      log.caloriesConsumed = totalConsumed;
      log.caloriesBurned = totalBurned;
      await log.save();
    }

    res.json({
      success: true,
      stats: log,
      todayMealsCount: meals.length,
      todayExercisesCompleted: exercises.length,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   POST /api/stats/steps
// @desc    Log steps with intelligent 0/-1 initial value checks and hardware baseline subtraction
router.post('/steps', protect, async (req, res) => {
  try {
    const { steps, rawSensorSteps } = req.body;
    const today = getTodayDateString();
    const User = require('../models/User');
    const user = await User.findById(req.user._id);

    let log = await DailyLog.findOne({ user: req.user._id, date: today });
    if (!log) {
      log = new DailyLog({
        user: req.user._id,
        date: today,
        todayDate: new Date(),
        steps: 0,
        rawSensorSteps: 0,
        stepBaseline: 0,
      });
    }

    let todaySteps = log.steps || 0;
    const rawCount = Number(rawSensorSteps);
    const directSteps = Number(steps);

    // 1. Check if rawSensorSteps is provided from hardware pedometer sensor
    if (!isNaN(rawCount)) {
      // Condition: if raw count is 0 or -1, that's an initial/uninitialized sensor value
      if (rawCount <= 0 || rawCount === -1) {
        console.log(`ℹ️ [Pedometer] Initial or idle sensor reading received (${rawCount}). Preserving today steps: ${todaySteps}`);
      } else {
        // Valid positive hardware reading (> 0)
        // Check if date changed (new day after midnight 12:00)
        if (!user.lastStepDate || user.lastStepDate !== today) {
          // New day starts: Baseline becomes current hardware reading, count starts at zero
          user.lastStepDate = today;
          user.lastStepBaseline = rawCount;
          user.lastPedometerReading = rawCount;
          todaySteps = 0;
          console.log(`🌅 [Pedometer] New Day (${today}) started. Hardware Baseline set to ${rawCount}. Today steps reset to 0.`);
        } else {
          // Same day: If count is greater than baseline, subtract baseline to get today's count
          let baseline = user.lastStepBaseline || 0;
          if (baseline === 0) {
            baseline = rawCount - todaySteps;
            user.lastStepBaseline = Math.max(0, baseline);
          }

          // If phone rebooted, rawCount may be lower than stored baseline
          if (rawCount < baseline) {
            console.log(`🔄 [Pedometer] Device reboot detected. Re-calibrating baseline from ${baseline} to ${rawCount}`);
            user.lastStepBaseline = Math.max(0, rawCount - todaySteps);
            baseline = user.lastStepBaseline;
          }

          const calculated = Math.max(0, rawCount - baseline);
          // Never decrease steps during the same day
          todaySteps = Math.max(todaySteps, calculated);
          user.lastPedometerReading = rawCount;
        }

        await user.save();
      }
    }

    // 2. If direct steps supplied and higher, respect monotonic increase
    if (!isNaN(directSteps) && directSteps > todaySteps) {
      todaySteps = directSteps;
    }

    // 3. Update today's DailyLog in database
    log.steps = Math.max(0, todaySteps);
    log.todayDate = new Date();
    if (!isNaN(rawCount) && rawCount > 0) {
      log.rawSensorSteps = rawCount;
      log.stepBaseline = user.lastStepBaseline || 0;
    }
    log.lastUpdated = new Date();
    await log.save();

    res.json({
      success: true,
      message: 'Steps synced successfully',
      steps: log.steps,
      todayDate: today,
      rawSensorSteps: log.rawSensorSteps,
      stepBaseline: log.stepBaseline,
      log,
    });
  } catch (error) {
    console.error('Error logging steps:', error);
    res.status(500).json({ message: error.message });
  }
});

// @route   POST /api/stats/sleep
// @desc    Log estimated sleep from device activity (usage_stats with 2-min threshold)
router.post('/sleep', protect, async (req, res) => {
  try {
    const { sleepHours, sleepBedTime, sleepWakeTime, sleepInterruptions, method } = req.body;
    const today = getTodayDateString();

    const hours = Math.round((Number(sleepHours) || 0) * 10) / 10;

    const log = await DailyLog.findOneAndUpdate(
      { user: req.user._id, date: today },
      { 
        $set: { 
          sleepHours: hours,
          todayDate: new Date(),
          sleepBedTime: sleepBedTime || '',
          sleepWakeTime: sleepWakeTime || '',
          sleepInterruptions: Number(sleepInterruptions) || 0,
          sleepCalculationMethod: method || 'usage_stats',
          lastUpdated: new Date()
        } 
      },
      { upsert: true, new: true }
    );

    res.json({
      success: true,
      message: 'Sleep logged successfully',
      sleepHours: log.sleepHours,
      sleepBedTime: log.sleepBedTime,
      sleepWakeTime: log.sleepWakeTime,
      sleepInterruptions: log.sleepInterruptions,
      log,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
