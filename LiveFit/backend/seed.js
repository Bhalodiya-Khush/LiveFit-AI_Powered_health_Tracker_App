const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const MONGO_URI = 'mongodb://127.0.0.1:27017/livefit';

// Schemas (Mirrored from server.js)
const userSchema = new mongoose.Schema({
  name: String,
  email: { type: String, unique: true },
  password: String,
  authProvider: { type: String, default: 'local' },
  age: Number,
  gender: String,
  weight: Number,
  height: Number,
  bmi: Number,
  goals: {
    stepGoal: { type: Number, default: 10000 },
    waterGoal: { type: Number, default: 2.5 },
    sleepGoal: { type: Number, default: 480 },
    calorieGoal: { type: Number, default: 2000 },
  }
});

const stepSchema = new mongoose.Schema({
  userId: mongoose.Schema.Types.ObjectId,
  steps: Number,
  date: String,
  recordedAt: { type: Date, default: Date.now }
});

const sleepSchema = new mongoose.Schema({
  userId: mongoose.Schema.Types.ObjectId,
  sleepMinutes: Number,
  sleepGoalMinutes: Number,
  sleepTime: String,
  wakeUpTime: String,
  date: String
});

const waterSchema = new mongoose.Schema({
  userId: mongoose.Schema.Types.ObjectId,
  amountLiters: Number,
  date: String
});

const User = mongoose.model('User', userSchema);
const Step = mongoose.model('Step', stepSchema);
const Sleep = mongoose.model('Sleep', sleepSchema);
const Water = mongoose.model('Water', waterSchema);

async function seedData() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('Connected to MongoDB for seeding...');

    // 1. Clear existing data
    await User.deleteMany({ email: 'tester@livefit.com' });
    console.log('Cleaned old test user.');

    // 2. Create Test User
    const hashedPassword = await bcrypt.hash('password123', 12);
    const user = await User.create({
      name: 'John Doe',
      email: 'tester@livefit.com',
      password: hashedPassword,
      age: 28,
      gender: 'male',
      weight: 75,
      height: 180,
      bmi: 23.1,
      goals: {
        stepGoal: 8000,
        waterGoal: 3.0,
        sleepGoal: 450,
        calorieGoal: 2200
      }
    });
    console.log('Created Test User: tester@livefit.com / password123');

    // 3. Generate 7 days of data
    const today = new Date();
    for (let i = 0; i < 7; i++) {
      const date = new Date(today);
      date.setDate(today.getDate() - i);
      const dateString = date.toISOString().slice(0, 10);

      // Steps
      await Step.create({
        userId: user._id,
        steps: Math.floor(Math.random() * 5000) + 4000, // 4000 - 9000 steps
        date: dateString
      });

      // Sleep
      await Sleep.create({
        userId: user._id,
        sleepMinutes: Math.floor(Math.random() * 120) + 360, // 6 - 8 hours
        sleepGoalMinutes: 450,
        sleepTime: '23:00',
        wakeUpTime: '07:00',
        date: dateString
      });

      // Water
      await Water.create({
        userId: user._id,
        amountLiters: (Math.random() * 2 + 1).toFixed(1), // 1.0 - 3.0 L
        date: dateString
      });
    }

    console.log('Successfully seeded 7 days of health data!');
    process.exit(0);
  } catch (error) {
    console.error('Seeding failed:', error);
    process.exit(1);
  }
}

seedData();
