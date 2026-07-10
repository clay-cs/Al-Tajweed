import 'dotenv/config';
import cors from 'cors';
import express from 'express';

import { connectDb } from './config/db.js';
import { errorHandler, notFound } from './middleware/error.js';
import adminQuranRoutes, { uploadsDir } from './routes/admin.quran.routes.js';
import adminRoutes, { imagesDir } from './routes/admin.routes.js';
import aiRoutes from './routes/ai.routes.js';
import authRoutes from './routes/auth.routes.js';
import bookmarkRoutes from './routes/bookmarks.routes.js';
import contentRoutes from './routes/content.routes.js';
import progressRoutes from './routes/progress.routes.js';
import quranRoutes from './routes/quran.routes.js';
import statsRoutes from './routes/stats.routes.js';

const app = express();

app.use(cors());
app.use(express.json());

app.get('/api/health', (_req, res) => res.json({ status: 'ok' }));

app.use('/api/auth', authRoutes);
app.use('/api/progress', progressRoutes);
app.use('/api/bookmarks', bookmarkRoutes);
app.use('/api/stats', statsRoutes);
app.use('/api/content', contentRoutes);
app.use('/api/quran', quranRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/admin/quran', adminQuranRoutes);
app.use('/api/admin', adminRoutes);

// Uploaded files (ayah audio, lesson images) — plain static files.
app.use('/uploads/audio', express.static(uploadsDir));
app.use('/uploads/images', express.static(imagesDir));

app.use(notFound);
app.use(errorHandler);

const port = process.env.PORT || 5000;

connectDb().then(() => {
  app.listen(port, () =>
    console.log(`✅ Quran AI API listening on http://localhost:${port}`),
  );
});
