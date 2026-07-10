import { Router } from 'express';

import { requireAuth } from '../middleware/auth.js';
import { httpError } from '../middleware/error.js';
import {
  QuizResult,
  Recitation,
  TasbeehSession,
} from '../models/Activity.js';
import { DailyActivity, LessonCompletion } from '../models/Content.js';
import { Progress, SurahCompletion } from '../models/Progress.js';

const router = Router();
router.use(requireAuth);

// The Madani mushaf: 6236 verses over 604 pages ≈ 10.3 verses per page.
const VERSES_PER_PAGE = 6236 / 604;

/**
 * Recomputes every profile stat from raw collections — nothing is trusted
 * from counters on the User document.
 */
export async function computeStats(userId) {
  const [versesAgg, recitAgg, streak, xpAgg, completedSurahs, lessonsDone] =
    await Promise.all([
      Progress.aggregate([
        { $match: { user: userId } },
        { $group: { _id: null, verses: { $sum: '$lastVerse' } } },
      ]),
      Recitation.aggregate([
        { $match: { user: userId } },
        { $group: { _id: null, count: { $sum: 1 }, avg: { $avg: '$score' } } },
      ]),
      DailyActivity.streakFor(userId),
      QuizResult.aggregate([
        { $match: { user: userId } },
        { $group: { _id: null, xp: { $sum: '$xpEarned' } } },
      ]),
      SurahCompletion.countDocuments({ user: userId }),
      LessonCompletion.countDocuments({ user: userId }),
    ]);

  // XP = quiz results + 10 XP per finished lesson, always from raw data.
  const xp = (xpAgg[0]?.xp ?? 0) + lessonsDone * 10;
  return {
    pagesRead: Math.round((versesAgg[0]?.verses ?? 0) / VERSES_PER_PAGE),
    recitationCount: recitAgg[0]?.count ?? 0,
    avgTajweedScore: Math.round(recitAgg[0]?.avg ?? 0),
    completedSurahs,
    streak,
    xp,
    level: 1 + Math.floor(xp / 200),
  };
}

/** Syncs the computed stats back onto the User doc (kept for quick reads). */
async function syncUserStats(user) {
  const stats = await computeStats(user._id);
  Object.assign(user, stats);
  await user.save();
  return stats;
}

// POST /api/stats/tasbeeh { dhikr, count, rounds }
router.post('/tasbeeh', async (req, res, next) => {
  try {
    const { dhikr, count, rounds = 0 } = req.body || {};
    if (!dhikr || count == null) throw httpError(400, 'dhikr and count are required');
    await TasbeehSession.create({ user: req.user._id, dhikr, count, rounds });
    await DailyActivity.touch(req.user._id);
    res.status(201).json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// POST /api/stats/quiz { correct, total, xpEarned }
router.post('/quiz', async (req, res, next) => {
  try {
    const { correct, total, xpEarned } = req.body || {};
    if (correct == null || total == null) {
      throw httpError(400, 'correct and total are required');
    }
    await QuizResult.create({
      user: req.user._id,
      correct,
      total,
      xpEarned: xpEarned ?? correct * 20,
    });
    await DailyActivity.touch(req.user._id);
    const stats = await syncUserStats(req.user);
    res.status(201).json({ xp: stats.xp, level: stats.level });
  } catch (err) {
    next(err);
  }
});

// POST /api/stats/recitation { surahNumber, ayahNumber, score, mistakes[] }
router.post('/recitation', async (req, res, next) => {
  try {
    const { surahNumber, ayahNumber, score, mistakes = [] } = req.body || {};
    if (!surahNumber || !ayahNumber || score == null) {
      throw httpError(400, 'surahNumber, ayahNumber and score are required');
    }
    await Recitation.create({
      user: req.user._id,
      surahNumber,
      ayahNumber,
      score,
      mistakes,
    });
    await DailyActivity.touch(req.user._id);
    const stats = await syncUserStats(req.user);
    res.status(201).json({ avgTajweedScore: stats.avgTajweedScore });
  } catch (err) {
    next(err);
  }
});

// GET /api/stats/recitations/weekly — last 7 days of scores for the chart
router.get('/recitations/weekly', async (req, res, next) => {
  try {
    const from = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const rows = await Recitation.aggregate([
      { $match: { user: req.user._id, createdAt: { $gte: from } } },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
          avgScore: { $avg: '$score' },
        },
      },
      { $sort: { _id: 1 } },
    ]);
    res.json({
      items: rows.map((r) => ({ date: r._id, score: Math.round(r.avgScore) })),
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/stats/summary — every profile number, recomputed from the DB
router.get('/summary', async (req, res, next) => {
  try {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);
    const [, tasbeehToday] = await Promise.all([
      syncUserStats(req.user),
      TasbeehSession.aggregate([
        { $match: { user: req.user._id, createdAt: { $gte: startOfDay } } },
        { $group: { _id: null, total: { $sum: '$count' } } },
      ]).then((r) => r[0]?.total ?? 0),
    ]);
    res.json({ user: req.user.toClient(), tasbeehToday });
  } catch (err) {
    next(err);
  }
});

export default router;
