import 'dotenv/config';
import mongoose from 'mongoose';

import { connectDb } from './config/db.js';
import { CourseLesson, Dua, Hadith, Lesson, QuizQuestion } from './models/Content.js';
import { Ayah, Surah } from './models/Quran.js';
import { User } from './models/User.js';

const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@quranai.uz';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'admin12345';

const quizzes = [
  {
    question: {
      en: 'How many counts should a natural madd (madd tabee‘ee) be held?',
      uz: 'Tabiiy madd (madd tabiiy) necha harakat cho‘ziladi?',
    },
    options: [
      { en: '1 count', uz: '1 harakat' },
      { en: '2 counts', uz: '2 harakat' },
      { en: '4 counts', uz: '4 harakat' },
      { en: '6 counts', uz: '6 harakat' },
    ],
    answer: 1,
    category: 'tajweed',
  },
  {
    question: {
      en: 'Which letters trigger Qalqalah when carrying sukoon?',
      uz: 'Sukunli holatda qaysi harflar qalqala hosil qiladi?',
    },
    options: [
      { en: 'ق ط ب ج د', uz: 'ق ط ب ج د' },
      { en: 'ن م و ي', uz: 'ن م و ي' },
      { en: 'ح خ ع غ', uz: 'ح خ ع غ' },
      { en: 'ص ض ط ظ', uz: 'ص ض ط ظ' },
    ],
    answer: 0,
    category: 'tajweed',
  },
  {
    question: {
      en: 'What is the ruling of noon saakinah followed by “ب”?',
      uz: 'Sokin nundan keyin “ب” kelsa qaysi hukm qo‘llanadi?',
    },
    options: [
      { en: 'Izhar', uz: 'Izhor' },
      { en: 'Idgham', uz: 'Idg‘om' },
      { en: 'Iqlab', uz: 'Iqlob' },
      { en: 'Ikhfa', uz: 'Ixfo' },
    ],
    answer: 2,
    category: 'tajweed',
  },
  {
    question: {
      en: 'Which surah is known as “The Heart of the Quran”?',
      uz: 'Qaysi sura “Qur’onning qalbi” deb ataladi?',
    },
    options: [
      { en: 'Al-Fatihah', uz: 'Fotiha' },
      { en: 'Ya-Sin', uz: 'Yosin' },
      { en: 'Al-Mulk', uz: 'Mulk' },
      { en: 'Ar-Rahman', uz: 'Rahmon' },
    ],
    answer: 1,
    category: 'quran',
  },
  {
    question: {
      en: 'How many verses are in Surah Al-Fatihah?',
      uz: 'Fotiha surasida nechta oyat bor?',
    },
    options: [
      { en: '5', uz: '5' },
      { en: '6', uz: '6' },
      { en: '7', uz: '7' },
      { en: '8', uz: '8' },
    ],
    answer: 2,
    category: 'quran',
  },
  {
    question: {
      en: 'How many surahs are there in the Quran?',
      uz: 'Qur’onda nechta sura bor?',
    },
    options: [
      { en: '110', uz: '110' },
      { en: '112', uz: '112' },
      { en: '114', uz: '114' },
      { en: '116', uz: '116' },
    ],
    answer: 2,
    category: 'quran',
  },
  {
    question: {
      en: 'Which surah is recited in every unit (rak‘ah) of prayer?',
      uz: 'Namozning har bir rakatida qaysi sura o‘qiladi?',
    },
    options: [
      { en: 'Al-Ikhlas', uz: 'Ixlos' },
      { en: 'Al-Fatihah', uz: 'Fotiha' },
      { en: 'Al-Kawthar', uz: 'Kavsar' },
      { en: 'An-Nas', uz: 'Nos' },
    ],
    answer: 1,
    category: 'quran',
  },
];

