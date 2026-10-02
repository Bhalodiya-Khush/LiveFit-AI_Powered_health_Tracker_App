const axios = require('axios');

// Standard nutritional database per 100g (Calories, Protein, Carbs, Fat)
const standardNutritionDb = {
  // Grains & Staples
  'white rice': { calories: 130, protein: 2.7, carbs: 28.2, fat: 0.3 },
  'brown rice': { calories: 111, protein: 2.6, carbs: 23.0, fat: 0.9 },
  'roti': { calories: 264, protein: 9.0, carbs: 49.0, fat: 3.5 },
  'chapati': { calories: 264, protein: 9.0, carbs: 49.0, fat: 3.5 },
  'bread': { calories: 265, protein: 9.0, carbs: 49.0, fat: 3.2 },
  'oats': { calories: 389, protein: 16.9, carbs: 66.3, fat: 6.9 },
  'oatmeal': { calories: 68, protein: 2.5, carbs: 12.0, fat: 1.4 },
  'pasta': { calories: 157, protein: 5.8, carbs: 30.6, fat: 0.9 },
  
  // Proteins
  'chicken breast': { calories: 165, protein: 31.0, carbs: 0.0, fat: 3.6 },
  'grilled chicken': { calories: 165, protein: 31.0, carbs: 0.0, fat: 3.6 },
  'chicken': { calories: 190, protein: 27.0, carbs: 0.0, fat: 8.0 },
  'egg': { calories: 143, protein: 12.6, carbs: 0.7, fat: 9.5 },
  'boiled egg': { calories: 155, protein: 13.0, carbs: 1.1, fat: 11.0 },
  'paneer': { calories: 265, protein: 18.0, carbs: 3.0, fat: 20.0 },
  'tofu': { calories: 76, protein: 8.0, carbs: 1.9, fat: 4.8 },
  'salmon': { calories: 208, protein: 20.0, carbs: 0.0, fat: 13.0 },
  'dal': { calories: 116, protein: 9.0, carbs: 20.0, fat: 0.4 },
  'lentils': { calories: 116, protein: 9.0, carbs: 20.0, fat: 0.4 },
  'chickpeas': { calories: 164, protein: 8.9, carbs: 27.4, fat: 2.6 },
  'yogurt': { calories: 61, protein: 3.5, carbs: 4.7, fat: 3.3 },
  'greek yogurt': { calories: 59, protein: 10.0, carbs: 3.6, fat: 0.4 },
  'milk': { calories: 60, protein: 3.2, carbs: 4.8, fat: 3.2 },

  // Fruits
  'apple': { calories: 52, protein: 0.3, carbs: 13.8, fat: 0.2 },
  'banana': { calories: 89, protein: 1.1, carbs: 22.8, fat: 0.3 },
  'orange': { calories: 47, protein: 0.9, carbs: 11.8, fat: 0.1 },
  'berries': { calories: 57, protein: 0.7, carbs: 14.5, fat: 0.3 },
  'strawberries': { calories: 32, protein: 0.7, carbs: 7.7, fat: 0.3 },
  'blueberries': { calories: 57, protein: 0.7, carbs: 14.5, fat: 0.3 },
  'avocado': { calories: 160, protein: 2.0, carbs: 8.5, fat: 14.7 },

  // Vegetables & Salads
  'salad': { calories: 35, protein: 1.5, carbs: 6.0, fat: 0.5 },
  'broccoli': { calories: 34, protein: 2.8, carbs: 6.6, fat: 0.4 },
  'spinach': { calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4 },
  'cucumber': { calories: 15, protein: 0.7, carbs: 3.6, fat: 0.1 },
  'tomato': { calories: 18, protein: 0.9, carbs: 3.9, fat: 0.2 },
  'carrot': { calories: 41, protein: 0.9, carbs: 9.6, fat: 0.2 },
  'potato': { calories: 87, protein: 1.9, carbs: 20.1, fat: 0.1 },

  // Common Meals & Snacks
  'sandwich': { calories: 230, protein: 10.0, carbs: 30.0, fat: 7.0 },
  'pizza': { calories: 266, protein: 11.0, carbs: 33.0, fat: 10.0 },
  'burger': { calories: 250, protein: 13.0, carbs: 24.0, fat: 11.0 },
  'soup': { calories: 45, protein: 2.0, carbs: 7.0, fat: 1.0 },
  'nuts': { calories: 607, protein: 20.0, carbs: 21.0, fat: 54.0 },
  'almonds': { calories: 579, protein: 21.0, carbs: 22.0, fat: 50.0 },
};

