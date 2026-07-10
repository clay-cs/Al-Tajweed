/// User object returned by the backend (`user.toClient()` shape).
class AuthUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final int xp;
  final int level;
  final int streak;
  final int pagesRead;
  final int recitationCount;
  final int avgTajweedScore;
  final int completedSurahs;
  final String language;
  final String theme;
  final String reciter;
  final String translation;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    this.pagesRead = 0,
    this.recitationCount = 0,
    this.avgTajweedScore = 0,
    this.completedSurahs = 0,
    this.language = 'system',
    this.theme = 'system',
    this.reciter = '',
    this.translation = '',
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: (json['role'] ?? 'user') as String,
        xp: (json['xp'] ?? 0) as int,
        level: (json['level'] ?? 1) as int,
        streak: (json['streak'] ?? 0) as int,
        pagesRead: (json['pagesRead'] ?? 0) as int,
        recitationCount: (json['recitationCount'] ?? 0) as int,
        avgTajweedScore: (json['avgTajweedScore'] ?? 0) as int,
        completedSurahs: (json['completedSurahs'] ?? 0) as int,
        language: (json['language'] ?? 'system') as String,
        theme: (json['theme'] ?? 'system') as String,
        reciter: (json['reciter'] ?? '') as String,
        translation: (json['translation'] ?? '') as String,
      );
}
