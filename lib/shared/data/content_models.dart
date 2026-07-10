import 'package:flutter/material.dart';

/// Shared content model classes. All real data comes from the backend
/// repositories — nothing here is hardcoded content.

class Surah {
  final int number;
  final String name;
  final String arabicName;
  final String meaning;
  final String revelation; // Meccan / Medinan
  final int verses;
  final double progress; // 0..1 reading progress
  final int juzStart; // first pora this surah appears in (0 = unknown)
  final int juzEnd; // last pora this surah appears in

  const Surah({
    required this.number,
    required this.name,
    required this.arabicName,
    required this.meaning,
    required this.revelation,
    required this.verses,
    this.progress = 0,
    this.juzStart = 0,
    this.juzEnd = 0,
  });
}

class Ayah {
  final int number;
  final String arabic;
  final String translation;
  final String transliteration;
  final int juz; // pora (1–30)
  final String? audioUrl; // server-relative /uploads/audio/… or null

  const Ayah({
    required this.number,
    required this.arabic,
    required this.translation,
    required this.transliteration,
    this.juz = 1,
    this.audioUrl,
  });
}

class HadithItem {
  final String? id; // backend id — null only for locally built items
  final String book; // e.g. "Sahih al-Buxoriy"
  final int bookNumber;
  final String chapter; // e.g. "Vahiyning boshlanishi"
  final int hadithNumber;
  final String narrator;
  final String arabic;
  final String translation; // localized (current app language)
  final String uzbek;
  final String english;
  final String grade;
  final List<String> tags;

  const HadithItem({
    this.id,
    required this.book,
    this.bookNumber = 1,
    this.chapter = '',
    required this.hadithNumber,
    required this.narrator,
    required this.arabic,
    required this.translation,
    this.uzbek = '',
    this.english = '',
    required this.grade,
    this.tags = const [],
  });
}

class DuaItem {
  final String title;
  final String category;
  final String arabic;
  final String transliteration;
  final String translation;

  const DuaItem({
    required this.title,
    required this.category,
    required this.arabic,
    required this.transliteration,
    required this.translation,
  });
}

class TajweedMistake {
  final String rule;
  final String word;
  final String detail;
  final String severity; // minor / moderate / major

  const TajweedMistake({
    required this.rule,
    required this.word,
    required this.detail,
    required this.severity,
  });
}

class NotificationItem {
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final bool unread;

  const NotificationItem({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    this.unread = false,
  });
}