const lessons = [
  {
    title: { en: 'Arabic Alphabet', uz: 'Arab alifbosi' },
    subtitle: { en: 'Letters, forms & sounds', uz: 'Harflar, shakllar va tovushlar' },
    totalLessons: 12,
    icon: 'translate',
    color: '#3B82F6',
    order: 1,
  },
  {
    title: { en: 'Tajweed Basics', uz: 'Tajvid asoslari' },
    subtitle: { en: 'Rules of recitation', uz: 'Tilovat qoidalari' },
    totalLessons: 18,
    icon: 'voice',
    color: '#0E9D7B',
    order: 2,
  },
  {
    title: { en: 'Noon & Meem Rules', uz: 'Nun va mim qoidalari' },
    subtitle: { en: 'Ikhfa, Idgham, Iqlab', uz: 'Ixfo, idg‘om, iqlob' },
    totalLessons: 10,
    icon: 'eq',
    color: '#8B5CF6',
    order: 3,
  },
  {
    title: { en: 'Madd Rules', uz: 'Madd qoidalari' },
    subtitle: { en: 'Elongation mastery', uz: 'Cho‘zish mahorati' },
    totalLessons: 8,
    icon: 'audio',
    color: '#E3B23C',
    order: 4,
  },
  {
    title: { en: 'Makharij', uz: 'Maxraj' },
    subtitle: { en: 'Articulation points', uz: 'Harflarning chiqish o‘rinlari' },
    totalLessons: 14,
    icon: 'mic',
    color: '#EF4444',
    order: 5,
  },
];

// Authentic daily duas with Latin reading and both translations.
const duas = [
  {
    title: { en: 'Upon Waking Up', uz: 'Uyg‘onganda' },
    category: 'Morning',
    arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
    transliteration: 'Alhamdu lillahil-laziy ahyona ba’da mo amotana wa ilayhin-nushur',
    translation: {
      en: 'All praise is for Allah who gave us life after having taken it from us, and unto Him is the resurrection.',
      uz: 'Bizni o‘limdan so‘ng (uyqudan) tiriltirgan Allohga hamd bo‘lsin. Qaytish ham Uning huzurigadir.',
    },
    order: 1,
  },
  {
    title: { en: 'Morning Remembrance', uz: 'Tong zikri' },
    category: 'Morning',
    arabic: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ',
    transliteration: 'Asbahno va asbahal-mulku lillah, valhamdu lillah',
    translation: {
      en: 'We have entered the morning and the dominion belongs to Allah, and all praise is for Allah.',
      uz: 'Tongga yetdik, butun mulk Allohnikidir, barcha hamdlar Allohgadir.',
    },
    order: 2,
  },
  {
    title: { en: 'Evening Remembrance', uz: 'Kech zikri' },
    category: 'Evening',
    arabic: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ',
    transliteration: 'Amsayno va amsal-mulku lillah, valhamdu lillah',
    translation: {
      en: 'We have entered the evening and the dominion belongs to Allah, and all praise is for Allah.',
      uz: 'Kechga yetdik, butun mulk Allohnikidir, barcha hamdlar Allohgadir.',
    },
    order: 3,
  },
  {
    title: { en: 'Before Eating', uz: 'Ovqatdan oldin' },
    category: 'Food',
    arabic: 'بِسْمِ اللَّهِ',
    transliteration: 'Bismillah',
    translation: {
      en: 'In the name of Allah.',
      uz: 'Alloh nomi bilan.',
    },
    order: 4,
  },
  {
    title: { en: 'After Eating', uz: 'Ovqatdan keyin' },
    category: 'Food',
    arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِينَ',
    transliteration: 'Alhamdu lillahil-laziy at’amana va saqona va ja’alana muslimiyn',
    translation: {
      en: 'Praise be to Allah who has fed us, given us drink and made us Muslims.',
      uz: 'Bizni yedirib-ichirgan va musulmonlardan qilgan Allohga hamd bo‘lsin.',
    },
    order: 5,
  },
  {
    title: { en: 'Before Sleeping', uz: 'Uxlashdan oldin' },
    category: 'Sleep',
    arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
    transliteration: 'Bismika Allohumma amutu va ahyo',
    translation: {
      en: 'In Your name, O Allah, I die and I live.',
      uz: 'Ey Alloh, Sening isming bilan o‘laman va tirilaman (uxlayman va uyg‘onaman).',
    },
    order: 6,
  },
  {
    title: { en: 'When Travelling', uz: 'Safarga chiqqanda' },
    category: 'Travel',
    arabic: 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ',
    transliteration: 'Subhanal-laziy saxxaro lana haza va mo kunna lahu muqriniyn',
    translation: {
      en: 'Glory to Him who has subjected this to us, and we could never have it (by our efforts).',
      uz: 'Buni bizga bo‘ysundirgan Zot pokdir. Biz bunga o‘zimiz qodir emas edik.',
    },
    order: 7,
  },
  {
    title: { en: 'Seeking Protection', uz: 'Panoh so‘rash' },
    category: 'Protection',
    arabic: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
    transliteration: 'A’uzu bikalimatillahit-tammati min sharri mo xalaq',
    translation: {
      en: 'I seek refuge in the perfect words of Allah from the evil of what He has created.',
      uz: 'Allohning komil kalimalari bilan U yaratgan narsalarning yomonligidan panoh so‘rayman.',
    },
    order: 8,
  },
  {
    title: { en: 'Seeking Forgiveness', uz: 'Istig‘for' },
    category: 'Forgiveness',
    arabic: 'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ',
    transliteration: 'Robbig‘fir liy va tub ‘alayya innaka antat-tavvabur-rohiym',
    translation: {
      en: 'My Lord, forgive me and accept my repentance. Indeed, You are the Accepting of repentance, the Merciful.',
      uz: 'Robbim, meni mag‘firat qil va tavbamni qabul et. Albatta, Sen tavbalarni qabul qiluvchi, rahmli Zotsan.',
    },
    order: 9,
  },
];

