// lib/data/courses.dart — SkillBridge AI

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// =============================================================================
// UTILITY: OPEN COURSE URL IN EXTERNAL BROWSER
// =============================================================================

void openCourseUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// =============================================================================
// PRIVATE CONSTANTS (Free providers)
// =============================================================================

const List<String> _kFreeProviderKeywords = [
  'youtube',
  'freecodecamp',
  'khan academy',
  'semrush academy',
  'edx',
  'hubspot',
  'google skillshop',
  'aws training',
  'tableau',
  'sqlzoo',
  'moz',
];

// =============================================================================
// §1  ENUMS & EXTENSIONS (Tavakoli 2022 taxonomy)
// =============================================================================

// ── 1.1  ContentLength ────────────────────────────────────────────────────────

enum ContentLength { short, medium, long }

extension ContentLengthExtension on ContentLength {
  String get displayName => switch (this) {
        ContentLength.short => 'Short',
        ContentLength.medium => 'Medium',
        ContentLength.long => 'Long',
      };
  String get description => switch (this) {
        ContentLength.short =>
          'Under 10 minutes — quick overviews or micro‑lessons',
        ContentLength.medium =>
          '10–20 minutes — focused lessons with some depth',
        ContentLength.long => 'Over 20 minutes — comprehensive deep‑dives',
      };
  IconData get icon => switch (this) {
        ContentLength.short => Icons.flash_on_rounded,
        ContentLength.medium => Icons.schedule_rounded,
        ContentLength.long => Icons.hourglass_bottom_rounded,
      };
  String get key => switch (this) {
        ContentLength.short => 'short',
        ContentLength.medium => 'medium',
        ContentLength.long => 'long',
      };
  String get preferenceKey => switch (this) {
        ContentLength.short => PreferenceKeys.lengthShort,
        ContentLength.medium => PreferenceKeys.lengthMedium,
        ContentLength.long => PreferenceKeys.lengthLong,
      };
  int get vectorIndex => switch (this) {
        ContentLength.short => 0,
        ContentLength.medium => 1,
        ContentLength.long => 2,
      };
  double get maxHours => switch (this) {
        ContentLength.short => 0.17,
        ContentLength.medium => 0.33,
        ContentLength.long => double.infinity,
      };
  static ContentLength fromKey(String key) =>
      switch (key.toLowerCase().trim()) {
        'short' => ContentLength.short,
        'long' => ContentLength.long,
        _ => ContentLength.medium,
      };
}

// ── 1.2  DetailLevel ──────────────────────────────────────────────────────────

enum DetailLevel { low, medium, high }

extension DetailLevelExtension on DetailLevel {
  String get displayName => switch (this) {
        DetailLevel.low => 'Overview',
        DetailLevel.medium => 'Standard',
        DetailLevel.high => 'In‑Depth',
      };
  String get description => switch (this) {
        DetailLevel.low =>
          'High‑level survey — key concepts without deep technical detail',
        DetailLevel.medium =>
          'Balanced coverage — concepts plus practical application',
        DetailLevel.high =>
          'Expert depth — full theory, edge cases, and advanced patterns',
      };
  Color get color => switch (this) {
        DetailLevel.low => const Color(0xFF78909C),
        DetailLevel.medium => const Color(0xFF1976D2),
        DetailLevel.high => const Color(0xFF6A1B9A),
      };
  IconData get icon => switch (this) {
        DetailLevel.low => Icons.layers_outlined,
        DetailLevel.medium => Icons.layers_rounded,
        DetailLevel.high => Icons.science_outlined,
      };
  String get key => switch (this) {
        DetailLevel.low => 'low',
        DetailLevel.medium => 'medium',
        DetailLevel.high => 'high',
      };
  String get preferenceKey => switch (this) {
        DetailLevel.low => PreferenceKeys.detailLow,
        DetailLevel.medium => PreferenceKeys.detailMedium,
        DetailLevel.high => PreferenceKeys.detailHigh,
      };
  int get vectorIndex => switch (this) {
        DetailLevel.low => 3,
        DetailLevel.medium => 4,
        DetailLevel.high => 5,
      };
  int get rank => switch (this) {
        DetailLevel.low => 1,
        DetailLevel.medium => 2,
        DetailLevel.high => 3,
      };
  static DetailLevel fromKey(String key) => switch (key.toLowerCase().trim()) {
        'low' => DetailLevel.low,
        'high' => DetailLevel.high,
        _ => DetailLevel.medium,
      };
}

// ── 1.3  LearningStrategy ─────────────────────────────────────────────────────

enum LearningStrategy { theoryOnly, exampleOnly, both }

extension LearningStrategyExtension on LearningStrategy {
  String get displayName => switch (this) {
        LearningStrategy.theoryOnly => 'Theory',
        LearningStrategy.exampleOnly => 'Examples',
        LearningStrategy.both => 'Theory + Examples',
      };
  String get description => switch (this) {
        LearningStrategy.theoryOnly =>
          'Conceptual explanations, definitions, and principles',
        LearningStrategy.exampleOnly =>
          'Worked examples, tutorials, and hands‑on practice',
        LearningStrategy.both =>
          'Balanced mix of theory and practical examples',
      };
  IconData get icon => switch (this) {
        LearningStrategy.theoryOnly => Icons.menu_book_outlined,
        LearningStrategy.exampleOnly => Icons.build_outlined,
        LearningStrategy.both => Icons.balance_outlined,
      };
  String get key => switch (this) {
        LearningStrategy.theoryOnly => 'theory',
        LearningStrategy.exampleOnly => 'example',
        LearningStrategy.both => 'both',
      };
  String get preferenceKey => switch (this) {
        LearningStrategy.theoryOnly => PreferenceKeys.strategyTheory,
        LearningStrategy.exampleOnly => PreferenceKeys.strategyExample,
        LearningStrategy.both => PreferenceKeys.strategyBoth,
      };
  int get vectorIndex => switch (this) {
        LearningStrategy.theoryOnly => 6,
        LearningStrategy.exampleOnly => 7,
        LearningStrategy.both => 8,
      };
  bool get includesExamples =>
      this == LearningStrategy.exampleOnly || this == LearningStrategy.both;
  bool get includesTheory =>
      this == LearningStrategy.theoryOnly || this == LearningStrategy.both;
  static LearningStrategy fromKey(String key) =>
      switch (key.toLowerCase().trim()) {
        'theory' => LearningStrategy.theoryOnly,
        'example' => LearningStrategy.exampleOnly,
        _ => LearningStrategy.both,
      };
}

// ── 1.4  ContentFormat ────────────────────────────────────────────────────────

enum ContentFormat { video, bookChapter, webPage, slide }

extension ContentFormatExtension on ContentFormat {
  String get displayName => switch (this) {
        ContentFormat.video => 'Video',
        ContentFormat.bookChapter => 'Book Chapter',
        ContentFormat.webPage => 'Web Page',
        ContentFormat.slide => 'Slides',
      };
  IconData get icon => switch (this) {
        ContentFormat.video => Icons.play_circle_outline_rounded,
        ContentFormat.bookChapter => Icons.menu_book_rounded,
        ContentFormat.webPage => Icons.language_rounded,
        ContentFormat.slide => Icons.slideshow_rounded,
      };
  Color get color => switch (this) {
        ContentFormat.video => const Color(0xFFD32F2F),
        ContentFormat.bookChapter => const Color(0xFF388E3C),
        ContentFormat.webPage => const Color(0xFF1976D2),
        ContentFormat.slide => const Color(0xFFF57C00),
      };
  String get key => switch (this) {
        ContentFormat.video => 'video',
        ContentFormat.bookChapter => 'book',
        ContentFormat.webPage => 'webpage',
        ContentFormat.slide => 'slide',
      };
  String get preferenceKey => switch (this) {
        ContentFormat.video => PreferenceKeys.contentVideo,
        ContentFormat.bookChapter => PreferenceKeys.contentBook,
        ContentFormat.webPage => PreferenceKeys.contentWebpage,
        ContentFormat.slide => PreferenceKeys.contentSlide,
      };
  int get vectorIndex => switch (this) {
        ContentFormat.video => 11,
        ContentFormat.bookChapter => 12,
        ContentFormat.webPage => 13,
        ContentFormat.slide => 14,
      };
  bool get isAsynchronous => this != ContentFormat.slide;
  static ContentFormat fromKey(String key) =>
      switch (key.toLowerCase().trim()) {
        'book' => ContentFormat.bookChapter,
        'webpage' => ContentFormat.webPage,
        'web' => ContentFormat.webPage,
        'slide' => ContentFormat.slide,
        'slides' => ContentFormat.slide,
        _ => ContentFormat.video,
      };
}

// ── 1.5  CourseLevel (seniority) ─────────────────────────────────────────────

enum CourseLevel {
  beginner('Beginner'),
  intermediate('Intermediate'),
  advanced('Advanced');

  const CourseLevel(this.value);
  final String value;

  static CourseLevel fromString(String raw) {
    for (final l in CourseLevel.values) {
      if (l.value.toLowerCase() == raw.toLowerCase().trim()) return l;
    }
    return CourseLevel.beginner;
  }

  int get rank => index + 1;
  Color get color => switch (this) {
        CourseLevel.beginner => const Color(0xFF388E3C),
        CourseLevel.intermediate => const Color(0xFF1976D2),
        CourseLevel.advanced => const Color(0xFF6A1B9A),
      };
  IconData get icon => switch (this) {
        CourseLevel.beginner => Icons.star_border_rounded,
        CourseLevel.intermediate => Icons.star_half_rounded,
        CourseLevel.advanced => Icons.star_rounded,
      };
  String get displayName => value;
}

// ── 1.6  CourseType (pedagogical format) ─────────────────────────────────────

enum CourseType {
  course('Course'),
  bootcamp('Bootcamp'),
  video('Video'),
  certificate('Certificate');

  const CourseType(this.value);
  final String value;

  static CourseType fromString(String raw) {
    for (final t in CourseType.values) {
      if (t.value.toLowerCase() == raw.toLowerCase().trim()) return t;
    }
    return CourseType.course;
  }

  bool get isCredential =>
      this == CourseType.certificate || this == CourseType.bootcamp;
  bool get isQuickFormat => this == CourseType.video;
  String get displayName => value;
  IconData get icon => switch (this) {
        CourseType.course => Icons.school_outlined,
        CourseType.bootcamp => Icons.rocket_launch_outlined,
        CourseType.video => Icons.play_circle_outline_rounded,
        CourseType.certificate => Icons.workspace_premium_outlined,
      };
}

// ── 1.7  CourseSortStrategy ───────────────────────────────────────────────────

enum CourseSortStrategy {
  ratingDesc,
  qualityScoreDesc,
  viewCountDesc,
  recommendationScoreDesc,
  detailLevelAsc,
  detailLevelDesc,
  titleAZ,
  freeFirst,
}

// =============================================================================
// §2  PreferenceKeys (15 canonical keys – matches CareerProfile)
// =============================================================================

abstract class PreferenceKeys {
  static const String lengthShort = 'length_short';
  static const String lengthMedium = 'length_medium';
  static const String lengthLong = 'length_long';
  static const String detailLow = 'detail_low';
  static const String detailMedium = 'detail_medium';
  static const String detailHigh = 'detail_high';
  static const String strategyTheory = 'strategy_theory';
  static const String strategyExample = 'strategy_example';
  static const String strategyBoth = 'strategy_both';
  static const String classBased = 'class_based';
  static const String nonClassBased = 'non_class_based';
  static const String contentVideo = 'format_video';
  static const String contentBook = 'format_book';
  static const String contentWebpage = 'format_web_page';
  static const String contentSlide = 'format_slide';

  static const List<String> all = [
    lengthShort,
    lengthMedium,
    lengthLong,
    detailLow,
    detailMedium,
    detailHigh,
    strategyTheory,
    strategyExample,
    strategyBoth,
    classBased,
    nonClassBased,
    contentVideo,
    contentBook,
    contentWebpage,
    contentSlide,
  ];
}

// =============================================================================
// §3  COURSEFILTER – immutable multi‑dimension filter
// =============================================================================

@immutable
class CourseFilter {
  final String category;
  final String provider;
  final CourseLevel? level;
  final CourseType? type;
  final ContentFormat? format;
  final ContentLength? length;
  final DetailLevel? detail;
  final LearningStrategy? strategy;
  final bool? isClassroomBased;
  final bool? isFree;
  final double minRating;
  final double minQualityScore;
  final List<String> anyOfSkills;
  final List<String> allOfSkills;

  const CourseFilter({
    this.category = 'All',
    this.provider = 'All',
    this.level,
    this.type,
    this.format,
    this.length,
    this.detail,
    this.strategy,
    this.isClassroomBased,
    this.isFree,
    this.minRating = 0.0,
    this.minQualityScore = 0.0,
    this.anyOfSkills = const [],
    this.allOfSkills = const [],
  });

  bool matches(Course course) {
    if (category != 'All' && course.category != category) return false;
    if (provider != 'All' && course.provider != provider) return false;
    if (level != null && course.courseLevelEnum != level) return false;
    if (type != null && course.courseTypeEnum != type) return false;
    if (format != null && course.contentFormat != format) return false;
    if (length != null && course.contentLength != length) return false;
    if (detail != null && course.detailLevel != detail) return false;
    if (strategy != null && course.learningStrategy != strategy) return false;
    if (isClassroomBased != null &&
        course.isClassroomBased != isClassroomBased) {
      return false;
    }
    if (isFree != null && course.isFree != isFree) return false;
    if (course.rating < minRating) return false;
    if (minQualityScore > 0.0 &&
        (course.qualityScore ?? 0.0) < minQualityScore) {
      return false;
    }

    if (anyOfSkills.isNotEmpty) {
      final lower = course.skills.map((s) => s.toLowerCase()).toSet();
      if (!anyOfSkills.any((s) => lower.contains(s.toLowerCase()))) {
        return false;
      }
    }
    if (allOfSkills.isNotEmpty) {
      final lower = course.skills.map((s) => s.toLowerCase()).toSet();
      if (!allOfSkills.every((s) => lower.contains(s.toLowerCase()))) {
        return false;
      }
    }
    return true;
  }

