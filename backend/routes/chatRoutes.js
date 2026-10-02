const express = require('express');
const router = express.Router();
const ChatMessage = require('../models/ChatMessage');
const DailyLog = require('../models/DailyLog');
const { protect } = require('../middleware/authMiddleware');
const { chatWithGemini } = require('../services/geminiService');
const { getWeather } = require('../services/weatherService');

const getTodayDateString = () => {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

// @route   POST /api/chat/message
// @desc    Direct user interaction with Gemini AI health coach
router.post('/message', protect, async (req, res) => {
  try {
    const { message, lat, lon } = req.body;

    if (!message || message.trim() === '') {
      return res.status(400).json({ message: 'Message is required' });
    }

    // 1. Store user message in DB
    await ChatMessage.create({
      user: req.user._id,
      role: 'user',
      message: message.trim(),
    });

    // 2. Gather rich context
    const today = getTodayDateString();
    const todayStats = await DailyLog.findOne({ user: req.user._id, date: today });
    const weather = await getWeather(lat ? Number(lat) : null, lon ? Number(lon) : null);

    // 3. Ask Gemini with 3-4 line instruction and hurdle adaptation (e.g. knee pain)
    const aiAnswer = await chatWithGemini({
      message: message.trim(),
      user: req.user,
      weather,
      todayStats,
    });

    // 4. Store AI response in DB
    const aiMessageDoc = await ChatMessage.create({
      user: req.user._id,
      role: 'model',
      message: aiAnswer,
      healthHurdleUsed: req.user.healthHurdles || '',
    });

    res.json({
      success: true,
      response: aiAnswer,
      message: aiMessageDoc,
    });
  } catch (error) {
    console.error('Chat error:', error);
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/chat/history
// @desc    Get user chat history with Gemini
router.get('/history', protect, async (req, res) => {
  try {
    const history = await ChatMessage.find({ user: req.user._id })
      .sort({ timestamp: 1 })
      .limit(50);

    res.json({
      success: true,
      history,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   DELETE /api/chat/history
// @desc    Clear chat history
router.delete('/history', protect, async (req, res) => {
  try {
    await ChatMessage.deleteMany({ user: req.user._id });
    res.json({ success: true, message: 'Chat history cleared' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
