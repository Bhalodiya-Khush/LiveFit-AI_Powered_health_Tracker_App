const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/livefit';
const JWT_SECRET = process.env.JWT_SECRET || 'livefit-secret-key';

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

// ============================================================================
// MONGOOSE SCHEMAS & MODELS
// ============================================================================

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    password: { type: String, required: true },
    authProvider: {
      type: String,
      enum: ['local', 'google'],
      default: 'local',
    },
    googleId: { type: String, default: null },
    age: { type: Number, default: 21 },
    gender: { type: String, enum: ['male', 'female', 'other'], default: 'male' },
    weight: { type: Number, default: 68 }, // in kg
    height: { type: Number, default: 175 }, // in cm
    bmi: { type: Number, default: 22.2 },
    bmr: { type: Number, default: 1650 },
    goals: {
      stepGoal: { type: Number, default: 10000 },
      waterGoal: { type: Number, default: 2.5 }, // in liters
      sleepGoal: { type: Number, default: 480 }, // in minutes (8 hours)
      calorieGoal: { type: Number, default: 2000 },
    },
  },
  { timestamps: true }
);

const User = mongoose.model('User', userSchema);

const stepSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    steps: { type: Number, required: true, min: 0, default: 0 },
    source: {
      type: String,
      enum: ['sensor', 'manual', 'device'],
      default: 'sensor',
    },
    date: {
      type: String,
      required: true,
      default: () => new Date().toISOString().slice(0, 10),
    },
    recordedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

const Step = mongoose.model('Step', stepSchema);

const sleepSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    sleepMinutes: { type: Number, required: true, min: 0, default: 0 },
    sleepGoalMinutes: { type: Number, required: true, min: 0, default: 480 },
    sleepTime: { type: String, default: '23:30' },
    wakeUpTime: { type: String, default: '07:00' },
    source: {
      type: String,
      enum: ['auto', 'sensor', 'wearable', 'manual'],
      default: 'auto',
    },
    date: {
      type: String,
      required: true,
      default: () => new Date().toISOString().slice(0, 10),
    },
    recordedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

const Sleep = mongoose.model('Sleep', sleepSchema);

const waterSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    amountLiters: { type: Number, required: true, default: 0 },
    date: {
      type: String,
      required: true,
      default: () => new Date().toISOString().slice(0, 10),
    },
    recordedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

const Water = mongoose.model('Water', waterSchema);

const foodItemSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, unique: true, lowercase: true, trim: true },
    calories: { type: Number, required: true },
    category: {
      type: String,
      enum: ['breakfast', 'lunch', 'dinner', 'snack', 'drink', 'general'],
      default: 'general',
    },
    serving: { type: String, default: '1 serving' },
  },
  { timestamps: true }
);

const FoodItem = mongoose.model('FoodItem', foodItemSchema);

const dailyMealSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    date: { type: String, required: true, default: () => new Date().toISOString().slice(0, 10) },
    breakfastText: { type: String, default: '' },
    breakfastCalories: { type: Number, default: 0 },
    lunchText: { type: String, default: '' },
    lunchCalories: { type: Number, default: 0 },
    dinnerText: { type: String, default: '' },
    dinnerCalories: { type: Number, default: 0 },
    totalCalories: { type: Number, default: 0 },
  },
  { timestamps: true }
);

const DailyMeal = mongoose.model('DailyMeal', dailyMealSchema);

const nutritionSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    foodName: { type: String, required: true },
    calories: { type: Number, required: true },
    protein: { type: Number, default: 0 },
    carbs: { type: Number, default: 0 },
    fat: { type: Number, default: 0 },
    mealType: {
      type: String,
      enum: ['breakfast', 'lunch', 'dinner', 'snack'],
      default: 'snack',
    },
    date: {
      type: String,
      required: true,
      default: () => new Date().toISOString().slice(0, 10),
    },
    recordedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

const Nutrition = mongoose.model('Nutrition', nutritionSchema);

const activitySchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    activityType: { type: String, required: true },
    durationMinutes: { type: Number, required: true, default: 15 },
    caloriesBurned: { type: Number, default: 0 },
    intensity: { type: String, enum: ['low', 'moderate', 'high'], default: 'moderate' },
    date: {
      type: String,
      required: true,
      default: () => new Date().toISOString().slice(0, 10),
    },
    recordedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

const Activity = mongoose.model('Activity', activitySchema);

const healthScoreSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    score: { type: Number, required: true, min: 0, max: 100 },
    breakdown: { type: String, default: '' },
    date: {
      type: String,
      required: true,
      default: () => new Date().toISOString().slice(0, 10),
    },
    recordedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

const HealthScore = mongoose.model('HealthScore', healthScoreSchema);

// ============================================================================
// HELPER FUNCTIONS & AUTH MIDDLEWARE
// ============================================================================

const generateToken = (user) =>
  jwt.sign(
    {
      id: user._id,
      email: user.email,
      name: user.name,
      provider: user.authProvider,
    },
    JWT_SECRET,
    { expiresIn: '30d' }
  );

const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization || '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;

    if (!token) {
      return res.status(401).json({ message: 'Authentication token is required.' });
    }

    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findById(decoded.id);

    if (!user) {
      return res.status(401).json({ message: 'User not found.' });
    }

    req.user = user;
    next();
  } catch (error) {
    return res.status(401).json({ message: 'Invalid or expired token.' });
  }
};

const isMongoReady = () => mongoose.connection.readyState === 1;

const mongoConnectionMessage = async () => {
  try {
    await mongoose.connect(MONGO_URI, {
      serverSelectionTimeoutMS: 5000,
    });
    console.log('MongoDB connected successfully');
  } catch (error) {
    console.error('MongoDB connection failed:', error.message);
  }
};

mongoConnectionMessage();

// ============================================================================
// API ROUTES
// ============================================================================

// 1. Health check
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    message: 'LiveFit backend is running',
    mongo: isMongoReady(),
  });
});

// 2. Auth: Register
app.post('/api/auth/register', async (req, res) => {
  try {
    if (!isMongoReady()) {
      return res.status(503).json({
        message: 'MongoDB connection is unavailable. Start MongoDB before registering users.',
      });
    }

    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Name, email, and password are required.' });
    }

    const cleanEmail = email.toLowerCase().trim();
    const existingUser = await User.findOne({ email: cleanEmail });
    if (existingUser) {
      return res.status(409).json({ message: 'User already exists.' });
    }

    const hashedPassword = await bcrypt.hash(password, 12);
    const user = await User.create({
      name: name.trim(),
      email: cleanEmail,
      password: hashedPassword,
      authProvider: 'local',
      age: 21,
      weight: 68,
      height: 175,
      bmi: 22.2,
      goals: {
        stepGoal: 10000,
        waterGoal: 2.5,
        sleepGoal: 480,
        calorieGoal: 2000,
      },
    });

    const token = generateToken(user);

    return res.status(201).json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        authProvider: user.authProvider,
        age: user.age,
        gender: user.gender,
        weight: user.weight,
        height: user.height,
        bmi: user.bmi,
        goals: user.goals,
      },
    });
  } catch (error) {
    console.error('Register error:', error.message);
    return res.status(500).json({ message: 'Registration failed.' });
  }
});

// 3. Auth: Login
app.post('/api/auth/login', async (req, res) => {
  try {
    if (!isMongoReady()) {
      return res.status(503).json({
        message: 'MongoDB connection is unavailable. Start MongoDB before logging in.',
      });
    }

    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required.' });
    }

    const cleanEmail = email.toLowerCase().trim();
    const user = await User.findOne({ email: cleanEmail });
    if (!user || user.authProvider !== 'local') {
      return res.status(401).json({ message: 'Invalid credentials.' });
    }

    const isMatch = await bcrypt.compare(password, user.password || '');
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials.' });
    }

    const token = generateToken(user);

    return res.status(200).json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        authProvider: user.authProvider,
        age: user.age ?? 21,
        gender: user.gender ?? 'male',
        weight: user.weight ?? 68,
        height: user.height ?? 175,
        bmi: user.bmi ?? 22.2,
        goals: user.goals,
      },
    });
  } catch (error) {
    console.error('Login error:', error.message);
    return res.status(500).json({ message: 'Login failed.' });
  }
});

