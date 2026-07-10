# Quran AI — Admin Panel (Next.js)

Quran AI backend'i uchun boshqaruv paneli. Next.js 16 (App Router) +
Tailwind CSS v4 + TypeScript.

## Ishga tushirish

```bash
# 1. Backend ishlab turishi kerak (5000-port):
cd ../backend && npm run dev

# 2. Panel:
cd admin_panel
npm install
npm run dev
```

Panel: **http://localhost:3000** — admin hisobi bilan kiring
(seed'dan keyin: `admin@quranai.uz` / `admin12345`).

Backend boshqa manzilda bo'lsa, `.env.local` da o'zgartiring:

```
NEXT_PUBLIC_API_URL=http://localhost:5000/api
```

## Bo'limlar

- **Boshqaruv** — jonli statistika, 7 kunlik faollik grafigi, yangi foydalanuvchilar
- **Foydalanuvchilar** — qidirish, tahrirlash, admin qilish, parol tiklash, o'chirish
- **Viktorina savollari** — kunlik viktorina savollari (EN + UZ) CRUD
- **Kurslar** — ilovadagi Learning Center kurslari (EN + UZ) CRUD

## Production build

```bash
npm run build && npm start
```
