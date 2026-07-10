import { Router } from 'express';

import { httpError } from '../middleware/error.js';
import { Ayah, Surah } from '../models/Quran.js';

const router = Router();

// Public — the app's Quran tab reads from here (guests included).

// GET /api/quran/surahs?lang=uz — all surahs with their real ayah counts
router.get('/surahs', async (req, res, next) => {
  try {
    const lang = req.query.lang === 'uz' ? 'uz' : 'en';
    const [surahs, counts] = await Promise.all([
      Surah.find().sort({ number: 1 }),
      Ayah.aggregate([
        {
          $group: {
            _id: '$surahNumber',
            count: { $sum: 1 },
            juzStart: { $min: '$juz' },
            juzEnd: { $max: '$juz' },
          },
        },
      ]),
    ]);
    const byNumber = Object.fromEntries(counts.map((c) => [c._id, c]));
    res.json({
      items: surahs.map((s) => {
        const agg = byNumber[s.number];
        return {
          ...s.toClient(lang, agg?.count ?? 0),
          juzStart: agg?.juzStart ?? 0,
          juzEnd: agg?.juzEnd ?? 0,
        };
      }),
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/quran/surahs/:number?lang=uz — one surah + all its ayahs
router.get('/surahs/:number', async (req, res, next) => {
  try {
    const lang = req.query.lang === 'uz' ? 'uz' : 'en';
    const number = Number(req.params.number);
    const [surah, ayahs] = await Promise.all([
      Surah.findOne({ number }),
      Ayah.find({ surahNumber: number }).sort({ number: 1 }),
    ]);
    if (!surah) throw httpError(404, 'Surah not found');
    res.json({
      surah: surah.toClient(lang, ayahs.length),
      ayahs: ayahs.map((a) => a.toClient(lang)),
    });
  } catch (err) {
    next(err);
  }
});

export default router;