// 4. Auth: Get Current Authenticated User (/api/auth/me)
app.get('/api/auth/me', authMiddleware, async (req, res) => {
  return res.status(200).json({
    user: {
      id: req.user._id,
      name: req.user.name,
      email: req.user.email,
      authProvider: req.user.authProvider,
      age: req.user.age ?? 21,
      gender: req.user.gender ?? 'male',
      weight: req.user.weight ?? 68,
      height: req.user.height ?? 175,
      bmi: req.user.bmi ?? 22.2,
      goals: req.user.goals,
    },
  });
});

// 5. User Profile: GET & PUT
app.get('/api/user/profile', authMiddleware, async (req, res) => {
  return res.status(200).json({
    user: {
      id: req.user._id,
      name: req.user.name,
      email: req.user.email,
      age: req.user.age ?? 21,
      gender: req.user.gender ?? 'male',
      weight: req.user.weight ?? 68,
      height: req.user.height ?? 175,
      bmi: req.user.bmi ?? 22.2,
      goals: req.user.goals,
    },
  });
});

app.put('/api/user/profile', authMiddleware, async (req, res) => {
  try {
    const { name, age, gender, weight, height, goals } = req.body;
    if (name) req.user.name = name.trim();
    if (age !== undefined) req.user.age = Number(age);
    if (gender) req.user.gender = gender;
    if (weight !== undefined) req.user.weight = Number(weight);
    if (height !== undefined) req.user.height = Number(height);

    if (req.user.weight && req.user.height) {
      const hM = req.user.height / 100;
      req.user.bmi = Number((req.user.weight / (hM * hM)).toFixed(1));
    }

    if (goals) {
      req.user.goals = {
        ...req.user.goals.toObject(),
        ...goals,
      };
    }

    await req.user.save();
    return res.status(200).json({
      message: 'Profile updated successfully',
      user: {
        id: req.user._id,
        name: req.user.name,
        email: req.user.email,
        age: req.user.age,
        gender: req.user.gender,
        weight: req.user.weight,
        height: req.user.height,
        bmi: req.user.bmi,
        goals: req.user.goals,
      },
    });
  } catch (error) {
    console.error('Update profile error:', error.message);
    return res.status(500).json({ message: 'Failed to update profile.' });
  }
});

// 6. Food Database: GET all foods & Calculate calories
app.get('/api/food', async (req, res) => {
  try {
    const foods = await FoodItem.find({}).sort({ name: 1 });
    return res.status(200).json({ foods });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to fetch food items.' });
  }
});

app.post('/api/food/calculate', async (req, res) => {
  try {
    const { query } = req.body;
    if (!query || typeof query !== 'string' || query.trim() === '') {
      return res.status(200).json({ totalCalories: 0, items: [] });
    }

    const allFoods = await FoodItem.find({});
    const foodMap = new Map();
    allFoods.forEach((f) => foodMap.set(f.name.toLowerCase().trim(), f.calories));

    const parts = query.split(/[,+]/);
    let totalCalories = 0;
    const items = [];

    for (let part of parts) {
      const clean = part.trim().toLowerCase();
      if (!clean) continue;

      const match = clean.match(/^(\d+)\s*(.*)$/);
      let quantity = 1;
      let foodName = clean;
      if (match) {
        quantity = parseInt(match[1], 10) || 1;
        foodName = match[2].trim() || clean;
      }

      let cal = foodMap.get(foodName);
      if (cal === undefined) {
        for (let [name, c] of foodMap.entries()) {
          if (foodName.includes(name) || name.includes(foodName)) {
            cal = c;
            break;
          }
        }
      }

      cal = cal !== undefined ? cal : 120;
      const subtotal = cal * quantity;
      totalCalories += subtotal;
      items.push({ name: foodName, quantity, caloriesEach: cal, subtotal });
    }

    return res.status(200).json({ totalCalories, items });
  } catch (error) {
    console.error('Calculate calories error:', error.message);
    return res.status(500).json({ message: 'Failed to calculate calories.' });
  }
});

