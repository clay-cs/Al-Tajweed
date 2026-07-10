import { Router } from 'express';

import { requireAuth } from '../middleware/auth.js';
import { httpError } from '../middleware/error.js';
import { Bookmark } from '../models/Bookmark.js';

const router = Router();
router.use(requireAuth);

// GET /api/bookmarks
router.get('/', async (req, res, next) => {
  try {
    const items = await Bookmark.find({ user: req.user._id }).sort({
      createdAt: -1,
    });
    res.json({
      items: items.map((b) => ({
        surahNumber: b.surahNumber,
        ayahNumber: b.ayahNumber,
        createdAt: b.createdAt,
      })),
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/bookmarks { surahNumber, ayahNumber? }
router.post('/', async (req, res, next) => {
  try {
    const { surahNumber, ayahNumber = null } = req.body || {};
    if (!surahNumber) throw httpError(400, 'surahNumber is required');
    await Bookmark.findOneAndUpdate(
      { user: req.user._id, surahNumber, ayahNumber },
      {},
      { upsert: true },
    );
    res.status(201).json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/bookmarks/:surah?ayah=N
router.delete('/:surah', async (req, res, next) => {
  try {
    const ayahNumber = req.query.ayah ? Number(req.query.ayah) : null;
    await Bookmark.deleteOne({
      user: req.user._id,
      surahNumber: Number(req.params.surah),
      ayahNumber,
    });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

export default router;
