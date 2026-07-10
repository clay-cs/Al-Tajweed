import mongoose from 'mongoose';

const localized = {
  en: { type: String, required: true },
  uz: { type: String, required: true },
};

// One of the 114 surahs — managed entirely from the admin panel.
const surahSchema = new mongoose.Schema(
  {
    number: { type: Number, required: true, unique: true, min: 1, max: 114 },
    arabicName: { type: String, required: true }, // e.g. الفاتحة
    name: localized, // e.g. Al-Fatihah / Fotiha
    meaning: localized, // e.g. The Opening / Ochuvchi
    revelation: {
      type: String,
      enum: ['Meccan', 'Medinan'],
      default: 'Meccan',
    },
  },
  { timestamps: true },
);

surahSchema.methods.toClient = function (lang = 'en', verses = 0) {
  const pick = (l) => (lang === 'uz' ? l.uz : l.en);
  return {
    number: this.number,
    arabicName: this.arabicName,
    name: pick(this.name),
    meaning: pick(this.meaning),
    revelation: this.revelation,
    verses,
  };
};

// A single ayah: Arabic text, Latin transliteration, translations,
// juz (pora) number and an optional recitation audio file.
const ayahSchema = new mongoose.Schema(
  {
    surahNumber: { type: Number, required: true, min: 1, max: 114, index: true },
    number: { type: Number, required: true, min: 1 }, // ayah number in surah
    juz: { type: Number, required: true, min: 1, max: 30 },
    arabic: { type: String, required: true },
    transliteration: { type: String, default: '' },
    translation: localized,
    audioUrl: { type: String, default: null }, // /uploads/audio/…
  },
  { timestamps: true },
);

ayahSchema.index({ surahNumber: 1, number: 1 }, { unique: true });

ayahSchema.methods.toClient = function (lang = 'en') {
  return {
    number: this.number,
    juz: this.juz,
    arabic: this.arabic,
    transliteration: this.transliteration,
    translation: lang === 'uz' ? this.translation.uz : this.translation.en,
    audioUrl: this.audioUrl,
  };
};

export const Surah = mongoose.model('Surah', surahSchema);
export const Ayah = mongoose.model('Ayah', ayahSchema);
