// Structured result of a Tajweed assessment, mirroring the AI service's
// JSON contract (see ai_service/app/schemas.py).

class TajweedLetter {
  final int index;
  final String letter;
  final String? heard;
  final String status; // correct|incorrect|unclear|missing|extra|substituted
  final String? rule;
  final double confidence;
  final double? start;
  final double? end;
  final String? feedback;

  const TajweedLetter({
    required this.index,
    required this.letter,
    this.heard,
    required this.status,
    this.rule,
    required this.confidence,
    this.start,
    this.end,
    this.feedback,
  });

  factory TajweedLetter.fromJson(Map<String, dynamic> j) => TajweedLetter(
        index: (j['index'] ?? 0) as int,
        letter: (j['letter'] ?? '') as String,
        heard: j['heard'] as String?,
        status: (j['status'] ?? 'correct') as String,
        rule: j['rule'] as String?,
        confidence: (j['confidence'] ?? 0).toDouble(),
        start: (j['start'] as num?)?.toDouble(),
        end: (j['end'] as num?)?.toDouble(),
        feedback: j['feedback'] as String?,
      );

  bool get isProblem =>
      status != 'correct' && status != 'unclear';
}

class TajweedError {
  final String rule;
  final String severity; // low|medium|high
  final int? letterIndex;
  final double? start;
  final double? end;
  final String? expected;
  final String? observed;
  final String feedback;

  const TajweedError({
    required this.rule,
    required this.severity,
    this.letterIndex,
    this.start,
    this.end,
    this.expected,
    this.observed,
    required this.feedback,
  });

  factory TajweedError.fromJson(Map<String, dynamic> j) => TajweedError(
        rule: (j['rule'] ?? '') as String,
        severity: (j['severity'] ?? 'low') as String,
        letterIndex: j['letter_index'] as int?,
        start: (j['start'] as num?)?.toDouble(),
        end: (j['end'] as num?)?.toDouble(),
        expected: j['expected'] as String?,
        observed: j['observed'] as String?,
        feedback: (j['feedback'] ?? '') as String,
      );
}

class TajweedWord {
  final int index;
  final String expected;
  final String? heard;
  final String status;
  final double confidence;

  const TajweedWord({
    required this.index,
    required this.expected,
    this.heard,
    required this.status,
    required this.confidence,
  });

  factory TajweedWord.fromJson(Map<String, dynamic> j) => TajweedWord(
        index: (j['index'] ?? 0) as int,
        expected: (j['expected'] ?? '') as String,
        heard: j['heard'] as String?,
        status: (j['status'] ?? 'correct') as String,
        confidence: (j['confidence'] ?? 0).toDouble(),
      );
}

class TajweedResult {
  final int score;
  final bool correct;
  final String transcript;
  final String reference;
  final double confidence;
  final List<TajweedLetter> letters;
  final List<TajweedWord> words;
  final List<TajweedError> errors;
  final double audioSeconds;
  final double speechSeconds;
  final double? wordsPerMinute;
  final List<String> feedback;
  final String engine;

  const TajweedResult({
    required this.score,
    required this.correct,
    required this.transcript,
    required this.reference,
    required this.confidence,
    required this.letters,
    required this.words,
    required this.errors,
    required this.audioSeconds,
    required this.speechSeconds,
    this.wordsPerMinute,
    required this.feedback,
    required this.engine,
  });

  factory TajweedResult.fromJson(Map<String, dynamic> j) {
    final timing = (j['timing'] ?? const {}) as Map<String, dynamic>;
    return TajweedResult(
      score: (j['score'] ?? 0) as int,
      correct: (j['correct'] ?? false) as bool,
      transcript: (j['transcript'] ?? '') as String,
      reference: (j['reference'] ?? '') as String,
      confidence: (j['confidence'] ?? 0).toDouble(),
      letters: [
        for (final l in (j['letters'] ?? []) as List)
          TajweedLetter.fromJson(l as Map<String, dynamic>),
      ],
      words: [
        for (final w in (j['words'] ?? []) as List)
          TajweedWord.fromJson(w as Map<String, dynamic>),
      ],
      errors: [
        for (final e in (j['tajweed_errors'] ?? []) as List)
          TajweedError.fromJson(e as Map<String, dynamic>),
      ],
      audioSeconds: (timing['audio_seconds'] ?? 0).toDouble(),
      speechSeconds: (timing['speech_seconds'] ?? 0).toDouble(),
      wordsPerMinute: (timing['words_per_minute'] as num?)?.toDouble(),
      feedback: [for (final f in (j['feedback'] ?? []) as List) f as String],
      engine: (j['engine'] ?? '') as String,
    );
  }
}