// First lessons of the "Arabic Alphabet" course — real teachable content.
const alphabetLessons = [
  { ar: 'ا', en: 'Alif', uz: 'Alif',
    bodyEn: 'Alif is the first letter. It is a long "aa" sound and never connects to the letter after it. Examples: أَب (father), قَالَ (he said).',
    bodyUz: 'Alif — birinchi harf. U cho‘ziq «aa» tovushini beradi va o‘zidan keyingi harfga qo‘shilmaydi. Misollar: أَب (ota), قَالَ (dedi).' },
  { ar: 'ب', en: 'Ba', uz: 'Bo',
    bodyEn: 'Ba sounds like "b". One dot below the letter. Forms: بـ ـبـ ـب. Example: بَاب (door), بِسْم (name/in the name).',
    bodyUz: '«B» tovushini beradi. Harf ostida bitta nuqta bor. Shakllari: بـ ـبـ ـب. Misol: بَاب (eshik), بِسْم (ism).' },
  { ar: 'ت', en: 'Ta', uz: 'To',
    bodyEn: 'Ta sounds like "t". Two dots above. Forms: تـ ـتـ ـت. Example: تِين (fig), كِتَاب (book).',
    bodyUz: '«T» tovushini beradi. Ustida ikkita nuqta bor. Shakllari: تـ ـتـ ـت. Misol: تِين (anjir), كِتَاب (kitob).' },
  { ar: 'ث', en: 'Tha', uz: 'So (sa)',
    bodyEn: 'Tha is the soft "th" as in "think". Three dots above. Example: ثَلَاثَة (three), ثَوْب (garment).',
    bodyUz: 'Ingliz tilidagi «think» so‘zidagi yumshoq «s» tovushi. Ustida uchta nuqta. Misol: ثَلَاثَة (uch), ثَوْب (kiyim).' },
  { ar: 'ج', en: 'Jim', uz: 'Jim',
    bodyEn: 'Jim sounds like "j". One dot below. Forms: جـ ـجـ ـج. Example: جَنَّة (garden/paradise), جَمَل (camel).',
    bodyUz: '«J» tovushini beradi. Ostida bitta nuqta. Shakllari: جـ ـجـ ـج. Misol: جَنَّة (jannat), جَمَل (tuya).' },
  { ar: 'ح', en: 'Ha', uz: 'Ha (qattiq)',
    bodyEn: 'Ha is a deep, breathy "h" from the middle of the throat — no dots. Example: حَمْد (praise), رَحْمَة (mercy).',
    bodyUz: 'Tomoq o‘rtasidan chiqadigan chuqur «h» tovushi — nuqtasiz. Misol: حَمْد (hamd), رَحْمَة (rahmat).' },
  { ar: 'خ', en: 'Kha', uz: 'Xo',
    bodyEn: 'Kha is the "kh" sound (like Scottish "loch"). One dot above. Example: خَيْر (goodness), خُبْز (bread).',
    bodyUz: '«X» tovushini beradi. Ustida bitta nuqta. Misol: خَيْر (yaxshilik), خُبْز (non).' },
  { ar: 'د', en: 'Dal', uz: 'Dol',
    bodyEn: 'Dal sounds like "d" and never connects forward. Example: دِين (religion), يَد (hand).',
    bodyUz: '«D» tovushini beradi va keyingi harfga qo‘shilmaydi. Misol: دِين (din), يَد (qo‘l).' },
].map((l, i) => ({
  order: i + 1,
  title: { en: `${l.en} — letter ${i + 1}`, uz: `${l.uz} — ${i + 1}-harf` },
  body: { en: l.bodyEn, uz: l.bodyUz },
  arabic: l.ar,
}));

