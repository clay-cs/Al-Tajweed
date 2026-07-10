import { randomUUID } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { Router } from 'express';
import multer from 'multer';

import { requireAdmin, requireAuth } from '../middleware/auth.js';
import { httpError } from '../middleware/error.js';
import {
  QuizResult,
  Recitation,
  TasbeehSession,
} from '../models/Activity.js';
import { Bookmark } from '../models/Bookmark.js';
import {
  CourseLesson,
  DailyActivity,
  Dua,
  Hadith,
  HadithRead,
  Lesson,
  LessonCompletion,
  QuizQuestion,
} from '../models/Content.js';
import {
  AyahMemorization,
  Progress,
  SurahCompletion,
} from '../models/Progress.js';
import { Ayah, Surah } from '../models/Quran.js';
import { User } from '../models/User.js';

const router = Router();
router.use(requireAuth, requireAdmin);

// ── Image upload (lesson illustrations) ───────────────────────────────

const dirname = path.dirname(fileURLToPath(import.meta.url));
export const imagesDir = path.join(dirname, '../../uploads/images');
fs.mkdirSync(imagesDir, { recursive: true });

const uploadImage = multer({
  storage: multer.diskStorage({
    destination: imagesDir,
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
      cb(null, `${randomUUID()}${ext}`);
    },
  }),
  limits: { fileSize: 8 * 1024 * 1024 }, // 8 MB
  fileFilter: (_req, file, cb) => {
    const ok =
      file.mimetype.startsWith('image/') ||
      /\.(png|jpe?g|gif|webp|svg)$/i.test(file.originalname);
    cb(ok ? null : httpError(400, 'Faqat rasm yuklash mumkin'), ok);
  },
});

// POST /api/admin/upload/image — multipart field "file" → { url }
router.post('/upload/image', uploadImage.single('file'), (req, res) => {
  if (!req.file) throw httpError(400, 'Rasm topilmadi');
  res.status(201).json({ url: `/uploads/images/${req.file.filename}` });
});

// ── Dashboard ─────────────────────────────────────────────────────────