/**
 * Match a recognized food item with OpenFoodFacts or fallback DB
 * @param {string} foodName 
 * @param {number} grams 
 */
async function getNutritionForFood(foodName, grams = 100) {
  const normalized = foodName.toLowerCase().trim();
  const scale = grams / 100;

  // 1. Try OpenFoodFacts API
  try {
    const encoded = encodeURIComponent(foodName);
    const offUrl = `https://world.openfoodfacts.net/api/v2/search?categories_tags_en=${encoded}&fields=code,product_name,nutriments&page_size=1`;
    
    const response = await axios.get(offUrl, {
      headers: { 'User-Agent': 'LiveFit-AI-HealthTracker/1.0 (health@livefit.app)' },
      timeout: 3000,
    });

    if (response.data && response.data.products && response.data.products.length > 0) {
      const product = response.data.products[0];
      const nutriments = product.nutriments || {};
      
      const caloriesPer100 = nutriments['energy-kcal_100g'] || 
        (nutriments['energy_100g'] ? Math.round(nutriments['energy_100g'] / 4.184) : null);
      
      if (caloriesPer100 != null) {
        const proteinPer100 = nutriments['proteins_100g'] || 0;
        const carbsPer100 = nutriments['carbohydrates_100g'] || 0;
        const fatPer100 = nutriments['fat_100g'] || 0;

        return {
          name: product.product_name || foodName,
          source: 'openfoodfacts',
          foodFactsId: product.code || '',
          estimatedGrams: grams,
          calories: Math.round(caloriesPer100 * scale),
          protein: Math.round(proteinPer100 * scale * 10) / 10,
          carbs: Math.round(carbsPer100 * scale * 10) / 10,
          fat: Math.round(fatPer100 * scale * 10) / 10,
        };
      }
    }
  } catch (err) {
    // OpenFoodFacts timeout or network issue - gracefully fall back
    console.warn(`OpenFoodFacts lookup for "${foodName}" failed, using fallback database.`, err.message);
  }

  // 2. Exact or substring match in Standard Nutrition DB
  for (const [key, val] of Object.entries(standardNutritionDb)) {
    if (normalized.includes(key) || key.includes(normalized)) {
      return {
        name: foodName,
        source: 'standard_nutrition_db',
        foodFactsId: 'USDA_' + key.replace(/\s+/g, '_'),
        estimatedGrams: grams,
        calories: Math.round(val.calories * scale),
        protein: Math.round(val.protein * scale * 10) / 10,
        carbs: Math.round(val.carbs * scale * 10) / 10,
        fat: Math.round(val.fat * scale * 10) / 10,
      };
    }
  }

  // 3. Sensible generic fallback for unknown dish
  const defaultPer100 = { calories: 150, protein: 5.0, carbs: 18.0, fat: 5.0 };
  return {
    name: foodName,
    source: 'estimated',
    foodFactsId: 'EST_UNKNOWN',
    estimatedGrams: grams,
    calories: Math.round(defaultPer100.calories * scale),
    protein: Math.round(defaultPer100.protein * scale * 10) / 10,
    carbs: Math.round(defaultPer100.carbs * scale * 10) / 10,
    fat: Math.round(defaultPer100.fat * scale * 10) / 10,
  };
}

module.exports = { getNutritionForFood, standardNutritionDb };