// 7. Nutrition: Log & Get
app.post('/api/nutrition/log', authMiddleware, async (req, res) => {
  try {
    const {
      breakfastText = '',
      breakfastCalories = 0,
      lunchText = '',
      lunchCalories = 0,
      dinnerText = '',
      dinnerCalories = 0,
      date = new Date().toISOString().slice(0, 10),
    } = req.body;

    const bCal = Number(breakfastCalories) || 0;
    const lCal = Number(lunchCalories) || 0;
    const dCal = Number(dinnerCalories) || 0;
    const totalCalories = bCal + lCal + dCal;

    let meal = await DailyMeal.findOne({ userId: req.user._id, date });
    if (!meal) {
      meal = await DailyMeal.create({
        userId: req.user._id,
        date,
        breakfastText,
        breakfastCalories: bCal,
        lunchText,
        lunchCalories: lCal,
        dinnerText,
        dinnerCalories: dCal,
        totalCalories,
      });
    } else {
      meal.breakfastText = breakfastText;
      meal.breakfastCalories = bCal;
      meal.lunchText = lunchText;
      meal.lunchCalories = lCal;
      meal.dinnerText = dinnerText;
      meal.dinnerCalories = dCal;
      meal.totalCalories = totalCalories;
      await meal.save();
    }

    return res.status(200).json({
      message: 'Nutrition logged successfully',
      meal,
    });
  } catch (error) {
    console.error('Nutrition log error:', error.message);
    return res.status(500).json({ message: 'Failed to save nutrition log.' });
  }
});

app.get('/api/nutrition/today', authMiddleware, async (req, res) => {
  try {
    const date = new Date().toISOString().slice(0, 10);
    const meal = await DailyMeal.findOne({ userId: req.user._id, date });
    if (!meal) {
      return res.status(200).json({
        date,
        breakfastText: '',
        breakfastCalories: 0,
        lunchText: '',
        lunchCalories: 0,
        dinnerText: '',
        dinnerCalories: 0,
        totalCalories: 0,
      });
    }
    return res.status(200).json(meal);
  } catch (error) {
    return res.status(500).json({ message: 'Failed to fetch nutrition.' });
  }
});

// 8. Steps: Sync & Today
app.post('/api/steps/sync', authMiddleware, async (req, res) => {
  try {
    const { steps, source = 'sensor', date = new Date().toISOString().slice(0, 10) } = req.body;
    const numericSteps = Number(steps);

    if (!Number.isFinite(numericSteps) || numericSteps < 0) {
      return res.status(400).json({ message: 'Valid step count is required.' });
    }

    let stepRecord = await Step.findOne({ userId: req.user._id, date });

    if (!stepRecord) {
      stepRecord = await Step.create({
        userId: req.user._id,
        steps: numericSteps,
        source,
        date,
        recordedAt: new Date(),
      });
    } else {
      stepRecord.steps = Math.max(stepRecord.steps || 0, numericSteps);
      stepRecord.source = source;
      stepRecord.recordedAt = new Date();
      await stepRecord.save();
    }

    return res.status(200).json({
      message: 'Step data synced successfully.',
      date,
      steps: stepRecord.steps,
      source: stepRecord.source,
    });
  } catch (error) {
    console.error('Step sync error:', error.message);
    return res.status(500).json({ message: 'Failed to sync step data.' });
  }
});

