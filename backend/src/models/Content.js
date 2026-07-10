import mongoose from 'mongoose';

// A localized string: English + Uzbek.
const localized = {
  en: { type: String, required: true },
  uz: { type: String, required: true },
};

// Quiz questions managed from the admin panel; the app pulls a daily set.
const quizQuestionSchema = new mongoose.Schema(
  {
    question: localized,
    options: {
      type: [{ en: String, uz: String, _id: false }],
      validate: [(v) => v.length >= 2 && v.length <= 6, '2–6 options required'],
    },
    answer: { type: Number, required: true, min: 0 },
    category: { type: String, default: 'general' }, // tajweed | quran | general…
    active: { type: Boolean, default: true },
  },
  { timestamps: true },
);

quizQuestionSchema.methods.toClient = function (lang = 'en') {
  const pick = (l) => (lang === 'uz' ? l.uz : l.en);
  return {
    id: this._id.toString(),
    question: pick(this.question),
    options: this.options.map(pick),
    answer: this.answer,
    category: this.category,
  };
};

// Learning Center courses managed from the admin panel.
const lessonSchema = new mongoose.Schema(
  {
    title: localized,
    subtitle: localized,
    totalLessons: { type: Number, required: true, min: 1 },
    icon: { type: String, default: 'school' }, // icon key mapped in the app
    color: { type: String, default: '#0E9D7B' },
    order: { type: Number, default: 0 },
    active: { type: Boolean, default: true },
  },
  { timestamps: true },
);

lessonSchema.methods.toClient = function (lang = 'en') {
  const pick = (l) => (lang === 'uz' ? l.uz : l.en);
  return {
    id: this._id.toString(),
    title: pick(this.title),
    subtitle: pick(this.subtitle),
    totalLessons: this.totalLessons,
    icon: this.icon,
    color: this.color,
    order: this.order,
  };
};

// Daily duas managed from the admin panel: Arabic, Latin reading and
// bilingual title/translation, grouped by category.
const duaSchema = new mongoose.Schema(
  {
    title: localized,
    category: {
      type: String,
      enum: ['Morning', 'Evening', 'Travel', 'Food', 'Sleep', 'Protection', 'Forgiveness'],
      default: 'Morning',
    },
    arabic: { type: String, required: true },
    transliteration: { type: String, default: '' },
    translation: localized,
    order: { type: Number, default: 0 },
    active: { type: Boolean, default: true },
  },
  { timestamps: true },
);

duaSchema.methods.toClient = function (lang = 'en') {
  const pick = (l) => (lang === 'uz' ? l.uz : l.en);
  return {
    id: this._id.toString(),
    title: pick(this.title),
    category: this.category,
    arabic: this.arabic,
    transliteration: this.transliteration,
    translation: pick(this.translation),
    order: this.order,
  };
};

// Hadiths managed from the admin panel: book, book/hadith numbers, chapter,
// narrator, authenticity grade, Arabic text, both translations and tags.
// ("book" — Mongoose reserves the "collection" path name.)
const hadithSchema = new mongoose.Schema(
  {
    book: { type: String, required: true }, // e.g. "Sahih al-Bukhari"
    bookNumber: { type: Number, default: 1 },
    chapter: { type: String, default: '' }, // e.g. "Vahiyning boshlanishi"
    hadithNumber: { type: Number, required: true },
    narrator: { type: String, default: '' },
    arabic: { type: String, required: true },
    translation: localized, // uz + en
    grade: { type: String, default: 'Sahih' }, // Sahih | Hasan | Da'if
    tags: { type: [String], default: [] },
    order: { type: Number, default: 0 },
    active: { type: Boolean, default: true },
  },
  { timestamps: true },
);

