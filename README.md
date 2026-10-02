# LiveFit - AI Powered Health Tracker App 🏃‍♂️🥗⚡

**LiveFit** is an AI-powered, holistic health and fitness mobile & web application built using **Flutter & Dart**, backed by a high-performance **Node.js, Express & MongoDB** backend.

Designed with an energetic **White and Orange aesthetic** (electric tangerine, warm amber, sunset gradient, and crisp white glassmorphic cards), LiveFit integrates state-of-the-art AI and sensor technologies to provide personal fitness guidance.

---

## 🌟 Key Features & Implementation Highlights

### 1. 🎨 Curated White & Orange Design Theme
* **Color Palette**: Electric Orange (`#FF6B00`), Sunset Tangerine (`#FF8533`), Deep Amber (`#E65100`), Soft Peach Cream (`#FFF4EC`), and Pure Surface White (`#FFFFFF`).
* **Modern Typography**: Google Fonts **Outfit** for bold, dynamic headings and **Inter** for clean, legible body metrics.
* **Micro-interactions & Cards**: Soft orange-tinted shadows, progress rings, pill badges, and animated transitions.

### 2. 🔐 JWT Authentication & Dynamic Age Calculation
* **Login**: Secure email and password authentication with JSON Web Tokens (JWT).
* **Registration**: Requires Name, Email, Password, Birthdate picker, Gender, Height (cm), Weight (kg), and Health Hurdles (e.g., *Knee Pain*).
* **Dynamic Age Calculation**: Backend and frontend dynamically compute user age from `birthDate` (`new Date().getFullYear() - birthDate.getFullYear()`).
* **Profile Management**: Profile page with BMI calculator, healthy weight category indicator, and condition hurdle manager.

### 3. 👟 Pedometer Step Tracking & 💤 Device Activity Sleep Estimation
* **Pedometer (`pedometer` package)**: Phone accelerometer sensor stream counts live steps, updates progress towards 10,000 steps, and automatically syncs to MongoDB `DailyLog`.
* **Sleep Estimation (`usage_stats` package)**: Analyzes device screen inactivity windows during the night (10 PM to 8 AM) to calculate estimated sleep duration, displayed on the dashboard and stored in DB.
* **Simulator Tools**: Built-in simulator controls (+500 / +1,500 steps and sleep slider) for instant evaluation on emulators and desktop platforms.

### 4. 📸 AI Meal & Calorie Scanner (Gemini Vision + OpenFoodFacts)
* User snaps or uploads a meal photo for **Breakfast**, **Lunch**, **Snack**, or **Dinner**.
* Backend sends the meal image to **Gemini LLM Vision (`gemini-1.5-flash`)** to recognize all food items and estimate portion weights in grams.
* Each food item is cross-referenced with **OpenFoodFacts** (`openfoodfacts` API) and nutritional databases to extract exact Calories, Protein, Carbohydrates, and Fats.
* Aggregates total calories, logs to MongoDB `Meal` collection, and updates Today's Calories Consumed on the dashboard.

### 5. 🏋️‍♂️ PA Compendium MET Workouts & ExerciseDB GIF Demos
* **PA Compendium Data (`https://pacompendium.com/`)**: Pre-seeded database of Metabolic Equivalent of Task (MET) values for exercises (Squats, Push-ups, Glute Bridges, Mountain Climbers, Jumping Jacks, Brisk Walking, etc.).
* **Calorie Burn Formula**:
  $$\text{Calories Burned} = \text{MET} \times \text{Weight (kg)} \times \left(\frac{\text{Duration in minutes}}{60}\right)$$
* **Weather-Aware 5 Suggested Exercises**: Uses `geolocator` coordinates and **Open-Meteo** (`https://open-meteo.com/`) to retrieve current local weather and temperature. A tailored prompt gives user age, height, weight, weather, and health hurdles to Gemini, which generates 5 customized exercises.
* **Knee-Pain & Hurdle Adaptation**: If the user has a hurdle like *knee pain*, Gemini automatically prioritizes knee-friendly movements (glute bridges, bird dogs, wall sits, pushups) without high-impact compressive shear.
* **ExerciseDB Animated GIFs (`https://oss.exercisedb.dev/`)**: Each exercise card and modal features an animated GIF demonstration so users can verify proper form.
* **Mark as Done**: Calculates burned calories, updates MongoDB, and reflects on the dashboard in real-time.

### 6. 🤖 Direct AI Health Coach Chat (Gemini LLM)
* Floating and header buttons provide one-tap access to the dedicated **AI Chat Screen**.
* Stores conversation in MongoDB and prompts Gemini:
  > *"You are LiveFit AI Health Coach. Give a summarized 3-4 line answer to the user's question, keeping in mind user context: age, height, weight, today's steps, weather, and health hurdles (e.g., knee pain)."*
* Quick chips for common queries: *"How am I doing today?"*, *"My knee is hurting today"*, *"Pre-workout snack"*, *"Sleep tips"*.