// Al-Fatihah — a complete sample so the Quran tab has real data to show.
const fatihah = {
  surah: {
    number: 1,
    arabicName: 'الفاتحة',
    name: { en: 'Al-Fatihah', uz: 'Fotiha' },
    meaning: { en: 'The Opening', uz: 'Ochuvchi' },
    revelation: 'Meccan',
  },
  ayahs: [
    {
      number: 1,
      arabic: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      transliteration: 'Bismillahir-Rahmanir-Rahim',
      translation: {
        en: 'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
        uz: 'Mehribon va rahmli Alloh nomi bilan (boshlayman).',
      },
    },
    {
      number: 2,
      arabic: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      transliteration: "Alhamdu lillahi Rabbil-'alamin",
      translation: {
        en: 'All praise is due to Allah, Lord of the worlds.',
        uz: 'Barcha hamdu sanolar olamlarning Robbi Allohga xosdir.',
      },
    },
    {
      number: 3,
      arabic: 'الرَّحْمَٰنِ الرَّحِيمِ',
      transliteration: 'Ar-Rahmanir-Rahim',
      translation: {
        en: 'The Entirely Merciful, the Especially Merciful.',
        uz: 'U mehribon va rahmlidir.',
      },
    },
    {
      number: 4,
      arabic: 'مَالِكِ يَوْمِ الدِّينِ',
      transliteration: 'Maliki yawmid-din',
      translation: {
        en: 'Sovereign of the Day of Recompense.',
        uz: 'U jazo (qiyomat) kunining egasidir.',
      },
    },
    {
      number: 5,
      arabic: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
      transliteration: "Iyyaka na'budu wa iyyaka nasta'in",
      translation: {
        en: 'It is You we worship and You we ask for help.',
        uz: 'Faqat Sengagina ibodat qilamiz va faqat Sendangina yordam so‘raymiz.',
      },
    },
    {
      number: 6,
      arabic: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
      transliteration: 'Ihdinas-siratal-mustaqim',
      translation: {
        en: 'Guide us to the straight path.',
        uz: 'Bizni to‘g‘ri yo‘lga hidoyat qilgin.',
      },
    },
    {
      number: 7,
      arabic:
        'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
      transliteration:
        "Siratal-lazina an'amta 'alayhim g'ayril-mag'dubi 'alayhim wa lad-dallin",
      translation: {
        en: 'The path of those upon whom You have bestowed favor, not of those who have earned Your anger or of those who are astray.',
        uz: 'O‘zing ne’mat berganlarning yo‘liga — g‘azabga uchraganlarning ham, adashganlarning ham yo‘liga emas.',
      },
    },
  ].map((a) => ({ ...a, surahNumber: 1, juz: 1 })),
};