  CourseFilter copyWith({
    String? category,
    String? provider,
    Object? level = _unset,
    Object? type = _unset,
    Object? format = _unset,
    Object? length = _unset,
    Object? detail = _unset,
    Object? strategy = _unset,
    Object? isClassroomBased = _unset,
    Object? isFree = _unset,
    double? minRating,
    double? minQualityScore,
    List<String>? anyOfSkills,
    List<String>? allOfSkills,
  }) {
    return CourseFilter(
      category: category ?? this.category,
      provider: provider ?? this.provider,
      level: level is _Unset ? this.level : level as CourseLevel?,
      type: type is _Unset ? this.type : type as CourseType?,
      format: format is _Unset ? this.format : format as ContentFormat?,
      length: length is _Unset ? this.length : length as ContentLength?,
      detail: detail is _Unset ? this.detail : detail as DetailLevel?,
      strategy:
          strategy is _Unset ? this.strategy : strategy as LearningStrategy?,
      isClassroomBased: isClassroomBased is _Unset
          ? this.isClassroomBased
          : isClassroomBased as bool?,
      isFree: isFree is _Unset ? this.isFree : isFree as bool?,
      minRating: minRating ?? this.minRating,
      minQualityScore: minQualityScore ?? this.minQualityScore,
      anyOfSkills: anyOfSkills ?? this.anyOfSkills,
      allOfSkills: allOfSkills ?? this.allOfSkills,
    );
  }

  static const CourseFilter none = CourseFilter();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseFilter &&
          other.category == category &&
          other.provider == provider &&
          other.level == level &&
          other.type == type &&
          other.format == format &&
          other.length == length &&
          other.detail == detail &&
          other.strategy == strategy &&
          other.isClassroomBased == isClassroomBased &&
          other.isFree == isFree &&
          other.minRating == minRating &&
          other.minQualityScore == minQualityScore);
  @override
  int get hashCode => Object.hash(
      category,
      provider,
      level,
      type,
      format,
      length,
      detail,
      strategy,
      isClassroomBased,
      isFree,
      minRating,
      minQualityScore);
  @override
  String toString() =>
      'CourseFilter(category: $category, level: $level, format: $format, isFree: $isFree, minRating: $minRating)';
}

const _unset = _Unset();

class _Unset {
  const _Unset();
}

// =============================================================================
// §4  COURSESTATS – aggregate analytics
// =============================================================================

class CourseStats {
  final int total;
  final int freeCount;
  final double meanRating;
  final double meanQualityScore;
  final Map<String, int> countByCategory;
  final Map<String, int> countByProvider;
  final Map<String, int> countByLevel;
  final Map<String, int> countByFormat;
  final Map<String, int> countByLength;
  final int classroomCount;
  final int highDetailCount;
  final List<String> topSkills;

  const CourseStats({
    required this.total,
    required this.freeCount,
    required this.meanRating,
    required this.meanQualityScore,
    required this.countByCategory,
    required this.countByProvider,
    required this.countByLevel,
    required this.countByFormat,
    required this.countByLength,
    required this.classroomCount,
    required this.highDetailCount,
    required this.topSkills,
  });

  factory CourseStats.fromCourses(List<Course> list) {
    if (list.isEmpty) {
      return const CourseStats(
        total: 0,
        freeCount: 0,
        meanRating: 0,
        meanQualityScore: 0,
        countByCategory: {},
        countByProvider: {},
        countByLevel: {},
        countByFormat: {},
        countByLength: {},
        classroomCount: 0,
        highDetailCount: 0,
        topSkills: [],
      );
    }
    double ratingSum = 0, qualitySum = 0;
    int qualityCount = 0;
    final byCategory = <String, int>{},
        byProvider = <String, int>{},
        byLevel = <String, int>{};
    final byFormat = <String, int>{}, byLength = <String, int>{};
    final skillFreq = <String, int>{};
    for (final c in list) {
      ratingSum += c.rating;
      if (c.qualityScore != null) {
        qualitySum += c.qualityScore!;
        qualityCount++;
      }
      byCategory[c.category] = (byCategory[c.category] ?? 0) + 1;
      byProvider[c.provider] = (byProvider[c.provider] ?? 0) + 1;
      byLevel[c.level] = (byLevel[c.level] ?? 0) + 1;
      byFormat[c.contentFormat.displayName] =
          (byFormat[c.contentFormat.displayName] ?? 0) + 1;
      byLength[c.contentLength.displayName] =
          (byLength[c.contentLength.displayName] ?? 0) + 1;
      for (final s in c.skills) {
        skillFreq[s.toLowerCase()] = (skillFreq[s.toLowerCase()] ?? 0) + 1;
      }
    }
    final topSkills = (skillFreq.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(10)
        .map((e) => e.key)
        .toList();
    return CourseStats(
      total: list.length,
      freeCount: list.where((c) => c.isFree).length,
      meanRating: ratingSum / list.length,
      meanQualityScore: qualityCount > 0 ? qualitySum / qualityCount : 0.0,
      countByCategory: Map.unmodifiable(byCategory),
      countByProvider: Map.unmodifiable(byProvider),
      countByLevel: Map.unmodifiable(byLevel),
      countByFormat: Map.unmodifiable(byFormat),
      countByLength: Map.unmodifiable(byLength),
      classroomCount: list.where((c) => c.isClassroomBased).length,
      highDetailCount:
          list.where((c) => c.detailLevel == DetailLevel.high).length,
      topSkills: topSkills,
    );
  }

  double get freeRatio => total > 0 ? freeCount / total : 0.0;
  double get classroomRatio => total > 0 ? classroomCount / total : 0.0;
  String get dominantCategory => countByCategory.isEmpty
      ? 'N/A'
      : (countByCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .first
          .key;
  @override
  String toString() =>
      'CourseStats(total: $total, free: $freeCount, meanRating: ${meanRating.toStringAsFixed(2)}, dominantCategory: $dominantCategory)';
}

// =============================================================================
// §5  COURSERECOMMENDATION & LEARNERPROGRESSSNAPSHOT
// =============================================================================

@immutable
class CourseRecommendation {
  final Course course;
  final double score;
  final double dotProduct;
  final double skillBoost;
  const CourseRecommendation(
      {required this.course,
      required this.score,
      required this.dotProduct,
      required this.skillBoost});
  String get scorePercent => '${(score * 100).round()}%';
  bool get isHighRelevance => score >= 0.5;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseRecommendation && other.course.id == course.id);
  @override
  int get hashCode => course.id.hashCode;
  @override
  String toString() =>
      'CourseRecommendation(course: "${course.title}", score: ${score.toStringAsFixed(3)})';
}

@immutable
class LearnerProgressSnapshot {
  final int courseId;
  final String courseTitle;
  final double completionRatio;
  final bool passedSkillAssessment;
  final String? lastAccessedAt;
  const LearnerProgressSnapshot(
      {required this.courseId,
      required this.courseTitle,
      required this.completionRatio,
      required this.passedSkillAssessment,
      this.lastAccessedAt});
  String get completionPercent => '${(completionRatio * 100).round()}%';
  String get statusLabel {
    if (completionRatio <= 0.0) return 'Not Started';
    if (completionRatio >= 1.0) return 'Completed';
    return 'In Progress';
  }

  bool get isCompleted => completionRatio >= 1.0;
  bool get isStarted => completionRatio > 0.0;
  int estimatedMinutesRemaining(int totalEstimatedMinutes) =>
      ((1.0 - completionRatio) * totalEstimatedMinutes).round();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearnerProgressSnapshot && other.courseId == courseId);
  @override
  int get hashCode => courseId.hashCode;
  @override
  String toString() =>
      'LearnerProgressSnapshot(course: "$courseTitle", completion: $completionPercent, status: $statusLabel)';
}

// =============================================================================
// §6  COURSE MODEL – comprehensive (includes all fields from both files)
// =============================================================================

@immutable
class Course {
  final int id;
  final String title;
  final String provider;
  final String level;
  final String type;
  final String url;
  final String category;
  final String duration;
  final String language;
  final double rating;
  final List<String> skills;
  final bool isFree;
  final List<String> topics;
  final double? qualityScore;
  final String contentTypeString;
  final String detailLevelString;
  final String lengthCategoryString;
  final String strategyString;
  final bool isClassBased;
  final Map<String, double> featureVector;
  final List<Map<String, dynamic>> mcqQuestions;
  final int? viewCount;
  final ContentLength contentLength;
  final DetailLevel detailLevel;
  final LearningStrategy learningStrategy;
  final bool isClassroomBased;
  final ContentFormat contentFormat;
  final List<String> topicsCovert;
  final String? transcriptSummary;
  final String? thumbnailUrl;
  final CourseRecommendation? recommendation;
  final LearnerProgressSnapshot? progress;

  const Course({
    required this.id,
    required this.title,
    required this.provider,
    required this.level,
    required this.type,
    required this.url,
    required this.category,
    required this.duration,
    required this.language,
    required this.rating,
    required this.skills,
    this.isFree = false,
    this.topics = const [],
    this.qualityScore,
    this.contentTypeString = 'video',
    this.detailLevelString = 'medium',
    this.lengthCategoryString = 'medium',
    this.strategyString = 'both',
    this.isClassBased = false,
    this.featureVector = const {},
    this.mcqQuestions = const [],
    this.viewCount,
    this.contentLength = ContentLength.medium,
    this.detailLevel = DetailLevel.medium,
    this.learningStrategy = LearningStrategy.both,
    this.isClassroomBased = false,
    this.contentFormat = ContentFormat.video,
    this.topicsCovert = const [],
    this.transcriptSummary,
    this.thumbnailUrl,
    this.recommendation,
    this.progress,
  });

  // Typed getters
  CourseLevel get courseLevelEnum => CourseLevel.fromString(level);
  CourseType get courseTypeEnum => CourseType.fromString(type);

  // Feature vector (15‑dim one‑hot)
  List<double> toFeatureVector() {
    final v = List<double>.filled(15, 0.0);
    v[contentLength.vectorIndex] = 1.0;
    v[detailLevel.vectorIndex] = 1.0;
    v[learningStrategy.vectorIndex] = 1.0;
    v[isClassroomBased ? 9 : 10] = 1.0;
    v[contentFormat.vectorIndex] = 1.0;
    return v;
  }

  Map<String, double> computeFeatureVector() {
    const keys = PreferenceKeys.all;
    final list = toFeatureVector();
    return {for (var i = 0; i < keys.length; i++) keys[i]: list[i]};
  }

  double dotProductWith(Map<String, double> prefVector) {
    if (prefVector.isEmpty) return 0.0;
    final vec = featureVector.isEmpty ? computeFeatureVector() : featureVector;
    return PreferenceKeys.all.fold(
        0.0, (sum, key) => sum + (vec[key] ?? 0.0) * (prefVector[key] ?? 0.0));
  }

  double dotProductWithList(List<double> prefVector) {
    assert(prefVector.length == 15,
        'prefVector must be 15‑dimensional; got ${prefVector.length}');
    final courseVec = toFeatureVector();
    double dot = 0.0;
    for (int i = 0; i < 15; i++) {
      dot += courseVec[i] * prefVector[i];
    }
    return dot;
  }

