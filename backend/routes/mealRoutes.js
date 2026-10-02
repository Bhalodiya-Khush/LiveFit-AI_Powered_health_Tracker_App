const express = require('express');
const router = express.Router();
const multer = require('multer');
const Meal = require('../models/Meal');
const DailyLog = require('../models/DailyLog');
const { protect } = require('../middleware/authMiddleware');
const { analyzeMealImage } = require('../services/geminiService');
const { getNutritionForFood } = require('../services/nutritionService');

// In-memory multer storage for image upload
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
});

const getTodayDateString = () => {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

/**
 * Time Slices for Meals:
 * - 05:00 - 11:30: Breakfast (Morning)
 * - 11:30 - 16:00: Lunch (Midday)
 * - 16:00 - 19:00: Snack (Late afternoon / tea)
 * - 19:00 - 05:00: Dinner (Evening / Night)
 */
const getCurrentMealType = () => {
  const now = new Date();
  const decimalTime = now.getHours() + now.getMinutes() / 60;

  if (decimalTime >= 5.0 && decimalTime < 11.5) {
    return 'breakfast';
  } else if (decimalTime >= 11.5 && decimalTime < 16.0) {
    return 'lunch';
  } else if (decimalTime >= 16.0 && decimalTime < 19.0) {
    return 'snack';
  } else {
    return 'dinner';
  }
};

// @route   GET /api/meals/current-slot
// @desc    Get current active meal slot based on time
router.get('/current-slot', (req, res) => {
  res.json({
    success: true,
    currentMealType: getCurrentMealType(),
    serverTime: new Date().toLocaleTimeString(),
  });
});

// @route   POST /api/meals/analyze
// @desc    Analyze meal image with Gemini LLM, match with OpenFoodFacts, and store in DB
router.post('/analyze', protect, upload.single('image'), async (req, res) => {
  try {
    const mealType = (req.body.mealType || getCurrentMealType()).toLowerCase();
    let base64Image = '';
    let mimeType = 'image/jpeg';

    if (req.file) {
      base64Image = req.file.buffer.toString('base64');
      mimeType = req.file.mimetype;
    } else if (req.body.imageBase64) {
      base64Image = req.body.imageBase64.replace(/^data:image\/\w+;base64,/, '');
      mimeType = req.body.mimeType || 'image/jpeg';
    } else {
      // In case user enters meal items manually or tests without image
      base64Image = '';
    }

    console.log(`Analyzing ${mealType} image with Gemini Vision...`);

    // 1. Ask Gemini LLM to recognize food items and estimated portions
    const detectedItems = await analyzeMealImage(base64Image, mimeType);

    // 2. Query OpenFoodFacts for each recognized item to retrieve real nutrition
    const enrichedItems = [];
    let totalCalories = 0;
    let totalProtein = 0;
    let totalCarbs = 0;
    let totalFat = 0;

    for (const item of detectedItems) {
      const nutrition = await getNutritionForFood(item.name, item.estimatedGrams || 100);
      enrichedItems.push({
        name: item.name,
        quantity: item.quantity || `${item.estimatedGrams || 100}g`,
        estimatedGrams: item.estimatedGrams || 100,
        calories: nutrition.calories,
        protein: nutrition.protein,
        carbs: nutrition.carbs,
        fat: nutrition.fat,
        foodFactsId: nutrition.foodFactsId || '',
        confidence: item.confidence || 0.9,
      });

      totalCalories += nutrition.calories;
      totalProtein += nutrition.protein;
      totalCarbs += nutrition.carbs;
      totalFat += nutrition.fat;
    }

    // 3. Save Meal to MongoDB
    const today = getTodayDateString();
    const meal = await Meal.create({
      user: req.user._id,
      date: today,
      mealType,
      imageUrl: base64Image ? `data:${mimeType};base64,${base64Image.slice(0, 100)}...` : '',
      items: enrichedItems,
      totalCalories: Math.round(totalCalories),
      totalProtein: Math.round(totalProtein * 10) / 10,
      totalCarbs: Math.round(totalCarbs * 10) / 10,
      totalFat: Math.round(totalFat * 10) / 10,
    });

    // 4. Update today's total calories in DailyLog
    const todayMeals = await Meal.find({ user: req.user._id, date: today });
    const todayTotalConsumed = todayMeals.reduce((sum, m) => sum + (m.totalCalories || 0), 0);

    await DailyLog.findOneAndUpdate(
      { user: req.user._id, date: today },
      { $set: { caloriesConsumed: todayTotalConsumed, lastUpdated: new Date() } },
      { upsert: true }
    );

    res.status(201).json({
      success: true,
      message: 'Meal analyzed and logged successfully',
      meal,
      todayCaloriesConsumed: todayTotalConsumed,
    });
  } catch (error) {
    console.error('Error analyzing meal:', error);
    res.status(500).json({ message: error.message || 'Error processing meal photo' });
  }
});

// @route   GET /api/meals/today
// @desc    Get all meals logged today
router.get('/today', protect, async (req, res) => {
  try {
    const today = getTodayDateString();
    const meals = await Meal.find({ user: req.user._id, date: today }).sort({ createdAt: -1 });

    const totals = meals.reduce(
      (acc, m) => ({
        calories: acc.calories + (m.totalCalories || 0),
        protein: acc.protein + (m.totalProtein || 0),
        carbs: acc.carbs + (m.totalCarbs || 0),
        fat: acc.fat + (m.totalFat || 0),
      }),
      { calories: 0, protein: 0, carbs: 0, fat: 0 }
    );

    res.json({
      success: true,
      currentMealType: getCurrentMealType(),
      meals,
      totals: {
        calories: Math.round(totals.calories),
        protein: Math.round(totals.protein * 10) / 10,
        carbs: Math.round(totals.carbs * 10) / 10,
        fat: Math.round(totals.fat * 10) / 10,
      },
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