// Admin-managed hadith library — starter set, editable from the panel.
const hadiths = [
  {
    book: 'Sahih al-Buxoriy',
    bookNumber: 1,
    chapter: 'Vahiyning boshlanishi',
    hadithNumber: 1,
    narrator: 'Umar ibn Xattob (r.a.)',
    arabic: 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى',
    translation: {
      en: 'Actions are but by intentions, and every man shall have only that which he intended.',
      uz: 'Amallar faqat niyatlarga bog‘liqdir. Har bir kishiga faqat niyat qilgan narsasi bo‘ladi.',
    },
    grade: 'Sahih',
    tags: ['niyat', 'ibodat'],
    order: 1,
  },
  {
    book: 'Sahih Muslim',
    bookNumber: 2,
    chapter: 'Ilm fazilati',
    hadithNumber: 2699,
    narrator: 'Abu Hurayra (r.a.)',
    arabic: 'مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ',
    translation: {
      en: 'Whoever travels a path in search of knowledge, Allah will make easy for him a path to Paradise.',
      uz: 'Kim ilm izlab yo‘lga chiqsa, Alloh unga jannat sari yo‘lni oson qilib qo‘yadi.',
    },
    grade: 'Sahih',
    tags: ['ilm', 'jannat'],
    order: 2,
  },
  {
    book: 'Sahih al-Buxoriy',
    bookNumber: 1,
    chapter: 'Qur’on fazilatlari',
    hadithNumber: 5027,
    narrator: 'Usmon ibn Affon (r.a.)',
    arabic: 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ',
    translation: {
      en: 'The best of you are those who learn the Quran and teach it.',
      uz: 'Sizlarning eng yaxshingiz Qur’onni o‘rganib, uni o‘rgatganingizdir.',
    },
    grade: 'Sahih',
    tags: ['quron', 'ilm', 'talim'],
    order: 3,
  },
  {
    book: 'Jome’ at-Termiziy',
    bookNumber: 5,
    chapter: 'Ilm bobi',
    hadithNumber: 2646,
    narrator: 'Anas ibn Molik (r.a.)',
    arabic: 'طَلَبُ الْعِلْمِ فَرِيضَةٌ عَلَى كُلِّ مُسْلِمٍ',
    translation: {
      en: 'Seeking knowledge is an obligation upon every Muslim.',
      uz: 'Ilm izlash har bir musulmonga farzdir.',
    },
    grade: 'Hasan',
    tags: ['ilm', 'farz'],
    order: 4,
  },
  {
    book: 'Sahih Muslim',
    bookNumber: 1,
    chapter: 'Iymon kitobi',
    hadithNumber: 91,
    narrator: 'Abdulloh ibn Mas’ud (r.a.)',
    arabic: 'لَا يَدْخُلُ الْجَنَّةَ مَنْ كَانَ فِي قَلْبِهِ مِثْقَالُ ذَرَّةٍ مِنْ كِبْرٍ',
    translation: {
      en: 'He who has, in his heart, an atom’s weight of pride will not enter Paradise.',
      uz: 'Qalbida zarra miqdorida kibri bor kishi jannatga kirmaydi.',
    },
    grade: 'Sahih',
    tags: ['kibr', 'axloq', 'jannat'],
    order: 5,
  },
  {
    book: 'Riyozus-solihin',
    bookNumber: 1,
    chapter: 'Yaxshilik yo‘llari',
    hadithNumber: 141,
    narrator: 'Abu Hurayra (r.a.)',
    arabic: 'الْكَلِمَةُ الطَّيِّبَةُ صَدَقَةٌ',
    translation: {
      en: 'A good word is charity.',
      uz: 'Yaxshi so‘z — sadaqadir.',
    },
    grade: 'Sahih',
    tags: ['sadaqa', 'axloq', 'soz'],
    order: 6,
  },
  {
    book: 'Sahih al-Buxoriy',
    bookNumber: 1,
    chapter: 'Iymon kitobi',
    hadithNumber: 13,
    narrator: 'Anas ibn Molik (r.a.)',
    arabic: 'لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ',
    translation: {
      en: 'None of you truly believes until he loves for his brother what he loves for himself.',
      uz: 'Sizlardan birortangiz o‘ziga yoqtirgan narsani birodariga ham yoqtirmaguncha komil mo‘min bo‘la olmaydi.',
    },
    grade: 'Sahih',
    tags: ['iymon', 'birodarlik'],
    order: 7,
  },
  {
    book: 'Sahih Muslim',
    bookNumber: 4,
    chapter: 'Yaxshilik va silai rahm',
    hadithNumber: 2564,
    narrator: 'Abu Hurayra (r.a.)',
    arabic: 'إِنَّ اللَّهَ لَا يَنْظُرُ إِلَى صُوَرِكُمْ وَأَمْوَالِكُمْ وَلَكِنْ يَنْظُرُ إِلَى قُلُوبِكُمْ وَأَعْمَالِكُمْ',
    translation: {
      en: 'Allah does not look at your appearance or wealth, but He looks at your hearts and your deeds.',
      uz: 'Alloh sizlarning suratlaringizga va mollaringizga qaramaydi, balki qalblaringizga va amallaringizga qaraydi.',
    },
    grade: 'Sahih',
    tags: ['qalb', 'amal', 'ixlos'],
    order: 8,
  },
];