  double cosineSimilarity(List<double> prefVector) {
    assert(prefVector.length == 15);
    final a = toFeatureVector();
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < 15; i++) {
      dot += a[i] * prefVector[i];
      normA += a[i] * a[i];
      normB += prefVector[i] * prefVector[i];
    }
    final denom = normA * normB;
    return denom == 0.0 ? 0.0 : dot / dartSqrt(denom);
  }

  // Duration helpers
  String get formattedDuration {
    final raw = duration.trim().toLowerCase();
    if (raw.contains('self') || raw.contains('paced')) return 'Self-paced';
    final weeksMatch = RegExp(r'^(\d+)\s*week').firstMatch(raw);
    if (weeksMatch != null) return '${weeksMatch.group(1)} wks';
    final monthsMatch = RegExp(r'^(\d+)\s*month').firstMatch(raw);
    if (monthsMatch != null) return '${monthsMatch.group(1)} mo';
    final hoursMatch = RegExp(r'^(\d+)\s*h').firstMatch(raw);
    if (hoursMatch != null) return '${hoursMatch.group(1)} h';
    final minsMatch = RegExp(r'^(\d+)\s*min').firstMatch(raw);
    if (minsMatch != null) return '${minsMatch.group(1)} min';
    return duration;
  }

  double? get estimatedHours {
    final raw = duration.trim().toLowerCase();
    if (raw.contains('self') || raw.contains('paced')) return null;
    final weeks = RegExp(r'^(\d+)\s*week').firstMatch(raw);
    if (weeks != null) return double.tryParse(weeks.group(1)!)! * 5.0;
    final months = RegExp(r'^(\d+)\s*month').firstMatch(raw);
    if (months != null) return double.tryParse(months.group(1)!)! * 20.0;
    final hours = RegExp(r'^(\d+(?:\.\d+)?)\s*h').firstMatch(raw);
    if (hours != null) return double.tryParse(hours.group(1)!);
    final mins = RegExp(r'^(\d+)\s*min').firstMatch(raw);
    if (mins != null) {
      final m = double.tryParse(mins.group(1)!);
      return m != null ? m / 60.0 : null;
    }
    return null;
  }

  // Quality & rating
  bool get passesQualityFilter => qualityScore == null || qualityScore! >= 0.5;
  bool get isHighQuality => (qualityScore ?? 0.0) >= 0.85;
  bool get isTopRated => rating >= 4.7;
  bool get hasThumbnail => thumbnailUrl != null && thumbnailUrl!.isNotEmpty;
  bool get hasSummary =>
      transcriptSummary != null && transcriptSummary!.isNotEmpty;
  double get normalizedRating => (rating / 5.0).clamp(0.0, 1.0);
  double get compositeScore =>
      ((qualityScore ?? 0.5) * 0.60 + normalizedRating * 0.40).clamp(0.0, 1.0);
  String get compositeScorePercent => '${(compositeScore * 100).round()}%';

  // MCQ
  List<Map<String, dynamic>> get progressQuestions =>
      mcqQuestions.where((q) => q['type'] == 'progress').toList();
  List<Map<String, dynamic>> get skillQuestions =>
      mcqQuestions.where((q) => q['type'] == 'skill').toList();
  bool get hasMcqQuestions => mcqQuestions.isNotEmpty;

  // Topics & skills
  List<String> get allTopics => [...topics, ...topicsCovert];
  int get totalTopicCount => allTopics.toSet().length;
  bool coversTopic(String topic) =>
      allTopics.any((t) => t.toLowerCase().contains(topic.toLowerCase()));
  double matchScore(List<String> missingSkills) {
    if (missingSkills.isEmpty) return 0.0;
    final lower = missingSkills.map((s) => s.toLowerCase()).toSet();
    final matched = skills.where((s) => lower.contains(s.toLowerCase())).length;
    return (matched / missingSkills.length).clamp(0.0, 1.0);
  }

  bool coversAnySkill(List<String> targetSkills) => skills
      .any((s) => targetSkills.any((t) => t.toLowerCase() == s.toLowerCase()));
  bool coversAllSkills(List<String> targetSkills) => targetSkills
      .every((t) => skills.any((s) => s.toLowerCase() == t.toLowerCase()));

  // Delivery
  bool get isSelfPaced =>
      !isClassroomBased && duration.toLowerCase().contains('self');
  bool get isStructuredSchedule =>
      isClassroomBased || duration.toLowerCase().contains('week');
  bool get isCertificateLevel => courseTypeEnum.isCredential;

  // Progress
  bool get hasProgress => progress != null;
  bool get isCompleted => progress?.isCompleted ?? false;
  bool get isStarted => progress?.isStarted ?? false;
  String get progressLabel => progress?.completionPercent ?? 'Not Started';

  // Composite predicates
  bool get isPremiumFree => isFree && isHighQuality && isTopRated;
  bool get isEntryFriendly =>
      courseLevelEnum == CourseLevel.beginner &&
      detailLevel.rank <= DetailLevel.medium.rank;

  // copyWith
  Course copyWith({
    int? id,
    String? title,
    String? provider,
    String? level,
    String? type,
    String? url,
    String? category,
    String? duration,
    String? language,
    double? rating,
    List<String>? skills,
    bool? isFree,
    List<String>? topics,
    Object? qualityScore = _unset,
    String? contentTypeString,
    String? detailLevelString,
    String? lengthCategoryString,
    String? strategyString,
    bool? isClassBased,
    Map<String, double>? featureVector,
    List<Map<String, dynamic>>? mcqQuestions,
    Object? viewCount = _unset,
    ContentLength? contentLength,
    DetailLevel? detailLevel,
    LearningStrategy? learningStrategy,
    bool? isClassroomBased,
    ContentFormat? contentFormat,
    List<String>? topicsCovert,
    Object? transcriptSummary = _unset,
    Object? thumbnailUrl = _unset,
    Object? recommendation = _unset,
    Object? progress = _unset,
    bool clearQualityScore = false,
    bool clearViewCount = false,
    bool clearTranscriptSummary = false,
    bool clearThumbnailUrl = false,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      provider: provider ?? this.provider,
      level: level ?? this.level,
      type: type ?? this.type,
      url: url ?? this.url,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      language: language ?? this.language,
      rating: rating ?? this.rating,
      skills: skills ?? this.skills,
      isFree: isFree ?? this.isFree,
      topics: topics ?? this.topics,
      qualityScore: clearQualityScore
          ? null
          : (qualityScore is _Unset
              ? this.qualityScore
              : qualityScore as double?),
      contentTypeString: contentTypeString ?? this.contentTypeString,
      detailLevelString: detailLevelString ?? this.detailLevelString,
      lengthCategoryString: lengthCategoryString ?? this.lengthCategoryString,
      strategyString: strategyString ?? this.strategyString,
      isClassBased: isClassBased ?? this.isClassBased,
      featureVector: featureVector ?? this.featureVector,
      mcqQuestions: mcqQuestions ?? this.mcqQuestions,
      viewCount: clearViewCount
          ? null
          : (viewCount is _Unset ? this.viewCount : viewCount as int?),
      contentLength: contentLength ?? this.contentLength,
      detailLevel: detailLevel ?? this.detailLevel,
      learningStrategy: learningStrategy ?? this.learningStrategy,
      isClassroomBased: isClassroomBased ?? this.isClassroomBased,
      contentFormat: contentFormat ?? this.contentFormat,
      topicsCovert: topicsCovert ?? this.topicsCovert,
      transcriptSummary: clearTranscriptSummary
          ? null
          : (transcriptSummary is _Unset
              ? this.transcriptSummary
              : transcriptSummary as String?),
      thumbnailUrl: clearThumbnailUrl
          ? null
          : (thumbnailUrl is _Unset
              ? this.thumbnailUrl
              : thumbnailUrl as String?),
      recommendation: recommendation is _Unset
          ? this.recommendation
          : recommendation as CourseRecommendation?,
      progress: progress is _Unset
          ? this.progress
          : progress as LearnerProgressSnapshot?,
    );
  }

  // Serialization
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'provider': provider,
        'level': level,
        'type': type,
        'url': url,
        'category': category,
        'duration': duration,
        'language': language,
        'rating': rating,
        'skills': skills,
        'isFree': isFree,
        'topics': topics,
        'qualityScore': qualityScore,
        'contentTypeString': contentTypeString,
        'detailLevelString': detailLevelString,
        'lengthCategoryString': lengthCategoryString,
        'strategyString': strategyString,
        'isClassBased': isClassBased,
        'featureVector': featureVector,
        'mcqQuestions': mcqQuestions,
        'viewCount': viewCount,
        'contentLength': contentLength.key,
        'detailLevel': detailLevel.key,
        'learningStrategy': learningStrategy.key,
        'isClassroomBased': isClassroomBased,
        'contentFormat': contentFormat.key,
        'topicsCovert': topicsCovert,
        'transcriptSummary': transcriptSummary,
        'thumbnailUrl': thumbnailUrl,
      };

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: (map['id'] as num?)?.toInt() ?? 0,
      title: (map['title'] as String?) ?? '',
      provider: (map['provider'] as String?) ?? '',
      level: (map['level'] as String?) ?? 'Beginner',
      type: (map['type'] as String?) ?? 'Course',
      url: (map['url'] as String?) ?? '',
      category: (map['category'] as String?) ?? '',
      duration: (map['duration'] as String?) ?? '',
      language: (map['language'] as String?) ?? 'English',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      skills: _castStringList(map['skills']),
      isFree: (map['isFree'] as bool?) ?? false,
      topics: _castStringList(map['topics']),
      qualityScore: (map['qualityScore'] as num?)?.toDouble(),
      contentTypeString: (map['contentTypeString'] as String?) ?? 'video',
      detailLevelString: (map['detailLevelString'] as String?) ?? 'medium',
      lengthCategoryString:
          (map['lengthCategoryString'] as String?) ?? 'medium',
      strategyString: (map['strategyString'] as String?) ?? 'both',
      isClassBased: (map['isClassBased'] as bool?) ?? false,
      featureVector: _parseDoubleMap(map['featureVector']),
      mcqQuestions: _parseMcqList(map['mcqQuestions']),
      viewCount: (map['viewCount'] as num?)?.toInt(),
      contentLength: ContentLengthExtension.fromKey(
          (map['contentLength'] as String?) ?? 'medium'),
      detailLevel: DetailLevelExtension.fromKey(
          (map['detailLevel'] as String?) ?? 'medium'),
      learningStrategy: LearningStrategyExtension.fromKey(
          (map['learningStrategy'] as String?) ?? 'both'),
      isClassroomBased: (map['isClassroomBased'] as bool?) ?? false,
      contentFormat: ContentFormatExtension.fromKey(
          (map['contentFormat'] as String?) ?? 'video'),
      topicsCovert: _castStringList(map['topicsCovert']),
      transcriptSummary: map['transcriptSummary'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Course && other.id == id && other.title == title);
  @override
  int get hashCode => Object.hash(id, title);
  @override
  String toString() =>
      'Course(id: $id, title: "$title", provider: "$provider", level: ${courseLevelEnum.displayName}, type: ${courseTypeEnum.displayName}, contentLength: ${contentLength.displayName}, detailLevel: ${detailLevel.displayName}, format: ${contentFormat.displayName}, rating: $rating, qualityScore: ${qualityScore?.toStringAsFixed(2) ?? "null"}, isFree: $isFree)';
}

// =============================================================================
// §7  COURSE EXTENSIONS
// =============================================================================

extension CourseComparison on Course {
  int compareRatingTo(Course other) => other.rating.compareTo(rating);
  int compareQualityTo(Course other) =>
      (other.qualityScore ?? 0.0).compareTo(qualityScore ?? 0.0);
  int compareViewCountTo(Course other) =>
      (other.viewCount ?? 0).compareTo(viewCount ?? 0);
}

extension CourseNullableHelpers on Course {
  String get qualityDisplay =>
      qualityScore != null ? '${(qualityScore! * 100).round()}%' : 'Unscored';
  String get viewCountDisplay =>
      viewCount != null ? _formatViewCount(viewCount!) : 'N/A';
  static String _formatViewCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toString();
  }
}

// =============================================================================
// §8  MATH HELPER (standalone sqrt)
// =============================================================================

double dartSqrt(double x) {
  if (x <= 0.0) return 0.0;
  double r = x;
  for (int i = 0; i < 20; i++) {
    r = (r + x / r) * 0.5;
  }
  return r;
}

// =============================================================================
// §9  PRIVATE HELPERS FOR SERIALIZATION
// =============================================================================

List<String> _castStringList(dynamic raw) {
  if (raw == null) return const [];
  if (raw is List<String>) return raw;
  try {
    return (raw as List).map((e) => e.toString()).toList();
  } catch (_) {
    return const [];
  }
}

Map<String, double> _parseDoubleMap(dynamic raw) {
  if (raw == null) return {};
  if (raw is Map<String, double>) return Map<String, double>.from(raw);
  try {
    return Map<String, double>.fromEntries((raw as Map)
        .entries
        .map((e) => MapEntry(e.key.toString(), (e.value as num).toDouble())));
  } catch (_) {
    return {};
  }
}

