import { Router } from 'express';

import { requireAuth } from '../middleware/auth.js';
import { httpError } from '../middleware/error.js';
import {
  CourseLesson,
  DailyActivity,
  LessonCompletion,
} from '../models/Content.js';
import {
  AyahMemorization,
  Progress,
  SurahCompletion,
} from '../models/Progress.js';

const router = Router();
router.use(requireAuth);

// GET /api/progress/completed — surah numbers the user has finished
router.get('/completed', async (req, res, next) => {
  try {
    const items = await SurahCompletion.find({ user: req.user._id }).select(
      'surahNumber',
    );
    res.json({ items: items.map((c) => c.surahNumber) });
  } catch (err) {
    next(err);
  }
});

// PUT /api/progress/:surah/completed { completed: true|false }
router.put('/:surah/completed', async (req, res, next) => {
  try {
    const surahNumber = Number(req.params.surah);
    if (!surahNumber || surahNumber < 1 || surahNumber > 114) {
      throw httpError(400, 'Bad surah number');
    }
    const completed = req.body?.completed !== false;

    if (completed) {
      await SurahCompletion.updateOne(
        { user: req.user._id, surahNumber },
        {},
        { upsert: true },
      ).catch(() => {}); // duplicate-key race is fine
      await DailyActivity.touch(req.user._id);
    } else {
      await SurahCompletion.deleteOne({ user: req.user._id, surahNumber });
    }

    const total = await SurahCompletion.countDocuments({
      user: req.user._id,
    });
    req.user.completedSurahs = total;
    await req.user.save();
    res.json({ completed, completedSurahs: total });
  } catch (err) {
    next(err);
  }
});

// GET /api/progress — all reading progress for the user
router.get('/', async (req, res, next) => {
  try {
    const items = await Progress.find({ user: req.user._id }).sort({
      updatedAt: -1,
    });
    res.json({ items: items.map((p) => p.toClient()) });
  } catch (err) {
    next(err);
  }
});

// GET /api/progress/lessons — completed lesson ids + per-course counts
router.get('/lessons', async (req, res, next) => {
  try {
    const items = await LessonCompletion.find({ user: req.user._id }).select(
      'courseLesson course',
    );
    const byCourse = {};
    for (const c of items) {
      const key = c.course.toString();
      byCourse[key] = (byCourse[key] ?? 0) + 1;
    }
    res.json({
      items: items.map((c) => c.courseLesson.toString()),
      byCourse,
    });
  } catch (err) {
    next(err);
  }
});

// PUT /api/progress/lessons/:itemId { completed: true|false }
router.put('/lessons/:itemId', async (req, res, next) => {
  try {
    const lesson = await CourseLesson.findById(req.params.itemId);
    if (!lesson) throw httpError(404, 'Dars topilmadi');
    const completed = req.body?.completed !== false;

    if (completed) {
      await LessonCompletion.updateOne(
        { user: req.user._id, courseLesson: lesson._id },
        { course: lesson.course },
        { upsert: true },
      ).catch(() => {});
      await DailyActivity.touch(req.user._id);
    } else {
      await LessonCompletion.deleteOne({
        user: req.user._id,
        courseLesson: lesson._id,
      });
    }

    const inCourse = await LessonCompletion.countDocuments({
      user: req.user._id,
      course: lesson.course,
    });
    res.json({ completed, completedInCourse: inCourse });
  } catch (err) {
    next(err);
  }
});

// GET /api/progress/:surah/memorized — memorized ayah numbers in a surah
router.get('/:surah/memorized', async (req, res, next) => {
  try {
    const items = await AyahMemorization.find({
      user: req.user._id,
      surahNumber: Number(req.params.surah),
    }).select('ayahNumber');
    res.json({ items: items.map((m) => m.ayahNumber) });
  } catch (err) {
    next(err);
  }
});

// PUT /api/progress/:surah/memorized/:ayah { memorized: true|false }
router.put('/:surah/memorized/:ayah', async (req, res, next) => {
  try {
    const surahNumber = Number(req.params.surah);
    const ayahNumber = Number(req.params.ayah);
    if (!surahNumber || !ayahNumber) throw httpError(400, 'Bad numbers');
    const memorized = req.body?.memorized !== false;

    if (memorized) {
      await AyahMemorization.updateOne(
        { user: req.user._id, surahNumber, ayahNumber },
        {},
        { upsert: true },
      ).catch(() => {});
      await DailyActivity.touch(req.user._id);
    } else {
      await AyahMemorization.deleteOne({
        user: req.user._id,
        surahNumber,
        ayahNumber,
      });
    }

    const count = await AyahMemorization.countDocuments({
      user: req.user._id,
      surahNumber,
    });
    res.json({ memorized, memorizedInSurah: count });
  } catch (err) {
    next(err);
  }
});

// PUT /api/progress/:surah — upsert "where I left off"
router.put('/:surah', async (req, res, next) => {
  try {
    const surahNumber = Number(req.params.surah);
    const { lastVerse, totalVerses } = req.body || {};
    if (!surahNumber || !lastVerse || !totalVerses) {
      throw httpError(400, 'surah, lastVerse and totalVerses are required');
    }
    const item = await Progress.findOneAndUpdate(
      { user: req.user._id, surahNumber },
      { lastVerse, totalVerses },
      { new: true, upsert: true, setDefaultsOnInsert: true },
    );

    // Reading today counts toward the streak — recomputed from DailyActivity.
    await DailyActivity.touch(req.user._id);
    req.user.streak = await DailyActivity.streakFor(req.user._id);
    req.user.lastReadAt = new Date();
    await req.user.save();

    res.json({ item: item.toClient(), streak: req.user.streak });
  } catch (err) {
    next(err);
  }
});

export default router;
