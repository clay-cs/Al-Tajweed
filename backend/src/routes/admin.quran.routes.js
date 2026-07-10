import { randomUUID } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { Router } from 'express';
import multer from 'multer';

import { requireAdmin, requireAuth } from '../middleware/auth.js';
import { httpError } from '../middleware/error.js';
import { Ayah, Surah } from '../models/Quran.js';

const router = Router();
router.use(requireAuth, requireAdmin);

// ── Audio upload ──────────────────────────────────────────────────────

const dirname = path.dirname(fileURLToPath(import.meta.url));
export const uploadsDir = path.join(dirname, '../../uploads/audio');
fs.mkdirSync(uploadsDir, { recursive: true });

const upload = multer({
  storage: multer.diskStorage({
    destination: uploadsDir,
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname).toLowerCase() || '.mp3';
      cb(null, `${randomUUID()}${ext}`);
    },
  }),
  limits: { fileSize: 20 * 1024 * 1024 }, // 20 MB per ayah
  fileFilter: (_req, file, cb) => {
    const ok =
      file.mimetype.startsWith('audio/') ||
      /\.(mp3|m4a|aac|ogg|wav)$/i.test(file.originalname);
    cb(ok ? null : httpError(400, 'Faqat audio fayl yuklash mumkin'), ok);
  },
});

// POST /api/admin/quran/audio — multipart field "file" → { url }
router.post('/audio', upload.single('file'), (req, res) => {
  if (!req.file) throw httpError(400, 'Audio fayl topilmadi');
  res.status(201).json({ url: `/uploads/audio/${req.file.filename}` });
});

// ── Surahs ────────────────────────────────────────────────────────────

// GET /api/admin/quran/surahs — full documents + ayah counts
router.get('/surahs', async (_req, res, next) => {
  try {
    const [items, counts] = await Promise.all([
      Surah.find().sort({ number: 1 }),
      Ayah.aggregate([
        { $group: { _id: '$surahNumber', count: { $sum: 1 } } },
      ]),
    ]);
    const countBy = Object.fromEntries(counts.map((c) => [c._id, c.count]));
    res.json({
      items: items.map((s) => ({
        ...s.toObject(),
        ayahCount: countBy[s.number] ?? 0,
      })),
    });
  } catch (err) {
    next(err);
  }
});

function validateSurah(body) {
  const { number, arabicName, name, meaning } = body || {};
  if (!number || number < 1 || number > 114) {
    throw httpError(400, 'Sura raqami 1–114 oralig‘ida bo‘lishi kerak');
  }
  if (!arabicName) throw httpError(400, 'Arabcha nomi majburiy');
  if (!name?.en || !name?.uz) throw httpError(400, 'Nomi (EN va UZ) majburiy');
  if (!meaning?.en || !meaning?.uz) {
    throw httpError(400, 'Ma’nosi (EN va UZ) majburiy');
  }
}

router.post('/surahs', async (req, res, next) => {
  try {
    validateSurah(req.body);
    const { number, arabicName, name, meaning, revelation } = req.body;
    const exists = await Surah.findOne({ number });
    if (exists) throw httpError(409, `${number}-sura allaqachon mavjud`);
    const item = await Surah.create({
      number,
      arabicName,
      name,
      meaning,
      revelation: revelation === 'Medinan' ? 'Medinan' : 'Meccan',
    });
    res.status(201).json({ item });
  } catch (err) {
    next(err);
  }
});

router.put('/surahs/:id', async (req, res, next) => {
  try {
    validateSurah(req.body);
    const { number, arabicName, name, meaning, revelation } = req.body;
    const item = await Surah.findById(req.params.id);
    if (!item) throw httpError(404, 'Sura topilmadi');

    // Renumbering moves the surah's ayahs with it.
    if (number !== item.number) {
      const clash = await Surah.findOne({ number });
      if (clash) throw httpError(409, `${number}-sura allaqachon mavjud`);
      await Ayah.updateMany(
        { surahNumber: item.number },
        { surahNumber: number },
      );
    }
    Object.assign(item, {
      number,
      arabicName,
      name,
      meaning,
      revelation: revelation === 'Medinan' ? 'Medinan' : 'Meccan',
    });
    await item.save();
    res.json({ item });
  } catch (err) {
    next(err);
  }
});

// Deleting a surah removes all of its ayahs too.
router.delete('/surahs/:id', async (req, res, next) => {
  try {
    const item = await Surah.findByIdAndDelete(req.params.id);
    if (!item) throw httpError(404, 'Sura topilmadi');
    await Ayah.deleteMany({ surahNumber: item.number });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ── Ayahs ─────────────────────────────────────────────────────────────

// GET /api/admin/quran/surahs/:number/ayahs
router.get('/surahs/:number/ayahs', async (req, res, next) => {
  try {
    const items = await Ayah.find({
      surahNumber: Number(req.params.number),
    }).sort({ number: 1 });
    res.json({ items });
  } catch (err) {
    next(err);
  }
});

function validateAyah(body) {
  const { surahNumber, number, juz, arabic, translation } = body || {};
  if (!surahNumber) throw httpError(400, 'surahNumber majburiy');
  if (!number || number < 1) throw httpError(400, 'Oyat raqami majburiy');
  if (!juz || juz < 1 || juz > 30) {
    throw httpError(400, 'Pora (juz) 1–30 oralig‘ida bo‘lishi kerak');
  }
  if (!arabic) throw httpError(400, 'Arabcha matn majburiy');
  if (!translation?.en || !translation?.uz) {
    throw httpError(400, 'Tarjima (EN va UZ) majburiy');
  }
}

router.post('/ayahs', async (req, res, next) => {
  try {
    validateAyah(req.body);
    const {
      surahNumber, number, juz, arabic,
      transliteration = '', translation, audioUrl = null,
    } = req.body;
    const surah = await Surah.findOne({ number: surahNumber });
    if (!surah) throw httpError(404, 'Avval surani yarating');
    const exists = await Ayah.findOne({ surahNumber, number });
    if (exists) {
      throw httpError(409, `${surahNumber}:${number} oyati allaqachon mavjud`);
    }
    const item = await Ayah.create({
      surahNumber, number, juz, arabic, transliteration, translation, audioUrl,
    });
    res.status(201).json({ item });
  } catch (err) {
    next(err);
  }
});

router.put('/ayahs/:id', async (req, res, next) => {
  try {
    validateAyah(req.body);
    const {
      surahNumber, number, juz, arabic,
      transliteration = '', translation, audioUrl = null,
    } = req.body;
    const clash = await Ayah.findOne({
      surahNumber, number, _id: { $ne: req.params.id },
    });
    if (clash) {
      throw httpError(409, `${surahNumber}:${number} oyati allaqachon mavjud`);
    }
    const item = await Ayah.findByIdAndUpdate(
      req.params.id,
      { surahNumber, number, juz, arabic, transliteration, translation, audioUrl },
      { new: true },
    );
    if (!item) throw httpError(404, 'Oyat topilmadi');
    res.json({ item });
  } catch (err) {
    next(err);
  }
});

router.delete('/ayahs/:id', async (req, res, next) => {
  try {
    const item = await Ayah.findByIdAndDelete(req.params.id);
    if (!item) throw httpError(404, 'Oyat topilmadi');
    // Remove the uploaded audio file with it (best-effort).
    if (item.audioUrl?.startsWith('/uploads/audio/')) {
      fs.promises
        .unlink(path.join(uploadsDir, path.basename(item.audioUrl)))
        .catch(() => {});
    }
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

export default router;
