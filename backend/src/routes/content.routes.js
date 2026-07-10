import { Router } from 'express';

import { requireAuth } from '../middleware/auth.js';
import {
  CourseLesson,
  DailyActivity,
  Dua,
  Hadith,
  HadithRead,
  Lesson,
  QuizQuestion,
} from '../models/Content.js';
import { Ayah, Surah } from '../models/Quran.js';

const router = Router();

// No auth — guests can take the daily quiz and browse courses too.

// GET /api/content/quiz/daily?lang=uz&count=5
// Deterministic per-day selection so everyone sees the same daily quiz.
router.get('/quiz/daily', async (req, res, next) => {
  try {
    const lang = req.query.lang === 'uz' ? 'uz' : 'en';
    const count = Math.min(Number(req.query.count) || 5, 20);

    const all = await QuizQuestion.find({ active: true }).sort({ _id: 1 });
    if (!all.length) return res.json({ items: [] });

    // Seed = days since epoch → rotates the window daily.
    const daySeed = Math.floor(Date.now() / (24 * 60 * 60 * 1000));
    const items = Array.from(
      { length: Math.min(count, all.length) },
      (_, i) => all[(daySeed * 7 + i * 13) % all.length],
    );
    // De-dup in case the stride wraps onto the same question.
    const unique = [...new Map(items.map((q) => [q.id, q])).values()];
    res.json({ items: unique.map((q) => q.toClient(lang)) });
  } catch (err) {
    next(err);
  }
});

// GET /api/content/lessons?lang=uz — courses with their REAL lesson counts
router.get('/lessons', async (req, res, next) => {
  try {
    const lang = req.query.lang === 'uz' ? 'uz' : 'en';
    const [items, counts] = await Promise.all([
      Lesson.find({ active: true }).sort({ order: 1 }),
      CourseLesson.aggregate([
        { $group: { _id: '$course', count: { $sum: 1 } } },
      ]),
    ]);
    const countBy = Object.fromEntries(
      counts.map((c) => [c._id.toString(), c.count]),
    );
    res.json({
      items: items.map((l) => ({
        ...l.toClient(lang),
        // Real content count wins over the declared number.
        totalLessons: countBy[l._id.toString()] ?? l.totalLessons,
      })),
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/content/lessons/:id/items?lang=uz — one course's lessons
router.get('/lessons/:id/items', async (req, res, next) => {
  try {
    const lang = req.query.lang === 'uz' ? 'uz' : 'en';
    const items = await CourseLesson.find({ course: req.params.id }).sort({
      order: 1,
      createdAt: 1,
    });
    res.json({ items: items.map((i) => i.toClient(lang)) });
  } catch (err) {
    next(err);
  }
});

// GET /api/content/duas?lang=uz — all active duas, grouped client-side
router.get('/duas', async (req, res, next) => {
  try {
    const lang = req.query.lang === 'uz' ? 'uz' : 'en';
    const items = await Dua.find({ active: true }).sort({ order: 1, createdAt: 1 });
    res.json({ items: items.map((d) => d.toClient(lang)) });
  } catch (err) {
    next(err);
  }
});

// GET /api/content/hadiths?lang=uz — all active hadiths
router.get('/hadiths', async (req, res, next) => {
  try {
    const lang = req.query.lang === 'uz' ? 'uz' : 'en';
    const items = await Hadith.find({ active: true }).sort({
      order: 1,
      createdAt: 1,
    });
    res.json({ items: items.map((h) => h.toClient(lang)) });
  } catch (err) {
    next(err);
  }
});

// GET /api/content/hadith-of-day?lang=uz — deterministic daily hadith
router.get('/hadith-of-day', async (req, res, next) => {
  try {
    const lang = req.query.lang === 'uz' ? 'uz' : 'en';
    const total = await Hadith.countDocuments({ active: true });
    if (!total) return res.json({ item: null });

    // Same hadith for everyone all day; rotates at midnight UTC.
    const daySeed = Math.floor(Date.now() / (24 * 60 * 60 * 1000));
    const hadith = await Hadith.findOne({ active: true })
      .sort({ order: 1, createdAt: 1 })
      .skip((daySeed * 31) % total);
    res.json({ item: hadith.toClient(lang) });
  } catch (err) {
    next(err);
  }
});

// POST /api/content/hadiths/:id/read — the signed-in user read this hadith.
// Idempotent: one (user, hadith) pair counts once. Feeds dashboard stats.
router.post('/hadiths/:id/read', requireAuth, async (req, res, next) => {
  try {
    await HadithRead.updateOne(
      { user: req.user._id, hadith: req.params.id },
      {},
      { upsert: true },
    ).catch(() => {}); // duplicate-key races are fine
    DailyActivity.touch(req.user._id);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// GET /api/content/verse-of-day?lang=uz — deterministic daily ayah
router.get('/verse-of-day', async (req, res, next) => {
  try {
    const lang = req.query.lang === 'uz' ? 'uz' : 'en';
    const total = await Ayah.countDocuments();
    if (!total) return res.json({ item: null });

    // Same verse for everyone all day; rotates at midnight UTC.
    const daySeed = Math.floor(Date.now() / (24 * 60 * 60 * 1000));
    const ayah = await Ayah.findOne()
      .sort({ surahNumber: 1, number: 1 })
      .skip((daySeed * 137) % total);
    const surah = await Surah.findOne({ number: ayah.surahNumber });
    res.json({
      item: {
        ...ayah.toClient(lang),
        surahNumber: ayah.surahNumber,
        surahName: surah?.toClient(lang, 0).name ?? `${ayah.surahNumber}`,
      },
    });
  } catch (err) {
    next(err);
  }
});

export default router;
