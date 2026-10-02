const Compendium = require('../models/Compendium');
const { compendiumList } = require('./compendiumData');

/**
 * Seed or update all exercise demos in MongoDB database
 */
async function syncExerciseDemosToDatabase() {
  try {
    for (const item of compendiumList) {
      await Compendium.findOneAndUpdate(
        { code: item.code },
        {
          $set: {
            code: item.code,
            name: item.name,
            aliases: item.aliases || [],
            category: item.category,
            description: item.description,
            met: item.met,
            targetMuscle: item.targetMuscle,
            exerciseDbId: item.exerciseDbId || '',
            gifUrl: item.gifUrl,
            instructions: item.instructions || [],
            repetitions: item.repetitions || '3 sets x 12 reps',
            durationMinutes: item.durationMinutes || 15,
            difficulty: item.difficulty || 'Beginner',
          },
        },
        { upsert: true, new: true }
      );
    }
    const count = await Compendium.countDocuments();
    console.log(`✅ Exercise Demo Library synced to MongoDB (${count} demos available)`);
    return count;
  } catch (err) {
    console.error('Error syncing exercise demos to MongoDB:', err.message);
  }
}

/**
 * Searches the MongoDB database for the best matching demo GIF and instructions
 * for any given exercise name or muscle group
 */
async function findExerciseDemoInDb(queryName, targetMuscle = '', category = '') {
  try {
    const raw = (queryName || '').trim();
    if (!raw) {
      const fallback = await Compendium.findOne();
      return fallback;
    }

    const clean = raw.toLowerCase();

    // 1. Exact Name or Alias match in MongoDB
    let match = await Compendium.findOne({
      $or: [
        { name: { $regex: new RegExp(`^${clean}$`, 'i') } },
        { aliases: clean },
      ],
    });
    if (match) return match;

    // 2. Keyword match against name and aliases in MongoDB
    // Extract meaningful tokens (skip "exercise", "daily", "workout", "gentle", "recommended", etc.)
    const stopWords = new Set(['exercise', 'workout', 'routine', 'daily', 'recommended', 'for', 'the', 'and', 'with', 'sets', 'reps']);
    const tokens = clean
      .replace(/[^a-z0-9\s-]/g, ' ')
      .split(/\s+/)
      .filter(t => t.length > 2 && !stopWords.has(t));

    for (const token of tokens) {
      match = await Compendium.findOne({
        $or: [
          { name: { $regex: token, $options: 'i' } },
          { aliases: { $regex: token, $options: 'i' } },
          { description: { $regex: token, $options: 'i' } },
        ],
      });
      if (match) return match;
    }

    // 3. Match by targetMuscle in MongoDB
    if (targetMuscle && targetMuscle.trim().length > 2) {
      const muscleToken = targetMuscle.trim().split(/\s+/)[0];
      match = await Compendium.findOne({
        targetMuscle: { $regex: muscleToken, $options: 'i' },
      });
      if (match) return match;
    }

    // 4. Match by category in MongoDB
    if (category && category.trim().length > 2) {
      match = await Compendium.findOne({
        category: { $regex: category.trim(), $options: 'i' },
      });
      if (match) return match;
    }

    // 5. Fallback to first available exercise demo in MongoDB
    const fallback = await Compendium.findOne({ code: '02052' }) || await Compendium.findOne();
    return fallback;
  } catch (err) {
    console.error('Error finding exercise demo in DB:', err.message);
    return null;
  }
}

module.exports = {
  syncExerciseDemosToDatabase,
  findExerciseDemoInDb,
};
