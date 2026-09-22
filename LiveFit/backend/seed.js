const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/livefit';

// Schemas
const userSchema = new mongoose.Schema({
  name: String,
  email: { type: String, unique: true, lowercase: true },
  password: String,
  authProvider: { type: String, default: 'local' },
  age: { type: Number, default: 21 },
  gender: { type: String, default: 'male' },
  weight: { type: Number, default: 68 },
  height: { type: Number, default: 175 },
  bmi: { type: Number, default: 22.2 },
  bmr: { type: Number, default: 1650 },
  goals: {
    stepGoal: { type: Number, default: 10000 },
    waterGoal: { type: Number, default: 2.5 },
    sleepGoal: { type: Number, default: 480 },
    calorieGoal: { type: Number, default: 2000 },
  },
}, { timestamps: true });

const foodItemSchema = new mongoose.Schema({
  name: { type: String, unique: true, lowercase: true, trim: true },
  calories: Number,
  category: String,
  serving: String,
});

const stepSchema = new mongoose.Schema({
  userId: mongoose.Schema.Types.ObjectId,
  steps: Number,
  source: { type: String, default: 'sensor' },
  date: String,
  recordedAt: { type: Date, default: Date.now }
});

const sleepSchema = new mongoose.Schema({
  userId: mongoose.Schema.Types.ObjectId,
  sleepMinutes: Number,
  sleepGoalMinutes: Number,
  sleepTime: String,
  wakeUpTime: String,
  source: { type: String, default: 'auto' },
  date: String,
  recordedAt: { type: Date, default: Date.now }
});

const waterSchema = new mongoose.Schema({
  userId: mongoose.Schema.Types.ObjectId,
  amountLiters: Number,
  date: String,
  recordedAt: { type: Date, default: Date.now }
});

const dailyMealSchema = new mongoose.Schema({
  userId: mongoose.Schema.Types.ObjectId,
  date: String,
  breakfastText: String,
  breakfastCalories: Number,
  lunchText: String,
  lunchCalories: Number,
  dinnerText: String,
  dinnerCalories: Number,
  totalCalories: Number,
});

const activitySchema = new mongoose.Schema({
  userId: mongoose.Schema.Types.ObjectId,
  activityType: String,
  durationMinutes: Number,
  caloriesBurned: Number,
  intensity: String,
  date: String,
  recordedAt: { type: Date, default: Date.now }
});

const healthScoreSchema = new mongoose.Schema({
  userId: mongoose.Schema.Types.ObjectId,
  score: Number,
  breakdown: String,
  date: String,
  recordedAt: { type: Date, default: Date.now }
});

const User = mongoose.model('User', userSchema);
const FoodItem = mongoose.model('FoodItem', foodItemSchema);
const Step = mongoose.model('Step', stepSchema);
const Sleep = mongoose.model('Sleep', sleepSchema);
const Water = mongoose.model('Water', waterSchema);
const DailyMeal = mongoose.model('DailyMeal', dailyMealSchema);
const Activity = mongoose.model('Activity', activitySchema);
const HealthScore = mongoose.model('HealthScore', healthScoreSchema);

