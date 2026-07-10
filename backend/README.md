# Quran AI — Backend API

Express + MongoDB (Mongoose) REST API for the Quran AI mobile app.

## Run

```bash
cd backend
npm install
cp .env.example .env     # set MONGODB_URI and JWT_SECRET
npm run seed             # creates the admin user + sample quizzes/lessons
npm run dev              # or: npm start
```

Needs Node 18+ and a MongoDB instance — either local (`mongod`) or a free
[MongoDB Atlas](https://www.mongodb.com/atlas) cluster (paste its connection
string into `MONGODB_URI`).

## Endpoints

All responses are JSON. Protected routes need `Authorization: Bearer <token>`.

| Method | Path | Body | Notes |
|---|---|---|---|
| GET | `/api/health` | — | liveness check |
| POST | `/api/auth/register` | `{name, email, password}` | → `{token, user}` |
| POST | `/api/auth/login` | `{email, password}` | → `{token, user}` |
| GET | `/api/auth/me` | — | current user 🔒 |
| PATCH | `/api/auth/me` | `{name?, language?, theme?, reciter?, translation?}` | update prefs 🔒 |
| GET | `/api/progress` | — | all reading progress 🔒 |
| PUT | `/api/progress/:surah` | `{lastVerse, totalVerses}` | upsert + streak 🔒 |
| GET | `/api/bookmarks` | — | 🔒 |
| POST | `/api/bookmarks` | `{surahNumber, ayahNumber?}` | 🔒 |
| DELETE | `/api/bookmarks/:surah?ayah=N` | — | 🔒 |
| POST | `/api/stats/tasbeeh` | `{dhikr, count, rounds}` | 🔒 |
| POST | `/api/stats/quiz` | `{correct, total, xpEarned}` | updates XP/level 🔒 |
| POST | `/api/stats/recitation` | `{surahNumber, ayahNumber, score, mistakes[]}` | updates avg score 🔒 |
| GET | `/api/stats/recitations/weekly` | — | chart data 🔒 |
| GET | `/api/stats/summary` | — | profile numbers, recomputed from the DB 🔒 |
| GET | `/api/content/quiz/daily?lang=uz` | — | daily quiz (public, rotates daily) |
| GET | `/api/content/lessons?lang=uz` | — | Learning Center courses (public) |
| GET | `/api/admin/overview` | — | dashboard totals 👑 |
| GET/PATCH/DELETE | `/api/admin/users[...]` | — | user management 👑 |
| GET/POST/PUT/DELETE | `/api/admin/quizzes[...]` | bilingual question | quiz CRUD 👑 |
| GET/POST/PUT/DELETE | `/api/admin/lessons[...]` | bilingual course | lesson CRUD 👑 |

👑 = admin role required (seed creates `admin@quranai.uz` / `admin12345` —
change it in `.env` before deploying).

## Admin panel

A full control panel ships with the backend — open
**http://localhost:5000/admin** and sign in with the admin account.
It manages users (edit, promote, reset password, delete), daily-quiz
questions and Learning Center courses in both English and Uzbek, and shows
live usage stats straight from MongoDB.

## Connecting from the Flutter app

The app's base URL lives in `lib/core/network/api_config.dart`:

- **Android emulator:** `http://10.0.2.2:5000/api`
- **iOS simulator:** `http://localhost:5000/api`
- **Real device:** `http://<your-computer-LAN-IP>:5000/api` (same Wi-Fi)
