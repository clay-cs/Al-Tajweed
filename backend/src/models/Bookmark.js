import mongoose from 'mongoose';

const bookmarkSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    surahNumber: { type: Number, required: true, min: 1, max: 114 },
    // Optional: bookmark a specific verse; null = whole surah.
    ayahNumber: { type: Number, default: null },
  },
  { timestamps: true },
);

bookmarkSchema.index(
  { user: 1, surahNumber: 1, ayahNumber: 1 },
  { unique: true },
);

export const Bookmark = mongoose.model('Bookmark', bookmarkSchema);