const initialFoods = [
  // Breakfast
  { name: 'oats', calories: 150, category: 'breakfast', serving: '1 bowl (40g)' },
  { name: 'oatmeal', calories: 150, category: 'breakfast', serving: '1 bowl' },
  { name: 'egg', calories: 70, category: 'breakfast', serving: '1 large egg' },
  { name: 'eggs', calories: 140, category: 'breakfast', serving: '2 eggs' },
  { name: 'boiled egg', calories: 70, category: 'breakfast', serving: '1 egg' },
  { name: 'omelette', calories: 160, category: 'breakfast', serving: '2 egg omelette' },
  { name: 'toast', calories: 80, category: 'breakfast', serving: '1 slice' },
  { name: 'bread', calories: 80, category: 'breakfast', serving: '1 slice' },
  { name: 'tea', calories: 40, category: 'drink', serving: '1 cup with milk' },
  { name: 'coffee', calories: 50, category: 'drink', serving: '1 cup' },
  { name: 'milk', calories: 120, category: 'drink', serving: '1 glass (250ml)' },
  { name: 'poha', calories: 180, category: 'breakfast', serving: '1 plate' },
  { name: 'upma', calories: 200, category: 'breakfast', serving: '1 plate' },
  { name: 'idli', calories: 90, category: 'breakfast', serving: '2 idlis' },
  { name: 'dosa', calories: 170, category: 'breakfast', serving: '1 plain dosa' },
  { name: 'paratha', calories: 260, category: 'breakfast', serving: '1 stuffed paratha' },
  { name: 'apple', calories: 95, category: 'snack', serving: '1 medium apple' },
  { name: 'banana', calories: 105, category: 'snack', serving: '1 medium banana' },
  { name: 'fruits', calories: 100, category: 'snack', serving: '1 bowl mixed fruits' },
  { name: 'cereal', calories: 130, category: 'breakfast', serving: '1 bowl' },
  { name: 'pancakes', calories: 220, category: 'breakfast', serving: '2 pancakes' },

  // Lunch
  { name: 'rice', calories: 200, category: 'lunch', serving: '1 cup cooked' },
  { name: 'brown rice', calories: 210, category: 'lunch', serving: '1 cup' },
  { name: 'roti', calories: 100, category: 'lunch', serving: '1 medium roti' },
  { name: 'chapati', calories: 100, category: 'lunch', serving: '1 chapati' },
  { name: 'dal', calories: 150, category: 'lunch', serving: '1 bowl' },
  { name: 'paneer', calories: 260, category: 'lunch', serving: '100g paneer' },
  { name: 'chicken', calories: 240, category: 'lunch', serving: '150g cooked' },
  { name: 'chicken curry', calories: 280, category: 'lunch', serving: '1 bowl' },
  { name: 'salad', calories: 60, category: 'lunch', serving: '1 fresh salad bowl' },
  { name: 'curd', calories: 90, category: 'lunch', serving: '1 small bowl' },
  { name: 'yogurt', calories: 100, category: 'snack', serving: '1 cup' },
  { name: 'rajma', calories: 240, category: 'lunch', serving: '1 bowl rajma' },
  { name: 'chole', calories: 250, category: 'lunch', serving: '1 bowl chole' },
  { name: 'subzi', calories: 120, category: 'lunch', serving: '1 bowl' },
  { name: 'vegetables', calories: 100, category: 'lunch', serving: '1 bowl sauteed' },
  { name: 'sandwich', calories: 250, category: 'lunch', serving: '1 whole sandwich' },

  // Dinner & Snacks
  { name: 'khichdi', calories: 220, category: 'dinner', serving: '1 bowl moong dal khichdi' },
  { name: 'soup', calories: 90, category: 'dinner', serving: '1 bowl tomato/veg soup' },
  { name: 'fish', calories: 200, category: 'dinner', serving: '1 fillet (150g)' },
  { name: 'pasta', calories: 280, category: 'dinner', serving: '1 plate' },
  { name: 'wrap', calories: 260, category: 'dinner', serving: '1 veggie/protein wrap' },
  { name: 'grilled chicken', calories: 220, category: 'dinner', serving: '150g' },
  { name: 'sprouts', calories: 80, category: 'snack', serving: '1 bowl sprouted moong' },
];