List<Map<String, dynamic>> _parseMcqList(dynamic raw) {
  if (raw == null) return const [];
  try {
    return (raw as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  } catch (_) {
    return const [];
  }
}

// =============================================================================
// §10  CONVERSION HELPER (turns simple course data into full Course objects)
// =============================================================================

/// Internal use only – converts a “simple” course (like those from the first dataset)
/// into a full [Course] instance with all fields properly derived.
Course _toFullCourse({
  required int id,
  required String title,
  required String provider,
  required String level,
  required String type,
  required String url,
  required String category,
  required String duration,
  required String language,
  required double rating,
  required List<String> skills,
}) {
  // isFree from provider keywords
  final isFree =
      _kFreeProviderKeywords.any((kw) => provider.toLowerCase().contains(kw));

  // qualityScore (same formula as first file's getter)
  final qualityScore = ((rating / 5.0) * 0.55) +
      ((skills.length / 12.0).clamp(0.0, 1.0) * 0.30) +
      (isFree ? 0.10 : 0.00) +
      (level == 'Advanced' ? 0.05 : 0.00);

  // contentTypeString
  final typeLow = type.toLowerCase();
  final providerLow = provider.toLowerCase();
  final contentTypeString = switch (typeLow) {
    'video' => 'Video',
    'bootcamp' || 'certification' => 'Interactive',
    'specialisation' => 'Video',
    _ => providerLow.contains('youtube') || providerLow.contains('khan')
        ? 'Video'
        : 'Web Page',
  };

  // detailLevelString & detailLevel enum
  final detailLevelString = switch (level) {
    'Beginner' => 'low',
    'Intermediate' => 'medium',
    'Advanced' => 'high',
    _ => 'medium',
  };
  final detailLevelEnum = DetailLevelExtension.fromKey(detailLevelString);

  // lengthCategoryString & contentLength enum from duration
  String lengthCategoryString = 'medium';
  ContentLength contentLengthEnum = ContentLength.medium;
  final durLow = duration.toLowerCase();
  if (durLow.contains('month')) {
    lengthCategoryString = 'long';
    contentLengthEnum = ContentLength.long;
  } else if (durLow.contains('week')) {
    final w = RegExp(r'(\d+)').firstMatch(durLow);
    if (w != null) {
      final weeks = int.tryParse(w.group(1)!) ?? 0;
      if (weeks <= 3) {
        lengthCategoryString = 'short';
        contentLengthEnum = ContentLength.short;
      } else if (weeks <= 6) {
        lengthCategoryString = 'medium';
        contentLengthEnum = ContentLength.medium;
      } else {
        lengthCategoryString = 'long';
        contentLengthEnum = ContentLength.long;
      }
    } else {
      lengthCategoryString = 'medium';
      contentLengthEnum = ContentLength.medium;
    }
  } else if (durLow.contains('hour')) {
    final h = RegExp(r'(\d+)').firstMatch(durLow);
    if (h != null) {
      final hours = int.tryParse(h.group(1)!) ?? 0;
      if (hours <= 6) {
        lengthCategoryString = 'short';
        contentLengthEnum = ContentLength.short;
      } else if (hours <= 20) {
        lengthCategoryString = 'medium';
        contentLengthEnum = ContentLength.medium;
      } else {
        lengthCategoryString = 'long';
        contentLengthEnum = ContentLength.long;
      }
    } else {
      lengthCategoryString = 'medium';
      contentLengthEnum = ContentLength.medium;
    }
  } else if (durLow.contains('min')) {
    final m = RegExp(r'(\d+)').firstMatch(durLow);
    if (m != null) {
      final mins = int.tryParse(m.group(1)!) ?? 0;
      if (mins < 10) {
        lengthCategoryString = 'short';
        contentLengthEnum = ContentLength.short;
      } else if (mins <= 20) {
        lengthCategoryString = 'medium';
        contentLengthEnum = ContentLength.medium;
      } else {
        lengthCategoryString = 'long';
        contentLengthEnum = ContentLength.long;
      }
    } else {
      lengthCategoryString = 'medium';
      contentLengthEnum = ContentLength.medium;
    }
  }

  // strategyString & learningStrategy
  final strategyString = 'both';
  final learningStrategyEnum = LearningStrategy.both;

  // contentFormat enum
  final contentFormatEnum = (providerLow.contains('youtube') ||
          providerLow.contains('khan') ||
          typeLow == 'video')
      ? ContentFormat.video
      : (typeLow == 'bootcamp' ? ContentFormat.webPage : ContentFormat.video);

  return Course(
    id: id,
    title: title,
    provider: provider,
    level: level,
    type: type,
    url: url,
    category: category,
    duration: duration,
    language: language,
    rating: rating,
    skills: skills,
    isFree: isFree,
    topics: const [],
    qualityScore: qualityScore,
    contentTypeString: contentTypeString,
    detailLevelString: detailLevelString,
    lengthCategoryString: lengthCategoryString,
    strategyString: strategyString,
    isClassBased: false,
    featureVector: const {},
    mcqQuestions: const [],
    viewCount: null,
    contentLength: contentLengthEnum,
    detailLevel: detailLevelEnum,
    learningStrategy: learningStrategyEnum,
    isClassroomBased: false,
    contentFormat: contentFormatEnum,
    topicsCovert: const [],
    transcriptSummary: null,
    thumbnailUrl: null,
    recommendation: null,
    progress: null,
  );
}

// =============================================================================
// §11  MASTER COURSE LIST – 78 courses (42 from first file + 36 from second)
// =============================================================================

final List<Course> courses = [
  // --------------------------------------------------------------------------
  // PART A: 42 courses imported from the first file (SkillBridge AI v5.0 dataset)
  // --------------------------------------------------------------------------
  // Software & Data Science (IDs 1–14)
  _toFullCourse(
    id: 1,
    title: 'Python for Everybody – Full Course',
    provider: 'YouTube (freeCodeCamp)',
    level: 'Beginner',
    type: 'Video',
    url: 'https://www.youtube.com/watch?v=8DvywoWv6fI',
    category: 'Data Science',
    duration: '14 hours',
    language: 'English',
    rating: 4.8,
    skills: [
      'python',
      'data analysis',
      'pandas',
      'numpy',
      'matplotlib',
      'loops',
      'functions'
    ],
  ),
  _toFullCourse(
    id: 2,
    title: 'Python 3 Programming Specialization',
    provider: 'Coursera',
    level: 'Beginner',
    type: 'Specialisation',
    url: 'https://www.coursera.org/specializations/python-3-programming',
    category: 'Programming',
    duration: '5 months',
    language: 'English',
    rating: 4.7,
    skills: [
      'python',
      'oop',
      'data analysis',
      'pandas',
      'numpy',
      'file handling',
      'algorithms'
    ],
  ),
  _toFullCourse(
    id: 3,
    title: 'Java Programming Masterclass',
    provider: 'Udemy',
    level: 'Beginner',
    type: 'Course',
    url:
        'https://www.udemy.com/course/java-the-complete-java-developer-course/',
    category: 'Software Engineering',
    duration: '80 hours',
    language: 'English',
    rating: 4.6,
    skills: [
      'java',
      'oop',
      'spring boot',
      'sql',
      'git',
      'testing',
      'microservices',
      'rest api'
    ],
  ),
  _toFullCourse(
    id: 4,
    title: 'Java Programming Tutorial – Full Course',
    provider: 'YouTube (freeCodeCamp)',
    level: 'Beginner',
    type: 'Video',
    url: 'https://www.youtube.com/watch?v=A74TOX803D0',
    category: 'Software Engineering',
    duration: '9 hours',
    language: 'English',
    rating: 4.7,
    skills: ['java', 'oop', 'data structures', 'algorithms'],
  ),
  _toFullCourse(
    id: 5,
    title: 'C++ Tutorial for Beginners – Full Course',
    provider: 'YouTube (freeCodeCamp)',
    level: 'Beginner',
    type: 'Video',
    url: 'https://www.youtube.com/watch?v=vLnPwxZdW4Y',
    category: 'Software Engineering',
    duration: '4 hours',
    language: 'English',
    rating: 4.6,
    skills: ['c++', 'oop', 'algorithms', 'data structures', 'pointers'],
  ),
  _toFullCourse(
    id: 6,
    title: 'SQL for Data Science',
    provider: 'Coursera (UC Davis)',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.coursera.org/learn/sql-for-data-science',
    category: 'Data Science',
    duration: '4 weeks',
    language: 'English',
    rating: 4.6,
    skills: [
      'sql',
      'database',
      'data analysis',
      'joins',
      'aggregation',
      'subqueries'
    ],
  ),
  _toFullCourse(
    id: 7,
    title: 'SQLZoo – Interactive SQL Tutorial',
    provider: 'SQLZoo',
    level: 'Beginner',
    type: 'Course',
    url: 'https://sqlzoo.net',
    category: 'Data Science',
    duration: 'Self-paced',
    language: 'English',
    rating: 4.5,
    skills: ['sql', 'database', 'joins', 'aggregation', 'data analysis'],
  ),
  _toFullCourse(
    id: 8,
    title: 'The Complete React Course 2024',
    provider: 'Udemy',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.udemy.com/course/react-the-complete-guide-incl-redux/',
    category: 'Web Development',
    duration: '28 hours',
    language: 'English',
    rating: 4.8,
    skills: [
      'react',
      'javascript',
      'typescript',
      'redux',
      'hooks',
      'rest api',
      'api integration'
    ],
  ),
  _toFullCourse(
    id: 9,
    title: 'Machine Learning Specialization',
    provider: 'Coursera (Andrew Ng)',
    level: 'Intermediate',
    type: 'Specialisation',
    url:
        'https://www.coursera.org/specializations/machine-learning-introduction',
    category: 'Data Science',
    duration: '3 months',
    language: 'English',
    rating: 4.9,
    skills: [
      'machine learning',
      'python',
      'statistical analysis',
      'neural networks',
      'supervised learning',
      'unsupervised learning',
      'data analysis'
    ],
  ),
  _toFullCourse(
    id: 10,
    title: 'Intro to Machine Learning – Full Course',
    provider: 'YouTube (freeCodeCamp)',
    level: 'Beginner',
    type: 'Video',
    url: 'https://www.youtube.com/watch?v=NWONeJKn6kc',
    category: 'Data Science',
    duration: '10 hours',
    language: 'English',
    rating: 4.6,
    skills: [
      'machine learning',
      'python',
      'scikit-learn',
      'data analysis',
      'pandas',
      'numpy'
    ],
  ),
  _toFullCourse(
    id: 11,
    title: 'AWS Cloud Practitioner Essentials',
    provider: 'AWS Training',
    level: 'Beginner',
    type: 'Certification',
    url:
        'https://aws.amazon.com/training/digital/aws-cloud-practitioner-essentials/',
    category: 'Cloud Computing',
    duration: '6 hours',
    language: 'English',
    rating: 4.6,
    skills: [
      'aws',
      'cloud computing',
      'devops',
      'linux',
      'networking',
      'security'
    ],
  ),
  _toFullCourse(
    id: 12,
    title: 'Flutter & Dart – The Complete Guide',
    provider: 'Udemy (Maximilian Schwarzmüller)',
    level: 'Beginner',
    type: 'Course',
    url:
        'https://www.udemy.com/course/learn-flutter-dart-to-build-ios-android-apps/',
    category: 'Mobile Development',
    duration: '42 hours',
    language: 'English',
    rating: 4.8,
    skills: [
      'flutter',
      'dart',
      'ui',
      'state management',
      'rest api',
      'firebase',
      'widgets'
    ],
  ),
  _toFullCourse(
    id: 13,
    title: 'Git and GitHub Crash Course',
    provider: 'YouTube (freeCodeCamp)',
    level: 'Beginner',
    type: 'Video',
    url: 'https://www.youtube.com/watch?v=RGOj5yH7evk',
    category: 'Version Control',
    duration: '1 hour',
    language: 'English',
    rating: 4.8,
    skills: ['git', 'github', 'version control', 'branching', 'commits'],
  ),
  _toFullCourse(
    id: 14,
    title: 'Deep Learning Specialization',
    provider: 'Coursera (DeepLearning.AI)',
    level: 'Advanced',
    type: 'Specialisation',
    url: 'https://www.coursera.org/specializations/deep-learning',
    category: 'Data Science',
    duration: '5 months',
    language: 'English',
    rating: 4.9,
    skills: [
      'python',
      'tensorflow',
      'deep learning',
      'machine learning',
      'numpy',
      'neural networks',
      'nlp',
      'statistical analysis'
    ],
  ),
  // Finance (IDs 15–19)
  _toFullCourse(
    id: 15,
    title: 'Excel for Beginners – Full Course',
    provider: 'YouTube (Kevin Stratvert)',
    level: 'Beginner',
    type: 'Video',
    url: 'https://www.youtube.com/watch?v=Vl0H-qTclOg',
    category: 'Finance',
    duration: '3 hours',
    language: 'English',
    rating: 4.7,
    skills: [
      'excel',
      'data analysis',
      'reporting',
      'pivot tables',
      'data visualization'
    ],
  ),
  _toFullCourse(
    id: 16,
    title: 'Excel Skills for Business Specialization',
    provider: 'Coursera (Macquarie)',
    level: 'Beginner',
    type: 'Specialisation',
    url: 'https://www.coursera.org/specializations/excel',
    category: 'Finance',
    duration: '3 months',
    language: 'English',
    rating: 4.8,
    skills: [
      'excel',
      'financial modeling',
      'data analysis',
      'pivot tables',
      'reporting'
    ],
  ),
  _toFullCourse(
    id: 17,
    title: 'Financial Modeling & Valuation Analyst (FMVA)',
    provider: 'CFI (Corporate Finance Institute)',
    level: 'Intermediate',
    type: 'Certification',
    url:
        'https://corporatefinanceinstitute.com/certifications/financial-modeling-valuation-analyst-fmva-program',
    category: 'Finance',
    duration: '6 months',
    language: 'English',
    rating: 4.7,
    skills: [
      'financial modeling',
      'excel',
      'risk analysis',
      'data analysis',
      'forecasting',
      'reporting',
      'presentation',
      'accounting'
    ],
  ),
  _toFullCourse(
    id: 18,
    title: 'Risk Management in Banking and Financial Markets',
    provider: 'Coursera (NYIF)',
    level: 'Intermediate',
    type: 'Course',
    url: 'https://www.coursera.org/learn/risk-management-banking',
    category: 'Finance',
    duration: '4 weeks',
    language: 'English',
    rating: 4.4,
    skills: [
      'risk analysis',
      'financial modeling',
      'statistical analysis',
      'data analysis'
    ],
  ),
  _toFullCourse(
    id: 19,
    title: 'Introduction to Financial Accounting (Wharton)',
    provider: 'Coursera (Wharton)',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.coursera.org/learn/wharton-accounting',
    category: 'Finance',
    duration: '4 weeks',
    language: 'English',
    rating: 4.8,
    skills: [
      'accounting',
      'excel',
      'financial modeling',
      'reporting',
      'data analysis'
    ],
  ),
  // Marketing (IDs 20–24)
  _toFullCourse(
    id: 20,
    title: 'Google Digital Marketing & E-commerce Certificate',
    provider: 'Coursera (Google)',
    level: 'Beginner',
    type: 'Certification',
    url:
        'https://www.coursera.org/professional-certificates/google-digital-marketing-ecommerce',
    category: 'Marketing',
    duration: '6 months',
    language: 'English',
    rating: 4.8,
    skills: [
      'seo',
      'google ads',
      'social media',
      'content writing',
      'market research',
      'email marketing',
      'analytics',
      'brand strategy'
    ],
  ),
  _toFullCourse(
    id: 21,
    title: 'SEO Training Course by Moz',
    provider: 'Moz Academy',
    level: 'Beginner',
    type: 'Certification',
    url: 'https://academy.moz.com/courses/seo-essentials-certification',
    category: 'Marketing',
    duration: '3.5 hours',
    language: 'English',
    rating: 4.5,
    skills: ['seo', 'content writing', 'market research', 'analytics'],
  ),
  _toFullCourse(
    id: 22,
    title: 'Content Marketing Certification',
    provider: 'HubSpot Academy',
    level: 'Beginner',
    type: 'Certification',
    url: 'https://academy.hubspot.com/courses/content-marketing',
    category: 'Marketing',
    duration: '5 hours',
    language: 'English',
    rating: 4.6,
    skills: [
      'content writing',
      'seo',
      'email marketing',
      'social media',
      'brand strategy'
    ],
  ),
  _toFullCourse(
    id: 23,
    title: 'Google Ads Search Certification',
    provider: 'Google Skillshop',
    level: 'Beginner',
    type: 'Certification',
    url: 'https://skillshop.withgoogle.com/googleads',
    category: 'Marketing',
    duration: '3 hours',
    language: 'English',
    rating: 4.6,
    skills: ['google ads', 'seo', 'analytics', 'market research'],
  ),
  _toFullCourse(
    id: 24,
    title: 'Social Media Marketing Masterclass',
    provider: 'Udemy',
    level: 'Beginner',
    type: 'Course',
    url:
        'https://www.udemy.com/course/social-media-marketing-agency-digital-marketing-specialist/',
    category: 'Marketing',
    duration: '12 hours',
    language: 'English',
    rating: 4.4,
    skills: [
      'social media',
      'content writing',
      'market research',
      'communication',
      'customer service'
    ],
  ),
  // Design (IDs 25–28)
  _toFullCourse(
    id: 25,
    title: 'Google UX Design Professional Certificate',
    provider: 'Coursera (Google)',
    level: 'Beginner',
    type: 'Certification',
    url: 'https://www.coursera.org/professional-certificates/google-ux-design',
    category: 'Design',
    duration: '6 months',
    language: 'English',
    rating: 4.8,
    skills: [
      'ui/ux design',
      'ui',
      'ux',
      'figma',
      'wireframing',
      'prototyping',
      'user research',
      'responsive design',
      'adobe xd'
    ],
  ),
  _toFullCourse(
    id: 26,
    title: 'Figma UI/UX Design Essentials',
    provider: 'Udemy',
    level: 'Beginner',
    type: 'Course',
    url:
        'https://www.udemy.com/course/figma-ux-ui-design-user-experience-tutorial-course/',
    category: 'Design',
    duration: '16 hours',
    language: 'English',
    rating: 4.7,
    skills: [
      'figma',
      'wireframing',
      'prototyping',
      'ui/ux design',
      'user research',
      'responsive design'
    ],
  ),
  _toFullCourse(
    id: 27,
    title: 'Graphic Design Bootcamp',
    provider: 'Udemy',
    level: 'Beginner',
    type: 'Bootcamp',
    url: 'https://www.udemy.com/course/graphic-design-masterclass/',
    category: 'Design',
    duration: '18 hours',
    language: 'English',
    rating: 4.5,
    skills: [
      'adobe photoshop',
      'illustrator',
      'figma',
      'branding',
      'typography',
      'ui',
      'color theory',
      'responsive design'
    ],
  ),
  _toFullCourse(
    id: 28,
    title: 'Photoshop for Beginners – Full Course',
    provider: 'YouTube (freeCodeCamp)',
    level: 'Beginner',
    type: 'Video',
    url: 'https://www.youtube.com/watch?v=IyR_uYsRdPs',
    category: 'Design',
    duration: '3.5 hours',
    language: 'English',
    rating: 4.5,
    skills: ['adobe photoshop', 'typography', 'color theory', 'branding'],
  ),
  // Healthcare (IDs 29–31)
  _toFullCourse(
    id: 29,
    title: 'Clinical Research Training (WHO)',
    provider: 'edX (WHO)',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.edx.org/course/clinical-research-trials',
    category: 'Healthcare',
    duration: '6 weeks',
    language: 'English',
    rating: 4.4,
    skills: [
      'medical research',
      'research',
      'documentation',
      'data collection',
      'statistical analysis'
    ],
  ),
  _toFullCourse(
    id: 30,
    title: 'Health Informatics Specialization',
    provider: 'Coursera (Johns Hopkins)',
    level: 'Intermediate',
    type: 'Specialisation',
    url: 'https://www.coursera.org/specializations/health-informatics',
    category: 'Healthcare',
    duration: '4 months',
    language: 'English',
    rating: 4.6,
    skills: [
      'health informatics',
      'medical research',
      'python',
      'sql',
      'data analysis',
      'documentation',
      'patient care',
      'research'
    ],
  ),
  _toFullCourse(
    id: 31,
    title: 'Health Data Science with Python (Harvard)',
    provider: 'edX (Harvard)',
    level: 'Intermediate',
    type: 'Course',
    url:
        'https://www.edx.org/course/data-science-foundations-using-r-specialization',
    category: 'Healthcare',
    duration: '8 weeks',
    language: 'English',
    rating: 4.7,
    skills: [
      'python',
      'sql',
      'statistical analysis',
      'data analysis',
      'research',
      'medical research',
      'documentation'
    ],
  ),
  // Manufacturing (IDs 32–34)
  _toFullCourse(
    id: 32,
    title: 'Supply Chain Management Specialization',
    provider: 'Coursera (Rutgers)',
    level: 'Intermediate',
    type: 'Specialisation',
    url: 'https://www.coursera.org/specializations/supply-chain-management',
    category: 'Operations',
    duration: '5 months',
    language: 'English',
    rating: 4.6,
    skills: [
      'supply chain',
      'production planning',
      'excel',
      'data analysis',
      'stakeholder',
      'reporting',
      'quality control',
      'communication',
      'logistics'
    ],
  ),
  _toFullCourse(
    id: 33,
    title: 'Quality Management & Six Sigma',
    provider: 'LinkedIn Learning',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.linkedin.com/learning/topics/quality-management',
    category: 'Operations',
    duration: '3 hours',
    language: 'English',
    rating: 4.4,
    skills: [
      'quality control',
      'lean manufacturing',
      'six sigma',
      'production planning',
      'data analysis'
    ],
  ),
  _toFullCourse(
    id: 34,
    title: 'Google Project Management Certificate',
    provider: 'Coursera (Google)',
    level: 'Beginner',
    type: 'Certification',
    url:
        'https://www.coursera.org/professional-certificates/google-project-management',
    category: 'Operations',
    duration: '6 months',
    language: 'English',
    rating: 4.8,
    skills: [
      'project management',
      'agile',
      'scrum',
      'stakeholder',
      'communication',
      'risk analysis',
      'documentation',
      'production planning'
    ],
  ),
  // Retail (IDs 35–36)
  _toFullCourse(
    id: 35,
    title: 'Customer Service Fundamentals',
    provider: 'Coursera (CVS Health)',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.coursera.org/learn/customer-service-fundamentals',
    category: 'Retail',
    duration: '4 weeks',
    language: 'English',
    rating: 4.5,
    skills: [
      'customer service',
      'communication',
      'sales',
      'merchandising',
      'problem solving',
      'stakeholder'
    ],
  ),
  _toFullCourse(
    id: 36,
    title: 'Sales Training – Practical Sales Techniques',
    provider: 'Udemy',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.udemy.com/course/sales-training/',
    category: 'Retail',
    duration: '5 hours',
    language: 'English',
    rating: 4.5,
    skills: [
      'sales',
      'customer service',
      'communication',
      'negotiation',
      'merchandising'
    ],
  ),
  // Education (IDs 37–39)
  _toFullCourse(
    id: 37,
    title: 'Foundations of Teaching for Learning Specialization',
    provider: 'Coursera (Commonwealth Edu Trust)',
    level: 'Beginner',
    type: 'Specialisation',
    url: 'https://www.coursera.org/specializations/foundations-teaching',
    category: 'Education',
    duration: '8 months',
    language: 'English',
    rating: 4.5,
    skills: [
      'teaching',
      'curriculum design',
      'edtech',
      'content writing',
      'communication',
      'research',
      'assessment design'
    ],
  ),
  _toFullCourse(
    id: 38,
    title: 'Curriculum Design and Teaching (MIT)',
    provider: 'edX (MIT)',
    level: 'Intermediate',
    type: 'Course',
    url: 'https://www.edx.org/course/designing-and-developing-curricula',
    category: 'Education',
    duration: '6 weeks',
    language: 'English',
    rating: 4.5,
    skills: [
      'curriculum design',
      'teaching',
      'research',
      'assessment design',
      'lesson planning'
    ],
  ),
  _toFullCourse(
    id: 39,
    title: 'Instructional Design & EdTech Fundamentals',
    provider: 'edX',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.edx.org/learn/instructional-design',
    category: 'Education',
    duration: '5 weeks',
    language: 'English',
    rating: 4.4,
    skills: [
      'edtech',
      'curriculum design',
      'teaching',
      'content writing',
      'presentation',
      'research'
    ],
  ),
  // Professional Skills (IDs 40–42)
  _toFullCourse(
    id: 40,
    title: 'Google Data Analytics Certificate',
    provider: 'Coursera (Google)',
    level: 'Beginner',
    type: 'Certification',
    url:
        'https://www.coursera.org/professional-certificates/google-data-analytics',
    category: 'Data Science',
    duration: '6 months',
    language: 'English',
    rating: 4.8,
    skills: [
      'data analysis',
      'sql',
      'tableau',
      'power bi',
      'excel',
      'python',
      'statistical analysis',
      'data visualization'
    ],
  ),
  _toFullCourse(
    id: 41,
    title: 'Improving Communication Skills (Penn)',
    provider: 'Coursera (Penn)',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.coursera.org/learn/wharton-communication-skills',
    category: 'Professional Skills',
    duration: '4 weeks',
    language: 'English',
    rating: 4.6,
    skills: [
      'communication',
      'presentation',
      'stakeholder',
      'documentation',
      'leadership',
      'cross-functional'
    ],
  ),
  _toFullCourse(
    id: 42,
    title: 'Data Structures Easy to Advanced (Full Course)',
    provider: 'YouTube (freeCodeCamp)',
    level: 'Intermediate',
    type: 'Video',
    url: 'https://www.youtube.com/watch?v=RBSGKlAvoiM',
    category: 'Software Engineering',
    duration: '8 hours',
    language: 'English',
    rating: 4.7,
    skills: ['data structures', 'algorithms', 'java', 'python', 'c++'],
  ),

  // --------------------------------------------------------------------------
  // PART B: 36 courses from the second file (comprehensive model with all fields)
  // --------------------------------------------------------------------------
  // Software / Data Science
  const Course(
    id: 43,
    title: 'Python for Data Analysis',
    provider: 'Coursera',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.coursera.org/learn/python-data-analysis',
    category: 'Data Science',
    duration: '6 weeks',
    language: 'English',
    rating: 4.7,
    isFree: false,
    skills: [
      'python',
      'data analysis',
      'pandas',
      'numpy',
      'matplotlib',
      'reporting'
    ],
    topics: [
      'python basics',
      'data wrangling',
      'pandas dataframes',
      'numpy arrays',
      'data visualisation',
      'reporting'
    ],
    qualityScore: 0.88,
    contentTypeString: 'video',
    detailLevelString: 'high',
    lengthCategoryString: 'long',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 450000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.high,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'variables',
      'lists',
      'dicts',
      'dataframe operations',
      'groupby',
      'matplotlib basics',
      'seaborn charts'
    ],
    transcriptSummary:
        'A practical 6‑week MOOC covering Python, pandas, and numpy for end‑to‑end data analysis.',
    thumbnailUrl:
        'https://img-c.udemycdn.com/course/480x270/python-data-analysis.jpg',
  ),
  const Course(
    id: 44,
    title: 'SQL for Data Science',
    provider: 'edX',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.edx.org/learn/sql',
    category: 'Data Science',
    duration: '4 weeks',
    language: 'English',
    rating: 4.6,
    isFree: false,
    skills: [
      'sql',
      'database',
      'data analysis',
      'joins',
      'aggregation',
      'reporting'
    ],
    topics: [
      'sql syntax',
      'joins',
      'aggregation',
      'subqueries',
      'database design',
      'reporting'
    ],
    qualityScore: 0.85,
    contentTypeString: 'video',
    detailLevelString: 'medium',
    lengthCategoryString: 'medium',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 320000,
    contentLength: ContentLength.medium,
    detailLevel: DetailLevel.medium,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'select',
      'where',
      'inner join',
      'left join',
      'group by',
      'having',
      'window functions',
      'cte'
    ],
    transcriptSummary:
        'Four‑week SQL course covering querying, joins, aggregation, and subqueries.',
  ),
  const Course(
    id: 45,
    title: 'Java Programming Masterclass',
    provider: 'Udemy',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.udemy.com/course/java-the-complete-java-developer-course',
    category: 'Software Development',
    duration: '80 hours',
    language: 'English',
    rating: 4.7,
    isFree: false,
    skills: ['java', 'oop', 'data structures', 'algorithms', 'spring', 'git'],
    topics: [
      'java fundamentals',
      'oop principles',
      'collections',
      'generics',
      'spring framework',
      'git basics'
    ],
    qualityScore: 0.87,
    contentTypeString: 'video',
    detailLevelString: 'high',
    lengthCategoryString: 'long',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 670000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.high,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'data types',
      'control flow',
      'inheritance',
      'interfaces',
      'generics',
      'streams',
      'spring boot',
      'junit'
    ],
    transcriptSummary:
        'Comprehensive 80‑hour Java course from syntax basics through Spring framework.',
  ),
  const Course(
    id: 46,
    title: 'Machine Learning A-Z',
    provider: 'Udemy',
    level: 'Intermediate',
    type: 'Course',
    url: 'https://www.udemy.com/course/machinelearning',
    category: 'Data Science',
    duration: '40 hours',
    language: 'English',
    rating: 4.6,
    isFree: false,
    skills: [
      'python',
      'machine learning',
      'scikit-learn',
      'pandas',
      'regression',
      'classification'
    ],
    topics: [
      'linear regression',
      'logistic regression',
      'decision trees',
      'random forests',
      'clustering',
      'neural networks intro'
    ],
    qualityScore: 0.86,
    contentTypeString: 'video',
    detailLevelString: 'high',
    lengthCategoryString: 'long',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 890000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.high,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'train/test split',
      'overfitting',
      'cross-validation',
      'feature engineering',
      'pca',
      'k‑means',
      'svm',
      'xgboost'
    ],
    transcriptSummary:
        'Hands‑on 40‑hour ML course covering supervised and unsupervised algorithms.',
  ),
  const Course(
    id: 47,
    title: 'React – The Complete Guide',
    provider: 'Udemy',
    level: 'Intermediate',
    type: 'Course',
    url: 'https://www.udemy.com/course/react-the-complete-guide-incl-redux',
    category: 'Web Development',
    duration: '48 hours',
    language: 'English',
    rating: 4.7,
    isFree: false,
    skills: [
      'react',
      'javascript',
      'html',
      'css',
      'api integration',
      'responsive design'
    ],
    topics: [
      'jsx',
      'components',
      'hooks',
      'context api',
      'redux',
      'routing',
      'api calls'
    ],
    qualityScore: 0.87,
    contentTypeString: 'video',
    detailLevelString: 'high',
    lengthCategoryString: 'long',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 750000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.high,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'jsx syntax',
      'functional components',
      'usestate',
      'useeffect',
      'usecontext',
      'react router',
      'redux toolkit',
      'fetch api'
    ],
    transcriptSummary:
        'Complete React course covering hooks, Redux, routing, and API integration.',
  ),
  const Course(
    id: 48,
    title: 'AWS Cloud Practitioner Essentials',
    provider: 'AWS',
    level: 'Beginner',
    type: 'Certificate',
    url: 'https://aws.amazon.com/training/learn-about/cloud-practitioner',
    category: 'Cloud Computing',
    duration: '8 hours',
    language: 'English',
    rating: 4.8,
    isFree: false,
    skills: [
      'aws',
      'cloud computing',
      'ec2',
      's3',
      'iam',
      'cloud architecture'
    ],
    topics: [
      'cloud concepts',
      'ec2',
      's3 storage',
      'iam',
      'pricing',
      'cloud architecture'
    ],
    qualityScore: 0.92,
    contentTypeString: 'video',
    detailLevelString: 'medium',
    lengthCategoryString: 'short',
    strategyString: 'theory',
    isClassBased: false,
    viewCount: 510000,
    contentLength: ContentLength.short,
    detailLevel: DetailLevel.medium,
    learningStrategy: LearningStrategy.theoryOnly,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'regions and azs',
      'ec2 types',
      's3 buckets',
      'iam policies',
      'vpc basics',
      'billing dashboard',
      'well‑architected framework'
    ],
    transcriptSummary:
        'Official AWS 8‑hour certification prep covering core cloud services.',
    thumbnailUrl:
        'https://d1.awsstatic.com/logos/aws-logo-lockups/poweredbyaws/PB_AWS_logo_RGB_stacked.png',
  ),
  const Course(
    id: 49,
    title: 'Web Development Bootcamp',
    provider: 'freeCodeCamp',
    level: 'Beginner',
    type: 'Bootcamp',
    url: 'https://www.freecodecamp.org',
    category: 'Web Development',
    duration: '300 hours',
    language: 'English',
    rating: 4.8,
    isFree: true,
    skills: [
      'html',
      'css',
      'javascript',
      'responsive design',
      'bootstrap',
      'git'
    ],
    topics: [
      'html structure',
      'css styling',
      'flexbox',
      'grid',
      'javascript dom',
      'responsive design',
      'accessibility'
    ],
    qualityScore: 0.90,
    contentTypeString: 'webpage',
    detailLevelString: 'high',
    lengthCategoryString: 'long',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 2000000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.high,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.webPage,
    topicsCovert: [
      'semantic html',
      'css box model',
      'flexbox',
      'css grid',
      'dom manipulation',
      'es6',
      'fetch api',
      'bootstrap 5'
    ],
    transcriptSummary:
        'Free self‑paced interactive curriculum covering full front‑end stack.',
  ),
  const Course(
    id: 50,
    title: 'Git & GitHub Essentials',
    provider: 'YouTube',
    level: 'Beginner',
    type: 'Video',
    url: 'https://www.youtube.com/watch?v=RGOj5yH7evk',
    category: 'Version Control',
    duration: '2 hours',
    language: 'English',
    rating: 4.4,
    isFree: true,
    skills: ['git', 'github', 'version control', 'branching', 'commits'],
    topics: ['git init', 'commits', 'branching', 'merging', 'pull requests'],
    qualityScore: 0.72,
    contentTypeString: 'video',
    detailLevelString: 'low',
    lengthCategoryString: 'short',
    strategyString: 'example',
    isClassBased: false,
    viewCount: 3800000,
    contentLength: ContentLength.short,
    detailLevel: DetailLevel.low,
    learningStrategy: LearningStrategy.exampleOnly,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'git init',
      'git add',
      'git commit',
      'git push',
      'branches',
      'merge conflicts',
      'pull requests',
      'forks'
    ],
    transcriptSummary:
        'Two‑hour YouTube walkthrough of Git and GitHub fundamentals.',
  ),
  const Course(
    id: 51,
    title: 'Advanced Python Programming',
    provider: 'Udemy',
    level: 'Intermediate',
    type: 'Course',
    url: 'https://www.udemy.com/course/advanced-python',
    category: 'Programming',
    duration: '15 hours',
    language: 'English',
    rating: 4.7,
    isFree: false,
    skills: ['python', 'oop', 'decorators', 'generators', 'asyncio', 'testing'],
    topics: [
      'decorators',
      'context managers',
      'generators',
      'async/await',
      'metaclasses',
      'unit testing'
    ],
    qualityScore: 0.85,
    contentTypeString: 'video',
    detailLevelString: 'high',
    lengthCategoryString: 'medium',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 290000,
    contentLength: ContentLength.medium,
    detailLevel: DetailLevel.high,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'closures',
      'decorators',
      'generators',
      'coroutines',
      'asyncio event loop',
      'dataclasses',
      'typing module',
      'pytest'
    ],
    transcriptSummary:
        'Deep‑dive into advanced Python features – decorators, async, metaclasses, and testing.',
  ),
  const Course(
    id: 52,
    title: 'Flutter & Dart – The Complete Guide',
    provider: 'Udemy',
    level: 'Beginner',
    type: 'Course',
    url:
        'https://www.udemy.com/course/learn-flutter-dart-to-build-ios-android-apps',
    category: 'Mobile Development',
    duration: '42 hours',
    language: 'English',
    rating: 4.6,
    isFree: false,
    skills: [
      'dart',
      'flutter',
      'firebase',
      'rest api',
      'state management',
      'ui',
      'widgets'
    ],
    topics: [
      'dart basics',
      'widgets',
      'state management',
      'navigation',
      'firebase',
      'rest api',
      'animations'
    ],
    qualityScore: 0.86,
    contentTypeString: 'video',
    detailLevelString: 'high',
    lengthCategoryString: 'long',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 310000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.high,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'dart null safety',
      'stateful widgets',
      'provider',
      'riverpod',
      'firebase auth',
      'firestore',
      'http package',
      'animations'
    ],
    transcriptSummary:
        'Comprehensive Flutter and Dart course building real mobile apps.',
  ),
  const Course(
    id: 53,
    title: 'C++ Programming: From Beginner to Expert',
    provider: 'Udemy',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.udemy.com/course/cpp-programming',
    category: 'Software Development',
    duration: '45 hours',
    language: 'English',
    rating: 4.5,
    isFree: false,
    skills: [
      'c++',
      'oop',
      'memory management',
      'algorithms',
      'problem solving'
    ],
    topics: [
      'c++ syntax',
      'pointers',
      'oop',
      'templates',
      'stl',
      'memory management',
      'algorithms'
    ],
    qualityScore: 0.82,
    contentTypeString: 'video',
    detailLevelString: 'high',
    lengthCategoryString: 'long',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 200000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.high,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'pointers',
      'references',
      'vtables',
      'raii',
      'smart pointers',
      'stl containers',
      'move semantics',
      'templates'
    ],
    transcriptSummary:
        '45‑hour C++ course covering fundamentals through advanced memory management and STL.',
  ),
  // Finance
  const Course(
    id: 54,
    title: 'Microsoft Excel – Beginner to Advanced',
    provider: 'Udemy',
    level: 'Beginner',
    type: 'Course',
    url:
        'https://www.udemy.com/course/microsoft-excel-2013-from-beginner-to-advanced-and-beyond',
    category: 'Finance',
    duration: '18 hours',
    language: 'English',
    rating: 4.7,
    isFree: false,
    skills: [
      'excel',
      'financial modeling',
      'data analysis',
      'reporting',
      'pivot tables'
    ],
    topics: [
      'spreadsheet basics',
      'formulas',
      'pivot tables',
      'vlookup',
      'financial functions',
      'charts',
      'macros'
    ],
    qualityScore: 0.87,
    contentTypeString: 'video',
    detailLevelString: 'high',
    lengthCategoryString: 'medium',
    strategyString: 'example',
    isClassBased: false,
    viewCount: 580000,
    contentLength: ContentLength.medium,
    detailLevel: DetailLevel.high,
    learningStrategy: LearningStrategy.exampleOnly,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'cell references',
      'if/nested if',
      'vlookup',
      'xlookup',
      'pivot tables',
      'power query',
      'vba macros',
      'financial functions'
    ],
    transcriptSummary:
        '18‑hour Excel course from basic spreadsheets through advanced pivot tables and VBA.',
  ),
  const Course(
    id: 55,
    title: 'Financial Modeling & Valuation (FMVA)',
    provider: 'Corporate Finance Institute',
    level: 'Intermediate',
    type: 'Certificate',
    url: 'https://corporatefinanceinstitute.com/certifications/fmva',
    category: 'Finance',
    duration: '120 hours',
    language: 'English',
    rating: 4.8,
    isFree: false,
    skills: [
      'financial modeling',
      'excel',
      'valuation',
      'risk analysis',
      'reporting',
      'accounting'
    ],
    topics: [
      'dcf valuation',
      'comparable analysis',
      '3‑statement model',
      'lbo modeling',
      'sensitivity analysis',
      'scenario analysis'
    ],
    qualityScore: 0.92,
    contentTypeString: 'video',
    detailLevelString: 'high',
    lengthCategoryString: 'long',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 220000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.high,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'income statement',
      'balance sheet',
      'cash flow statement',
      'dcf model',
      'wacc',
      'terminal value',
      'lbo model',
      'precedent transactions'
    ],
    transcriptSummary:
        'Industry‑standard 120‑hour FMVA certification covering all core financial modeling and valuation methodologies.',
  ),
  const Course(
    id: 56,
    title: 'Risk Management Professional Certificate',
    provider: 'edX',
    level: 'Intermediate',
    type: 'Certificate',
    url: 'https://www.edx.org/professional-certificate/risk-management',
    category: 'Finance',
    duration: '16 weeks',
    language: 'English',
    rating: 4.6,
    isFree: false,
    skills: [
      'risk analysis',
      'financial modeling',
      'excel',
      'statistics',
      'sql',
      'reporting'
    ],
    topics: [
      'risk identification',
      'quantitative risk',
      'credit risk',
      'market risk',
      'operational risk',
      'risk reporting'
    ],
    qualityScore: 0.88,
    contentTypeString: 'video',
    detailLevelString: 'high',
    lengthCategoryString: 'long',
    strategyString: 'theory',
    isClassBased: true,
    viewCount: 180000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.high,
    learningStrategy: LearningStrategy.theoryOnly,
    isClassroomBased: true,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'var calculation',
      'credit scoring',
      'stress testing',
      'basel framework',
      'operational risk matrix',
      'risk dashboards'
    ],
    transcriptSummary:
        'University‑style 16‑week professional certificate covering quantitative and qualitative risk management.',
  ),
  const Course(
    id: 57,
    title: 'Python for Finance',
    provider: 'Udemy',
    level: 'Intermediate',
    type: 'Course',
    url:
        'https://www.udemy.com/course/python-for-finance-investment-fundamentals',
    category: 'Finance',
    duration: '10 hours',
    language: 'English',
    rating: 4.5,
    isFree: false,
    skills: [
      'python',
      'financial modeling',
      'data analysis',
      'pandas',
      'statistics',
      'risk analysis'
    ],
    topics: [
      'python finance libraries',
      'time series',
      'portfolio optimisation',
      'monte carlo',
      'risk metrics'
    ],
    qualityScore: 0.82,
    contentTypeString: 'video',
    detailLevelString: 'medium',
    lengthCategoryString: 'short',
    strategyString: 'example',
    isClassBased: false,
    viewCount: 145000,
    contentLength: ContentLength.short,
    detailLevel: DetailLevel.medium,
    learningStrategy: LearningStrategy.exampleOnly,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'yfinance',
      'pandas datareader',
      'portfolio returns',
      'sharpe ratio',
      'monte carlo simulation',
      'capm',
      'markowitz'
    ],
    transcriptSummary:
        'Practical 10‑hour course applying Python to portfolio analysis and risk metrics.',
  ),
  // Healthcare
  const Course(
    id: 58,
    title: 'Patient Care & Clinical Fundamentals',
    provider: 'Coursera',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.coursera.org/learn/patient-care',
    category: 'Healthcare',
    duration: '6 weeks',
    language: 'English',
    rating: 4.6,
    isFree: false,
    skills: [
      'patient care',
      'nursing',
      'communication skills',
      'medical research',
      'clinical documentation'
    ],
    topics: [
      'patient assessment',
      'vital signs',
      'clinical communication',
      'documentation',
      'infection control',
      'nursing ethics'
    ],
    qualityScore: 0.86,
    contentTypeString: 'video',
    detailLevelString: 'medium',
    lengthCategoryString: 'long',
    strategyString: 'both',
    isClassBased: true,
    viewCount: 270000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.medium,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: true,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'admission assessment',
      'glasgow scale',
      'handover protocol',
      'soap notes',
      'hand hygiene',
      'ppe',
      'medication administration'
    ],
    transcriptSummary:
        'Six‑week clinical nursing fundamentals course covering patient assessment and safe care practices.',
  ),
  const Course(
    id: 59,
    title: 'Pharmacology Essentials',
    provider: 'edX',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.edx.org/learn/pharmacology',
    category: 'Healthcare',
    duration: '8 weeks',
    language: 'English',
    rating: 4.5,
    isFree: false,
    skills: [
      'pharmaceuticals',
      'medical research',
      'patient care',
      'clinical documentation'
    ],
    topics: [
      'drug classes',
      'pharmacokinetics',
      'pharmacodynamics',
      'adverse effects',
      'clinical trials',
      'drug safety'
    ],
    qualityScore: 0.84,
    contentTypeString: 'video',
    detailLevelString: 'medium',
    lengthCategoryString: 'long',
    strategyString: 'theory',
    isClassBased: true,
    viewCount: 160000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.medium,
    learningStrategy: LearningStrategy.theoryOnly,
    isClassroomBased: true,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'absorption',
      'distribution',
      'metabolism',
      'excretion',
      'receptor binding',
      'adrs',
      'drug interactions',
      'clinical trials phases'
    ],
    transcriptSummary:
        'Eight‑week pharmacology course covering drug mechanisms, clinical trials, and adverse event assessment.',
  ),
  const Course(
    id: 60,
    title: 'Healthcare Data Analytics',
    provider: 'Coursera',
    level: 'Intermediate',
    type: 'Course',
    url: 'https://www.coursera.org/learn/healthcare-data-analytics',
    category: 'Healthcare',
    duration: '8 weeks',
    language: 'English',
    rating: 4.7,
    isFree: false,
    skills: [
      'data analysis',
      'sql',
      'excel',
      'medical research',
      'reporting',
      'python'
    ],
    topics: [
      'health data types',
      'ehr systems',
      'sql for health data',
      'predictive analytics',
      'data visualisation',
      'quality metrics'
    ],
    qualityScore: 0.88,
    contentTypeString: 'video',
    detailLevelString: 'high',
    lengthCategoryString: 'long',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 210000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.high,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'hl7 fhir',
      'ehr data structures',
      'icd codes',
      'survival analysis',
      'cohort studies',
      'tableau for health',
      'hipaa'
    ],
    transcriptSummary:
        'Eight‑week course applying SQL, Python, and analytics to electronic health records.',
  ),
  // Marketing
  const Course(
    id: 61,
    title: 'Google Digital Marketing & E-commerce Certificate',
    provider: 'Google',
    level: 'Beginner',
    type: 'Certificate',
    url: 'https://grow.google/certificates/digital-marketing-ecommerce',
    category: 'Marketing',
    duration: '6 months',
    language: 'English',
    rating: 4.8,
    isFree: false,
    skills: [
      'seo',
      'google ads',
      'analytics',
      'social media',
      'content writing',
      'email marketing'
    ],
    topics: [
      'seo fundamentals',
      'google ads',
      'social media strategy',
      'email marketing',
      'analytics',
      'e‑commerce basics'
    ],
    qualityScore: 0.93,
    contentTypeString: 'video',
    detailLevelString: 'medium',
    lengthCategoryString: 'long',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 920000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.medium,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'keyword research',
      'on‑page seo',
      'google ads campaign',
      'search console',
      'ga4 events',
      'email funnels',
      'shopify basics'
    ],
    transcriptSummary:
        'Official Google 6‑month certificate programme covering search, social, email marketing, and e‑commerce.',
    thumbnailUrl:
        'https://grow.google/certificates/images/digital-marketing.png',
  ),
  const Course(
    id: 62,
    title: 'Market Research & Consumer Behaviour',
    provider: 'Coursera',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.coursera.org/learn/market-research',
    category: 'Marketing',
    duration: '5 weeks',
    language: 'English',
    rating: 4.4,
    isFree: false,
    skills: [
      'market research',
      'data analysis',
      'reporting',
      'seo',
      'communication skills'
    ],
    topics: [
      'primary research',
      'secondary research',
      'surveys',
      'focus groups',
      'consumer psychology',
      'competitive analysis'
    ],
    qualityScore: 0.80,
    contentTypeString: 'video',
    detailLevelString: 'medium',
    lengthCategoryString: 'medium',
    strategyString: 'theory',
    isClassBased: false,
    viewCount: 140000,
    contentLength: ContentLength.medium,
    detailLevel: DetailLevel.medium,
    learningStrategy: LearningStrategy.theoryOnly,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'research design',
      'survey construction',
      'sampling',
      'focus group facilitation',
      'conjoint analysis',
      'perceptual mapping'
    ],
    transcriptSummary:
        'Five‑week course on research design, consumer psychology, and competitive analysis methodologies.',
  ),
  const Course(
    id: 63,
    title: 'Social Media Marketing Masterclass',
    provider: 'Udemy',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.udemy.com/course/social-media-marketing-masterclass',
    category: 'Marketing',
    duration: '14 hours',
    language: 'English',
    rating: 4.6,
    isFree: false,
    skills: [
      'social media',
      'content writing',
      'google ads',
      'copywriting',
      'analytics',
      'seo'
    ],
    topics: [
      'instagram marketing',
      'facebook ads',
      'tiktok strategy',
      'content calendar',
      'analytics',
      'influencer outreach'
    ],
    qualityScore: 0.82,
    contentTypeString: 'video',
    detailLevelString: 'medium',
    lengthCategoryString: 'medium',
    strategyString: 'example',
    isClassBased: false,
    viewCount: 380000,
    contentLength: ContentLength.medium,
    detailLevel: DetailLevel.medium,
    learningStrategy: LearningStrategy.exampleOnly,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'instagram reels',
      'facebook pixel',
      'tiktok ads',
      'content scheduling',
      'meta ads manager',
      'hashtag strategy',
      'social analytics'
    ],
    transcriptSummary:
        '14‑hour social media masterclass with hands‑on platform walkthroughs for Instagram, Facebook, and TikTok.',
  ),
  const Course(
    id: 64,
    title: 'UX Design Professional Certificate',
    provider: 'Google',
    level: 'Beginner',
    type: 'Certificate',
    url: 'https://grow.google/certificates/ux-design',
    category: 'Design',
    duration: '6 months',
    language: 'English',
    rating: 4.8,
    isFree: false,
    skills: [
      'ux design',
      'figma',
      'user research',
      'prototyping',
      'wireframing',
      'communication skills'
    ],
    topics: [
      'design thinking',
      'user research',
      'wireframing',
      'prototyping in figma',
      'usability testing',
      'design systems'
    ],
    qualityScore: 0.93,
    contentTypeString: 'video',
    detailLevelString: 'high',
    lengthCategoryString: 'long',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 840000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.high,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'empathy mapping',
      'personas',
      'user journeys',
      'low‑fi wireframes',
      'high‑fi prototypes',
      'usability testing scripts',
      'design handoff',
      'design systems'
    ],
    transcriptSummary:
        'Official Google 6‑month UX certificate covering the full design process from user research through Figma prototyping.',
    thumbnailUrl: 'https://grow.google/certificates/images/ux-design.png',
  ),
  // Manufacturing
  const Course(
    id: 65,
    title: 'Supply Chain Management Fundamentals',
    provider: 'Coursera',
    level: 'Beginner',
    type: 'Course',
    url:
        'https://www.coursera.org/learn/supply-chain-management-a-learning-perspective',
    category: 'Manufacturing',
    duration: '8 weeks',
    language: 'English',
    rating: 4.6,
    isFree: false,
    skills: [
      'supply chain',
      'logistics',
      'inventory management',
      'communication skills',
      'reporting'
    ],
    topics: [
      'supply chain basics',
      'procurement',
      'logistics',
      'inventory control',
      'demand forecasting',
      'supplier relations'
    ],
    qualityScore: 0.85,
    contentTypeString: 'video',
    detailLevelString: 'medium',
    lengthCategoryString: 'long',
    strategyString: 'theory',
    isClassBased: true,
    viewCount: 190000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.medium,
    learningStrategy: LearningStrategy.theoryOnly,
    isClassroomBased: true,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'bull‑whip effect',
      'eoq model',
      'jit',
      'safety stock',
      'rfq process',
      'incoterms',
      'supplier scorecards'
    ],
    transcriptSummary:
        'Eight‑week university‑level supply chain course covering procurement, inventory, and logistics frameworks.',
  ),
  const Course(
    id: 66,
    title: 'Quality Management & Six Sigma',
    provider: 'edX',
    level: 'Intermediate',
    type: 'Course',
    url: 'https://www.edx.org/learn/quality-management',
    category: 'Manufacturing',
    duration: '10 weeks',
    language: 'English',
    rating: 4.5,
    isFree: false,
    skills: [
      'quality control',
      'production planning',
      'supply chain',
      'reporting',
      'inspection'
    ],
    topics: [
      'six sigma dmaic',
      'control charts',
      'root cause analysis',
      'process capability',
      'lean manufacturing',
      'kaizen'
    ],
    qualityScore: 0.84,
    contentTypeString: 'video',
    detailLevelString: 'high',
    lengthCategoryString: 'long',
    strategyString: 'both',
    isClassBased: true,
    viewCount: 120000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.high,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: true,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'define phase',
      'measure phase',
      'analyse phase',
      'improve phase',
      'control charts',
      'fishbone diagram',
      'poka yoke',
      '5s'
    ],
    transcriptSummary:
        '10‑week Six Sigma DMAIC course covering lean manufacturing, control charts, and process improvement tools.',
  ),
  const Course(
    id: 67,
    title: 'Production Planning & Operations Management',
    provider: 'LinkedIn Learning',
    level: 'Intermediate',
    type: 'Course',
    url: 'https://www.linkedin.com/learning/production-planning',
    category: 'Manufacturing',
    duration: '8 hours',
    language: 'English',
    rating: 4.4,
    isFree: false,
    skills: [
      'production planning',
      'quality control',
      'supply chain',
      'erp systems',
      'reporting'
    ],
    topics: [
      'mrp',
      'production scheduling',
      'capacity planning',
      'erp systems',
      'shop floor control',
      'kpis'
    ],
    qualityScore: 0.78,
    contentTypeString: 'video',
    detailLevelString: 'medium',
    lengthCategoryString: 'short',
    strategyString: 'example',
    isClassBased: false,
    viewCount: 95000,
    contentLength: ContentLength.short,
    detailLevel: DetailLevel.medium,
    learningStrategy: LearningStrategy.exampleOnly,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'mrp inputs',
      'master production schedule',
      'rough cut capacity',
      'erp modules',
      'kanban boards',
      'oee metrics'
    ],
    transcriptSummary:
        'Eight‑hour LinkedIn Learning course on production scheduling, MRP, ERP systems, and OEE metrics.',
  ),
  const Course(
    id: 68,
    title: 'Strategic Procurement & Sourcing',
    provider: 'Coursera',
    level: 'Intermediate',
    type: 'Course',
    url: 'https://www.coursera.org/learn/strategic-procurement',
    category: 'Manufacturing',
    duration: '6 weeks',
    language: 'English',
    rating: 4.5,
    isFree: false,
    skills: [
      'supply chain',
      'vendor management',
      'negotiation',
      'communication skills',
      'strategic planning'
    ],
    topics: [
      'sourcing strategy',
      'supplier evaluation',
      'contract negotiation',
      'spend analysis',
      'risk management',
      'e‑procurement'
    ],
    qualityScore: 0.83,
    contentTypeString: 'video',
    detailLevelString: 'medium',
    lengthCategoryString: 'long',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 110000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.medium,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'make‑or‑buy decisions',
      'rfp/rfq',
      'supplier audits',
      'total cost of ownership',
      'contract types',
      'e‑sourcing platforms'
    ],
    transcriptSummary:
        'Six‑week strategic procurement course covering sourcing strategy, supplier evaluation, and contract negotiation.',
  ),
  // Retail
  const Course(
    id: 69,
    title: 'Retail Sales & Customer Service Excellence',
    provider: 'Udemy',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.udemy.com/course/retail-sales-customer-service',
    category: 'Retail',
    duration: '4 hours',
    language: 'English',
    rating: 4.3,
    isFree: false,
    skills: [
      'customer service',
      'sales',
      'communication skills',
      'merchandising',
      'product knowledge'
    ],
    topics: [
      'retail fundamentals',
      'customer service techniques',
      'upselling',
      'merchandising',
      'handling complaints'
    ],
    qualityScore: 0.75,
    contentTypeString: 'video',
    detailLevelString: 'low',
    lengthCategoryString: 'short',
    strategyString: 'example',
    isClassBased: false,
    viewCount: 85000,
    contentLength: ContentLength.short,
    detailLevel: DetailLevel.low,
    learningStrategy: LearningStrategy.exampleOnly,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'greeting customers',
      'needs analysis',
      'upsell scripts',
      'planogram basics',
      'complaint resolution',
      'pos systems'
    ],
    transcriptSummary:
        'Four‑hour practical retail course covering customer service scripts, merchandising layout, and sales techniques.',
  ),
  const Course(
    id: 70,
    title: 'E-Commerce & Online Retail Strategy',
    provider: 'Coursera',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.coursera.org/learn/ecommerce-strategy',
    category: 'Retail',
    duration: '5 weeks',
    language: 'English',
    rating: 4.5,
    isFree: false,
    skills: [
      'merchandising',
      'seo',
      'customer service',
      'data analysis',
      'market research',
      'sales'
    ],
    topics: [
      'e‑commerce platforms',
      'product listings',
      'seo for retail',
      'conversion optimisation',
      'fulfilment',
      'customer retention'
    ],
    qualityScore: 0.83,
    contentTypeString: 'video',
    detailLevelString: 'medium',
    lengthCategoryString: 'medium',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 130000,
    contentLength: ContentLength.medium,
    detailLevel: DetailLevel.medium,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'shopify setup',
      'product photography',
      'a/b testing',
      'cart abandonment',
      '3pl logistics',
      'email retargeting',
      'reviews management'
    ],
    transcriptSummary:
        'Five‑week e‑commerce strategy course covering platform setup, SEO, conversion optimisation, and fulfilment.',
  ),
  const Course(
    id: 71,
    title: 'Business Development & Negotiation Skills',
    provider: 'LinkedIn Learning',
    level: 'Intermediate',
    type: 'Course',
    url: 'https://www.linkedin.com/learning/negotiation-skills',
    category: 'Retail',
    duration: '6 hours',
    language: 'English',
    rating: 4.4,
    isFree: false,
    skills: [
      'sales',
      'business development',
      'negotiation',
      'communication skills',
      'market research'
    ],
    topics: [
      'negotiation tactics',
      'persuasion',
      'stakeholder management',
      'business development cycle',
      'pitching',
      'closing deals'
    ],
    qualityScore: 0.78,
    contentTypeString: 'video',
    detailLevelString: 'medium',
    lengthCategoryString: 'short',
    strategyString: 'example',
    isClassBased: false,
    viewCount: 70000,
    contentLength: ContentLength.short,
    detailLevel: DetailLevel.medium,
    learningStrategy: LearningStrategy.exampleOnly,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'batna',
      'anchoring',
      'mirroring',
      'objection handling',
      'discovery calls',
      'pipeline management',
      'contract negotiation'
    ],
    transcriptSummary:
        'Six‑hour LinkedIn Learning course on negotiation tactics, sales pipeline management, and deal‑closing techniques.',
  ),
  // Education
  const Course(
    id: 72,
    title: 'Instructional Design for E-Learning',
    provider: 'Coursera',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.coursera.org/learn/instructional-design-ell',
    category: 'Education',
    duration: '6 weeks',
    language: 'English',
    rating: 4.6,
    isFree: false,
    skills: [
      'curriculum design',
      'edtech',
      'content writing',
      'communication skills',
      'research'
    ],
    topics: [
      'addie model',
      'learning objectives',
      'storyboarding',
      'e‑learning authoring',
      'assessment design',
      'accessibility'
    ],
    qualityScore: 0.85,
    contentTypeString: 'video',
    detailLevelString: 'medium',
    lengthCategoryString: 'long',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 160000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.medium,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'addie',
      'blooms taxonomy',
      'storyboard tools',
      'articulate storyline',
      'scorm',
      'accessibility wcag',
      'lms integration'
    ],
    transcriptSummary:
        'Six‑week instructional design course covering ADDIE, learning objectives, and e‑learning authoring tools.',
  ),
  const Course(
    id: 73,
    title: 'Teaching & Learning Online',
    provider: 'edX',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.edx.org/learn/teaching',
    category: 'Education',
    duration: '5 weeks',
    language: 'English',
    rating: 4.5,
    isFree: true,
    skills: [
      'teaching',
      'curriculum design',
      'edtech',
      'research',
      'communication skills'
    ],
    topics: [
      'pedagogy',
      'online facilitation',
      'learner engagement',
      'formative assessment',
      'edtech tools',
      'feedback'
    ],
    qualityScore: 0.83,
    contentTypeString: 'video',
    detailLevelString: 'medium',
    lengthCategoryString: 'medium',
    strategyString: 'theory',
    isClassBased: true,
    viewCount: 200000,
    contentLength: ContentLength.medium,
    detailLevel: DetailLevel.medium,
    learningStrategy: LearningStrategy.theoryOnly,
    isClassroomBased: true,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'synchronous vs asynchronous',
      'zoom facilitation',
      'discussion prompts',
      'peer assessment',
      'lms forums',
      'rubric design'
    ],
    transcriptSummary:
        'Five‑week university‑style course on online pedagogy, learner engagement strategies, and formative assessment design.',
  ),
  const Course(
    id: 74,
    title: 'Corporate Training & Facilitation',
    provider: 'LinkedIn Learning',
    level: 'Intermediate',
    type: 'Course',
    url: 'https://www.linkedin.com/learning/training-facilitation',
    category: 'Education',
    duration: '8 hours',
    language: 'English',
    rating: 4.4,
    isFree: false,
    skills: [
      'teaching',
      'curriculum design',
      'presentation skills',
      'communication skills',
      'training'
    ],
    topics: [
      'needs analysis',
      'workshop design',
      'facilitation techniques',
      'blended learning',
      'evaluation',
      'coaching'
    ],
    qualityScore: 0.78,
    contentTypeString: 'video',
    detailLevelString: 'medium',
    lengthCategoryString: 'short',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 88000,
    contentLength: ContentLength.short,
    detailLevel: DetailLevel.medium,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'training needs analysis',
      'icebreakers',
      'breakout rooms',
      'kirkpatrick model',
      'coaching conversations',
      'hybrid facilitation'
    ],
    transcriptSummary:
        'Eight‑hour facilitation course covering training needs analysis, workshop design, and Kirkpatrick evaluation.',
  ),
  // Cross‑industry
  const Course(
    id: 75,
    title: 'IBM Data Analyst Professional Certificate',
    provider: 'Coursera',
    level: 'Beginner',
    type: 'Certificate',
    url: 'https://www.coursera.org/professional-certificates/ibm-data-analyst',
    category: 'Data Science',
    duration: '11 months',
    language: 'English',
    rating: 4.7,
    isFree: false,
    skills: [
      'python',
      'data analysis',
      'sql',
      'excel',
      'pandas',
      'reporting',
      'data visualisation'
    ],
    topics: [
      'data analysis methodology',
      'python basics',
      'sql querying',
      'excel analytics',
      'visualisation',
      'capstone project'
    ],
    qualityScore: 0.91,
    contentTypeString: 'video',
    detailLevelString: 'high',
    lengthCategoryString: 'long',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 1100000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.high,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'data lifecycle',
      'python lists/dicts',
      'pandas merge',
      'sql window functions',
      'cognos analytics',
      'tableau',
      'capstone dataset'
    ],
    transcriptSummary:
        'IBM 11‑month end‑to‑end data analyst certificate covering Python, SQL, Excel, and Tableau with a capstone project.',
    thumbnailUrl:
        'https://d3njjcbhbojbot.cloudfront.net/api/utilities/v1/imageproxy/ibm-data-analyst.jpg',
  ),
  const Course(
    id: 76,
    title: 'Project Management Professional (PMP) Prep',
    provider: 'Udemy',
    level: 'Intermediate',
    type: 'Course',
    url: 'https://www.udemy.com/course/pmp-pmbok6-exam',
    category: 'Management',
    duration: '35 hours',
    language: 'English',
    rating: 4.6,
    isFree: false,
    skills: [
      'project management',
      'communication skills',
      'leadership',
      'risk analysis',
      'reporting'
    ],
    topics: [
      'pmbok framework',
      'project lifecycle',
      'scope management',
      'risk management',
      'stakeholder management',
      'agile overview'
    ],
    qualityScore: 0.85,
    contentTypeString: 'video',
    detailLevelString: 'high',
    lengthCategoryString: 'long',
    strategyString: 'theory',
    isClassBased: false,
    viewCount: 340000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.high,
    learningStrategy: LearningStrategy.theoryOnly,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'initiating process group',
      'wbs creation',
      'earned value',
      'critical path method',
      'risk register',
      'change control',
      'agile sprints'
    ],
    transcriptSummary:
        '35‑hour PMP exam prep covering PMBOK 7 knowledge areas, agile hybrids, and 200 practice questions.',
  ),
  const Course(
    id: 77,
    title: 'Communication Skills for Professionals',
    provider: 'Coursera',
    level: 'Beginner',
    type: 'Course',
    url: 'https://www.coursera.org/learn/communication-skills',
    category: 'Soft Skills',
    duration: '4 weeks',
    language: 'English',
    rating: 4.5,
    isFree: false,
    skills: [
      'communication skills',
      'presentation skills',
      'negotiation',
      'teamwork',
      'leadership'
    ],
    topics: [
      'verbal communication',
      'written communication',
      'active listening',
      'presentations',
      'conflict resolution',
      'cross‑cultural comms'
    ],
    qualityScore: 0.82,
    contentTypeString: 'video',
    detailLevelString: 'low',
    lengthCategoryString: 'medium',
    strategyString: 'example',
    isClassBased: false,
    viewCount: 420000,
    contentLength: ContentLength.medium,
    detailLevel: DetailLevel.low,
    learningStrategy: LearningStrategy.exampleOnly,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'non‑verbal cues',
      'elevator pitch',
      'email etiquette',
      'slide design',
      'feedback frameworks',
      'cultural intelligence'
    ],
    transcriptSummary:
        'Four‑week communication essentials course covering written, verbal, and presentation skills.',
  ),
  const Course(
    id: 78,
    title: 'Statistics & Probability for Data Science',
    provider: 'Khan Academy',
    level: 'Beginner',
    type: 'Video',
    url: 'https://www.khanacademy.org/math/statistics-probability',
    category: 'Data Science',
    duration: 'Self-paced',
    language: 'English',
    rating: 4.7,
    isFree: true,
    skills: [
      'statistics',
      'data analysis',
      'probability',
      'python',
      'research',
      'machine learning'
    ],
    topics: [
      'descriptive statistics',
      'probability',
      'distributions',
      'hypothesis testing',
      'regression',
      'confidence intervals'
    ],
    qualityScore: 0.89,
    contentTypeString: 'video',
    detailLevelString: 'medium',
    lengthCategoryString: 'long',
    strategyString: 'both',
    isClassBased: false,
    viewCount: 5000000,
    contentLength: ContentLength.long,
    detailLevel: DetailLevel.medium,
    learningStrategy: LearningStrategy.both,
    isClassroomBased: false,
    contentFormat: ContentFormat.video,
    topicsCovert: [
      'mean/median/mode',
      'standard deviation',
      'normal distribution',
      'z‑scores',
      'p‑values',
      'type I/II errors',
      'linear regression',
      'chi‑square'
    ],
    transcriptSummary:
        'Free self‑paced Khan Academy statistics curriculum covering descriptive stats, probability, and inferential testing.',
    thumbnailUrl:
        'https://cdn.kastatic.org/images/khan-logo-dark-background.png',
  ),
];

