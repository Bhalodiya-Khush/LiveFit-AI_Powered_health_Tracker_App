# LiveFit Backend

This is the MongoDB + JWT backend for the LiveFit Flutter app.

## Setup

1. Install dependencies:
   npm install
2. Copy `.env.example` to `.env` and adjust values if needed.
3. Start MongoDB locally on port 27017.
4. Start the API:
   npm run dev

## Endpoints

- GET /api/health
- POST /api/auth/register
- POST /api/auth/login
- POST /api/auth/google

## Default MongoDB URL

mongodb://127.0.0.1:27017/livefit

## Environment variables

- PORT=5000
- MONGO_URI=mongodb://127.0.0.1:27017/livefit
- JWT_SECRET=livefit-secret-key