hadithSchema.methods.toClient = function (lang = 'en') {
  const pick = (l) => (lang === 'uz' ? l.uz : l.en);
  return {
    id: this._id.toString(),
    book: this.book,
    bookNumber: this.bookNumber,
    chapter: this.chapter,
    hadithNumber: this.hadithNumber,
    narrator: this.narrator,
    arabic: this.arabic,
    // Localized main text + both languages for the detail view.
    translation: pick(this.translation),
    uzbek: this.translation.uz,
    english: this.translation.en,
    grade: this.grade,
    tags: this.tags,
    order: this.order,
  };
};

// One document per (user, hadith) the user has read — powers the
// "hadiths read" statistics on the admin dashboard.
const hadithReadSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    hadith: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Hadith',
      required: true,
    },
  },
  { timestamps: true },
);

hadithReadSchema.index({ user: 1, hadith: 1 }, { unique: true });

// A single lesson INSIDE a course (Lesson = course, CourseLesson = step):
// title, body text, optional Arabic example and an optional image.
const courseLessonSchema = new mongoose.Schema(
  {
    course: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Lesson',
      required: true,
      index: true,
    },
    order: { type: Number, default: 0 },
    title: localized,
    body: localized,
    arabic: { type: String, default: '' }, // example text, shown large
    imageUrl: { type: String, default: null }, // /uploads/images/…
  },
  { timestamps: true },
);

courseLessonSchema.methods.toClient = function (lang = 'en') {
  const pick = (l) => (lang === 'uz' ? l.uz : l.en);
  return {
    id: this._id.toString(),
    courseId: this.course.toString(),
    order: this.order,
    title: pick(this.title),
    body: pick(this.body),
    arabic: this.arabic,
    imageUrl: this.imageUrl,
  };
};

// One document per finished lesson — powers course progress bars and XP.
const lessonCompletionSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    courseLesson: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'CourseLesson',
      required: true,
    },
    course: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Lesson',
      required: true,
      index: true,
    },
  },
  { timestamps: true },
);

lessonCompletionSchema.index(
  { user: 1, courseLesson: 1 },
  { unique: true },
);

// One document per (user, day) — the source of truth for day streaks.
// Upserted whenever the user reads, recites, quizzes or does tasbeeh.
const dailyActivitySchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    day: { type: String, required: true }, // YYYY-MM-DD (UTC)
  },
  { timestamps: true },
);

dailyActivitySchema.index({ user: 1, day: 1 }, { unique: true });

/** Marks "the user was active today" — safe to call repeatedly. */
dailyActivitySchema.statics.touch = function (userId) {
  const day = new Date().toISOString().slice(0, 10);
  return this.updateOne({ user: userId, day }, {}, { upsert: true }).catch(
    () => {}, // duplicate-key races are fine
  );
};

/** Consecutive-day streak ending today or yesterday. */
dailyActivitySchema.statics.streakFor = async function (userId) {
  const days = await this.find({ user: userId })
    .sort({ day: -1 })
    .limit(400)
    .select('day')
    .lean();
  if (!days.length) return 0;

  const set = new Set(days.map((d) => d.day));
  const cursor = new Date();
  const iso = (d) => d.toISOString().slice(0, 10);

  // A streak may end today (already read) or yesterday (not read yet today).
  if (!set.has(iso(cursor))) cursor.setUTCDate(cursor.getUTCDate() - 1);
  let streak = 0;
  while (set.has(iso(cursor))) {
    streak += 1;
    cursor.setUTCDate(cursor.getUTCDate() - 1);
  }
  return streak;
};

export const QuizQuestion = mongoose.model('QuizQuestion', quizQuestionSchema);
export const Dua = mongoose.model('Dua', duaSchema);
export const Hadith = mongoose.model('Hadith', hadithSchema);
export const HadithRead = mongoose.model('HadithRead', hadithReadSchema);
export const Lesson = mongoose.model('Lesson', lessonSchema);
export const CourseLesson = mongoose.model('CourseLesson', courseLessonSchema);
export const LessonCompletion = mongoose.model(
  'LessonCompletion',
  lessonCompletionSchema,
);
export const DailyActivity = mongoose.model('DailyActivity', dailyActivitySchema);
