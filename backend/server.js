require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const authRoutes = require('./routes/authRoutes');
const dailyStatsRoutes = require('./routes/dailyStatsRoutes');
const mealRoutes = require('./routes/mealRoutes');
const exerciseRoutes = require('./routes/exerciseRoutes');
const chatRoutes = require('./routes/chatRoutes');
const reportRoutes = require('./routes/reportRoutes');

const Compendium = require('./models/Compendium');
const { compendiumList } = require('./services/compendiumData');

const app = express();

// Middlewares
app.use(cors());
app.use(express.json({ limit: '25mb' }));
app.use(express.urlencoded({ extended: true, limit: '25mb' }));

// Health Check
app.get('/', (req, res) => {
  res.json({
    status: 'LiveFit AI-Powered HealthTracker Backend is Running 🚀',
    version: '1.0.0',
    mongodb: mongoose.connection.readyState === 1 ? 'Connected' : 'Connecting...',
    geminiConfigured: !!process.env.GEMINI_API_KEY,
    timestamp: new Date().toISOString(),
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/stats', dailyStatsRoutes);
app.use('/api/meals', mealRoutes);
app.use('/api/exercises', exerciseRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/reports', reportRoutes);

// Error Handling Middleware
app.use((err, req, res, next) => {
  console.error('Unhandled Server Error:', err.stack);
  res.status(500).json({
    message: err.message || 'An unexpected server error occurred',
  });
});

const { syncExerciseDemosToDatabase } = require('./services/exerciseDemoService');
const { initMidnightDailyScheduler } = require('./services/schedulerService');

// Database Connection & Server Initialization
const PORT = process.env.PORT || 5000;
const HOST = '0.0.0.0';
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/livefit_db';

mongoose
  .connect(MONGODB_URI)
  .then(async () => {
    console.log('✅ Connected to MongoDB successfully at:', MONGODB_URI);

    // Auto-sync full exercise demo library with working GIF links into MongoDB
    try {
      await syncExerciseDemosToDatabase();
    } catch (seedErr) {
      console.warn('Exercise demo library sync warning:', seedErr.message);
    }

    // Initialize 23:59 daily midnight steps reset and finalization scheduler
    try {
      initMidnightDailyScheduler();
    } catch (schedErr) {
      console.warn('Midnight daily scheduler warning:', schedErr.message);
    }

    app.listen(PORT, HOST, () => {
      console.log(`🔥 LiveFit Backend REST API is running on port ${PORT}!`);
      console.log(`   - Local / Wired USB Debug: http://127.0.0.1:${PORT}`);
      console.log(`   - Connected to MongoDB database on port 27017 (${MONGODB_URI})`);
    });
  })
  .catch((err) => {
    console.error('❌ MongoDB Connection Error:', err.message);
    console.log('Starting server in offline-db mode...');
    app.listen(PORT, HOST, () => {
      console.log(`🔥 LiveFit Backend Server running (offline DB mode) on port ${PORT}`);
    });
  });