app.get('/api/steps/today', authMiddleware, async (req, res) => {
  try {
    const date = new Date().toISOString().slice(0, 10);
    let stepRecord = await Step.findOne({ userId: req.user._id, date }).sort({ recordedAt: -1 });

    if (!stepRecord) {
      return res.status(200).json({ date, steps: 0, source: 'sensor' });
    }

    return res.status(200).json({
      date,
      steps: stepRecord.steps,
      source: stepRecord.source,
      recordedAt: stepRecord.recordedAt,
    });
  } catch (error) {
    return res.status(500).json({ message: 'Unable to fetch step data.' });
  }
});

// 9. Sleep: Sync & Today
app.post('/api/sleep/sync', authMiddleware, async (req, res) => {
  try {
    const {
      sleepMinutes,
      sleepGoalMinutes = 480,
      sleepTime = '23:30',
      wakeUpTime = '07:00',
      source = 'auto',
      date = new Date().toISOString().slice(0, 10),
    } = req.body;

    const numericSleepMinutes = Number(sleepMinutes ?? 0);
    const numericGoalMinutes = Number(sleepGoalMinutes ?? 480);

    let sleepRecord = await Sleep.findOne({ userId: req.user._id, date });

    if (!sleepRecord) {
      sleepRecord = await Sleep.create({
        userId: req.user._id,
        sleepMinutes: numericSleepMinutes,
        sleepGoalMinutes: numericGoalMinutes,
        sleepTime,
        wakeUpTime,
        source,
        date,
        recordedAt: new Date(),
      });
    } else {
      sleepRecord.sleepMinutes = Math.max(sleepRecord.sleepMinutes || 0, numericSleepMinutes);
      sleepRecord.sleepGoalMinutes = numericGoalMinutes;
      sleepRecord.sleepTime = sleepTime;
      sleepRecord.wakeUpTime = wakeUpTime;
      sleepRecord.source = source;
      sleepRecord.recordedAt = new Date();
      await sleepRecord.save();
    }

    return res.status(200).json({
      message: 'Sleep data synced successfully.',
      date,
      sleepMinutes: sleepRecord.sleepMinutes,
      sleepGoalMinutes: sleepRecord.sleepGoalMinutes,
      sleepTime: sleepRecord.sleepTime,
      wakeUpTime: sleepRecord.wakeUpTime,
      source: sleepRecord.source,
    });
  } catch (error) {
    console.error('Sleep sync error:', error.message);
    return res.status(500).json({ message: 'Failed to sync sleep data.' });
  }
});

app.get('/api/sleep/today', authMiddleware, async (req, res) => {
  try {
    const date = new Date().toISOString().slice(0, 10);
    let sleepRecord = await Sleep.findOne({ userId: req.user._id, date }).sort({ recordedAt: -1 });

    if (!sleepRecord) {
      return res.status(200).json({
        date,
        sleepMinutes: 0,
        sleepGoalMinutes: 480,
        sleepTime: '23:30',
        wakeUpTime: '07:00',
        source: 'auto',
      });
    }

    return res.status(200).json({
      date,
      sleepMinutes: sleepRecord.sleepMinutes,
      sleepGoalMinutes: sleepRecord.sleepGoalMinutes,
      sleepTime: sleepRecord.sleepTime,
      wakeUpTime: sleepRecord.wakeUpTime,
      source: sleepRecord.source,
      recordedAt: sleepRecord.recordedAt,
    });
  } catch (error) {
    return res.status(500).json({ message: 'Unable to fetch sleep data.' });
  }
});

// 10. Activities: Log & Today
app.post('/api/activities/log', authMiddleware, async (req, res) => {
  try {
    const {
      activityType = 'Workout',
      durationMinutes = 15,
      caloriesBurned = 0,
      intensity = 'moderate',
      date = new Date().toISOString().slice(0, 10),
    } = req.body;

    const activity = await Activity.create({
      userId: req.user._id,
      activityType,
      durationMinutes: Number(durationMinutes),
      caloriesBurned: Number(caloriesBurned),
      intensity,
      date,
    });

    return res.status(201).json({
      message: 'Activity logged successfully',
      activity,
    });
  } catch (error) {
    console.error('Activity log error:', error.message);
    return res.status(500).json({ message: 'Failed to log activity.' });
  }
});

