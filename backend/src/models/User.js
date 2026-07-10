import bcrypt from 'bcryptjs';
import mongoose from 'mongoose';

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    passwordHash: { type: String, required: true },
    role: { type: String, enum: ['user', 'admin'], default: 'user' },

    // Gamification / stats shown on Home, Learning and Profile.
    xp: { type: Number, default: 0 },
    level: { type: Number, default: 1 },
    streak: { type: Number, default: 0 },
    lastReadAt: { type: Date },
    pagesRead: { type: Number, default: 0 },
    recitationCount: { type: Number, default: 0 },
    avgTajweedScore: { type: Number, default: 0 },
    completedSurahs: { type: Number, default: 0 },

    // Preferences (mirrors the Settings screen).
    language: { type: String, enum: ['system', 'en', 'uz'], default: 'system' },
    theme: { type: String, enum: ['system', 'light', 'dark'], default: 'system' },
    reciter: { type: String, default: 'Mishary Rashid Alafasy' },
    translation: { type: String, default: 'Saheeh International (English)' },
  },
  { timestamps: true },
);

userSchema.methods.checkPassword = function (plain) {
  return bcrypt.compare(plain, this.passwordHash);
};

userSchema.statics.hashPassword = function (plain) {
  return bcrypt.hash(plain, 10);
};

/** Shape sent to the mobile app — never includes the hash. */
userSchema.methods.toClient = function () {
  return {
    id: this._id.toString(),
    name: this.name,
    email: this.email,
    role: this.role,
    xp: this.xp,
    level: this.level,
    streak: this.streak,
    pagesRead: this.pagesRead,
    recitationCount: this.recitationCount,
    avgTajweedScore: this.avgTajweedScore,
    completedSurahs: this.completedSurahs,
    language: this.language,
    theme: this.theme,
    reciter: this.reciter,
    translation: this.translation,
  };
};

export const User = mongoose.model('User', userSchema);