async function seed() {
  await connectDb();

  let admin = await User.findOne({ email: ADMIN_EMAIL });
  if (!admin) {
    admin = await User.create({
      name: 'Administrator',
      email: ADMIN_EMAIL,
      passwordHash: await User.hashPassword(ADMIN_PASSWORD),
      role: 'admin',
    });
    console.log(`✅ Admin created: ${ADMIN_EMAIL} / ${ADMIN_PASSWORD}`);
  } else if (admin.role !== 'admin') {
    admin.role = 'admin';
    await admin.save();
    console.log(`✅ ${ADMIN_EMAIL} promoted to admin`);
  } else {
    console.log(`ℹ️  Admin already exists: ${ADMIN_EMAIL}`);
  }

  if ((await QuizQuestion.countDocuments()) === 0) {
    await QuizQuestion.insertMany(quizzes);
    console.log(`✅ ${quizzes.length} quiz questions seeded`);
  } else {
    console.log('ℹ️  Quiz questions already present — skipped');
  }

  if ((await Lesson.countDocuments()) === 0) {
    await Lesson.insertMany(lessons);
    console.log(`✅ ${lessons.length} lessons seeded`);
  } else {
    console.log('ℹ️  Lessons already present — skipped');
  }

  if ((await Dua.countDocuments()) === 0) {
    await Dua.insertMany(duas);
    console.log(`✅ ${duas.length} duas seeded`);
  } else {
    console.log('ℹ️  Duas already present — skipped');
  }

  if ((await Hadith.countDocuments()) === 0) {
    await Hadith.insertMany(hadiths);
    console.log(`✅ ${hadiths.length} hadiths seeded`);
  } else {
    console.log('ℹ️  Hadiths already present — skipped');
  }

  if ((await CourseLesson.countDocuments()) === 0) {
    const alphabetCourse = await Lesson.findOne({ 'title.en': 'Arabic Alphabet' });
    if (alphabetCourse) {
      await CourseLesson.insertMany(
        alphabetLessons.map((l) => ({ ...l, course: alphabetCourse._id })),
      );
      console.log(`✅ ${alphabetLessons.length} alphabet lessons seeded`);
    }
  } else {
    console.log('ℹ️  Course lessons already present — skipped');
  }

  if ((await Surah.countDocuments()) === 0) {
    await Surah.create(fatihah.surah);
    await Ayah.insertMany(fatihah.ayahs);
    console.log('✅ Al-Fatihah seeded (1 surah, 7 ayahs)');
  } else {
    console.log('ℹ️  Quran content already present — skipped');
  }

  await mongoose.disconnect();
  console.log('Done.');
}

seed();