app.get('/api/activities/today', authMiddleware, async (req, res) => {
  try {
    const date = new Date().toISOString().slice(0, 10);
    const activities = await Activity.find({ userId: req.user._id, date }).sort({ createdAt: -1 });
    const totalBurned = activities.reduce((sum, a) => sum + (a.caloriesBurned || 0), 0);

    return res.status(200).json({
      date,
      totalBurned,
      activities,
    });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to fetch activities.' });
  }
});

// 11. Health Score: Save & Today
app.post('/api/health-score/save', authMiddleware, async (req, res) => {
  try {
    const { score, breakdown = '', date = new Date().toISOString().slice(0, 10) } = req.body;
    const numScore = Number(score);

    let doc = await HealthScore.findOne({ userId: req.user._id, date });
    if (!doc) {
      doc = await HealthScore.create({
        userId: req.user._id,
        score: numScore,
        breakdown,
        date,
      });
    } else {
      doc.score = numScore;
      doc.breakdown = breakdown;
      await doc.save();
    }

    return res.status(200).json({ message: 'Health score saved', healthScore: doc });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to save health score.' });
  }
});

// 12. Combined Today Dashboard
app.get('/api/dashboard/today', authMiddleware, async (req, res) => {
  try {
    const date = new Date().toISOString().slice(0, 10);

    const [stepDoc, sleepDoc, mealDoc, activities, healthDoc] = await Promise.all([
      Step.findOne({ userId: req.user._id, date }),
      Sleep.findOne({ userId: req.user._id, date }),
      DailyMeal.findOne({ userId: req.user._id, date }),
      Activity.find({ userId: req.user._id, date }),
      HealthScore.findOne({ userId: req.user._id, date }).sort({ createdAt: -1 }),
    ]);

    const totalBurnedFromActivities = activities.reduce((sum, a) => sum + (a.caloriesBurned || 0), 0);
    const stepCount = stepDoc ? stepDoc.steps : 0;
    const burnedFromSteps = Math.round(stepCount * 0.04);
    const totalBurned = totalBurnedFromActivities + burnedFromSteps;

    return res.status(200).json({
      date,
      user: {
        id: req.user._id,
        name: req.user.name,
        email: req.user.email,
        age: req.user.age ?? 21,
        weight: req.user.weight ?? 68,
        height: req.user.height ?? 175,
        bmi: req.user.bmi ?? 22.2,
        goals: req.user.goals,
      },
      steps: {
        count: stepCount,
        goal: req.user.goals?.stepGoal || 10000,
        source: stepDoc?.source || 'sensor',
      },
      sleep: {
        minutes: sleepDoc ? sleepDoc.sleepMinutes : 450,
        goalMinutes: req.user.goals?.sleepGoal || 480,
        sleepTime: sleepDoc?.sleepTime || '23:30',
        wakeUpTime: sleepDoc?.wakeUpTime || '07:00',
        source: sleepDoc?.source || 'auto',
      },
      nutrition: {
        consumedCalories: mealDoc ? mealDoc.totalCalories : 0,
        targetCalories: req.user.goals?.calorieGoal || 2000,
        breakfastText: mealDoc?.breakfastText || '',
        breakfastCalories: mealDoc?.breakfastCalories || 0,
        lunchText: mealDoc?.lunchText || '',
        lunchCalories: mealDoc?.lunchCalories || 0,
        dinnerText: mealDoc?.dinnerText || '',
        dinnerCalories: mealDoc?.dinnerCalories || 0,
      },
      burnedCalories: totalBurned,
      healthScore: healthDoc ? healthDoc.score : null,
    });
  } catch (error) {
    console.error('Dashboard today error:', error.message);
    return res.status(500).json({ message: 'Failed to fetch dashboard data.' });
  }
});

app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

app.listen(PORT, () => {
  console.log(`LiveFit backend running on http://localhost:${PORT}`);
});
