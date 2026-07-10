import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// App-wide localization: English + Uzbek (Oʻzbekcha, Latin script).
///
/// UI strings live here as typed getters — `_t('English', 'Oʻzbekcha')`.
/// Content strings (hadith translations, dua bodies, quiz questions) stay
/// in the mock-data layer and will be localized by the future backend.
class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static const supportedLocales = [Locale('en'), Locale('uz')];
  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  bool get _uz => locale.languageCode == 'uz';
  String _t(String en, String uz) => _uz ? uz : en;

  // ── Splash / Onboarding ─────────────────────────────────────────────
  String get splashTagline => _t('Read. Learn. Recite beautifully.',
      'O‘qing. O‘rganing. Go‘zal tilovat qiling.');
  String get skip => _t('Skip', 'O‘tkazish');
  String get continueLabel => _t('Continue', 'Davom etish');
  String get getStarted => _t('Get Started', 'Boshlash');

  String get onb1Title => _t('The Quran, beautifully readable',
      'Qur’onni go‘zal tarzda o‘qing');
  String get onb1Body => _t(
      'A crisp Mushaf-quality reading experience with translations, transliteration and audio from world-class reciters.',
      'Tarjima, transliteratsiya va mashhur qorilar tilovati bilan yuqori sifatli mushaf o‘qish tajribasi.');
  String get onb2Title => _t('Perfect your recitation with AI',
      'Tilovatingizni AI bilan mukammallashtiring');
  String get onb2Body => _t(
      'Recite any verse and get instant, verse-by-verse Tajweed feedback — madd, ghunnah, qalqalah and more.',
      'Istalgan oyatni o‘qing va madd, g‘unna, qalqala kabi tajvid qoidalari bo‘yicha bir zumda baho oling.');
  String get onb3Title =>
      _t('Build a habit that lasts', 'Mustahkam odat shakllantiring');
  String get onb3Body => _t(
      'Daily goals, streaks, prayer times and gentle reminders keep your connection with the Quran growing every day.',
      'Kunlik maqsadlar, davomiylik, namoz vaqtlari va eslatmalar Qur’on bilan aloqangizni har kuni mustahkamlaydi.');

  // ── Auth ────────────────────────────────────────────────────────────
  String get welcomeTitle => _t('Assalamu alaikum 👋', 'Assalomu alaykum 👋');
  String get welcomeSubtitle => _t(
      'Your companion for reading, learning and\nperfecting Quran recitation.',
      'Qur’on o‘qish, o‘rganish va tilovatni\nmukammallashtirishdagi hamrohingiz.');
  String get createAccount => _t('Create Account', 'Hisob yaratish');
  String get signIn => _t('Sign In', 'Kirish');
  String get continueAsGuest =>
      _t('Continue as guest', 'Mehmon sifatida davom etish');
  String get welcomeBack => _t('Welcome back', 'Xush kelibsiz');
  String get signInToContinue => _t('Sign in to continue your Quran journey.',
      'Qur’on safaringizni davom ettirish uchun tizimga kiring.');
  String get email => _t('Email', 'Email');
  String get password => _t('Password', 'Parol');
  String get forgotPassword => _t('Forgot password?', 'Parolni unutdingizmi?');
  String get orContinueWith =>
      _t('or continue with', 'yoki quyidagilar orqali');
  String get noAccount => _t("Don't have an account?", 'Hisobingiz yo‘qmi?');
  String get createOne => _t('Create one', 'Yaratish');
  String get createAccountTitle => _t('Create account', 'Hisob yaratish');
  String get startJourney => _t('Start your journey with the Quran today.',
      'Qur’on bilan safaringizni bugun boshlang.');
  String get fullName => _t('Full name', 'To‘liq ism');
  String get passwordHint8 =>
      _t('At least 8 characters', 'Kamida 8 ta belgi');
  String get agreePrefix => _t('I agree to the ', 'Men ');
  String get termsOfService =>
      _t('Terms of Service', 'Foydalanish shartlari');
  String get andWord => _t(' and ', ' va ');
  String get privacyPolicy => _t('Privacy Policy', 'Maxfiylik siyosati');
  String get agreeSuffix => _t('', 'ga roziman');
  String get haveAccount =>
      _t('Already have an account?', 'Hisobingiz bormi?');
  String get signInAction => _t('Sign in', 'Kirish');
  String get fillAllFields =>
      _t('Please fill in all fields', 'Barcha maydonlarni to‘ldiring');
  String get networkError => _t('Could not connect to the server',
      'Serverga ulanib bo‘lmadi');
  String wiredLater(String feature) => _t('$feature will be wired later',
      '$feature keyinroq ulanadi');

  // ── Navigation ──────────────────────────────────────────────────────
  String get navHome => _t('Home', 'Asosiy');
  String get navQuran => _t('Quran', 'Qur’on');
  String get navLearn => _t('Learn', 'O‘rganish');
  String get navAi => 'AI';
  String get navProfile => _t('Profile', 'Profil');

  // ── Home ────────────────────────────────────────────────────────────
  String greeting(String name) =>
      _t('Assalamu alaikum, $name', 'Assalomu alaykum, $name');
  String get continueReading =>
      _t('Continue reading', 'O‘qishni davom eting');
  String verseOfTotal(int v, int total) =>
      _t('Verse $v of $total', '$v-oyat ($total tadan)');
  String get prayerTimes => _t('Prayer times', 'Namoz vaqtlari');
  String get asrInMinutes => _t('Asr in 25 min', 'Asrgacha 25 daqiqa');
  String get quickActions => _t('Quick actions', 'Tezkor amallar');
  String get qibla => _t('Qibla', 'Qibla');
  String get tasbeeh => _t('Tasbeeh', 'Tasbeh');
  String get duas => _t('Duas', 'Duolar');
  String get hadith => _t('Hadith', 'Hadis');
  String get prayers => _t('Prayers', 'Namoz');
  String get search => _t('Search', 'Qidiruv');
  String get verseOfTheDay => _t('Verse of the day', 'Kun oyati');
  String get hadithOfTheDay => _t('Hadith of the day', 'Kun hadisi');
  String get recentlyOpened => _t('Recently opened', 'Yaqinda ochilganlar');
  String get seeAll => _t('See all', 'Barchasi');
  String versesCount(int n) => _t('$n verses', '$n oyat');
  String get learningProgress =>
      _t('Learning progress', 'O‘rganish jarayoni');
  String lessonsCompleted(int done, int total) => _t(
      '$done of $total lessons completed',
      '$total ta darsdan $done tasi tugallandi');
  String get dayStreak7 => _t('7-day streak', '7 kunlik davomiylik');
  String get dailyGoals => _t('Daily goals', 'Kunlik maqsadlar');
  String get goalRead10 => _t('Read 10 verses', '10 oyat o‘qish');
  String get goalRead10Progress => _t('7 / 10 verses', '7 / 10 oyat');
  String get goalPractice => _t('Practice recitation', 'Tilovat mashqi');
  String get goalPracticeProgress =>
      _t('1 / 2 sessions', '1 / 2 mashg‘ulot');
  String get goalLesson => _t('Complete 1 lesson', '1 darsni tugatish');
  String get goalLessonProgress => _t('1 / 1 lesson', '1 / 1 dars');

  // ── Quran ───────────────────────────────────────────────────────────
  String get theQuran => _t('The Quran', 'Qur’on');
  String get searchSurahHint => _t('Search surah name or number…',
      'Sura nomi yoki raqamini qidiring…');
  String get all => _t('All', 'Barchasi');
  String juzN(int n) => _t('Juz $n', '$n-juz');
  String get khatmahProgress => _t('Khatmah progress', 'Xatm jarayoni');
  String get juzPageInfo =>
      _t('Juz 9 • Page 187 of 604', '9-juz • 187/604-sahifa');
  String get lastRead => _t('Last read', 'Oxirgi o‘qilgan');
  String revelation(String type) => switch (type) {
        'Meccan' => _t('Meccan', 'Makkiy'),
        'Medinan' => _t('Medinan', 'Madaniy'),
        _ => type,
      };
  String get dbEmptyTitle =>
      _t('Database is empty', 'Ma’lumotlar bazasi bo‘sh');
  String get dbEmptyBody => _t(
      'No surahs have been added yet.\nAdd them from the admin panel.',
      'Suralar hali qo‘shilmagan.\nAdmin panel orqali qo‘shing.');
  String get noAyahsYet => _t('No verses have been added to this surah yet.',
      'Bu suraga hali oyatlar qo‘shilmagan.');
  String get noAudioForAyah =>
      _t('No audio for this verse yet', 'Bu oyat uchun hali audio yo‘q');
  String get retry => _t('Retry', 'Qayta urinish');
  String get copied => _t('Copied to clipboard', 'Nusxalandi');
  String get markCompleted => _t('I finished this surah', 'Tugatdim');
  String get surahCompleted =>
      _t('Surah completed', 'Sura tugatildi');
  String get completedBadge => _t('Completed ✓', 'Tugatilgan ✓');
  String get statSurahsMemorized =>
      _t('Surahs memorized', 'Yodlangan suralar');
  String memorizedOfTotal(int done, int total) =>
      _t('$done of $total verses memorized',
          '$total oyatdan $done tasi yodlandi');
  String versesLeft(int n) => _t('$n left', '$n ta qoldi');
  String get memorizedLabel => _t('Memorized', 'Yodlandi');
  String get fullSurah => _t('Full surah', 'To‘liq sura');
  String get repeatingAyah =>
      _t('Repeating verse', 'Oyat takrorlanmoqda');
  String get readingOptions =>
      _t('Reading options', 'O‘qish sozlamalari');
  String get showTransliteration =>
      _t('Show transliteration', 'Transliteratsiyani ko‘rsatish');
  String get showTranslation =>
      _t('Show translation', 'Tarjimani ko‘rsatish');
  String get arabicTextSize =>
      _t('Arabic text size', 'Arabcha matn o‘lchami');
  String get listen => _t('Listen', 'Tinglash');
  String verseRange(String surah, int total) =>
      _t('$surah • Verse 1–$total', '$surah • 1–$total-oyatlar');

  // ── AI Tajweed ──────────────────────────────────────────────────────
  String get aiCoachTitle => _t('AI Tajweed Coach', 'AI Tajvid ustozi');
  String get chooseVerse => _t('Choose a verse', 'Oyatni tanlang');
  String surahVerse(String surah, int n) =>
      _t('$surah • Verse $n', '$surah • $n-oyat');
  String get change => _t('Change', 'O‘zgartirish');
  String get tapMicAndRecite => _t('Tap the microphone and recite',
      'Mikrofonni bosing va tilovat qiling');
  String get analyzing => _t('Analyzing your recitation…',
      'Tilovatingiz tahlil qilinmoqda…');
  String get tapToStop => _t('Tap to stop', 'To‘xtatish uchun bosing');
  String get holdDevice => _t('Hold your device ~20 cm away',
      'Qurilmani ~20 sm masofada tuting');
  String get tajweedScore => _t('Tajweed Score', 'Tajvid bahosi');
  String get outOf100 => _t('out of 100', '100 dan');
  String get areasToImprove =>
      _t('Areas to improve', 'Yaxshilash kerak bo‘lgan joylar');
  String nFound(int n) => _t('$n found', '$n ta topildi');
  String get hearCorrect => _t('Hear correct pronunciation',
      'To‘g‘ri talaffuzni tinglang');
  String get thisWeek => _t('This week', 'Shu hafta');
  String get tryAgain => _t('Try Again', 'Qayta urinish');
  String get practiceThisRule =>
      _t('Practice this rule', 'Bu qoidani mashq qilish');
  String get micPermissionNeeded => _t(
      'Microphone permission is required',
      'Mikrofon uchun ruxsat kerak');
  String get aiServiceDown => _t(
      'AI service is offline. Try again later.',
      'AI xizmati o‘chiq. Keyinroq urinib ko‘ring.');
  String get recordingFailed =>
      _t('Recording failed', 'Yozib olishda xatolik');
  String get analysisFailed =>
      _t('Analysis failed', 'Tahlilda xatolik');
  String get tooShort => _t('Recitation too short — try again',
      'Tilovat juda qisqa — qayta urinib ko‘ring');
  String get whatWeHeard => _t('What we heard', 'Biz eshitgan matn');
  String get letterAnalysis =>
      _t('Letter-by-letter', 'Harflar bo‘yicha');
  String get correctLetters => _t('Correct', 'To‘g‘ri');
  String get problemLetters => _t('Issues', 'Xatolar');
  String get missingLetters => _t('Missing', 'Tushib qolgan');
  String get pronunciationAccuracy =>
      _t('Pronunciation', 'Talaffuz');
  String get noTajweedErrors => _t(
      'No Tajweed mistakes detected. Excellent!',
      'Tajvid xatolari topilmadi. Ajoyib!');
  String get preparingModels => _t(
      'Preparing AI models (first run may take a moment)…',
      'AI modellari tayyorlanmoqda (birinchi ishga tushish biroz vaqt oladi)…');
  String letterStatus(String s) => switch (s) {
        'correct' => _t('correct', 'to‘g‘ri'),
        'incorrect' => _t('incorrect', 'noto‘g‘ri'),
        'unclear' => _t('unclear', 'noaniq'),
        'missing' => _t('missing', 'tushib qolgan'),
        'extra' => _t('extra', 'ortiqcha'),
        'substituted' => _t('substituted', 'almashtirilgan'),
        _ => s,
      };

  // ── Hadith / Duas ───────────────────────────────────────────────────
  String get searchHadithHint => _t('Search hadith…', 'Hadis qidirish…');
  String get noHadithFound => _t('No hadith found', 'Hadis topilmadi');
  String get readMore => _t('Read more', 'Batafsil');
  String get hadithRead => _t('Read', 'O‘qildi');
  String get bookLabel => _t('Book', 'Kitob');
  String get bookNumberLabel => _t('Book no.', 'Kitob raqami');
  String get chapterLabel => _t('Chapter', 'Bob');
  String get hadithNumberLabel => _t('Hadith no.', 'Hadis raqami');
  String get narratorLabel => _t('Narrator', 'Roviy');
  String get gradeLabel => _t('Grade', 'Daraja');
  String get uzbekTranslation =>
      _t('Uzbek translation', 'O‘zbekcha tarjima');
  String get englishTranslation =>
      _t('English translation', 'Inglizcha tarjima');
  String get tagsLabel => _t('Tags', 'Teglar');
  String get dailyDuas => _t('Daily Duas', 'Kunlik duolar');
  String get noDuasYet =>
      _t('No duas added yet.', 'Duolar hali qo‘shilmagan.');
  String get noQuizToday => _t('Today’s quiz isn’t ready yet.',
      'Bugungi test hali tayyor emas.');
  String get noCoursesYet =>
      _t('No courses added yet.', 'Kurslar hali qo‘shilmagan.');
  String get dailyVerseReady =>
      _t('Verse of the day is ready', 'Kun oyati tayyor');
  String get dailyHadithReady =>
      _t('Hadith of the day is ready', 'Kun hadisi tayyor');
  String streakNotif(int n) => _t('$n-day streak! Keep it going. 🔥',
      '$n kunlik seriya! Davom eting. 🔥');
  String get nowLabel => _t('now', 'hozir');
  String qiblaFromNorth(int deg) =>
      _t('Qibla is $deg° from north', 'Qibla: shimoldan $deg°');
  String kmToKaaba(String km) =>
      _t('$km km to the Kaaba', 'Ka’bagacha $km km');
  String duaCategory(String en) => switch (en) {
        'All' => all,
        'Morning' => _t('Morning', 'Tong'),
        'Evening' => _t('Evening', 'Kech'),
        'Travel' => _t('Travel', 'Safar'),
        'Food' => _t('Food', 'Taom'),
        'Sleep' => _t('Sleep', 'Uyqu'),
        'Protection' => _t('Protection', 'Himoya'),
        'Forgiveness' => _t('Forgiveness', 'Istig‘for'),
        _ => en,
      };

  // ── Prayer / Qibla / Tasbeeh ────────────────────────────────────────
  String get prayerTimesTitle => _t('Prayer Times', 'Namoz vaqtlari');
  String get nextPrayer => _t('Next prayer', 'Keyingi namoz');
  String get beginsIn25 =>
      _t('Begins in 25 minutes', '25 daqiqadan so‘ng boshlanadi');
  String countdown(int hours, int minutes) => hours > 0
      ? _t('$hours h $minutes min left', '$hours soat $minutes daqiqa qoldi')
      : _t('$minutes min left', '$minutes daqiqa qoldi');
  String prayerIn(String prayer, int hours, int minutes) => hours > 0
      ? _t('$prayer in ${hours}h ${minutes}m', '$prayer: $hours s $minutes daq')
      : _t('$prayer in $minutes min', '$prayer: $minutes daqiqa');
  String ramadanDay(int day) =>
      _t('Ramadan • day $day', 'Ramazon • $day-kun');
  String get prayerSettings =>
      _t('Prayer settings', 'Namoz sozlamalari');
  String get city => _t('City', 'Shahar');
  String get country => _t('Country', 'Davlat');
  String get calcMethod => _t('Calculation method', 'Hisoblash usuli');
  String get hanafiAsr =>
      _t('Hanafi Asr (later time)', 'Asr — Hanafiy usulda (kechroq)');
  String get byCity => _t('By city', 'Shahar bo‘yicha');
  String get byCoords => _t('By coordinates', 'Koordinata bo‘yicha');
  String get latitude => _t('Latitude', 'Kenglik (latitude)');
  String get longitude => _t('Longitude', 'Uzunlik (longitude)');
  String get invalidCoords =>
      _t('Enter valid coordinates', 'To‘g‘ri koordinata kiriting');
  String get todaysSchedule => _t('Today’s schedule', 'Bugungi jadval');
  String prayerName(String en) => switch (en) {
        'Fajr' => _t('Fajr', 'Bomdod'),
        'Sunrise' => _t('Sunrise', 'Quyosh'),
        'Dhuhr' => _t('Dhuhr', 'Peshin'),
        'Asr' => _t('Asr', 'Asr'),
        'Maghrib' => _t('Maghrib', 'Shom'),
        'Isha' => _t('Isha', 'Xufton'),
        _ => en,
      };
  String get qiblaDirection => _t('Qibla is 247° west of north',
      'Qibla: shimoldan 247° g‘arbda');
  String get alignedWithQibla =>
      _t('Aligned with the Qibla', 'Qiblaga to‘g‘rilandi');
  String get holdPhoneFlat => _t(
      'Hold your phone flat and rotate until the Kaaba points up.',
      'Telefonni tekis tuting va Ka’ba yuqoriga ko‘rsatguncha buriling.');
  String get tapCircle =>
      _t('Tap anywhere on the circle', 'Doiraning istalgan joyiga bosing');
  String ofN(int n) => _t('of $n', '$n dan');
  String get rounds => _t('Rounds', 'Davrlar');
  String get totalToday => _t('Total today', 'Bugun jami');

  // ── Learning / Quiz ─────────────────────────────────────────────────
  String get learningCenter => _t('Learning Center', 'O‘quv markazi');
  String get masterRecitation => _t('Master recitation, step by step.',
      'Tilovatni bosqichma-bosqich mukammallashtiring.');
  String get intermediateReciter =>
      _t('Intermediate Reciter', 'O‘rta darajali qori');
  String get beginnerReciter =>
      _t('Beginner Reciter', 'Boshlang‘ich qori');
  String get advancedReciter =>
      _t('Advanced Reciter', 'Yuqori darajali qori');
  String reciterRank(int level) => level <= 2
      ? beginnerReciter
      : level <= 5
          ? intermediateReciter
          : advancedReciter;
  String xpLine(int xp, int needed, int nextLevel) => _t(
      '$xp XP • $needed XP to level $nextLevel',
      '$xp XP • $nextLevel-darajagacha $needed XP');
  String get xpToNextLevel =>
      _t('580 XP • 220 XP to level 5', '580 XP • 5-darajagacha 220 XP');
  String get dailyQuiz => _t('Daily Quiz', 'Kunlik viktorina');
  String get dailyQuizSubtitle => _t('5 questions • Tajweed & Quran knowledge',
      '5 ta savol • Tajvid va Qur’on bilimi');
  String get start => _t('Start', 'Boshlash');
  String get courses => _t('Courses', 'Kurslar');
  String questionXofY(int x, int y) =>
      _t('Question $x of $y', 'Savol $x / $y');
  String get results => _t('Results', 'Natijalar');
  String get correct => _t('correct', 'to‘g‘ri');
  String correctSoFar(int n) =>
      _t('$n correct so far', 'Hozircha $n ta to‘g‘ri');
  String get resultExcellent =>
      _t('Masha’Allah — excellent!', 'MashaAlloh — a’lo!');
  String get resultGood => _t('Well done, keep practicing!',
      'Barakalla, mashqni davom eting!');
  String get resultRetry => _t('Good effort — review and retry!',
      'Yaxshi harakat — takrorlab, qayta urining!');
  String earnedXp(int xp) =>
      _t('You earned $xp XP', 'Siz $xp XP to‘pladingiz');
  String get backToLearning =>
      _t('Back to Learning', 'O‘rganishga qaytish');
  String get lessonDone => _t('Lesson completed', 'Dars tugatildi');
  String get markLessonDone => _t('Mark as completed', 'Darsni tugatdim');
  String get lessonDoneBadge => _t('Completed ✓', 'Tugatilgan ✓');
  String get nextLesson => _t('Next lesson', 'Keyingi dars');
  String get noLessonsYet => _t('No lessons have been added yet.',
      'Darslar hali qo‘shilmagan.');
  String lessonOrder(int n) => _t('Lesson $n', '$n-dars');
  String get retryQuiz => _t('Retry Quiz', 'Qayta urinish');

  // ── Profile ─────────────────────────────────────────────────────────
  String get profile => _t('Profile', 'Profil');
  String get guest => _t('Guest', 'Mehmon');
  String get guestHint => _t('Sign in to sync your progress',
      'Ma’lumotlaringizni saqlash uchun tizimga kiring');
  String levelBadgeN(int level) => _t('Level $level', '$level-daraja');
  String get levelBadge =>
      _t('Level 4 • Intermediate', '4-daraja • O‘rta');
  String get statDayStreak => _t('Day streak', 'Kunlik davomiylik');
  String get statPagesRead => _t('Pages read', 'O‘qilgan sahifalar');
  String get statRecitations => _t('Recitations', 'Tilovatlar');
  String get statAvgTajweed => _t('Avg. Tajweed', 'O‘rtacha tajvid');
  String get achievements => _t('Achievements', 'Yutuqlar');
  String get achStreak => dayStreak7;
  String get achKhatmah => _t('First khatmah', 'Birinchi xatm');
  String get achRecitations => _t('50 recitations', '50 ta tilovat');
  String get achAlphabet => _t('Alphabet master', 'Alifbo ustasi');
  String get achQuiz => _t('Quiz champion', 'Viktorina chempioni');
  String get notifications => _t('Notifications', 'Bildirishnomalar');
  String get bookmarks => _t('Bookmarks', 'Xatcho‘plar');
  String get bookmarksEmpty =>
      _t('No bookmarks yet', 'Xatcho‘plar hali yo‘q');
  String get bookmarksEmptyBody => _t(
      'Bookmark surahs and verses from the Quran tab — they will appear here.',
      'Qur’on bo‘limida sura va oyatlarni belgilang — ular shu yerda ko‘rinadi.');
  String ayahRef(int surah, int ayah) =>
      _t('Verse $surah:$ayah', '$surah:$ayah-oyat');
  String get wholeSurah => _t('Whole surah', 'Butun sura');
  String get editProfile => _t('Edit profile', 'Profilni tahrirlash');
  String get profileUpdated => _t('Profile updated', 'Profil yangilandi');
  String get changePassword =>
      _t('Change password', 'Parolni o‘zgartirish');
  String get currentPassword => _t('Current password', 'Joriy parol');
  String get newPassword => _t('New password', 'Yangi parol');
  String get passwordChanged =>
      _t('Password changed', 'Parol o‘zgartirildi');
  String get save => _t('Save', 'Saqlash');
  String get helpBody => _t(
      'Questions or ideas? Write to us — the address is copied with one tap.',
      'Savol yoki takliflaringiz bo‘lsa yozing — manzil bir bosishda nusxalanadi.');
  String get downloads => _t('Downloads', 'Yuklab olinganlar');
  String get settings => _t('Settings', 'Sozlamalar');
  String get helpFeedback =>
      _t('Help & feedback', 'Yordam va fikr-mulohaza');
  String get signOut => _t('Sign out', 'Chiqish');

  // ── Settings ────────────────────────────────────────────────────────
  String get appearance => _t('Appearance', 'Ko‘rinish');
  String get themeSystem => _t('System', 'Tizim');
  String get themeLight => _t('Light', 'Yorug‘');
  String get themeDark => _t('Dark', 'Tungi');
  String get language => _t('Language', 'Til');
  String get languageSystem => _t('System', 'Tizim');
  String get reading => _t('Reading', 'O‘qish');
  String get translation => _t('Translation', 'Tarjima');
  String get audio => _t('Audio', 'Audio');
  String get reciter => _t('Reciter', 'Qori');
  String get prayerAlerts =>
      _t('Prayer time alerts', 'Namoz vaqti ogohlantirishlari');
  String get prayerAlertsSub => _t('Adhan notification for each prayer',
      'Har bir namoz uchun azon bildirishnomasi');
  String get dailyVerseSetting => _t('Daily verse', 'Kunlik oyat');
  String get dailyVerseSub => _t('A verse every morning at 7:00',
      'Har kuni ertalab 7:00 da bitta oyat');
  String get streakReminder =>
      _t('Streak reminder', 'Davomiylik eslatmasi');
  String get streakReminderSub => _t('Evening nudge if you haven’t read',
      'O‘qimagan bo‘lsangiz kechki eslatma');
  String get about => _t('About', 'Ilova haqida');
  String get version => _t('Version', 'Versiya');

  // ── Notifications / Search ──────────────────────────────────────────
  String get markAllRead =>
      _t('Mark all read', 'Barchasini o‘qilgan deb belgilash');
  String get allCaughtUp => _t('All caught up', 'Hammasi o‘qildi');
  String get newNotificationsHere => _t('New notifications will appear here.',
      'Yangi bildirishnomalar shu yerda ko‘rinadi.');
  String get searchGlobalHint =>
      _t('Surahs, hadith, duas…', 'Suralar, hadislar, duolar…');
  String get recentSearches => _t('Recent searches', 'So‘nggi qidiruvlar');
  String get clear => _t('Clear', 'Tozalash');
  String get surahs => _t('Surahs', 'Suralar');
  String get hadithPlural => _t('Hadith', 'Hadislar');
  String get duasPlural => _t('Duas', 'Duolar');
  String noResultsFor(String q) =>
      _t('No results for “$q”', '“$q” bo‘yicha natija topilmadi');
  String get tryDifferent => _t('Try a different spelling or keyword.',
      'Boshqa so‘z bilan urinib ko‘ring.');

  // ── Shared ──────────────────────────────────────────────────────────
  String get cancel => _t('Cancel', 'Bekor qilish');
  String get confirm => _t('Confirm', 'Tasdiqlash');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales
          .any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
