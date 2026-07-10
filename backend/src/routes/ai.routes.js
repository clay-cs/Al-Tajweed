import { Router } from 'express';
import multer from 'multer';

import { optionalAuth } from '../middleware/auth.js';
import { httpError } from '../middleware/error.js';
import { Recitation } from '../models/Activity.js';
import { DailyActivity } from '../models/Content.js';

const router = Router();

// The Python Tajweed AI service. Overridable per-environment.
const AI_URL = process.env.AI_SERVICE_URL || 'http://localhost:8001';
const AI_TIMEOUT_MS = Number(process.env.AI_TIMEOUT_MS || 60000);

// Accept a single audio file in memory (mobile clips are small). 25 MB cap.
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 25 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const ok =
      file.mimetype.startsWith('audio/') ||
      /\.(wav|m4a|aac|mp3|ogg|webm|flac)$/i.test(file.originalname || '');
    cb(ok ? null : httpError(400, 'Faqat audio fayl yuklash mumkin'), ok);
  },
});

/** Forwards audio + reference to the AI service and returns its JSON. */
async function callAiService(buffer, filename, mimetype, reference) {
  const form = new FormData();
  form.append('reference', reference);
  form.append(
    'audio',
    new Blob([buffer], { type: mimetype || 'application/octet-stream' }),
    filename || 'recitation.wav',
  );

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), AI_TIMEOUT_MS);
  try {
    const res = await fetch(`${AI_URL}/v1/tajweed/assess`, {
      method: 'POST',
      body: form,
      signal: controller.signal,
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      throw httpError(
        res.status === 503 ? 503 : 502,
        data.detail || 'AI xizmati javob bermadi',
      );
    }
    return data;
  } catch (err) {
    if (err.name === 'AbortError') {
      throw httpError(504, 'AI xizmati javobi kechikdi');
    }
    if (err.status) throw err;
    throw httpError(
      502,
      'AI xizmatiga ulanib bo‘lmadi. Python servis ishga tushganini tekshiring.',
    );
  } finally {
    clearTimeout(timer);
  }
}

// GET /api/ai/health — proxy the AI service health for the admin panel/app.
router.get('/health', async (_req, res, next) => {
  try {
    const r = await fetch(`${AI_URL}/health`).catch(() => null);
    if (!r || !r.ok) return res.json({ status: 'down', url: AI_URL });
    res.json(await r.json());
  } catch (err) {
    next(err);
  }
});

// POST /api/ai/tajweed — multipart: reference + audio.
// Auth is OPTIONAL: guests get the analysis, signed-in users also get the
// recitation logged so it counts toward their stats/streak.
router.post(
  '/tajweed',
  optionalAuth,
  upload.single('audio'),
  async (req, res, next) => {
    try {
      const reference = (req.body?.reference || '').trim();
      const surahNumber = Number(req.body?.surahNumber) || null;
      const ayahNumber = Number(req.body?.ayahNumber) || null;
      if (!reference) throw httpError(400, 'Oyat matni (reference) majburiy');
      if (!req.file) throw httpError(400, 'Audio fayl topilmadi');

      const result = await callAiService(
        req.file.buffer,
        req.file.originalname,
        req.file.mimetype,
        reference,
      );

      // Log for signed-in users so recitation stats/streak stay real.
      if (req.user && surahNumber && ayahNumber) {
        Recitation.create({
          user: req.user._id,
          surahNumber,
          ayahNumber,
          score: Math.round(result.score ?? 0),
        }).catch(() => {});
        DailyActivity.touch(req.user._id);
      }

      res.json(result);
    } catch (err) {
      next(err);
    }
  },
);

export default router;
