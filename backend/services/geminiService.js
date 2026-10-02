const axios = require('axios');

// Supported production Gemini models with automatic load-balancing
const CANDIDATE_MODELS = [
  'gemini-3.1-flash-lite',
  'gemini-flash-latest',
  'gemini-3.8-flash',
  'gemini-3.5-flash',
];

/**
 * Universal Gemini API caller supporting both new AQ.* keys and traditional AIza* keys
 */
async function callGemini(contents, timeoutMs = 25000) {
  const key = (process.env.GEMINI_API_KEY || '').trim();
  if (!key) {
    throw new Error('Gemini API key is not configured in backend/.env.');
  }

  let lastError = null;

  for (const model of CANDIDATE_MODELS) {
    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
      const response = await axios.post(
        url,
        { contents },
        {
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': key,
          },
          timeout: timeoutMs,
        }
      );

      const candidate = response.data && response.data.candidates && response.data.candidates[0];
      if (candidate && candidate.content && candidate.content.parts && candidate.content.parts[0]) {
        return candidate.content.parts[0].text.trim();
      }
    } catch (err) {
      const status = err.response ? err.response.status : null;
      const errorMsg = err.response && err.response.data && err.response.data.error
        ? err.response.data.error.message
        : err.message;
      lastError = errorMsg;

      // If model retired (404) or high demand (503) or rate limit (429) or timeout (ECONNABORTED), try next candidate
      if (status === 404 || status === 503 || status === 429 || err.code === 'ECONNABORTED' || (err.message && err.message.includes('timeout'))) {
        continue;
      }

      // Hard error (e.g. 401 or 400)
      throw new Error(`Gemini API Error (${status || 'Network'}): ${errorMsg}`);
    }
  }

  throw new Error(`Gemini service error: ${lastError || 'All models unavailable'}`);
}

/**
 * 1. Analyze Meal Image with Gemini Vision
 */
async function analyzeMealImage(base64Data, mimeType = 'image/jpeg') {
  if (!base64Data || base64Data.trim() === '') {
    throw new Error('No meal image provided. Please capture or select a photo of your meal.');
  }

  const prompt = `You are an expert nutritionist and computer vision AI.
Analyze this meal image carefully.
Identify all distinct food items visible on the plate or bowl.
Estimate the portion and weight in grams for each food item.

Return ONLY a clean JSON array (no markdown code blocks, no backticks, just raw JSON) matching this structure:
[
  {
    "name": "White Rice",
    "quantity": "1 cup",
    "estimatedGrams": 150,
    "confidence": 0.95
  }
]`;

  const contents = [
    {
      parts: [
        { text: prompt },
        {
          inline_data: {
            mime_type: mimeType || 'image/jpeg',
            data: base64Data,
          },
        },
      ],
    },
  ];

  try {
    let text = await callGemini(contents, 30000);

    // Clean up markdown code fences if present
    if (text.startsWith('```json')) text = text.replace(/^```json/, '').replace(/```$/, '').trim();
    else if (text.startsWith('```')) text = text.replace(/^```/, '').replace(/```$/, '').trim();

    const parsed = JSON.parse(text);
    if (Array.isArray(parsed) && parsed.length > 0) {
      return parsed;
    }
    throw new Error('AI was unable to detect distinct food items in this photo. Please try a clearer picture.');
  } catch (err) {
    console.error('Gemini vision analysis error:', err.message);
    throw new Error(`AI Meal Recognition Error: ${err.message}`);
  }
}

/**
 * 2. Generate 5 Tailored Exercises with Gemini
 * 100% Dependent on Gemini LLM (Age, Height, Weight, Weather, and Health Hurdles)
 */