### 7. 📊 Weekly Analytics & Graphs (`fl_chart`)
* Dedicated analytics page visualizing the past 7 days:
  * **Daily Steps Bar Chart**: Steps per day vs. 10,000 steps goal.
  * **Dual-Bar Calorie Balance**: Food Intake Calories (Orange) vs. Calories Burned (Red).
  * **Sleep Hours Trend Line**: Inactivity sleep hours over the week.
  * **Health Score (0–100)**: Dynamic composite rating based on steps, sleep, and workouts.

---

## 🏗️ Project Architecture

```
LiveFit/
├── backend/                        # Node.js + Express + MongoDB REST API
│   ├── .env                        # Environment variables (PORT, MONGO_URI, JWT_SECRET, GEMINI_API_KEY)
│   ├── server.js                   # Express server entry point & MongoDB connection
│   ├── models/
│   │   ├── User.js                 # User schema (birthDate, calculated age, hurdles)
│   │   ├── DailyLog.js             # Steps, sleep, calories consumed & burned
│   │   ├── Meal.js                 # Food items, quantities, OpenFoodFacts macros
│   │   ├── Exercise.js             # Exercises, MET, duration, calories burned, GIF URLs
│   │   ├── Compendium.js           # PA Compendium entries with MET values
│   │   └── ChatMessage.js          # AI health chat message history
│   ├── routes/
│   │   ├── authRoutes.js           # /api/auth (register, login, profile)
│   │   ├── dailyStatsRoutes.js     # /api/stats (today, steps, sleep)
│   │   ├── mealRoutes.js           # /api/meals (analyze photo, today meals)
│   │   ├── exerciseRoutes.js       # /api/exercises (suggested, mark-done, compendium)
│   │   ├── chatRoutes.js           # /api/chat (message, history)
│   │   └── reportRoutes.js         # /api/reports (weekly 7-day analytics)
│   └── services/
│       ├── geminiService.js        # Gemini Vision analysis, 5-exercise routine, 3-4 line chat
│       ├── nutritionService.js     # OpenFoodFacts API query & USDA fallback database
│       ├── weatherService.js       # Open-Meteo forecast integration
│       └── compendiumData.js       # PA Compendium seed dataset with ExerciseDB GIFs
│
└── frontend/                       # Flutter Application (Android, iOS, Web, Windows)
    ├── pubspec.yaml                # pedometer, usage_stats, geolocator, fl_chart, google_fonts, etc.
    └── lib/
        ├── main.dart               # MultiProvider setup & theme routing
        ├── constants/
        │   └── theme.dart          # White & Orange design system and color palette
        ├── services/
        │   ├── api_service.dart    # HTTP client with JWT handling
        │   └── sensor_service.dart # Pedometer stream, Geolocator, usage_stats sleep
        ├── providers/
        │   ├── auth_provider.dart  # Authentication & user state
        │   └── health_provider.dart# Steps, sleep, nutrition, exercises, weather, chat
        ├── widgets/
        │   ├── weather_card.dart   # Open-Meteo weather display card
        │   ├── exercise_gif_dialog.dart # ExerciseDB GIF demo modal
        │   └── stat_progress_card.dart  # Metric card
        └── screens/
            ├── auth/
            │   ├── login_screen.dart    # JWT login
            │   └── register_screen.dart # Birthdate picker, age calc, hurdles
            ├── main_navigation_screen.dart # Floating bottom navigation & AI fab
            ├── dashboard/
            │   └── dashboard_screen.dart # Central health dashboard
            ├── meals/
            │   └── meal_tracker_screen.dart # Gemini Vision + OpenFoodFacts scanner
            ├── exercises/
            │   └── exercise_screen.dart  # 5 suggested workouts & MET burn tracker
            ├── chat/
            │   └── ai_chat_screen.dart   # Direct Gemini health coach chat
            ├── reports/
            │   └── weekly_report_screen.dart # fl_chart 7-day trends & health score
            └── profile/
                └── profile_screen.dart   # Calculated age, BMI, hurdles manager
```

---

## 🚀 Running the Application

### Step 1: Start MongoDB
MongoDB Server is already installed on your system. To ensure it is running:
```powershell
net start MongoDB
```

### Step 2: Run the Backend
```powershell
cd "d:\B.Tech\SEM5\New folder SDP project\LiveFit\backend"
npm install
node server.js
```
The backend starts on `http://localhost:5050` and automatically connects to MongoDB `livefit_db` and seeds the PA Compendium exercises.

> **Optional**: Set your Gemini API key in `LiveFit/backend/.env`:
> ```env
> GEMINI_API_KEY=your_gemini_api_key_here
> ```
> *Note: If no key is set, the server includes a calibrated fallback engine for vision, workouts, and chat so the app runs smoothly in offline/demo environments.*

### Step 3: Run the Flutter App
```powershell
cd "d:\B.Tech\SEM5\New folder SDP project\LiveFit\frontend"
flutter pub get
```

#### Run on Chrome / Web:
```powershell
flutter run -d chrome
```

#### Run on Windows Desktop:
```powershell
flutter run -d windows
```

#### Run on Connected Android Device / Emulator:
```powershell
flutter run -d android
```

---

## 🧪 Quick Test Credentials
* **Email**: `alex@example.com`
* **Password**: `password123`
* *Or tap "Create Account" on the login screen to register a new user with custom birthdate and health hurdles!*