// =============================================================================
// §12  SORT, FILTER, RECOMMENDATION UTILITIES
// =============================================================================

List<Course> sortCourses(List<Course> list, CourseSortStrategy strategy) {
  final sorted = List<Course>.from(list);
  switch (strategy) {
    case CourseSortStrategy.ratingDesc:
      sorted.sort((a, b) => b.rating.compareTo(a.rating));
    case CourseSortStrategy.qualityScoreDesc:
      sorted.sort(
          (a, b) => (b.qualityScore ?? 0.0).compareTo(a.qualityScore ?? 0.0));
    case CourseSortStrategy.viewCountDesc:
      sorted.sort((a, b) => (b.viewCount ?? 0).compareTo(a.viewCount ?? 0));
    case CourseSortStrategy.recommendationScoreDesc:
      sorted.sort((a, b) => (b.recommendation?.score ?? 0.0)
          .compareTo(a.recommendation?.score ?? 0.0));
    case CourseSortStrategy.detailLevelAsc:
      sorted.sort((a, b) => a.detailLevel.rank.compareTo(b.detailLevel.rank));
    case CourseSortStrategy.detailLevelDesc:
      sorted.sort((a, b) => b.detailLevel.rank.compareTo(a.detailLevel.rank));
    case CourseSortStrategy.titleAZ:
      sorted.sort((a, b) => a.title.compareTo(b.title));
    case CourseSortStrategy.freeFirst:
      sorted.sort((a, b) {
        if (a.isFree == b.isFree) return 0;
        return a.isFree ? -1 : 1;
      });
  }
  return sorted;
}