async function generateTailoredExercises({ age, height, weight, weather, hurdle = 'none' }) {
  const hasKneePain = (hurdle && hurdle.toLowerCase().includes('knee'));

  const prompt = `You are a certified sports science trainer and exercise physiologist.
Create a personalized routine of EXACTLY 5 tailored exercises for this user:
- Age: ${age} years
- Weight: ${weight} kg
- Height: ${height} cm
- Current Weather: ${weather ? weather.condition : 'Pleasant'}, ${weather ? weather.temperature : 25}°C (Indoor workout recommended: ${weather ? weather.indoorRecommended : false})
- Health Hurdle/Injury: "${hurdle}"

CRITICAL INSTRUCTIONS:
${hasKneePain ? '- The user has KNEE PAIN. You MUST avoid deep heavy knee flexions, jumping squats, and high impact plyometrics. Suggest knee-friendly movements (e.g., Glute Bridges, Bird Dog, Wall Sit, Modified Knee Push-ups, Gentle Yoga & Mobility, Brisk Walking).' : '- Tailor the intensity according to age, weight, and weather.'}
- Reference standard Metabolic Equivalent of Task (MET) from the Physical Activity Compendium.
- For maximum demo compatibility, prioritize standard recognized exercises from our library: [Bodyweight Squats, Push-ups, Knee Push-ups, Plank Hold, Side Plank, Bodyweight Lunges, Mountain Climbers, High Knees, Glute Bridges, Wall Sit, Brisk Walking, Gentle Yoga & Mobility, Bird Dog, Bicycle Crunches, Tricep Dips, Calf Raises, Arm Circles, Russian Twists, Dead Bug, Jumping Jacks].

Return ONLY a clean JSON array (no markdown code blocks, just raw JSON) of 5 items:
[
  {
    "exerciseName": "Glute Bridges",
    "category": "Conditioning",
    "targetMuscle": "Glutes & Core",
    "metValue": 3.5,
    "durationMinutes": 15,
    "repetitions": "3 sets x 15 reps",
    "reason": "Strengthens hips and glutes without placing compressive load on knee joints.",
    "exerciseDbQuery": "glute bridges"
  }
]`;

  const contents = [
    {
      parts: [{ text: prompt }],
    },
  ];

  try {
    let text = await callGemini(contents, 25000);
    if (text.startsWith('```json')) text = text.replace(/^```json/, '').replace(/```$/, '').trim();
    else if (text.startsWith('```')) text = text.replace(/^```/, '').replace(/```$/, '').trim();

    const parsed = JSON.parse(text);
    if (Array.isArray(parsed) && parsed.length >= 3) {
      return parsed.slice(0, 5);
    }
    throw new Error('Gemini returned an invalid exercise format.');
  } catch (err) {
    console.error('Gemini exercise generation error:', err.message);
    throw new Error(`Gemini AI Exercise Generation Error: ${err.message}`);
  }
}

/**
 * 3. Chat with Gemini LLM
 * Delivers concise 3-4 line answers considering user health hurdles (like knee pain)
 */
async function chatWithGemini({ message, user, weather, todayStats }) {
  const hurdle = user.healthHurdles || 'none';
  const age = user.age || 25;
  const weight = user.weight || 70;
  const height = user.height || 175;
  const steps = todayStats ? todayStats.steps : 0;
  const weatherCond = weather ? `${weather.condition}, ${weather.temperature}°C` : 'Pleasant';

  const prompt = `You are LiveFit AI, a friendly, certified fitness and nutrition coach.
User Context:
- Name: ${user.name}
- Age: ${age} years old
- Height: ${height} cm, Weight: ${weight} kg
- Health hurdle / condition: "${hurdle}"
- Today's Steps: ${steps}
- Current Weather: ${weatherCond}

User Question: "${message}"

RESPONSE RULES (CRITICAL):
1. Give a direct, encouraging, scientifically grounded answer in EXACTLY 3 to 4 concise lines.
2. If the user mentions pain (e.g., knee pain, back pain) or asks what to do with a hurdle, address it empathetically with safe modifications and advice.
3. Keep the tone warm, empowering, and actionable. Do not output preamble or fluff.`;

  const contents = [
    {
      parts: [{ text: prompt }],
    },
  ];

  try {
    return await callGemini(contents, 25000);
  } catch (err) {
    console.error('Gemini chat error:', err.message);
    return `⚠️ LiveFit AI: Unable to connect to Gemini (${err.message}). Please check your internet connection.`;
  }
}

module.exports = {
  analyzeMealImage,
  generateTailoredExercises,
  chatWithGemini,
};