// GET /api/admin/overview — headline numbers + recent signups + activity
router.get('/overview', async (_req, res, next) => {
  try {
    const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const [
      users,
      newUsersWeek,
      quizzes,
      lessons,
      recitations,
      quizAttempts,
      tasbeehSessions,
      avgScoreAgg,
      recentUsers,
      activeByDay,
    ] = await Promise.all([
      User.countDocuments(),
      User.countDocuments({ createdAt: { $gte: weekAgo } }),
      QuizQuestion.countDocuments(),
      Lesson.countDocuments(),
      Recitation.countDocuments(),
      QuizResult.countDocuments(),
      TasbeehSession.countDocuments(),
      Recitation.aggregate([
        { $group: { _id: null, avg: { $avg: '$score' } } },
      ]),
      User.find().sort({ createdAt: -1 }).limit(8),
      DailyActivity.aggregate([
        { $match: { createdAt: { $gte: weekAgo } } },
        { $group: { _id: '$day', users: { $addToSet: '$user' } } },
        { $project: { day: '$_id', count: { $size: '$users' }, _id: 0 } },
        { $sort: { day: 1 } },
      ]),
    ]);

    res.json({
      totals: {
        users,
        newUsersWeek,
        quizzes,
        lessons,
        recitations,
        quizAttempts,
        tasbeehSessions,
        avgTajweedScore: Math.round(avgScoreAgg[0]?.avg ?? 0),
      },
      recentUsers: recentUsers.map((u) => u.toClient()),
      activeByDay,
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/admin/stats — everything the dashboard charts need
router.get('/stats', async (_req, res, next) => {
  try {
    const DAYS = 30;
    const since = new Date(Date.now() - DAYS * 24 * 60 * 60 * 1000);
    since.setUTCHours(0, 0, 0, 0);
    const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    // createdAt → per-day counts for any collection.
    const byDay = (Model, filter = {}) =>
      Model.aggregate([
        { $match: { createdAt: { $gte: since }, ...filter } },
        {
          $group: {
            _id: {
              $dateToString: { format: '%Y-%m-%d', date: '$createdAt' },
            },
            count: { $sum: 1 },
          },
        },
        { $project: { day: '$_id', count: 1, _id: 0 } },
        { $sort: { day: 1 } },
      ]);

    const [
      users,
      activeUsers7d,
      hadiths,
      hadithReads,
      duas,
      surahs,
      ayahs,
      quizzes,
      courses,
      courseLessons,
      memorizedAyahs,
      completedSurahs,
      lessonsCompleted,
      quizAttempts,
      recitations,
      registrationsByDay,
      activeByDay,
      hadithReadsByDay,
      lessonsByDay,
      memorizedByDay,
      topMemorizedSurahs,
      recentUsers,
    ] = await Promise.all([
      User.countDocuments(),
      DailyActivity.distinct('user', { createdAt: { $gte: weekAgo } }).then(
        (ids) => ids.length,
      ),
      Hadith.countDocuments(),
      HadithRead.countDocuments(),
      Dua.countDocuments(),
      Surah.countDocuments(),
      Ayah.countDocuments(),
      QuizQuestion.countDocuments(),
      Lesson.countDocuments(),
      CourseLesson.countDocuments(),
      AyahMemorization.countDocuments(),
      SurahCompletion.countDocuments(),
      LessonCompletion.countDocuments(),
      QuizResult.countDocuments(),
      Recitation.countDocuments(),
      byDay(User),
      DailyActivity.aggregate([
        { $match: { createdAt: { $gte: since } } },
        { $group: { _id: '$day', users: { $addToSet: '$user' } } },
        { $project: { day: '$_id', count: { $size: '$users' }, _id: 0 } },
        { $sort: { day: 1 } },
      ]),
      byDay(HadithRead),
      byDay(LessonCompletion),
      byDay(AyahMemorization),
      AyahMemorization.aggregate([
        { $group: { _id: '$surahNumber', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 6 },
        { $project: { surahNumber: '$_id', count: 1, _id: 0 } },
      ]),
      User.find().sort({ createdAt: -1 }).limit(6),
    ]);

    // Surah names for the top-memorized bar chart.
    const surahDocs = await Surah.find({
      number: { $in: topMemorizedSurahs.map((s) => s.surahNumber) },
    });
    const nameBy = Object.fromEntries(
      surahDocs.map((s) => [s.number, s.name?.uz || s.name?.en || `${s.number}`]),
    );

    res.json({
      days: DAYS,
      totals: {
        users,
        activeUsers7d,
        hadiths,
        hadithReads,
        duas,
        surahs,
        ayahs,
        quizzes,
        courses,
        courseLessons,
        memorizedAyahs,
        completedSurahs,
        lessonsCompleted,
        quizAttempts,
        recitations,
      },
      registrationsByDay,
      activeByDay,
      hadithReadsByDay,
      lessonsByDay,
      memorizedByDay,
      topMemorizedSurahs: topMemorizedSurahs.map((s) => ({
        ...s,
        name: nameBy[s.surahNumber] ?? `Sura ${s.surahNumber}`,
      })),
      recentUsers: recentUsers.map((u) => ({
        ...u.toClient(),
        createdAt: u.createdAt,
      })),
    });
  } catch (err) {
    next(err);
  }
});

// ── Users ─────────────────────────────────────────────────────────────

// GET /api/admin/users?q=&page=1
router.get('/users', async (req, res, next) => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = 20;
    const q = (req.query.q || '').trim();
    const filter = q
      ? {
          $or: [
            { name: { $regex: q, $options: 'i' } },
            { email: { $regex: q, $options: 'i' } },
          ],
        }
      : {};
    const [items, total] = await Promise.all([
      User.find(filter)
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit),
      User.countDocuments(filter),
    ]);
    res.json({
      items: items.map((u) => ({
        ...u.toClient(),
        createdAt: u.createdAt,
        lastReadAt: u.lastReadAt,
      })),
      total,
      page,
      pages: Math.ceil(total / limit),
    });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/admin/users/:id — edit name/role, reset password
router.patch('/users/:id', async (req, res, next) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) throw httpError(404, 'User not found');

    const { name, role, password } = req.body || {};
    if (name !== undefined) user.name = name;
    if (role !== undefined) {
      if (!['user', 'admin'].includes(role)) throw httpError(400, 'Bad role');
      if (
        user._id.equals(req.user._id) &&
        role !== 'admin'
      ) {
        throw httpError(400, 'You cannot remove your own admin role');
      }
      user.role = role;
    }
    if (password) {
      if (password.length < 8) throw httpError(400, 'Password too short');
      user.passwordHash = await User.hashPassword(password);
    }
    await user.save();
    res.json({ user: user.toClient() });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/admin/users/:id — removes the user and all their data
router.delete('/users/:id', async (req, res, next) => {
  try {
    if (req.user._id.equals(req.params.id)) {
      throw httpError(400, 'You cannot delete your own account');
    }
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) throw httpError(404, 'User not found');
    await Promise.all([
      Progress.deleteMany({ user: user._id }),
      SurahCompletion.deleteMany({ user: user._id }),
      AyahMemorization.deleteMany({ user: user._id }),
      LessonCompletion.deleteMany({ user: user._id }),
      Bookmark.deleteMany({ user: user._id }),
      Recitation.deleteMany({ user: user._id }),
      QuizResult.deleteMany({ user: user._id }),
      TasbeehSession.deleteMany({ user: user._id }),
      DailyActivity.deleteMany({ user: user._id }),
      HadithRead.deleteMany({ user: user._id }),
    ]);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ── Quiz questions ────────────────────────────────────────────────────

router.get('/quizzes', async (_req, res, next) => {
  try {
    const items = await QuizQuestion.find().sort({ createdAt: -1 });
    res.json({ items });
  } catch (err) {
    next(err);
  }
});

function validateQuiz(body) {
  const { question, options, answer } = body || {};
  if (!question?.en || !question?.uz) {
    throw httpError(400, 'question.en and question.uz are required');
  }
  if (!Array.isArray(options) || options.length < 2) {
    throw httpError(400, 'At least 2 options are required');
  }
  for (const o of options) {
    if (!o.en || !o.uz) throw httpError(400, 'Every option needs en and uz');
  }
  if (answer == null || answer < 0 || answer >= options.length) {
    throw httpError(400, 'answer must index one of the options');
  }
}

router.post('/quizzes', async (req, res, next) => {
  try {
    validateQuiz(req.body);
    const { question, options, answer, category, active } = req.body;
    const item = await QuizQuestion.create({
      question,
      options,
      answer,
      category: category || 'general',
      active: active ?? true,
    });
    res.status(201).json({ item });
  } catch (err) {
    next(err);
  }
});

router.put('/quizzes/:id', async (req, res, next) => {
  try {
    validateQuiz(req.body);
    const { question, options, answer, category, active } = req.body;
    const item = await QuizQuestion.findByIdAndUpdate(
      req.params.id,
      { question, options, answer, category, active },
      { new: true },
    );
    if (!item) throw httpError(404, 'Question not found');
    res.json({ item });
  } catch (err) {
    next(err);
  }
});

router.delete('/quizzes/:id', async (req, res, next) => {
  try {
    const item = await QuizQuestion.findByIdAndDelete(req.params.id);
    if (!item) throw httpError(404, 'Question not found');
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ── Lessons (Learning Center courses) ─────────────────────────────────

router.get('/lessons', async (_req, res, next) => {
  try {
    const items = await Lesson.find().sort({ order: 1 });
    res.json({ items });
  } catch (err) {
    next(err);
  }
});

function validateLesson(body) {
  const { title, subtitle, totalLessons } = body || {};
  if (!title?.en || !title?.uz) {
    throw httpError(400, 'title.en and title.uz are required');
  }
  if (!subtitle?.en || !subtitle?.uz) {
    throw httpError(400, 'subtitle.en and subtitle.uz are required');
  }
  if (!totalLessons || totalLessons < 1) {
    throw httpError(400, 'totalLessons must be at least 1');
  }
}

router.post('/lessons', async (req, res, next) => {
  try {
    validateLesson(req.body);
    const { title, subtitle, totalLessons, icon, color, order, active } =
      req.body;
    const item = await Lesson.create({
      title,
      subtitle,
      totalLessons,
      icon: icon || 'school',
      color: color || '#0E9D7B',
      order: order ?? 0,
      active: active ?? true,
    });
    res.status(201).json({ item });
  } catch (err) {
    next(err);
  }
});

router.put('/lessons/:id', async (req, res, next) => {
  try {
    validateLesson(req.body);
    const { title, subtitle, totalLessons, icon, color, order, active } =
      req.body;
    const item = await Lesson.findByIdAndUpdate(
      req.params.id,
      { title, subtitle, totalLessons, icon, color, order, active },
      { new: true },
    );
    if (!item) throw httpError(404, 'Lesson not found');
    res.json({ item });
  } catch (err) {
    next(err);
  }
});

// Deleting a course removes its lessons and everyone's progress in it.
router.delete('/lessons/:id', async (req, res, next) => {
  try {
    const item = await Lesson.findByIdAndDelete(req.params.id);
    if (!item) throw httpError(404, 'Lesson not found');
    await Promise.all([
      CourseLesson.deleteMany({ course: item._id }),
      LessonCompletion.deleteMany({ course: item._id }),
    ]);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ── Duas ──────────────────────────────────────────────────────────────

router.get('/duas', async (_req, res, next) => {
  try {
    const items = await Dua.find().sort({ order: 1, createdAt: 1 });
    res.json({ items });
  } catch (err) {
    next(err);
  }
});

function validateDua(body) {
  const { title, arabic, translation } = body || {};
  if (!title?.en || !title?.uz) {
    throw httpError(400, 'title.en va title.uz majburiy');
  }
  if (!arabic) throw httpError(400, 'Arabcha matn majburiy');
  if (!translation?.en || !translation?.uz) {
    throw httpError(400, 'Tarjima (EN va UZ) majburiy');
  }
}

router.post('/duas', async (req, res, next) => {
  try {
    validateDua(req.body);
    const {
      title, category, arabic,
      transliteration = '', translation, order = 0, active = true,
    } = req.body;
    const item = await Dua.create({
      title, category, arabic, transliteration, translation, order, active,
    });
    res.status(201).json({ item });
  } catch (err) {
    next(err);
  }
});

router.put('/duas/:id', async (req, res, next) => {
  try {
    validateDua(req.body);
    const {
      title, category, arabic,
      transliteration = '', translation, order = 0, active = true,
    } = req.body;
    const item = await Dua.findByIdAndUpdate(
      req.params.id,
      { title, category, arabic, transliteration, translation, order, active },
      { new: true },
    );
    if (!item) throw httpError(404, 'Duo topilmadi');
    res.json({ item });
  } catch (err) {
    next(err);
  }
});

router.delete('/duas/:id', async (req, res, next) => {
  try {
    const item = await Dua.findByIdAndDelete(req.params.id);
    if (!item) throw httpError(404, 'Duo topilmadi');
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ── Hadiths ───────────────────────────────────────────────────────────

router.get('/hadiths', async (_req, res, next) => {
  try {
    const items = await Hadith.find().sort({ order: 1, createdAt: 1 });
    res.json({ items });
  } catch (err) {
    next(err);
  }
});

function validateHadith(body) {
  const { book, hadithNumber, arabic, translation } = body || {};
  if (!book) throw httpError(400, 'Kitob (to‘plam) majburiy');
  if (hadithNumber == null || Number(hadithNumber) < 1) {
    throw httpError(400, 'Hadis raqami majburiy');
  }
  if (!arabic) throw httpError(400, 'Arabcha matn majburiy');
  if (!translation?.en || !translation?.uz) {
    throw httpError(400, 'Tarjima (EN va UZ) majburiy');
  }
}

// Normalizes the request body into the schema shape.
function hadithFields(body) {
  const {
    book, bookNumber = 1, chapter = '', hadithNumber,
    narrator = '', arabic, translation, grade = 'Sahih',
    tags = [], order = 0, active = true,
  } = body;
  return {
    book,
    bookNumber: Number(bookNumber) || 1,
    chapter,
    hadithNumber: Number(hadithNumber),
    narrator,
    arabic,
    translation,
    grade,
    tags: Array.isArray(tags)
      ? tags.map((t) => String(t).trim()).filter(Boolean)
      : [],
    order,
    active,
  };
}

router.post('/hadiths', async (req, res, next) => {
  try {
    validateHadith(req.body);
    const item = await Hadith.create(hadithFields(req.body));
    res.status(201).json({ item });
  } catch (err) {
    next(err);
  }
});

router.put('/hadiths/:id', async (req, res, next) => {
  try {
    validateHadith(req.body);
    const item = await Hadith.findByIdAndUpdate(
      req.params.id,
      hadithFields(req.body),
      { new: true },
    );
    if (!item) throw httpError(404, 'Hadis topilmadi');
    res.json({ item });
  } catch (err) {
    next(err);
  }
});

router.delete('/hadiths/:id', async (req, res, next) => {
  try {
    const item = await Hadith.findByIdAndDelete(req.params.id);
    if (!item) throw httpError(404, 'Hadis topilmadi');
    await HadithRead.deleteMany({ hadith: item._id });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ── Course content (lessons inside a course) ──────────────────────────

// GET /api/admin/lessons/:id/items
router.get('/lessons/:id/items', async (req, res, next) => {
  try {
    const items = await CourseLesson.find({ course: req.params.id }).sort({
      order: 1,
      createdAt: 1,
    });
    res.json({ items });
  } catch (err) {
    next(err);
  }
});

function validateLessonItem(body) {
  const { title, body: text } = body || {};
  if (!title?.en || !title?.uz) {
    throw httpError(400, 'title.en va title.uz majburiy');
  }
  if (!text?.en || !text?.uz) {
    throw httpError(400, 'body.en va body.uz majburiy');
  }
}

// POST /api/admin/lessons/:id/items
router.post('/lessons/:id/items', async (req, res, next) => {
  try {
    const course = await Lesson.findById(req.params.id);
    if (!course) throw httpError(404, 'Kurs topilmadi');
    validateLessonItem(req.body);
    const { title, body, arabic = '', imageUrl = null, order = 0 } = req.body;
    const item = await CourseLesson.create({
      course: course._id,
      title,
      body,
      arabic,
      imageUrl,
      order,
    });
    res.status(201).json({ item });
  } catch (err) {
    next(err);
  }
});

// PUT /api/admin/lesson-items/:id
router.put('/lesson-items/:id', async (req, res, next) => {
  try {
    validateLessonItem(req.body);
    const { title, body, arabic = '', imageUrl = null, order = 0 } = req.body;
    const item = await CourseLesson.findByIdAndUpdate(
      req.params.id,
      { title, body, arabic, imageUrl, order },
      { new: true },
    );
    if (!item) throw httpError(404, 'Dars topilmadi');
    res.json({ item });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/admin/lesson-items/:id
router.delete('/lesson-items/:id', async (req, res, next) => {
  try {
    const item = await CourseLesson.findByIdAndDelete(req.params.id);
    if (!item) throw httpError(404, 'Dars topilmadi');
    await LessonCompletion.deleteMany({ courseLesson: item._id });
    // Best-effort: remove the uploaded illustration with it.
    if (item.imageUrl?.startsWith('/uploads/images/')) {
      fs.promises
        .unlink(path.join(imagesDir, path.basename(item.imageUrl)))
        .catch(() => {});
    }
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

export default router;