List<Course> coursesByFilter(CourseFilter filter) =>
    courses.where(filter.matches).toList();

List<Course> recommendCourses(List<String> missingSkills) {
  if (missingSkills.isEmpty) return [];
  final lower = missingSkills.map((s) => s.toLowerCase()).toSet();
  return courses
      .where((c) => c.skills.any((s) => lower.contains(s.toLowerCase())))
      .toList()
    ..sort((a, b) =>
        b.matchScore(missingSkills).compareTo(a.matchScore(missingSkills)));
}

List<Course> coursesByCategory(String category) =>
    courses.where((c) => c.category == category).toList();

Course? bestCourseForSkill(String targetSkill) {
  final norm = targetSkill.trim().toLowerCase();
  final candidates = courses
      .where((c) => c.skills.any((s) => s.toLowerCase().contains(norm)))
      .toList()
    ..sort((a, b) => b.rating.compareTo(a.rating));
  return candidates.isEmpty ? null : candidates.first;
}

List<Course> coursesByMaxLevel(String level) {
  final order = {'Beginner': 0, 'Intermediate': 1, 'Advanced': 2};
  final max = order[level] ?? 2;
  return courses.where((c) => (order[c.level] ?? 0) <= max).toList();
}

List<Course> freeCourses() => courses.where((c) => c.isFree).toList();

