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
  origin: '*', // Allow all origins for development
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, lowercase: true },
    password: { type: String },
    authProvider: {
      type: String,
      enum: ['local', 'google'],
      default: 'local',
    },
    googleId: { type: String, default: null },
    // Profile Details
    age: { type: Number },
    gender: { type: String, enum: ['male', 'female', 'other'] },
    weight: { type: Number }, // in kg
    height: { type: Number }, // in cm
    bmi: { type: Number },
    bmr: { type: Number },
    // Daily Goals
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
    sleepGoalMinutes: { type: Number, required: true, min: 0, default: 420 },
    sleepTime: { type: String, default: '00:00' },
    wakeUpTime: { type: String, default: '00:00' },
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
    activityType: { type: String, required: true }, // e.g., 'Running', 'Yoga'
    durationMinutes: { type: Number, required: true },
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
    breakdown: { type: String }, // AI generated reasoning
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

const generateToken = (user) =>
  jwt.sign(
    {
      id: user._id,
      email: user.email,
      name: user.name,
      provider: user.authProvider,
    },
    JWT_SECRET,
    { expiresIn: '7d' }
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

app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    message: 'LiveFit backend is running',
    mongo: isMongoReady(),
  });
});

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

    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(409).json({ message: 'User already exists.' });
    }

    const hashedPassword = await bcrypt.hash(password, 12);
    const user = await User.create({
      name,
      email: email.toLowerCase(),
      password: hashedPassword,
      authProvider: 'local',
    });

    const token = generateToken(user);

    return res.status(201).json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        authProvider: user.authProvider,
        goals: user.goals,
        profile: {
          age: user.age,
          gender: user.gender,
          weight: user.weight,
          height: user.height,
          bmi: user.bmi,
        }
      },
    });
  } catch (error) {
    console.error('Register error:', error.message);
    return res.status(500).json({ message: 'Registration failed.' });
  }
});

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

    const user = await User.findOne({ email: email.toLowerCase() });
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
        goals: user.goals,
        profile: {
          age: user.age,
          gender: user.gender,
          weight: user.weight,
          height: user.height,
          bmi: user.bmi,
        }
      },
    });
  } catch (error) {
    console.error('Login error:', error.message);
    return res.status(500).json({ message: 'Login failed.' });
  }
});

app.post('/api/steps/sync', authMiddleware, async (req, res) => {
  try {
    const { steps, source = 'sensor' } = req.body;
    const numericSteps = Number(steps);

    if (!Number.isFinite(numericSteps) || numericSteps < 0) {
      return res.status(400).json({ message: 'Valid step count is required.' });
    }

    const date = new Date().toISOString().slice(0, 10);

    let stepRecord = await Step.findOne({
      userId: req.user._id,
      date,
    });

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
    console.error('Get today steps error:', error.message);
    return res.status(500).json({ message: 'Unable to fetch step data.' });
  }
});

app.get('/api/steps/history', authMiddleware, async (req, res) => {
  try {
    const { start, end } = req.query;

    const query = { userId: req.user._id };

    if (start || end) {
      query.date = {};
      if (start) query.date.$gte = String(start);
      if (end) query.date.$lte = String(end);
    }

    const history = await Step.find(query)
      .sort({ date: -1, recordedAt: -1 })
      .select('date steps source recordedAt');

    return res.status(200).json({ history });
  } catch (error) {
    console.error('Step history error:', error.message);
    return res.status(500).json({ message: 'Unable to fetch step history.' });
  }
});

app.post('/api/sleep/sync', authMiddleware, async (req, res) => {
  try {
    const {
      sleepMinutes,
      sleepGoalMinutes = 420,
      sleepTime = '00:00',
      wakeUpTime = '00:00',
      source = 'auto',
    } = req.body;

    const numericSleepMinutes = Number(sleepMinutes ?? 0);
    const numericGoalMinutes = Number(sleepGoalMinutes ?? 420);

    if (!Number.isFinite(numericSleepMinutes) || numericSleepMinutes < 0) {
      return res.status(400).json({ message: 'Valid sleep duration is required.' });
    }

    if (!Number.isFinite(numericGoalMinutes) || numericGoalMinutes <= 0) {
      return res.status(400).json({ message: 'Sleep goal must be greater than zero.' });
    }

    const date = new Date().toISOString().slice(0, 10);

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
        sleepGoalMinutes: 420,
        sleepTime: '00:00',
        wakeUpTime: '00:00',
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
    console.error('Get sleep summary error:', error.message);
    return res.status(500).json({ message: 'Unable to fetch sleep data.' });
  }
});

app.get('/api/sleep/history', authMiddleware, async (req, res) => {
  try {
    const { start, end } = req.query;
    const query = { userId: req.user._id };

    if (start || end) {
      query.date = {};
      if (start) query.date.$gte = String(start);
      if (end) query.date.$lte = String(end);
    }

    const history = await Sleep.find(query)
      .sort({ date: -1, recordedAt: -1 })
      .select('date sleepMinutes sleepGoalMinutes sleepTime wakeUpTime source recordedAt');

    return res.status(200).json({ history });
  } catch (error) {
    console.error('Sleep history error:', error.message);
    return res.status(500).json({ message: 'Unable to fetch sleep history.' });
  }
});

app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

app.listen(PORT, () => {
  console.log(`LiveFit backend running on http://localhost:${PORT}`);
});