async function seedDatabase() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('Connected to MongoDB for seeding...');

    // 1. Seed Food Items
    console.log('Seeding food items...');
    for (const food of initialFoods) {
      await FoodItem.findOneAndUpdate(
        { name: food.name.toLowerCase() },
        food,
        { upsert: true, new: true }
      );
    }
    const foodCount = await FoodItem.countDocuments();
    console.log(`Food database ready! Total foods in MongoDB: ${foodCount}`);

    // 2. Seed Users
    const hashedPassword = await bcrypt.hash('password123', 12);

    const usersToSeed = [
      {
        name: 'Khush Bhalodiya',
        email: 'khush@livefit.com',
        password: hashedPassword,
        authProvider: 'local',
        age: 21,
        gender: 'male',
        weight: 68,
        height: 175,
        bmi: 22.2,
        bmr: 1680,
        goals: {
          stepGoal: 10000,
          waterGoal: 2.5,
          sleepGoal: 480,
          calorieGoal: 2000,
        },
      },
      {
        name: 'Alex Johnson',
        email: 'tester@livefit.com',
        password: hashedPassword,
        authProvider: 'local',
        age: 24,
        gender: 'male',
        weight: 72,
        height: 180,
        bmi: 22.2,
        bmr: 1720,
        goals: {
          stepGoal: 10000,
          waterGoal: 3.0,
          sleepGoal: 480,
          calorieGoal: 2200,
        },
      },
    ];

    for (const u of usersToSeed) {
      const user = await User.findOneAndUpdate(
        { email: u.email },
        u,
        { upsert: true, new: true }
      );
      console.log(`Seeded user: ${user.name} (${user.email}) [password: password123]`);

      // Clean old history for this user
      await Step.deleteMany({ userId: user._id });
      await Sleep.deleteMany({ userId: user._id });
      await Water.deleteMany({ userId: user._id });
      await DailyMeal.deleteMany({ userId: user._id });
      await Activity.deleteMany({ userId: user._id });
      await HealthScore.deleteMany({ userId: user._id });

      // Seed 7 days of realistic health data
      const today = new Date();
      for (let i = 0; i < 7; i++) {
        const d = new Date(today);
        d.setDate(today.getDate() - i);
        const dateString = d.toISOString().slice(0, 10);

        // Steps
        const steps = i === 0 ? 6540 : Math.floor(Math.random() * 4000) + 7000;
        await Step.create({
          userId: user._id,
          steps,
          source: 'sensor',
          date: dateString,
        });

        // Sleep
        const sleepMinutes = i === 0 ? 450 : Math.floor(Math.random() * 80) + 420;
        await Sleep.create({
          userId: user._id,
          sleepMinutes,
          sleepGoalMinutes: 480,
          sleepTime: '23:30',
          wakeUpTime: '07:00',
          source: 'auto',
          date: dateString,
        });

        // Water
        await Water.create({
          userId: user._id,
          amountLiters: Number((Math.random() * 1.5 + 2.0).toFixed(1)),
          date: dateString,
        });

        // Meals
        await DailyMeal.create({
          userId: user._id,
          date: dateString,
          breakfastText: 'Oats, 2 Eggs, Tea',
          breakfastCalories: 330,
          lunchText: '2 Roti, Dal, Rice, Salad',
          lunchCalories: 610,
          dinnerText: 'Khichdi, Curd',
          dinnerCalories: 310,
          totalCalories: 1250,
        });

        // Activity / Workout
        await Activity.create({
          userId: user._id,
          activityType: i % 2 === 0 ? 'Outdoor Brisk Walking' : 'Bodyweight Squats & Core Planks',
          durationMinutes: 20,
          caloriesBurned: 180,
          intensity: 'moderate',
          date: dateString,
        });

        // Health score
        await HealthScore.create({
          userId: user._id,
          score: 82,
          breakdown: 'Good step count and consistent sleep hours.',
          date: dateString,
        });
      }
      console.log(`Seeded 7 days of health, steps, sleep, meals, & activity data for ${user.email}`);
    }

    console.log('\n--- SEEDING COMPLETED SUCCESSFULLY ---');
    process.exit(0);
  } catch (error) {
    console.error('Seeding error:', error);
    process.exit(1);
  }
}

seedDatabase();