List<Course> coursesByQuality() => courses.toList()
  ..sort((a, b) => (b.qualityScore ?? 0.0).compareTo(a.qualityScore ?? 0.0));

List<Course> coursesByLength(String band) =>
    courses.where((c) => c.contentLength.displayName == band).toList();

List<Course> rankByPreference(
        List<Course> list, List<double> preferenceVector) =>
    list.toList()
      ..sort((a, b) => b
          .dotProductWithList(preferenceVector)
          .compareTo(a.dotProductWithList(preferenceVector)));

List<String> get allCourseCategories =>
    courses.map((c) => c.category).toSet().toList()..sort();
List<String> get allCourseProviders =>
    courses.map((c) => c.provider).toSet().toList()..sort();

// Additional recommendation engines (Tavakoli 2022)
List<Course> recommendByPreferenceVector(List<double> prefVector,
    {List<String> missingSkills = const [], int? topN}) {
  if (prefVector.length != 15) {
    throw ArgumentError(
        'prefVector must be 15‑dimensional; got ${prefVector.length}');
  }
  final candidates = courses
      .where((c) => c.passesQualityFilter)
      .map((c) {
        final dot = c.dotProductWithList(prefVector);
        final overlap =
            missingSkills.isEmpty ? 0.0 : c.matchScore(missingSkills);
        final score = dot + (overlap * 0.5);
        return (course: c, score: score);
      })
      .where((e) => e.score > 0)
      .toList()
    ..sort((a, b) => b.score.compareTo(a.score));
  final results = candidates.map((e) => e.course).toList();
  return topN != null ? results.take(topN).toList() : results;
}

