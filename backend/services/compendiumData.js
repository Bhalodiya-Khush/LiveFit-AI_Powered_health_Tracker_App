// Physical Activity Compendium Data (https://pacompendium.com/)
// Pre-mapped with ExerciseDB verified GIFs stored directly in the LiveFit database

const compendiumList = [
  {
    code: '02050',
    name: 'Jumping Jacks',
    aliases: ['jumping jacks', 'jack', 'jumping jack', 'star jumps', 'jumping'],
    category: 'Conditioning',
    description: 'Jumping Jacks (vigorous cardiovascular endurance)',
    met: 8.0,
    targetMuscle: 'Full Body / Cardiovascular',
    exerciseDbId: '0514',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/1g5bPpA.gif',
    instructions: [
      'Stand upright with feet together and arms resting at your sides.',
      'Jump up, spreading your feet beyond hip-width while bringing your arms overhead.',
      'Jump back to the starting position with feet together and arms down.',
      'Maintain a light, rhythmic pace landing softly on the balls of your feet.'
    ],
    repetitions: '3 sets x 30 reps',
    durationMinutes: 10,
    difficulty: 'Beginner'
  },
  {
    code: '02052',
    name: 'Bodyweight Squats',
    aliases: ['squat', 'squats', 'bodyweight squats', 'air squat', 'air squats', 'deep squat', 'knee-friendly squat', 'chair squat', 'bodyweight squat'],
    category: 'Strength',
    description: 'Bodyweight Squats (lower body strength and mobility)',
    met: 5.0,
    targetMuscle: 'Quadriceps, Glutes',
    exerciseDbId: '0043',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/LIlE5Tn.gif',
    instructions: [
      'Stand with feet shoulder-width apart, chest upright and core braced.',
      'Hinge at hips and bend knees, lowering your body as if sitting back into a chair.',
      'Keep knees tracked in line with toes, descending until thighs are parallel to the floor.',
      'Drive through your heels to return to standing.'
    ],
    repetitions: '3 sets x 15 reps',
    durationMinutes: 15,
    difficulty: 'Beginner'
  },
  {
    code: '02020',
    name: 'Push-ups',
    aliases: ['pushup', 'push-up', 'pushups', 'push-ups', 'standard push-up', 'chest pushup'],
    category: 'Strength',
    description: 'Push-ups (chest, anterior deltoid and core conditioning)',
    met: 4.0,
    targetMuscle: 'Chest, Triceps, Shoulders',
    exerciseDbId: '0662',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/I4hDWkc.gif',
    instructions: [
      'Start in a high plank position with hands slightly wider than shoulder-width.',
      'Keep core braced and spine in a neutral line from head to heels.',
      'Lower your chest towards the floor until elbows reach 90 degrees.',
      'Press firmly through your palms to return to starting position.'
    ],
    repetitions: '3 sets x 12 reps',
    durationMinutes: 12,
    difficulty: 'Intermediate'
  },
  {
    code: '02021',
    name: 'Knee Push-ups',
    aliases: ['knee push-up', 'knee pushup', 'modified push-up', 'incline pushup', 'chair push-up', 'knee push-ups'],
    category: 'Strength',
    description: 'Modified Knee Push-ups (joint-friendly upper body strength)',
    met: 3.5,
    targetMuscle: 'Chest, Triceps',
    exerciseDbId: '0662',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/I4hDWkc.gif',
    instructions: [
      'Rest knees on an exercise mat, crossing ankles behind you.',
      'Place palms flat on the ground shoulder-width apart.',
      'Lower chest towards the floor with controlled breathing.',
      'Push back up keeping hips and torso moving as one unit.'
    ],
    repetitions: '3 sets x 10 reps',
    durationMinutes: 10,
    difficulty: 'Beginner'
  },
  {
    code: '02035',
    name: 'Plank Hold',
    aliases: ['plank', 'plank hold', 'forearm plank', 'core plank', 'planks'],
    category: 'Core',
    description: 'Plank (Isometric Core & Abdominal Hold)',
    met: 3.5,
    targetMuscle: 'Core, Abs, Lower Back',
    exerciseDbId: '0467',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/CosupLu.gif',
    instructions: [
      'Rest on forearms with elbows directly under shoulders.',
      'Extend legs behind you, balancing on toes.',
      'Engage glutes and core, keeping body in a straight line from head to heels.',
      'Hold steady, breathing consistently without letting hips sag.'
    ],
    repetitions: '3 sets x 45 seconds',
    durationMinutes: 10,
    difficulty: 'Beginner'
  },
  {
    code: '02036',
    name: 'Side Plank',
    aliases: ['side plank', 'side plank hold', 'oblique plank'],
    category: 'Core',
    description: 'Side Plank (Lateral core stability and oblique strengthening)',
    met: 3.5,
    targetMuscle: 'Obliques, Core, Shoulders',
    exerciseDbId: '0467',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/CosupLu.gif',
    instructions: [
      'Lie on your side with legs straight and feet stacked.',
      'Prop your upper body up on your elbow and forearm.',
      'Raise hips until your body forms a straight line from ankles to shoulders.',
      'Hold position and switch sides.'
    ],
    repetitions: '3 sets x 30 sec each side',
    durationMinutes: 10,
    difficulty: 'Intermediate'
  },
  {
    code: '02054',
    name: 'Bodyweight Lunges',
    aliases: ['lunge', 'lunges', 'bodyweight lunges', 'forward lunges', 'reverse lunges', 'walking lunges'],
    category: 'Strength',
    description: 'Bodyweight Lunges (quad, hamstring and balance conditioning)',
    met: 4.0,
    targetMuscle: 'Quadriceps, Hamstrings, Glutes',
    exerciseDbId: '0060',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/kMzUs9Y.gif',
    instructions: [
      'Stand tall with feet hip-width apart.',
      'Step forward with your right leg and lower hips until both knees are bent at about 90 degrees.',
      'Ensure front knee remains stacked over ankle, not past toes.',
      'Push back up through heel and switch legs.'
    ],
    repetitions: '3 sets x 12 reps per leg',
    durationMinutes: 15,
    difficulty: 'Intermediate'
  },
  {
    code: '02060',
    name: 'Mountain Climbers',
    aliases: ['mountain climber', 'mountain climbers', 'climbers', 'climber'],
    category: 'Cardio',
    description: 'Mountain Climbers (dynamic core and aerobic power)',
    met: 8.0,
    targetMuscle: 'Core, Hip Flexors, Shoulders',
    exerciseDbId: '0484',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/RJgzwny.gif',
    instructions: [
      'Begin in a traditional high plank position.',
      'Drive your right knee toward your chest without letting hips raise.',
      'Quickly switch, extending right leg back while driving left knee forward.',
      'Continue alternating in a fluid running motion.'
    ],
    repetitions: '3 sets x 30 seconds',
    durationMinutes: 10,
    difficulty: 'Intermediate'
  },
  {
    code: '02070',
    name: 'High Knees',
    aliases: ['high knee', 'high knees', 'marching in place', 'knee lifts', 'knee'],
    category: 'Cardio',
    description: 'High Knees (cardiovascular agility and calf conditioning)',
    met: 8.0,
    targetMuscle: 'Cardio, Calves, Hip Flexors',
    exerciseDbId: '0512',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/ealLwvX.gif',
    instructions: [
      'Stand in place with feet hip-width apart.',
      'Drive one knee up toward your chest as high as comfortable.',
      'Quickly alternate to the opposite leg with an active arm swing.',
      'Maintain an upright posture and soft landing.'
    ],
    repetitions: '3 sets x 40 seconds',
    durationMinutes: 10,
    difficulty: 'Intermediate'
  },
  {
    code: '02080',
    name: 'Glute Bridges',
    aliases: ['glute bridge', 'glute bridges', 'bridge', 'hip bridge', 'pelvic lift', 'single leg bridge'],
    category: 'Conditioning',
    description: 'Glute Bridges (zero-knee-stress glute and posterior chain strengthening)',
    met: 3.5,
    targetMuscle: 'Glutes, Hamstrings, Lower Back',
    exerciseDbId: '0142',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/u0cNiij.gif',
    instructions: [
      'Lie flat on your back with knees bent and feet flat on the floor, hip-width apart.',
      'Squeeze your glutes and push through your heels to raise hips toward ceiling.',
      'Form a straight diagonal line from knees to shoulders.',
      'Pause at the top for 1-2 seconds, then slowly lower down.'
    ],
    repetitions: '3 sets x 15 reps',
    durationMinutes: 12,
    difficulty: 'Beginner'
  },
  {
    code: '02090',
    name: 'Wall Sit',
    aliases: ['wall sit', 'wall squat', 'isometric wall sit', 'wall sits'],
    category: 'Strength',
    description: 'Wall Sit (Isometric Quad & Knee Joint Stability)',
    met: 3.0,
    targetMuscle: 'Quadriceps, Glutes',
    exerciseDbId: '0450',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/xdYPUtE.gif',
    instructions: [
      'Stand 2 feet from a sturdy wall, leaning your back flat against it.',
      'Slide down until thighs are parallel to the floor (or 45 degrees if knee discomfort).',
      'Keep ankles directly below knees and back straight.',
      'Hold position while breathing evenly.'
    ],
    repetitions: '3 sets x 30-45 seconds',
    durationMinutes: 10,
    difficulty: 'Beginner'
  },
  {
    code: '12020',
    name: 'Brisk Walking',
    aliases: ['brisk walk', 'walk', 'walking', 'brisk walking', 'power walk', 'indoor walk', 'outdoor walk', 'gentle walk'],
    category: 'Cardio',
    description: 'Brisk Walking (Aerobic conditioning and calorie burn)',
    met: 4.3,
    targetMuscle: 'Cardiovascular, Legs',
    exerciseDbId: '1001',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/IZVHb27.gif',
    instructions: [
      'Walk at a steady, vigorous pace of approx 3.5 - 4.0 mph.',
      'Keep eyes forward, shoulders relaxed, and swing arms naturally.',
      'Push off with toes and land smoothly through the heel.'
    ],
    repetitions: '1 continuous session',
    durationMinutes: 20,
    difficulty: 'Beginner'
  },
  {
    code: '02110',
    name: 'Gentle Yoga & Mobility',
    aliases: ['yoga', 'stretch', 'stretching', 'mobility', 'joint mobility', 'gentle yoga', 'cat-cow', 'child pose', 'downward dog', 'cobra stretch'],
    category: 'Mobility',
    description: 'Gentle Yoga & Joint Mobility (Restorative movement and joint decompression)',
    met: 2.5,
    targetMuscle: 'Mobility, Flexibility, Full Body',
    exerciseDbId: '01qpYSe',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/bWlZvXh.gif',
    instructions: [
      'Transition smoothly through gentle stretches (Cat-Cow, Child pose, Cobra).',
      'Coordinate movement with slow, deep nasal breaths.',
      'Never push into sharp joint pain; focus on opening tight joints gently.'
    ],
    repetitions: '5 slow breath cycles per pose',
    durationMinutes: 15,
    difficulty: 'Beginner'
  },
  {
    code: '02120',
    name: 'Bird Dog',
    aliases: ['bird dog', 'bird-dog', 'quadruped reach', 'back extension quadruped'],
    category: 'Core',
    description: 'Bird Dog (Spine & Core Stability, zero spinal compression)',
    met: 3.0,
    targetMuscle: 'Erector Spinae, Glutes, Deltoids',
    exerciseDbId: '0150',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/rmEukuS.gif',
    instructions: [
      'Start on all fours with hands under shoulders and knees under hips.',
      'Slowly extend right arm forward and left leg backward until parallel to floor.',
      'Hold for 2 seconds, maintaining level hips without arching lower back.',
      'Lower down and repeat with opposite arm and leg.'
    ],
    repetitions: '3 sets x 10 reps each side',
    durationMinutes: 10,
    difficulty: 'Beginner'
  },
  {
    code: '02130',
    name: 'Bicycle Crunches',
    aliases: ['bicycle crunch', 'bicycle crunches', 'crunches', 'crunch', 'abdominal crunch', 'abs'],
    category: 'Core',
    description: 'Bicycle Crunches (deep abdominal and oblique conditioning)',
    met: 4.5,
    targetMuscle: 'Rectus Abdominis, Obliques',
    exerciseDbId: '0312',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/31xL9wV.gif',
    instructions: [
      'Lie flat on your back, knees bent, hands behind your head with elbows wide.',
      'Pedal legs in bicycle motion while twisting your torso to bring opposite elbow to knee.',
      'Engage core and avoid pulling on your neck.'
    ],
    repetitions: '3 sets x 15 reps',
    durationMinutes: 10,
    difficulty: 'Intermediate'
  },
  {
    code: '02140',
    name: 'Tricep Dips',
    aliases: ['tricep dip', 'tricep dips', 'chair dips', 'bench dips', 'dips'],
    category: 'Strength',
    description: 'Chair / Bench Tricep Dips (arms and upper body tone)',
    met: 4.0,
    targetMuscle: 'Triceps, Front Deltoids',
    exerciseDbId: '0214',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/XjA0wB3.gif',
    instructions: [
      'Sit on the edge of a stable chair or bench, hands gripping edge next to hips.',
      'Slide hips off edge, bending elbows to lower your body until elbows reach 90 degrees.',
      'Push through palms to return to starting position.'
    ],
    repetitions: '3 sets x 12 reps',
    durationMinutes: 10,
    difficulty: 'Beginner'
  },
  {
    code: '02150',
    name: 'Calf Raises',
    aliases: ['calf raise', 'calf raises', 'standing calf raise', 'heel lifts'],
    category: 'Strength',
    description: 'Calf Raises (ankle stability and lower leg endurance)',
    met: 3.5,
    targetMuscle: 'Gastrocnemius, Soleus, Ankles',
    exerciseDbId: '0215',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/yY2w2Z3.gif',
    instructions: [
      'Stand upright near a wall for balance with feet hip-width apart.',
      'Slowly press up onto the balls of your feet, lifting heels high.',
      'Pause at the peak for a full second, feeling calves contract.',
      'Slowly lower down until heels touch the ground.'
    ],
    repetitions: '3 sets x 20 reps',
    durationMinutes: 8,
    difficulty: 'Beginner'
  },
  {
    code: '02160',
    name: 'Arm Circles',
    aliases: ['arm circle', 'arm circles', 'shoulder circles', 'shoulder warmup'],
    category: 'Mobility',
    description: 'Arm Circles (shoulder joint warm-up and rotator cuff activation)',
    met: 2.8,
    targetMuscle: 'Deltoids, Upper Back',
    exerciseDbId: '0216',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/bWlZvXh.gif',
    instructions: [
      'Stand tall and extend arms straight out to the sides parallel to the floor.',
      'Make controlled forward circular motions for 30 seconds.',
      'Reverse direction and circle backwards for 30 seconds.'
    ],
    repetitions: '3 sets x 30 seconds',
    durationMinutes: 6,
    difficulty: 'Beginner'
  },
  {
    code: '02170',
    name: 'Russian Twists',
    aliases: ['russian twist', 'russian twists', 'seated twist', 'torso rotation'],
    category: 'Core',
    description: 'Russian Twists (rotational core strength and abdominal stability)',
    met: 4.0,
    targetMuscle: 'Obliques, Core',
    exerciseDbId: '0217',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/31xL9wV.gif',
    instructions: [
      'Sit on floor with knees bent and feet slightly elevated or on the floor.',
      'Lean back slightly to engage your core.',
      'Rotate your torso from side to side with hands clasped in front.'
    ],
    repetitions: '3 sets x 20 twists',
    durationMinutes: 10,
    difficulty: 'Intermediate'
  },
  {
    code: '02180',
    name: 'Dead Bug',
    aliases: ['dead bug', 'deadbug', 'supine core hold'],
    category: 'Core',
    description: 'Dead Bug (Spine-safe deep core and pelvic floor stabilization)',
    met: 3.2,
    targetMuscle: 'Transverse Abdominis, Core',
    exerciseDbId: '0218',
    gifUrl: 'https://raw.githubusercontent.com/Johnson-Jia/exercises-dataset/main/media/rmEukuS.gif',
    instructions: [
      'Lie flat on back with arms pointed toward ceiling and knees at 90 degrees.',
      'Press lower back firmly into the floor.',
      'Simultaneously lower right arm overhead and left leg toward floor without arching back.',
      'Return to center and switch to opposite limbs.'
    ],
    repetitions: '3 sets x 12 reps',
    durationMinutes: 10,
    difficulty: 'Beginner'
  }
];

module.exports = { compendiumList };
