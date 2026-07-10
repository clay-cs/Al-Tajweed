import 'dotenv/config';
import mongoose from 'mongoose';

import { connectDb } from './config/db.js';
import { Ayah, Surah } from './models/Quran.js';

/**
 * Imports the complete Quran (114 surahs, 6236 ayahs) from the Quran.com
 * API v4 into MongoDB:
 *   - Arabic (Uthmani script)
 *   - Latin transliteration          (resource 57)
 *   - English — Saheeh International (resource 20)
 *   - Uzbek — M. Sodiq M. Yusuf, Latin (resource 55)
 *   - Juz (pora) number per ayah
 *   - Per-ayah audio (Mishary Alafasy, everyayah.com)
 *
 * Existing Quran content is REPLACED. Run: npm run import:quran
 */

const API = 'https://api.quran.com/api/v4';
const EN_ID = 20;
const UZ_ID = 55;
const TRANSLIT_ID = 57;

// Traditional Uzbek (Latin) surah names, 1..114.
const UZ_NAMES = [
  'Fotiha', 'Baqara', 'Oli Imron', 'Niso', 'Moida', 'An’om', 'A’rof',
  'Anfol', 'Tavba', 'Yunus', 'Hud', 'Yusuf', 'Ra’d', 'Ibrohim', 'Hijr',
  'Nahl', 'Isro', 'Kahf', 'Maryam', 'Toha', 'Anbiyo', 'Haj', 'Mo‘minun',
  'Nur', 'Furqon', 'Shuaro', 'Naml', 'Qasas', 'Ankabut', 'Rum', 'Luqmon',
  'Sajda', 'Ahzob', 'Saba', 'Fotir', 'Yosin', 'Soffot', 'Sod', 'Zumar',
  'G‘ofir', 'Fussilat', 'Sho‘ro', 'Zuxruf', 'Duxon', 'Josiya', 'Ahqof',
  'Muhammad', 'Fath', 'Hujurot', 'Qof', 'Zoriyot', 'Tur', 'Najm', 'Qamar',
  'Rahmon', 'Voqea', 'Hadid', 'Mujodala', 'Hashr', 'Mumtahana', 'Saff',
  'Juma', 'Munofiqun', 'Tag‘obun', 'Taloq', 'Tahrim', 'Mulk', 'Qalam',
  'Haqqa', 'Maorij', 'Nuh', 'Jin', 'Muzzammil', 'Muddassir', 'Qiyomat',
  'Inson', 'Mursalot', 'Naba', 'Noziot', 'Abasa', 'Takvir', 'Infitor',
  'Mutaffifin', 'Inshiqoq', 'Buruj', 'Toriq', 'A’lo', 'G‘oshiya', 'Fajr',
  'Balad', 'Shams', 'Layl', 'Zuho', 'Sharh', 'Tiyn', 'Alaq', 'Qadr',
  'Bayyina', 'Zalzala', 'Odiyot', 'Qoria', 'Takosur', 'Asr', 'Humaza',
  'Fil', 'Quraysh', 'Moun', 'Kavsar', 'Kofirun', 'Nasr', 'Masad', 'Ixlos',
  'Falaq', 'Nos',
];

const pad3 = (n) => String(n).padStart(3, '0');
const audioUrlFor = (surah, ayah) =>
  `https://everyayah.com/data/Alafasy_128kbps/${pad3(surah)}${pad3(ayah)}.mp3`;

/** Removes footnote markers and any other HTML from translation text. */
const strip = (s) =>
  (s || '')
    .replace(/<sup[^>]*>.*?<\/sup>/gs, '')
    .replace(/<[^>]+>/g, '')
    .replace(/\s+/g, ' ')
    .trim();

async function fetchJson(url, tries = 3) {
  for (let i = 1; i <= tries; i++) {
    try {
      const res = await fetch(url, { headers: { Accept: 'application/json' } });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return await res.json();
    } catch (err) {
      if (i === tries) throw new Error(`${url} — ${err.message}`);
      await new Promise((r) => setTimeout(r, 1200 * i));
    }
  }
}

async function fetchChapterAyahs(chapterNumber) {
  const ayahs = [];
  let page = 1;
  while (page) {
    const data = await fetchJson(
      `${API}/verses/by_chapter/${chapterNumber}` +
        `?translations=${EN_ID},${UZ_ID},${TRANSLIT_ID}` +
        `&fields=text_uthmani,juz_number&per_page=50&page=${page}`,
    );
    for (const v of data.verses) {
      const byResource = Object.fromEntries(
        (v.translations || []).map((t) => [t.resource_id, strip(t.text)]),
      );
      ayahs.push({
        surahNumber: chapterNumber,
        number: v.verse_number,
        juz: v.juz_number || 1,
        arabic: v.text_uthmani,
        transliteration: byResource[TRANSLIT_ID] || '',
        translation: {
          en: byResource[EN_ID] || '',
          uz: byResource[UZ_ID] || '',
        },
        audioUrl: audioUrlFor(chapterNumber, v.verse_number),
      });
    }
    page = data.pagination?.next_page ?? null;
  }
  return ayahs;
}

async function run() {
  console.log('📥 Quran.com API dan import boshlandi…');
  await connectDb();

  const { chapters } = await fetchJson(`${API}/chapters?language=en`);
  if (chapters?.length !== 114) {
    throw new Error(`Kutilgan 114 sura, kelgani: ${chapters?.length}`);
  }

  // Full replace — the admin panel owns any edits made after the import.
  await Ayah.deleteMany({});
  await Surah.deleteMany({});
  console.log('🗑  Eski Qur’on kontenti tozalandi.');

  let totalAyahs = 0;
  for (const c of chapters) {
    await Surah.create({
      number: c.id,
      arabicName: c.name_arabic,
      name: { en: c.name_simple, uz: UZ_NAMES[c.id - 1] },
      meaning: {
        en: c.translated_name?.name || c.name_simple,
        uz: c.translated_name?.name || c.name_simple,
      },
      revelation: c.revelation_place === 'madinah' ? 'Medinan' : 'Meccan',
    });

    const ayahs = await fetchChapterAyahs(c.id);
    if (ayahs.length !== c.verses_count) {
      console.warn(
        `⚠️  ${c.id}-sura: kutilgan ${c.verses_count}, kelgani ${ayahs.length}`,
      );
    }
    await Ayah.insertMany(ayahs);
    totalAyahs += ayahs.length;
    console.log(
      `✅ ${String(c.id).padStart(3)}/114  ${UZ_NAMES[c.id - 1]} — ${ayahs.length} oyat (jami ${totalAyahs})`,
    );
  }

  console.log(`\n🎉 Tugadi: 114 sura, ${totalAyahs} oyat import qilindi.`);
  await mongoose.disconnect();
}

run().catch((err) => {
  console.error('❌ Import xatosi:', err.message);
  process.exit(1);
});
