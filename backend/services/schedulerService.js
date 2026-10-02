const cron = require('node-cron');
const DailyLog = require('../models/DailyLog');
const User = require('../models/User');

const getTodayDateString = (offsetDays = 0) => {
  const d = new Date();
  if (offsetDays !== 0) {
    d.setDate(d.getDate() + offsetDays);
  }
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

/**
 * Initializes daily scheduler:
 * Runs at 23:59:00 (11:59 PM) every night
 * - Finalizes today's step count in database for all users
 * - Ensures today's date and steps are locked in DailyLog
 * - Prepares next day (starting at 00:00:00 midnight) with 0 steps
 */
function initMidnightDailyScheduler() {
  console.log('⏰ Initializing LiveFit 23:59 Daily Midnight Steps Scheduler...');

  // Schedule task at 23:59 (11:59 PM) every day: '59 23 * * *'
  cron.schedule('59 23 * * *', async () => {
    try {
      const today = getTodayDateString(0);
      const tomorrow = getTodayDateString(1);
      console.log(`🌙 [Midnight Scheduler - 23:59] Finalizing daily steps for date: ${today}`);

      // 1. Finalize all active user logs for today
      const todayLogs = await DailyLog.find({ date: today });
      for (const log of todayLogs) {
        log.isFinalized = true;
        log.lastUpdated = new Date();
        await log.save();
      }
      console.log(`✅ [Midnight Scheduler] Finalized ${todayLogs.length} user daily logs for ${today}.`);

      // 2. Pre-seed or reset base offsets for active users for tomorrow
      const allUsers = await User.find({}, '_id lastPedometerReading lastStepDate lastStepBaseline');
      for (const user of allUsers) {
        // If user recorded pedometer steps today, set baseline for tomorrow to current raw reading
        if (user.lastPedometerReading && user.lastPedometerReading > 0) {
          user.lastStepBaseline = user.lastPedometerReading;
          user.lastStepDate = tomorrow;
          await user.save();
        }

        // Pre-create tomorrow's initial log with 0 steps starting after 12:00 midnight
        await DailyLog.findOneAndUpdate(
          { user: user._id, date: tomorrow },
          {
            $setOnInsert: {
              user: user._id,
              date: tomorrow,
              todayDate: new Date(new Date().setHours(24, 0, 0, 0)),
              steps: 0,
              rawSensorSteps: user.lastPedometerReading || 0,
              stepBaseline: user.lastPedometerReading || 0,
              sleepHours: 0,
              caloriesConsumed: 0,
              caloriesBurned: 0,
              waterMl: 0,
              activeMinutes: 0,
              isFinalized: false,
              lastUpdated: new Date(),
            },
          },
          { upsert: true, new: true }
        );
      }

      console.log(`🌅 [Midnight Scheduler] Next day (${tomorrow}) initialized with 0 steps for all users.`);
    } catch (err) {
      console.error('❌ Error during 23:59 midnight daily scheduler execution:', err.message);
    }
  });

  console.log('✅ Daily Midnight Scheduler active (triggers automatically at 23:59 every night).');
}

module.exports = {
  initMidnightDailyScheduler,
  getTodayDateString,
};
