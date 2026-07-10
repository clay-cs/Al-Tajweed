import mongoose from 'mongoose';

// Tasbeeh sessions — powers "Total today" and dhikr history.
const tasbeehSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    dhikr: { type: String, required: true },
    count: { type: Number, required: true, min: 0 },
    rounds: { type: Number, default: 0 },
  },
  { timestamps: true },
);

// Quiz attempts — powers XP and the Learning screen.
const quizResultSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    correct: { type: Number, required: true },
    total: { type: Number, required: true },
    xpEarned: { type: Number, required: true },
  },
  { timestamps: true },
);

// AI Tajweed attempts — powers the weekly progress chart.
const recitationSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    surahNumber: { type: Number, required: true },
    ayahNumber: { type: Number, required: true },
    score: { type: Number, required: true, min: 0, max: 100 },
    mistakes: [
      {
        rule: String,
        word: String,
        detail: String,
        severity: { type: String, enum: ['minor', 'moderate', 'major'] },
      },
    ],
  },
  { timestamps: true },
);

export const TasbeehSession = mongoose.model('TasbeehSession', tasbeehSchema);
export const QuizResult = mongoose.model('QuizResult', quizResultSchema);
export const Recitation = mongoose.model('Recitation', recitationSchema);
