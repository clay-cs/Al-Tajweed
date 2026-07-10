// Thin client for the Quran AI backend (Express + MongoDB).
// The panel is a token-based SPA: the JWT lives in localStorage.

export const API_URL =
  process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:5000/api";

/** Backend origin for uploaded files (audio) — API_URL without `/api`. */
export const FILES_URL = API_URL.replace(/\/api\/?$/, "");

/** Playable src for an ayah audio: absolute URLs pass through, uploads get the backend origin. */
export const audioSrc = (url: string) =>
  url.startsWith("http") ? url : `${FILES_URL}${url}`;

const TOKEN_KEY = "qa_admin_token";

export function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string) {
  localStorage.setItem(TOKEN_KEY, token);
}

export function clearToken() {
  localStorage.removeItem(TOKEN_KEY);
}

export class ApiError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

export async function api<T>(
  path: string,
  options: { method?: string; body?: unknown } = {},
): Promise<T> {
  const token = getToken();
  const res = await fetch(API_URL + path, {
    method: options.method ?? "GET",
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: options.body === undefined ? undefined : JSON.stringify(options.body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new ApiError(res.status, data.message ?? "Xatolik yuz berdi");
  }
  return data as T;
}

async function uploadFile(endpoint: string, file: File): Promise<string> {
  const token = getToken();
  const form = new FormData();
  form.append("file", file);
  const res = await fetch(`${API_URL}${endpoint}`, {
    method: "POST",
    headers: token ? { Authorization: `Bearer ${token}` } : {},
    body: form,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new ApiError(res.status, data.message ?? "Yuklashda xatolik");
  }
  return data.url as string;
}

/** Ayah audio upload → server-relative URL (/uploads/audio/…). */
export const uploadAudio = (file: File) =>
  uploadFile("/admin/quran/audio", file);

/** Lesson image upload → server-relative URL (/uploads/images/…). */
export const uploadImage = (file: File) =>
  uploadFile("/admin/upload/image", file);

// ── Shared types (backend toClient shapes) ────────────────────────────

export interface AdminUser {
  id: string;
  name: string;
  email: string;
  role: "user" | "admin";
  xp: number;
  level: number;
  streak: number;
  pagesRead: number;
  recitationCount: number;
  avgTajweedScore: number;
  createdAt?: string;
  lastReadAt?: string | null;
}

export interface Localized {
  en: string;
  uz: string;
}

export interface QuizQuestion {
  _id: string;
  question: Localized;
  options: Localized[];
  answer: number;
  category: string;
  active: boolean;
}

export interface Lesson {
  _id: string;
  title: Localized;
  subtitle: Localized;
  totalLessons: number;
  icon: string;
  color: string;
  order: number;
  active: boolean;
}

export interface Surah {
  _id: string;
  number: number;
  arabicName: string;
  name: Localized;
  meaning: Localized;
  revelation: "Meccan" | "Medinan";
  ayahCount: number;
}

export interface AyahDoc {
  _id: string;
  surahNumber: number;
  number: number;
  juz: number;
  arabic: string;
  transliteration: string;
  translation: Localized;
  audioUrl: string | null;
}

export interface DuaDoc {
  _id: string;
  title: Localized;
  category: string;
  arabic: string;
  transliteration: string;
  translation: Localized;
  order: number;
  active: boolean;
}

export interface CourseLessonDoc {
  _id: string;
  course: string;
  order: number;
  title: Localized;
  body: Localized;
  arabic: string;
  imageUrl: string | null;
}

export interface HadithDoc {
  _id: string;
  book: string;
  bookNumber: number;
  chapter: string;
  hadithNumber: number;
  narrator: string;
  arabic: string;
  translation: Localized;
  grade: string;
  tags: string[];
  order: number;
  active: boolean;
}

export interface DayPointDto {
  day: string;
  count: number;
}

export interface AdminStats {
  days: number;
  totals: {
    users: number;
    activeUsers7d: number;
    hadiths: number;
    hadithReads: number;
    duas: number;
    surahs: number;
    ayahs: number;
    quizzes: number;
    courses: number;
    courseLessons: number;
    memorizedAyahs: number;
    completedSurahs: number;
    lessonsCompleted: number;
    quizAttempts: number;
    recitations: number;
  };
  registrationsByDay: DayPointDto[];
  activeByDay: DayPointDto[];
  hadithReadsByDay: DayPointDto[];
  lessonsByDay: DayPointDto[];
  memorizedByDay: DayPointDto[];
  topMemorizedSurahs: { surahNumber: number; count: number; name: string }[];
  recentUsers: AdminUser[];
}

export interface Overview {
  totals: {
    users: number;
    newUsersWeek: number;
    quizzes: number;
    lessons: number;
    recitations: number;
    quizAttempts: number;
    tasbeehSessions: number;
    avgTajweedScore: number;
  };
  recentUsers: AdminUser[];
  activeByDay: { day: string; count: number }[];
}
