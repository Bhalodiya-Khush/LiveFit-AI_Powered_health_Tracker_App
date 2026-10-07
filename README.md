# LiveFit - AI Powered Health Tracker App 🏃‍♂️🥗⚡

[![Download APK](https://img.shields.io/badge/Download_APK-v1.0.1-FF6B00?style=for-the-badge&logo=android&logoColor=white)](https://github.com/Bhalodiya-Khush/LiveFit-AI_Powered_health_Tracker_App/releases/download/v1.0.1/app-release.apk)
[![Backend Status](https://img.shields.io/badge/Backend-Live_on_Render-28A745?style=for-the-badge&logo=render&logoColor=white)](https://livefit-ai-powered-health-tracker-app.onrender.com)
[![Database](https://img.shields.io/badge/Database-MongoDB_Atlas-47A248?style=for-the-badge&logo=mongodb&logoColor=white)](https://www.mongodb.com/atlas)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Gemini AI](https://img.shields.io/badge/Google_Gemini-Vision_%26_LLM-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://aistudio.google.com)

**LiveFit** is a full-stack, AI-powered health and fitness mobile application built with **Flutter & Dart**, backed by a production-ready **Node.js, Express & MongoDB Atlas** cloud API deployed on **Render**.

Designed with an energetic **White and Orange aesthetic** (electric tangerine, warm amber, and crisp glassmorphic cards), LiveFit seamlessly integrates hardware pedometer streams, device sleep analysis, Gemini Vision meal scanning, and real-time weather-adapted exercise recommendations.

---

## 📲 Download & Install the Android App

You can install and run the production app directly on your Android phone without needing any development tools or USB cables:

### 📥 Direct Download Links:
* **[Download LiveFit Release APK (v1.0.1)](https://github.com/Bhalodiya-Khush/LiveFit-AI_Powered_health_Tracker_App/releases/download/v1.0.1/app-release.apk)**
* **[View GitHub Release Page (v1.0.1)](https://github.com/Bhalodiya-Khush/LiveFit-AI_Powered_health_Tracker_App/releases/tag/v1.0.1)**

### 📱 Installation Steps:
1. Tap the **Download APK** link above on your Android phone (or download on PC and transfer to phone's **Download** folder via USB).
2. Open **Files** / **My Files** on your phone → Tap **Downloads** (or **Installation files**).
3. Tap **`app-release.apk`** and tap **Install** *(if prompted, allow installation from this source)*.
4. Open **LiveFit**, create an account or sign in, and you're ready to go!

---

## 🌐 Live Cloud Architecture

The mobile application is pre-configured to connect directly to the live cloud backend over secure HTTPS:

* **Production Backend API**: [`https://livefit-ai-powered-health-tracker-app.onrender.com`](https://livefit-ai-powered-health-tracker-app.onrender.com)
* **Cloud Database**: MongoDB Atlas Global Shared Cluster (Active & Whitelisted)
* **AI Engine**: Google Gemini 1.5 Flash Vision & LLM
* **Weather API**: Open-Meteo Live Geocoded Forecast

---

## 🌟 Core Features & Implementation Highlights

### 1. 👟 Real-Time Pedometer & Daily Reset Engine
* **Hardware Step Stream**: Listens to device accelerometer/pedometer hardware events (`pedometer` package).
* **0 / -1 Sensor Calibration**: Gracefully filters uncalibrated or idle sensor values so step counts never display erratic jumps.
* **Daily Baseline Subtraction**: Accurately calculates today's steps by subtracting the starting baseline from the cumulative hardware reading:
  $$\text{Today Steps} = \text{Current Hardware Reading} - \text{Baseline at Start of Day}$$
* **Automatic 23:59 Midnight Reset**: A background cron scheduler on the server automatically finalizes each day's step counts at 11:59 PM so every day begins at 0 steps.
* **View-Only Dashboard Cards**: The four primary metrics (**Steps**, **Sleep**, **Food Intake**, and **Calories Burned**) are presented as clean, read-only metric displays.

### 2. 💤 Smart Sleep Detection (Screen Activity Analysis)
* **Phone Usage Analysis (`usage_stats`)**: Evaluates nightly device activity between 10:00 PM and 8:00 AM.
* **2-Minute Glance Filter**: Screen interactions under 2 minutes (checking time or glancing at notifications) are filtered out and treated as rest rather than waking up.
* **Morning Wake-up Marker**: Continuous phone usage in the morning marks the true wake-up time.

### 3. 📸 AI Smart Meal Scanner (Gemini Vision + OpenFoodFacts)
* **Time-Sliced Automatic Focus**: Automatically focuses on the appropriate meal slice based on the current time of day while allowing instant manual tab switching:
  * **05:00 – 11:30**: 🥞 Breakfast
  * **11:30 – 16:00**: 🥗 Lunch
  * **16:00 – 19:00**: ☕ Snack
  * **19:00 – 05:00**: 🍲 Dinner
* **Gemini AI Vision**: Analyzes plate photos, detects individual food items, and estimates portion weights in grams.
* **OpenFoodFacts Integration**: Matches items with open nutritional databases to extract exact Calories, Protein, Carbohydrates, and Fats.

### 4. 🏋️ Weather & Hurdle-Adapted 5 AI Workouts
* **PA Compendium MET Formulas**: Uses Metabolic Equivalent of Task (MET) ratings to calculate exact calories burned:
  $$\text{Calories Burned} = \text{MET} \times \text{Weight (kg)} \times \left(\frac{\text{Duration in minutes}}{60}\right)$$
* **Weather & Location Adaptation**: Automatically fetches local temperature and weather conditions via `geolocator` and **Open-Meteo**.
* **Health Hurdle Personalization**: If a user specifies health hurdles (e.g. *lower back stiffness* or *knee pain*), the AI dynamically selects safe, low-impact routines.
* **ExerciseDB Animated GIFs**: Every exercise includes an animated GIF demonstration and step-by-step instructions.

### 5. 🤖 Direct AI Health Coach Chat
* Dedicated AI chat powered by Gemini LLM.
* Context-aware responses that account for user age, weight, today's steps, weather, and health conditions.
* Quick suggestion chips for common fitness, nutrition, and recovery questions.

### 6. 📊 7-Day Analytics & Health Reports (`fl_chart`)
* **Weekly Steps Bar Chart**: Visualizes daily steps vs. daily step goal.
* **Calorie Balance**: Compares food intake (orange) against calories burned (red).
* **Sleep Duration**: Tracks nightly rest trends across the week.
* **Composite Health Score**: Generates a dynamic 0–100 health score.

---

## 🏗️ Project Structure

```
LiveFit/
├── backend/                        # Node.js + Express REST API (Deployed on Render)
│   ├── .env.example                # Safe environment variable template
│   ├── server.js                   # Server entry point & MongoDB Atlas connection
│   ├── models/
│   │   ├── User.js                 # User profile, calculated age, health hurdles
│   │   ├── DailyLog.js             # Daily steps, sleep, calories consumed & burned
│   │   ├── Meal.js                 # Food items, grams, macro breakdown
│   │   ├── Exercise.js             # Exercise records, MET calories, completion status
│   │   ├── Compendium.js           # PA Compendium exercise catalog with demo GIFs
│   │   └── ChatMessage.js          # User chat history
│   ├── routes/
│   │   ├── authRoutes.js           # /api/auth (register, login, profile, goals)
│   │   ├── dailyStatsRoutes.js     # /api/stats (today stats, steps, sleep)
│   │   ├── mealRoutes.js           # /api/meals (analyze, today meals, time slices)
│   │   ├── exerciseRoutes.js       # /api/exercises (suggested, mark-done, demos)
│   │   ├── chatRoutes.js           # /api/chat (message, history)
│   │   └── reportRoutes.js         # /api/reports (weekly analytics)
│   └── services/
│       ├── geminiService.js        # Gemini Vision analysis & workout generator
│       ├── nutritionService.js     # OpenFoodFacts API query
│       ├── weatherService.js       # Open-Meteo forecast service
│       ├── schedulerService.js     # 23:59 daily midnight reset scheduler
│       └── compendiumData.js       # 20 standard fitness exercises with ExerciseDB GIFs
│
└── frontend/                       # Flutter Cross-Platform Application
    ├── pubspec.yaml                # Dependencies (pedometer, fl_chart, google_fonts, etc.)
    └── lib/
        ├── main.dart               # MultiProvider setup & theme routing
        ├── constants/theme.dart    # White & Orange design system
        ├── services/
        │   ├── api_service.dart    # Cloud API client with automatic token handling
        │   └── sensor_service.dart # Pedometer sensor stream & usage_stats sleep
        ├── providers/
        │   ├── auth_provider.dart  # Authentication & user profile state
        │   └── health_provider.dart# Step sync, meals, workouts, chat state
        ├── screens/
        │   ├── auth/               # Login & Registration screens
        │   ├── dashboard/          # Central dashboard with read-only metric cards
        │   ├── meals/              # Time-sliced AI meal photo scanner
        │   ├── exercises/          # 5 suggested workouts with demo GIF dialogs
        │   ├── chat/               # Dedicated Gemini AI Health Coach chat
        │   ├── reports/            # Weekly 7-day analytics & trend charts
        │   └── profile/            # Profile settings, goals, hurdle editor
        └── widgets/                # Reusable weather cards, dialogs, progress bars
```

---

## 🛠️ Local Development Setup

If you want to run the project locally on your machine:

### 1. Prerequisites:
* Flutter SDK (3.x or higher)
* Node.js (v18 or higher)
* Android Studio / VS Code

### 2. Backend Setup:
```powershell
cd backend
npm install
node server.js
```
*(Copy `backend/.env.example` to `backend/.env` and add your MongoDB URI and Gemini API key).*

### 3. Flutter Frontend Setup:
```powershell
cd frontend
flutter pub get
flutter run
```

---

## 🔒 Security & Privacy Audit
* **Dependency Health**: `npm audit` returned **0 vulnerabilities**.
* **Password Encryption**: Salted `bcrypt` one-way hashing for all user passwords.
* **Secret Protection**: All Gemini API keys and database credentials reside exclusively in cloud environment variables, completely isolated from client APK code.
* **Transport Encryption**: All client-server traffic is encrypted using TLS/HTTPS.

---

## 👨‍💻 Authors & Academic Project
Developed by **Khush Bhalodiya** as part of the B.Tech Semester 5 Software Development Project (SDP).