List<CourseRecommendation> rankByRecommendationScore(List<double> prefVector,
    {List<String> missingSkills = const [], int? topN}) {
  if (prefVector.length != 15) {
    throw ArgumentError(
        'prefVector must be 15‑dimensional; got ${prefVector.length}');
  }
  final recs = courses
      .where((c) => c.passesQualityFilter)
      .map((c) {
        final dot = c.dotProductWithList(prefVector);
        final boost =
            (missingSkills.isEmpty ? 0.0 : c.matchScore(missingSkills)) * 0.5;
        final score = dot + boost;
        return CourseRecommendation(
            course: c, score: score, dotProduct: dot, skillBoost: boost);
      })
      .where((r) => r.score > 0)
      .toList()
    ..sort((a, b) => b.score.compareTo(a.score));
  return topN != null ? recs.take(topN).toList() : recs;
}

List<Course> recommendByPreference(Map<String, double> prefVector,
    {List<String> missingSkills = const [], int? topN}) {
  final candidates = courses
      .where((c) => c.passesQualityFilter)
      .map((c) {
        final dot = c.dotProductWith(prefVector);
        final overlap =
            missingSkills.isEmpty ? 0.0 : c.matchScore(missingSkills);
        final score = dot + (overlap * 0.5);
        return (course: c, score: score);
      })
      .where((e) => e.score > 0)
      .toList()
    ..sort((a, b) => b.score.compareTo(a.score));
  final results = candidates.map((e) => e.course).toList();
  return topN != null ? results.take(topN).toList() : results;
}

List<Course> rankByCosineSimilarity(List<double> prefVector, {int? topN}) {
  if (prefVector.length != 15) {
    throw ArgumentError('prefVector must be 15‑dimensional.');
  }
  final ranked = courses
      .map((c) => (course: c, score: c.cosineSimilarity(prefVector)))
      .where((e) => e.score > 0)
      .toList()
    ..sort((a, b) => b.score.compareTo(a.score));
  final results = ranked.map((e) => e.course).toList();
  return topN != null ? results.take(topN).toList() : results;
}

// Additional helpers
List<Course> coursesMatchingAnySkill(List<String> targetSkills) =>
    targetSkills.isEmpty
        ? []
        : courses.where((c) => c.coversAnySkill(targetSkills)).toList();

List<Course> topCoursesByRating({int topN = 10, double minRating = 4.0}) =>
    sortCourses(
            courses
                .where((c) => c.passesQualityFilter && c.rating >= minRating)
                .toList(),
            CourseSortStrategy.ratingDesc)
        .take(topN)
        .toList();

List<Course> computeAllFeatureVecs() => courses
    .map((c) => c.copyWith(featureVector: c.computeFeatureVector()))
    .toList();

CourseStats courseStats() => CourseStats.fromCourses(courses);

Map<String, List<Course>> groupByCategory([List<Course>? list]) {
  final src = list ?? courses;
  final map = <String, List<Course>>{};
  for (final c in src) {
    map.putIfAbsent(c.category, () => []).add(c);
  }
  return map;
}

Map<String, List<Course>> groupByProvider([List<Course>? list]) {
  final src = list ?? courses;
  final map = <String, List<Course>>{};
  for (final c in src) {
    map.putIfAbsent(c.provider, () => []).add(c);
  }
  return map;
}

// Legacy session 2 helpers
List<Course> get freeCoursesList => courses.where((c) => c.isFree).toList();
List<Course> coursesByLevel(String level) =>
    courses.where((c) => c.level == level).toList();
List<Course> qualityFilteredCourses({double minScore = 0.5}) =>
    courses.where((c) => c.passesQualityFilter).toList();
List<Course> coursesByContentFormat(ContentFormat format) =>
    courses.where((c) => c.contentFormat == format).toList();
List<Course> coursesByContentLength(ContentLength length) =>
    courses.where((c) => c.contentLength == length).toList();
List<Course> coursesByDetailLevel(DetailLevel level) =>
    courses.where((c) => c.detailLevel == level).toList();
List<Course> coursesByStrategy(LearningStrategy strategy) =>
    courses.where((c) => c.learningStrategy == strategy).toList();
List<Course> coursesByTopic(String topic) {
  final needle = topic.toLowerCase();
  return courses
      .where((c) =>
          c.topics.any((t) => t.toLowerCase().contains(needle)) ||
          c.topicsCovert.any((t) => t.toLowerCase().contains(needle)))
      .toList();
}

List<Course> premiumFreeCourses() =>
    courses.where((c) => c.isPremiumFree).toList();
List<Course> entryFriendlyCourses() =>
    courses.where((c) => c.isEntryFriendly).toList();
List<Course> certificateCourses() =>
    courses.where((c) => c.isCertificateLevel).toList();
