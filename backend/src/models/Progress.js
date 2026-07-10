import mongoose from 'mongoose';

// One document per (user, surah): where the reader left off.
const progressSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    surahNumber: { type: Number, required: true, min: 1, max: 114 },
    lastVerse: { type: Number, required: true, min: 1 },
    totalVerses: { type: Number, required: true },
  },
  { timestamps: true },
);

progressSchema.index({ user: 1, surahNumber: 1 }, { unique: true });

progressSchema.methods.toClient = function () {
  return {
    surahNumber: this.surahNumber,
    lastVerse: this.lastVerse,
    totalVerses: this.totalVerses,
    progress: Math.min(1, this.lastVerse / this.totalVerses),
    updatedAt: this.updatedAt,
  };
};

export const Progress = mongoose.model('Progress', progressSchema);

// One document per (user, surah) the user finished memorizing/reading —
// powers the "surahs memorized" profile stat.
const surahCompletionSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    surahNumber: { type: Number, required: true, min: 1, max: 114 },
  },
  { timestamps: true },
);

surahCompletionSchema.index({ user: 1, surahNumber: 1 }, { unique: true });

export const SurahCompletion = mongoose.model(
  'SurahCompletion',
  surahCompletionSchema,
);

// One document per memorized ayah — powers the per-surah progress bar
// ("X of N verses memorized") on the reading screen.
const ayahMemorizationSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    surahNumber: { type: Number, required: true, min: 1, max: 114 },
    ayahNumber: { type: Number, required: true, min: 1 },
  },
  { timestamps: true },
);

ayahMemorizationSchema.index(
  { user: 1, surahNumber: 1, ayahNumber: 1 },
  { unique: true },
);

export const AyahMemorization = mongoose.model(
  'AyahMemorization',
  ayahMemorizationSchema,
);
