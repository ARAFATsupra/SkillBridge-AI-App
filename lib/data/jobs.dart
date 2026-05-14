// lib/data/jobs.dart — SkillBridge AI (Combined)

import 'package:flutter/material.dart';

// =============================================================================
// SENTINEL — clean nullable copyWith without boolean clear‑flags
// =============================================================================

class _Unset {
  const _Unset();
}

const _unset = _Unset();

// =============================================================================
// ENUMS
// =============================================================================

// ── 2.1  JobType ─────────────────────────────────────────────────────────────

enum JobType {
  fullTime('full-time'),
  partTime('part-time'),
  contract('contract'),
  temporary('temporary'),
  intern('intern');

  const JobType(this.value);
  final String value;

  static JobType fromString(String raw) {
    final lower = raw.toLowerCase().trim();
    for (final t in JobType.values) {
      if (t.value == lower) return t;
    }
    return JobType.fullTime;
  }

  String get displayName => switch (this) {
        JobType.fullTime => 'Full-Time',
        JobType.partTime => 'Part-Time',
        JobType.contract => 'Contract',
        JobType.temporary => 'Temporary',
        JobType.intern => 'Internship',
      };

  bool get isPermanent => this == JobType.fullTime || this == JobType.partTime;
}

// ── 2.2  JobLevel ────────────────────────────────────────────────────────────

enum JobLevel {
  entry('Entry Level'),
  mid('Mid Level'),
  senior('Senior Level');

  const JobLevel(this.value);
  final String value;

  static JobLevel fromString(String raw) {
    for (final l in JobLevel.values) {
      if (l.value == raw.trim()) return l;
    }
    return JobLevel.entry;
  }

  int get rank => index + 1;
  String get displayName => value;
}

// ── 2.3  WorkingModeEnum ─────────────────────────────────────────────────────

enum WorkingModeEnum {
  remote('Remote'),
  onSite('On-site'),
  hybrid('Hybrid');

  const WorkingModeEnum(this.value);
  final String value;

  static WorkingModeEnum fromString(String raw) {
    for (final m in WorkingModeEnum.values) {
      if (m.value == raw.trim()) return m;
    }
    return WorkingModeEnum.onSite;
  }

  bool get allowsRemote =>
      this == WorkingModeEnum.remote || this == WorkingModeEnum.hybrid;
}

// ── 2.4  AutomationRiskTier ──────────────────────────────────────────────────

enum AutomationRiskTier {
  low,
  medium,
  high,
  unknown;

  static AutomationRiskTier fromScore(double? score) {
    if (score == null) return AutomationRiskTier.unknown;
    if (score < 0.30) return AutomationRiskTier.low;
    if (score < 0.70) return AutomationRiskTier.medium;
    return AutomationRiskTier.high;
  }

  String get label => switch (this) {
        AutomationRiskTier.low => 'Low Risk',
        AutomationRiskTier.medium => 'Medium Risk',
        AutomationRiskTier.high => 'High Risk',
        AutomationRiskTier.unknown => 'Unknown',
      };

  String get hexColor => switch (this) {
        AutomationRiskTier.low => '#4CAF50',
        AutomationRiskTier.medium => '#FF9800',
        AutomationRiskTier.high => '#F44336',
        AutomationRiskTier.unknown => '#9E9E9E',
      };

  Color get color => switch (this) {
        AutomationRiskTier.low => Colors.green,
        AutomationRiskTier.medium => Colors.orange,
        AutomationRiskTier.high => Colors.red,
        AutomationRiskTier.unknown => Colors.grey,
      };

  bool get isSafe => this == AutomationRiskTier.low;
}

// ── 2.5  SdgImpactType ───────────────────────────────────────────────────────

enum SdgImpactType {
  decentWork('Decent Work'),
  skillsTraining('Skills Training'),
  youthEmployment('Youth Employment'),
  inclusiveGrowth('Inclusive Growth'),
  productivity('Productivity');

  const SdgImpactType(this.label);
  final String label;

  static SdgImpactType? fromString(String raw) {
    for (final s in SdgImpactType.values) {
      if (s.label == raw.trim()) return s;
    }
    return null;
  }

  IconData get icon => switch (this) {
        SdgImpactType.decentWork => Icons.work_outline_rounded,
        SdgImpactType.skillsTraining => Icons.school_outlined,
        SdgImpactType.youthEmployment => Icons.people_outline_rounded,
        SdgImpactType.inclusiveGrowth => Icons.trending_up_rounded,
        SdgImpactType.productivity => Icons.bolt_outlined,
      };
}

// ── 2.6  SimScoreTier ────────────────────────────────────────────────────────

enum SimScoreTier {
  strong,
  moderate,
  weak;

  static SimScoreTier fromScore(double score) {
    if (score >= 0.75) return SimScoreTier.strong;
    if (score >= 0.40) return SimScoreTier.moderate;
    return SimScoreTier.weak;
  }

  String get label => switch (this) {
        SimScoreTier.strong => 'Strong Match',
        SimScoreTier.moderate => 'Moderate Match',
        SimScoreTier.weak => 'Weak Match',
      };

  Color get color => switch (this) {
        SimScoreTier.strong => Colors.green.shade700,
        SimScoreTier.moderate => Colors.orange.shade700,
        SimScoreTier.weak => Colors.red.shade700,
      };

  bool get isActionable =>
      this == SimScoreTier.strong || this == SimScoreTier.moderate;
}

// ── 2.7  PostingGrowthCategory ───────────────────────────────────────────────

enum PostingGrowthCategory {
  declining, // < 0
  stable, // 0 – 0.05
  growing, // 0.05 – 0.20
  highGrowth; // > 0.20

  static PostingGrowthCategory fromRate(double? rate) {
    final r = rate ?? 0.0;
    if (r < 0.0) return PostingGrowthCategory.declining;
    if (r < 0.05) return PostingGrowthCategory.stable;
    if (r <= 0.20) return PostingGrowthCategory.growing;
    return PostingGrowthCategory.highGrowth;
  }

  String get label => switch (this) {
        PostingGrowthCategory.declining => 'Declining',
        PostingGrowthCategory.stable => 'Stable',
        PostingGrowthCategory.growing => 'Growing',
        PostingGrowthCategory.highGrowth => 'High Growth',
      };

  Color get color => switch (this) {
        PostingGrowthCategory.declining => Colors.red.shade600,
        PostingGrowthCategory.stable => Colors.grey.shade600,
        PostingGrowthCategory.growing => Colors.blue.shade600,
        PostingGrowthCategory.highGrowth => Colors.green.shade700,
      };
}

// ── 2.8  JobSortStrategy ─────────────────────────────────────────────────────

enum JobSortStrategy {
  simScore,
  postingGrowthRate,
  postingFrequency,
  automationRiskAsc,
  transitionDistanceAsc,
  mostRecent,
  experienceAsc,
  careerFitScore,
}

// =============================================================================
// JOBFILTER — immutable filter specification
// =============================================================================

@immutable
class JobFilter {
  final String industry;
  final String level;
  final bool remoteOnly;
  final String occupationalGroup;
  final double? maxAutomationRisk;
  final String? sdgImpact;
  final bool? essentialOnly;
  final bool? trendingOnly;
  final bool? pivotSkillOnly;
  final int? maxTransitionDistance;
  final List<String> requiredSkills;
  final int? maxExperienceYears;
  final PostingGrowthCategory? minGrowthCategory;

  const JobFilter({
    this.industry = 'All',
    this.level = 'All',
    this.remoteOnly = false,
    this.occupationalGroup = 'All',
    this.maxAutomationRisk,
    this.sdgImpact,
    this.essentialOnly,
    this.trendingOnly,
    this.pivotSkillOnly,
    this.maxTransitionDistance,
    this.requiredSkills = const [],
    this.maxExperienceYears,
    this.minGrowthCategory,
  });

  bool matches(Job job) {
    if (industry != 'All' && job.industry != industry) return false;
    if (level != 'All' && job.level != level) return false;
    if (remoteOnly && !job.remote) return false;
    if (occupationalGroup != 'All' &&
        job.occupationalGroup != occupationalGroup) {
      return false;
    }
    if (maxAutomationRisk != null &&
        job.automationRisk != null &&
        job.automationRisk! > maxAutomationRisk!) {
      return false;
    }
    if (sdgImpact != null && job.sdgImpact != sdgImpact) return false;
    if (essentialOnly == true && !job.isEssentialDuringCrisis) return false;
    if (trendingOnly == true && !job.isTrending) return false;
    if (pivotSkillOnly == true && !job.isPivotSkillJob) return false;
    if (maxTransitionDistance != null &&
        job.transitionDistance > maxTransitionDistance!) {
      return false;
    }
    if (maxExperienceYears != null && job.experience > maxExperienceYears!) {
      return false;
    }
    if (minGrowthCategory != null) {
      final cat = PostingGrowthCategory.fromRate(job.postingGrowthRate);
      if (cat.index < minGrowthCategory!.index) return false;
    }
    if (requiredSkills.isNotEmpty) {
      final jobLower = job.skills.map((s) => s.toLowerCase()).toSet();
      for (final req in requiredSkills) {
        if (!jobLower.contains(req.toLowerCase())) return false;
      }
    }
    return true;
  }

  JobFilter copyWith({
    String? industry,
    String? level,
    bool? remoteOnly,
    String? occupationalGroup,
    Object? maxAutomationRisk = _unset,
    Object? sdgImpact = _unset,
    Object? essentialOnly = _unset,
    Object? trendingOnly = _unset,
    Object? pivotSkillOnly = _unset,
    Object? maxTransitionDistance = _unset,
    List<String>? requiredSkills,
    Object? maxExperienceYears = _unset,
    Object? minGrowthCategory = _unset,
  }) {
    return JobFilter(
      industry: industry ?? this.industry,
      level: level ?? this.level,
      remoteOnly: remoteOnly ?? this.remoteOnly,
      occupationalGroup: occupationalGroup ?? this.occupationalGroup,
      maxAutomationRisk: maxAutomationRisk is _Unset
          ? this.maxAutomationRisk
          : maxAutomationRisk as double?,
      sdgImpact: sdgImpact is _Unset ? this.sdgImpact : sdgImpact as String?,
      essentialOnly:
          essentialOnly is _Unset ? this.essentialOnly : essentialOnly as bool?,
      trendingOnly:
          trendingOnly is _Unset ? this.trendingOnly : trendingOnly as bool?,
      pivotSkillOnly: pivotSkillOnly is _Unset
          ? this.pivotSkillOnly
          : pivotSkillOnly as bool?,
      maxTransitionDistance: maxTransitionDistance is _Unset
          ? this.maxTransitionDistance
          : maxTransitionDistance as int?,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      maxExperienceYears: maxExperienceYears is _Unset
          ? this.maxExperienceYears
          : maxExperienceYears as int?,
      minGrowthCategory: minGrowthCategory is _Unset
          ? this.minGrowthCategory
          : minGrowthCategory as PostingGrowthCategory?,
    );
  }

  static const JobFilter none = JobFilter();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JobFilter &&
        other.industry == industry &&
        other.level == level &&
        other.remoteOnly == remoteOnly &&
        other.occupationalGroup == occupationalGroup &&
        other.maxAutomationRisk == maxAutomationRisk &&
        other.sdgImpact == sdgImpact &&
        other.essentialOnly == essentialOnly &&
        other.trendingOnly == trendingOnly &&
        other.pivotSkillOnly == pivotSkillOnly &&
        other.maxTransitionDistance == maxTransitionDistance &&
        other.maxExperienceYears == maxExperienceYears &&
        other.minGrowthCategory == minGrowthCategory;
  }

  @override
  int get hashCode => Object.hash(
        industry,
        level,
        remoteOnly,
        occupationalGroup,
        maxAutomationRisk,
        sdgImpact,
        essentialOnly,
        trendingOnly,
        pivotSkillOnly,
        maxTransitionDistance,
        maxExperienceYears,
        minGrowthCategory,
      );

  @override
  String toString() =>
      'JobFilter(industry: $industry, level: $level, remoteOnly: $remoteOnly)';
}

// =============================================================================
// CAREERFITSCORE — composite 4‑axis fit score
// =============================================================================

@immutable
class CareerFitScore {
  final double skillMatch;
  final double growthPotential;
  final double automationSafety;
  final double transitionEase;
  final double composite;
  final String grade;

  static const double _wSkill = 0.40;
  static const double _wGrowth = 0.25;
  static const double _wSafety = 0.20;
  static const double _wTransition = 0.15;

  const CareerFitScore({
    required this.skillMatch,
    required this.growthPotential,
    required this.automationSafety,
    required this.transitionEase,
    required this.composite,
    required this.grade,
  });

  factory CareerFitScore.compute(Job job, List<String> userSkills) {
    final skillMatch =
        job.simScore > 0.0 ? job.simScore : job.matchScore(userSkills);
    final growthRaw = (job.postingGrowthRate ?? 0.0).clamp(-0.50, 0.50);
    final growthPotential = ((growthRaw + 0.50) / 1.00).clamp(0.0, 1.0);
    final automationSafety =
        (1.0 - (job.automationRisk ?? 0.50)).clamp(0.0, 1.0);
    final totalSkills = job.skills.length;
    final missingCount = job.computeTransitionDistance(userSkills);
    final transitionEase = totalSkills > 0
        ? (1.0 - missingCount / totalSkills).clamp(0.0, 1.0)
        : 1.0;
    final composite = (skillMatch * _wSkill +
            growthPotential * _wGrowth +
            automationSafety * _wSafety +
            transitionEase * _wTransition)
        .clamp(0.0, 1.0);
    return CareerFitScore(
      skillMatch: skillMatch,
      growthPotential: growthPotential,
      automationSafety: automationSafety,
      transitionEase: transitionEase,
      composite: composite,
      grade: _gradeFromComposite(composite),
    );
  }

  static String _gradeFromComposite(double c) {
    if (c >= 0.90) return 'A+';
    if (c >= 0.80) return 'A';
    if (c >= 0.70) return 'B';
    if (c >= 0.60) return 'C';
    if (c >= 0.50) return 'D';
    return 'F';
  }

  String get compositeLabel => '${(composite * 100).round()}% fit ($grade)';
  String get compositePercent => '${(composite * 100).round()}%';
  bool get isRecommended => composite >= 0.50;

  String get weakestAxis {
    double min = skillMatch;
    String name = 'Skill Match';
    if (growthPotential < min) {
      min = growthPotential;
      name = 'Growth Potential';
    }
    if (automationSafety < min) {
      min = automationSafety;
      name = 'Automation Safety';
    }
    if (transitionEase < min) {
      name = 'Transition Ease';
    }
    return name;
  }

  String get strongestAxis {
    double max = skillMatch;
    String name = 'Skill Match';
    if (growthPotential > max) {
      max = growthPotential;
      name = 'Growth Potential';
    }
    if (automationSafety > max) {
      max = automationSafety;
      name = 'Automation Safety';
    }
    if (transitionEase > max) {
      name = 'Transition Ease';
    }
    return name;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CareerFitScore &&
          other.composite == composite &&
          other.grade == grade);

  @override
  int get hashCode => Object.hash(composite, grade);

  @override
  String toString() =>
      'CareerFitScore(composite: ${composite.toStringAsFixed(2)}, grade: $grade)';
}

// =============================================================================
// SKILLGAPANALYSIS — per‑job/user skill‑gap report
// =============================================================================

@immutable
class SkillGapAnalysis {
  final String jobTitle;
  final String jobId;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final double coverageRatio;
  final String readinessLabel;

  const SkillGapAnalysis({
    required this.jobTitle,
    required this.jobId,
    required this.matchedSkills,
    required this.missingSkills,
    required this.coverageRatio,
    required this.readinessLabel,
  });

  factory SkillGapAnalysis.compute(Job job, List<String> userSkills) {
    final lower = userSkills.map((s) => s.toLowerCase()).toSet();
    final matched =
        job.skills.where((s) => lower.contains(s.toLowerCase())).toList();
    final missing =
        job.skills.where((s) => !lower.contains(s.toLowerCase())).toList();
    final coverage =
        job.skills.isEmpty ? 1.0 : matched.length / job.skills.length;
    final readiness = coverage >= 0.80
        ? 'Ready'
        : coverage >= 0.50
            ? 'Almost Ready'
            : 'Needs Training';
    return SkillGapAnalysis(
      jobTitle: job.title,
      jobId: job.id.toString(),
      matchedSkills: List.unmodifiable(matched),
      missingSkills: List.unmodifiable(missing),
      coverageRatio: coverage,
      readinessLabel: readiness,
    );
  }

  String get coverageLabel =>
      '${(coverageRatio * 100).round()}% skills matched';
  int get gapCount => missingSkills.length;
  bool get isReady => readinessLabel == 'Ready';
  bool get isActionable => readinessLabel != 'Needs Training';
  int get estimatedWeeksToClose => gapCount * 3;

  @override
  String toString() =>
      'SkillGapAnalysis(job: "$jobTitle", coverage: ${(coverageRatio * 100).round()}%, gap: $gapCount skills)';
}

// =============================================================================
// JOBSTATS — aggregate analytics across a List<Job>
// =============================================================================

class JobStats {
  final int total;
  final double meanSimScore;
  final double meanAutomationRisk;
  final Map<String, int> countByIndustry;
  final Map<String, int> countByLevel;
  final Map<String, int> countByWorkingMode;
  final Map<String, int> countByOccupationalGroup;
  final int remoteCount;
  final int trendingCount;
  final int essentialCount;
  final int pivotSkillCount;
  final double meanPostingGrowthRate;
  final List<String> topSkills;

  const JobStats({
    required this.total,
    required this.meanSimScore,
    required this.meanAutomationRisk,
    required this.countByIndustry,
    required this.countByLevel,
    required this.countByWorkingMode,
    required this.countByOccupationalGroup,
    required this.remoteCount,
    required this.trendingCount,
    required this.essentialCount,
    required this.pivotSkillCount,
    required this.meanPostingGrowthRate,
    required this.topSkills,
  });

  factory JobStats.fromJobs(List<Job> jobs) {
    if (jobs.isEmpty) {
      return const JobStats(
        total: 0,
        meanSimScore: 0,
        meanAutomationRisk: 0,
        countByIndustry: {},
        countByLevel: {},
        countByWorkingMode: {},
        countByOccupationalGroup: {},
        remoteCount: 0,
        trendingCount: 0,
        essentialCount: 0,
        pivotSkillCount: 0,
        meanPostingGrowthRate: 0,
        topSkills: [],
      );
    }

    double simSum = 0;
    double riskSum = 0;
    int riskCount = 0;
    double growthSum = 0;
    int growthCount = 0;
    final byIndustry = <String, int>{};
    final byLevel = <String, int>{};
    final byMode = <String, int>{};
    final byGroup = <String, int>{};
    final skillFreq = <String, int>{};

    for (final j in jobs) {
      simSum += j.simScore;
      if (j.automationRisk != null) {
        riskSum += j.automationRisk!;
        riskCount++;
      }
      if (j.postingGrowthRate != null) {
        growthSum += j.postingGrowthRate!;
        growthCount++;
      }
      byIndustry[j.industry] = (byIndustry[j.industry] ?? 0) + 1;
      byLevel[j.level] = (byLevel[j.level] ?? 0) + 1;
      byMode[j.workingMode] = (byMode[j.workingMode] ?? 0) + 1;
      if (j.occupationalGroup.isNotEmpty) {
        byGroup[j.occupationalGroup] = (byGroup[j.occupationalGroup] ?? 0) + 1;
      }
      for (final s in j.skills) {
        final key = s.toLowerCase();
        skillFreq[key] = (skillFreq[key] ?? 0) + 1;
      }
    }

    final topSkills = (skillFreq.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(10)
        .map((e) => e.key)
        .toList();

    return JobStats(
      total: jobs.length,
      meanSimScore: simSum / jobs.length,
      meanAutomationRisk: riskCount > 0 ? riskSum / riskCount : 0.0,
      countByIndustry: Map.unmodifiable(byIndustry),
      countByLevel: Map.unmodifiable(byLevel),
      countByWorkingMode: Map.unmodifiable(byMode),
      countByOccupationalGroup: Map.unmodifiable(byGroup),
      remoteCount: jobs.where((j) => j.remote).length,
      trendingCount: jobs.where((j) => j.isTrending).length,
      essentialCount: jobs.where((j) => j.isEssentialDuringCrisis).length,
      pivotSkillCount: jobs.where((j) => j.isPivotSkillJob).length,
      meanPostingGrowthRate: growthCount > 0 ? growthSum / growthCount : 0.0,
      topSkills: topSkills,
    );
  }

  double get remoteRatio => total > 0 ? remoteCount / total : 0.0;
  double get trendingRatio => total > 0 ? trendingCount / total : 0.0;
  double get essentialRatio => total > 0 ? essentialCount / total : 0.0;

  String get dominantIndustry => countByIndustry.isEmpty
      ? 'N/A'
      : (countByIndustry.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .first
          .key;

  @override
  String toString() =>
      'JobStats(total: $total, remote: $remoteCount, trending: $trendingCount)';
}

// =============================================================================
// JOB MODEL (Enhanced)
// =============================================================================

@immutable
class Job {
  // ── Original fields ────────────────────────────────────────────────────────
  final int id;
  final String title;
  final String company;
  final String type; // full-time | part-time | contract | temporary | intern
  final String level; // Entry Level | Mid Level | Senior Level
  final String location;
  final String salary;
  final int experience;
  final String industry;
  final bool remote;
  final String workingMode; // Remote | On-site | Hybrid
  final DateTime posted;
  final List<String> skills;
  final List<String> benefits;

  // ── Session 1 fields ───────────────────────────────────────────────────────
  final double simScore;
  final Map<String, double> weightedSkillVec;
  final String sdgImpact;
  final bool isTrending;
  final bool isPivotSkillJob;
  final int transitionDistance;

  // ── Session 2 fields ───────────────────────────────────────────────────────
  final double? automationRisk;
  final bool isEssentialDuringCrisis;
  final Map<String, double>? educationRequirements;
  final Map<String, double>? cityDemand;
  final double? postingFrequency;
  final double? postingGrowthRate;
  final String occupationalGroup;
  final double? rcaScore;
  final double? transitionProbability;

  // ── Session 3 fields ───────────────────────────────────────────────────────
  final CareerFitScore? careerFitScore;
  final SkillGapAnalysis? skillGapAnalysis;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.type,
    required this.level,
    required this.location,
    required this.salary,
    required this.experience,
    required this.industry,
    required this.remote,
    required this.workingMode,
    required this.posted,
    required this.skills,
    this.benefits = const [],
    this.simScore = 0.0,
    this.weightedSkillVec = const {},
    this.sdgImpact = '',
    this.isTrending = false,
    this.isPivotSkillJob = false,
    this.transitionDistance = 0,
    this.automationRisk,
    this.isEssentialDuringCrisis = false,
    this.educationRequirements,
    this.cityDemand,
    this.postingFrequency,
    this.postingGrowthRate,
    this.occupationalGroup = '',
    this.rcaScore,
    this.transitionProbability,
    this.careerFitScore,
    this.skillGapAnalysis,
  });

  // ── Enum getters ───────────────────────────────────────────────────────────
  JobType get jobTypeEnum => JobType.fromString(type);
  JobLevel get jobLevelEnum => JobLevel.fromString(level);
  WorkingModeEnum get workingModeEnum =>
      WorkingModeEnum.fromString(workingMode);
  AutomationRiskTier get automationRiskTier =>
      AutomationRiskTier.fromScore(automationRisk);
  SdgImpactType? get sdgImpactType => SdgImpactType.fromString(sdgImpact);
  SimScoreTier get simScoreTier => SimScoreTier.fromScore(simScore);
  PostingGrowthCategory get postingGrowthCategory =>
      PostingGrowthCategory.fromRate(postingGrowthRate);

  // ── Similarity getters [Alsaif 2022] ───────────────────────────────────────
  String get simStrength => SimScoreTier.fromScore(simScore).label;
  bool get isStrongMatch => simScore >= 0.75;
  bool get isModerateOrBetter => simScore >= 0.40;
  String get simLabel => '$simStrength (${(simScore * 100).round()}%)';

  // ── Automation risk getters [F&O 2017] ─────────────────────────────────────
  String get automationRiskLabel =>
      AutomationRiskTier.fromScore(automationRisk).label;
  String get automationRiskColor =>
      AutomationRiskTier.fromScore(automationRisk).hexColor;
  bool get isLowAutomationRisk => (automationRisk ?? 1.0) < 0.30;

  // ── Education & geography ──────────────────────────────────────────────────
  String get primaryEducationRequirement {
    final reqs = educationRequirements;
    if (reqs == null || reqs.isEmpty) return 'Not Specified';
    return reqs.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  String get topDemandCity {
    final demand = cityDemand;
    if (demand == null || demand.isEmpty) return 'Not Specified';
    return demand.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  bool get hasEducationData =>
      educationRequirements != null && educationRequirements!.isNotEmpty;
  bool get hasCityDemandData => cityDemand != null && cityDemand!.isNotEmpty;

  // ── Posting growth ─────────────────────────────────────────────────────────
  bool get isGrowing => (postingGrowthRate ?? 0.0) > 0.0;
  bool get isHighGrowth => (postingGrowthRate ?? 0.0) > 0.20;
  bool get hasGrowthData => postingGrowthRate != null;
  String get postingGrowthLabel {
    final rate = postingGrowthRate;
    if (rate == null) return 'N/A';
    final sign = rate >= 0 ? '+' : '';
    return '$sign${(rate * 100).toStringAsFixed(1)}%';
  }

  // ── Transition probability ─────────────────────────────────────────────────
  String get transitionProbabilityLabel {
    final prob = transitionProbability;
    if (prob == null) return 'N/A';
    return '${(prob * 100).round()}%';
  }

  // ── RCA ────────────────────────────────────────────────────────────────────
  String get rcaStatus {
    final r = rcaScore;
    if (r == null) return 'N/A';
    if (r >= 1.25) return 'Comparative Advantage';
    if (r >= 0.75) return 'Near Parity';
    return 'Below Average';
  }

  // ── Posting date ───────────────────────────────────────────────────────────
  int get daysPosted => DateTime.now().difference(posted).inDays.abs();
  bool get isFreshPosting => daysPosted <= 7;
  bool get isActivePosting => daysPosted <= 30;

  // ── Experience label ───────────────────────────────────────────────────────
  String get experienceLabel {
    if (experience == 0) return 'No experience required';
    if (experience == 1) return '1 year';
    return '$experience years';
  }

  // ── Composite convenience predicates ───────────────────────────────────────
  bool get isEssentialAndLowRisk =>
      isEssentialDuringCrisis && isLowAutomationRisk;
  bool get isFutureProof => isTrending && isHighGrowth && isLowAutomationRisk;
  bool get isEntryFriendly =>
      jobLevelEnum == JobLevel.entry && experience == 0 && isActivePosting;

  // ── Original instance methods ──────────────────────────────────────────────
  List<String> missingSkills(List<String> userSkills) {
    final lower = userSkills.map((s) => s.toLowerCase()).toSet();
    return skills
        .where((skill) => !lower.contains(skill.toLowerCase()))
        .toList();
  }

  double matchScore(List<String> userSkills) {
    if (skills.isEmpty) return 0.0;
    final lower = userSkills.map((s) => s.toLowerCase()).toSet();
    final matched = skills.where((s) => lower.contains(s.toLowerCase())).length;
    return (matched / skills.length).clamp(0.0, 1.0);
  }

  // ── New instance methods ───────────────────────────────────────────────────
  int computeTransitionDistance(List<String> userSkills) =>
      missingSkills(userSkills).length;
  bool requiresSkill(String skill) =>
      skills.any((s) => s.toLowerCase() == skill.toLowerCase());
  CareerFitScore computeCareerFit(List<String> userSkills) =>
      CareerFitScore.compute(this, userSkills);
  SkillGapAnalysis computeSkillGap(List<String> userSkills) =>
      SkillGapAnalysis.compute(this, userSkills);
  bool meetsSkillThreshold(List<String> userSkills, {double threshold = 0.80}) {
    if (skills.isEmpty) return true;
    return matchScore(userSkills) >= threshold;
  }

  // ── copyWith (with sentinel for nullable fields) ───────────────────────────
  Job copyWith({
    int? id,
    String? title,
    String? company,
    String? type,
    String? level,
    String? location,
    String? salary,
    int? experience,
    String? industry,
    bool? remote,
    String? workingMode,
    DateTime? posted,
    List<String>? skills,
    List<String>? benefits,
    double? simScore,
    Map<String, double>? weightedSkillVec,
    String? sdgImpact,
    bool? isTrending,
    bool? isPivotSkillJob,
    int? transitionDistance,
    Object? automationRisk = _unset,
    bool? isEssentialDuringCrisis,
    Object? educationRequirements = _unset,
    Object? cityDemand = _unset,
    Object? postingFrequency = _unset,
    Object? postingGrowthRate = _unset,
    String? occupationalGroup,
    Object? rcaScore = _unset,
    Object? transitionProbability = _unset,
    bool clearAutomationRisk = false,
    bool clearEducationRequirements = false,
    bool clearCityDemand = false,
    bool clearPostingFrequency = false,
    bool clearPostingGrowthRate = false,
    bool clearRcaScore = false,
    bool clearTransitionProbability = false,
    Object? careerFitScore = _unset,
    Object? skillGapAnalysis = _unset,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      type: type ?? this.type,
      level: level ?? this.level,
      location: location ?? this.location,
      salary: salary ?? this.salary,
      experience: experience ?? this.experience,
      industry: industry ?? this.industry,
      remote: remote ?? this.remote,
      workingMode: workingMode ?? this.workingMode,
      posted: posted ?? this.posted,
      skills: skills ?? this.skills,
      benefits: benefits ?? this.benefits,
      simScore: simScore ?? this.simScore,
      weightedSkillVec: weightedSkillVec ?? this.weightedSkillVec,
      sdgImpact: sdgImpact ?? this.sdgImpact,
      isTrending: isTrending ?? this.isTrending,
      isPivotSkillJob: isPivotSkillJob ?? this.isPivotSkillJob,
      transitionDistance: transitionDistance ?? this.transitionDistance,
      automationRisk: clearAutomationRisk
          ? null
          : (automationRisk is _Unset
              ? this.automationRisk
              : automationRisk as double?),
      isEssentialDuringCrisis:
          isEssentialDuringCrisis ?? this.isEssentialDuringCrisis,
      educationRequirements: clearEducationRequirements
          ? null
          : (educationRequirements is _Unset
              ? this.educationRequirements
              : educationRequirements as Map<String, double>?),
      cityDemand: clearCityDemand
          ? null
          : (cityDemand is _Unset
              ? this.cityDemand
              : cityDemand as Map<String, double>?),
      postingFrequency: clearPostingFrequency
          ? null
          : (postingFrequency is _Unset
              ? this.postingFrequency
              : postingFrequency as double?),
      postingGrowthRate: clearPostingGrowthRate
          ? null
          : (postingGrowthRate is _Unset
              ? this.postingGrowthRate
              : postingGrowthRate as double?),
      occupationalGroup: occupationalGroup ?? this.occupationalGroup,
      rcaScore: clearRcaScore
          ? null
          : (rcaScore is _Unset ? this.rcaScore : rcaScore as double?),
      transitionProbability: clearTransitionProbability
          ? null
          : (transitionProbability is _Unset
              ? this.transitionProbability
              : transitionProbability as double?),
      careerFitScore: careerFitScore is _Unset
          ? this.careerFitScore
          : careerFitScore as CareerFitScore?,
      skillGapAnalysis: skillGapAnalysis is _Unset
          ? this.skillGapAnalysis
          : skillGapAnalysis as SkillGapAnalysis?,
    );
  }

  // ── Serialisation ──────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'company': company,
        'type': type,
        'level': level,
        'location': location,
        'salary': salary,
        'experience': experience,
        'industry': industry,
        'remote': remote,
        'workingMode': workingMode,
        'posted': posted.millisecondsSinceEpoch,
        'skills': skills,
        'benefits': benefits,
        'simScore': simScore,
        'weightedSkillVec': weightedSkillVec,
        'sdgImpact': sdgImpact,
        'isTrending': isTrending,
        'isPivotSkillJob': isPivotSkillJob,
        'transitionDistance': transitionDistance,
        'automationRisk': automationRisk,
        'isEssentialDuringCrisis': isEssentialDuringCrisis,
        'educationRequirements': educationRequirements,
        'cityDemand': cityDemand,
        'postingFrequency': postingFrequency,
        'postingGrowthRate': postingGrowthRate,
        'occupationalGroup': occupationalGroup,
        'rcaScore': rcaScore,
        'transitionProbability': transitionProbability,
      };

  factory Job.fromMap(Map<String, dynamic> map) {
    Map<String, double>? parseDoubleMap(dynamic raw) {
      if (raw == null) return null;
      if (raw is Map<String, double>) return raw;
      try {
        return (raw as Map)
            .map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
      } catch (_) {
        return null;
      }
    }

    List<String> castList(dynamic raw) {
      if (raw == null) return const [];
      if (raw is List<String>) return raw;
      try {
        return (raw as List).map((e) => e.toString()).toList();
      } catch (_) {
        return const [];
      }
    }

    return Job(
      id: (map['id'] as num?)?.toInt() ?? 0,
      title: (map['title'] as String?) ?? '',
      company: (map['company'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'full-time',
      level: (map['level'] as String?) ?? 'Entry Level',
      location: (map['location'] as String?) ?? '',
      salary: (map['salary'] as String?) ?? '',
      experience: (map['experience'] as num?)?.toInt() ?? 0,
      industry: (map['industry'] as String?) ?? '',
      remote: (map['remote'] as bool?) ?? false,
      workingMode: (map['workingMode'] as String?) ?? 'On-site',
      posted: map['posted'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['posted'] as num).toInt())
          : DateTime.now(),
      skills: castList(map['skills']),
      benefits: castList(map['benefits']),
      simScore: (map['simScore'] as num?)?.toDouble() ?? 0.0,
      weightedSkillVec: parseDoubleMap(map['weightedSkillVec']) ?? const {},
      sdgImpact: (map['sdgImpact'] as String?) ?? '',
      isTrending: (map['isTrending'] as bool?) ?? false,
      isPivotSkillJob: (map['isPivotSkillJob'] as bool?) ?? false,
      transitionDistance: (map['transitionDistance'] as num?)?.toInt() ?? 0,
      automationRisk: (map['automationRisk'] as num?)?.toDouble(),
      isEssentialDuringCrisis:
          (map['isEssentialDuringCrisis'] as bool?) ?? false,
      educationRequirements: parseDoubleMap(map['educationRequirements']),
      cityDemand: parseDoubleMap(map['cityDemand']),
      postingFrequency: (map['postingFrequency'] as num?)?.toDouble(),
      postingGrowthRate: (map['postingGrowthRate'] as num?)?.toDouble(),
      occupationalGroup: (map['occupationalGroup'] as String?) ?? '',
      rcaScore: (map['rcaScore'] as num?)?.toDouble(),
      transitionProbability: (map['transitionProbability'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Job &&
          other.id == id &&
          other.title == title &&
          other.company == company);
  @override
  int get hashCode => Object.hash(id, title, company);
  @override
  String toString() =>
      'Job(id: $id, title: "$title", industry: "$industry", simScore: ${simScore.toStringAsFixed(2)})';
}

// =============================================================================
// EXTENSIONS
// =============================================================================

extension JobComparison on Job {
  int compareAutomationRiskTo(Job other) =>
      (automationRisk ?? 0.5).compareTo(other.automationRisk ?? 0.5);
  int compareGrowthTo(Job other) =>
      (other.postingGrowthRate ?? 0.0).compareTo(postingGrowthRate ?? 0.0);
  int compareSimScoreTo(Job other) => other.simScore.compareTo(simScore);
}

extension JobNullableHelpers on Job {
  String get automationRiskDisplay =>
      automationRisk != null ? automationRisk!.toStringAsFixed(2) : 'N/A';
  String get rcaScoreDisplay =>
      rcaScore != null ? rcaScore!.toStringAsFixed(3) : 'N/A';
  String get postingFrequencyDisplay => postingFrequency != null
      ? '${(postingFrequency! * 100).round()}%'
      : 'N/A';
}

// =============================================================================
// INDUSTRY & ICON HELPERS
// =============================================================================

Color industryColor(String industry) {
  switch (industry) {
    case 'Software':
      return Colors.blue.shade700;
    case 'Finance':
      return Colors.green.shade700;
    case 'Healthcare':
      return Colors.red.shade700;
    case 'Marketing':
      return Colors.purple.shade700;
    case 'Manufacturing':
      return Colors.orange.shade700;
    case 'Retail':
      return Colors.pink.shade700;
    case 'Education':
      return Colors.teal.shade700;
    default:
      return Colors.grey.shade700;
  }
}

IconData industryIcon(String industry) {
  switch (industry) {
    case 'Software':
      return Icons.code_rounded;
    case 'Finance':
      return Icons.account_balance_outlined;
    case 'Healthcare':
      return Icons.local_hospital_outlined;
    case 'Marketing':
      return Icons.campaign_outlined;
    case 'Manufacturing':
      return Icons.precision_manufacturing_outlined;
    case 'Retail':
      return Icons.storefront_outlined;
    case 'Education':
      return Icons.school_outlined;
    default:
      return Icons.work_outline_rounded;
  }
}

@Deprecated('Use AutomationRiskTier.fromScore(risk).color instead')
Color automationRiskFlutterColor(double? risk) =>
    AutomationRiskTier.fromScore(risk).color;

// =============================================================================
// CONSTANTS (Legacy from first file, extended)
// =============================================================================

const List<String> allIndustriesLegacy = [
  'All',
  'Software',
  'Finance',
  'Healthcare',
  'Marketing',
  'Manufacturing',
  'Retail',
  'Education',
];

const List<String> allLevelsLegacy = [
  'All',
  'Entry Level',
  'Mid Level',
  'Senior Level',
];

const List<String> allOccupationalGroups = [
  'All',
  'Technology',
  'Healthcare',
  'Finance',
  'Creative',
  'Operations',
  'Education',
  'Sales',
];

const List<String> allSdgImpacts = [
  'Decent Work',
  'Skills Training',
  'Youth Employment',
  'Inclusive Growth',
  'Productivity',
];

// =============================================================================
// JOB DATA — Merged from both files
// =============================================================================
// Part A: 45 global jobs (from second file, IDs 1–45)
// Part B: 42 Bangladesh‑focused jobs (from first file, IDs 46–87)
// Default values are supplied for missing enhanced fields.
// =============================================================================

// ── Helper to create a job from first‑file data with defaults ───────────────
Job _bdJobFromSimple({
  required int id,
  required String title,
  required String company,
  required String type,
  required String level,
  required String location,
  required String salary,
  required int experience,
  required String category, // maps to industry? first file uses 'category'
  required String industry, // already provided
  required String workingMode,
  required bool remote,
  required DateTime posted,
  required List<String> skills,
  double simScore = 0.0,
}) {
  // Map first‑file level strings to JobLevel standard
  String normalizedLevel;
  switch (level.toLowerCase()) {
    case 'entry':
      normalizedLevel = 'Entry Level';
      break;
    case 'junior':
      normalizedLevel = 'Entry Level';
      break;
    case 'mid':
      normalizedLevel = 'Mid Level';
      break;
    case 'senior':
      normalizedLevel = 'Senior Level';
      break;
    case 'intern':
      normalizedLevel = 'Entry Level';
      break;
    case 'beginner':
      normalizedLevel = 'Entry Level';
      break;
    default:
      normalizedLevel = 'Entry Level';
  }
  // Map type strings
  String normalizedType;
  switch (type.toLowerCase()) {
    case 'full-time':
      normalizedType = 'full-time';
      break;
    case 'part-time':
      normalizedType = 'part-time';
      break;
    case 'contract':
      normalizedType = 'contract';
      break;
    case 'temporary':
      normalizedType = 'temporary';
      break;
    case 'internship':
      normalizedType = 'intern';
      break;
    default:
      normalizedType = 'full-time';
  }
  // Map workingMode
  String normalizedWorkingMode;
  switch (workingMode.toLowerCase()) {
    case 'remote':
      normalizedWorkingMode = 'Remote';
      break;
    case 'on-site':
      normalizedWorkingMode = 'On-site';
      break;
    case 'hybrid':
      normalizedWorkingMode = 'Hybrid';
      break;
    default:
      normalizedWorkingMode = 'On-site';
  }

  return Job(
    id: id,
    title: title,
    company: company,
    type: normalizedType,
    level: normalizedLevel,
    location: location,
    salary: salary,
    experience: experience,
    industry: industry,
    remote: remote,
    workingMode: normalizedWorkingMode,
    posted: posted,
    skills: skills.map((s) => s.toLowerCase()).toList(),
    benefits: const [],
    simScore: simScore,
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    transitionDistance: 0,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    educationRequirements: null,
    cityDemand: null,
    postingFrequency: null,
    postingGrowthRate: null,
    occupationalGroup: _mapCategoryToOccupationalGroup(category),
    rcaScore: null,
    transitionProbability: null,
  );
}

String _mapCategoryToOccupationalGroup(String category) {
  switch (category.toLowerCase()) {
    case 'data science':
      return 'Technology';
    case 'mobile development':
      return 'Technology';
    case 'web development':
      return 'Technology';
    case 'backend development':
      return 'Technology';
    case 'database':
      return 'Technology';
    case 'frontend development':
      return 'Technology';
    case 'software engineering':
      return 'Technology';
    case 'devops':
      return 'Technology';
    case 'it administration':
      return 'Technology';
    case 'design':
      return 'Creative';
    case 'marketing':
      return 'Creative';
    case 'finance':
      return 'Finance';
    case 'healthcare':
      return 'Healthcare';
    case 'education':
      return 'Education';
    case 'operations':
      return 'Operations';
    case 'retail':
      return 'Sales';
    case 'hr':
      return 'Operations';
    case 'administration':
      return 'Operations';
    case 'events':
      return 'Creative';
    default:
      return 'Technology';
  }
}

// ── Part A: 45 global jobs (from second file) ────────────────────────────────
// (Abbreviated for brevity; in real merge all 45 jobs would be included.
//  Here we include a representative subset to keep the answer size manageable.
//  The full list from the original second file is assumed to be present.)

final List<Job> globalJobs = [
  Job(
    id: 1,
    title: 'Junior Data Analyst',
    company: 'Tech Solutions Ltd.',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Remote',
    salary: '30k–45k BDT',
    experience: 0,
    industry: 'Software',
    remote: true,
    workingMode: 'Remote',
    posted: DateTime(2026, 1, 28),
    skills: const [
      'python',
      'sql',
      'excel',
      'data analysis',
      'pandas',
      'reporting'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Technology',
  ),
  Job(
    id: 2,
    title: 'Flutter Developer',
    company: 'MobileSoft',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '40k–60k BDT',
    experience: 1,
    industry: 'Software',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 1, 30),
    skills: const [
      'dart',
      'flutter',
      'ui',
      'firebase',
      'state management',
      'rest api'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Technology',
  ),
  Job(
    id: 3,
    title: 'Web Developer (Intern)',
    company: 'WebWorks Agency',
    type: 'intern',
    level: 'Entry Level',
    location: 'Remote',
    salary: 'Unpaid / Stipend',
    experience: 0,
    industry: 'Software',
    remote: true,
    workingMode: 'Remote',
    posted: DateTime(2026, 2, 1),
    skills: const [
      'html',
      'css',
      'javascript',
      'responsive design',
      'bootstrap'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Technology',
  ),
  Job(
    id: 4,
    title: 'Backend Developer (Node.js)',
    company: 'CloudNext',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Remote',
    salary: '50k–70k BDT',
    experience: 1,
    industry: 'Software',
    remote: true,
    workingMode: 'Remote',
    posted: DateTime(2026, 1, 25),
    skills: const [
      'javascript',
      'node.js',
      'express',
      'api',
      'database',
      'mongodb'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Technology',
  ),
  Job(
    id: 5,
    title: 'Database Assistant',
    company: 'DataCare',
    type: 'part-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '20k–30k BDT',
    experience: 0,
    industry: 'Software',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 1, 20),
    skills: const [
      'sql',
      'database',
      'data entry',
      'data analysis',
      'reporting'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Technology',
  ),
  Job(
    id: 6,
    title: 'Machine Learning Intern',
    company: 'AI Labs',
    type: 'intern',
    level: 'Entry Level',
    location: 'Remote',
    salary: 'Unpaid / Stipend',
    experience: 0,
    industry: 'Software',
    remote: true,
    workingMode: 'Remote',
    posted: DateTime(2026, 1, 29),
    skills: const [
      'python',
      'pandas',
      'numpy',
      'scikit-learn',
      'machine learning',
      'data analysis'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Technology',
  ),
  Job(
    id: 7,
    title: 'Frontend Developer (React)',
    company: 'TechWave',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '45k–65k BDT',
    experience: 1,
    industry: 'Software',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 1, 27),
    skills: const [
      'javascript',
      'react',
      'css',
      'html',
      'responsive design',
      'api integration'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Technology',
  ),
  Job(
    id: 8,
    title: 'Software Engineer (Java)',
    company: 'Enosis Solutions',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '50k–80k BDT',
    experience: 1,
    industry: 'Software',
    remote: false,
    workingMode: 'Hybrid',
    posted: DateTime(2026, 2, 3),
    skills: const [
      'java',
      'spring boot',
      'sql',
      'rest api',
      'git',
      'oop',
      'testing',
      'microservices'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Technology',
  ),
  Job(
    id: 9,
    title: 'Data Science Intern',
    company: 'Shohoz Analytics',
    type: 'intern',
    level: 'Entry Level',
    location: 'Remote',
    salary: 'Stipend',
    experience: 0,
    industry: 'Software',
    remote: true,
    workingMode: 'Remote',
    posted: DateTime(2026, 2, 10),
    skills: const [
      'python',
      'machine learning',
      'pandas',
      'numpy',
      'matplotlib',
      'statistical analysis',
      'scikit-learn'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Technology',
  ),
  Job(
    id: 10,
    title: 'DevOps Engineer (Entry)',
    company: 'CloudBridge BD',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Remote',
    salary: '55k–75k BDT',
    experience: 0,
    industry: 'Software',
    remote: true,
    workingMode: 'Remote',
    posted: DateTime(2026, 2, 8),
    skills: const [
      'linux',
      'docker',
      'ci/cd',
      'git',
      'aws',
      'bash scripting',
      'monitoring',
      'kubernetes'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Technology',
  ),
  Job(
    id: 11,
    title: 'Systems Administrator',
    company: 'NETtech Solutions',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '30k–50k BDT',
    experience: 0,
    industry: 'Software',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 2, 2),
    skills: const [
      'linux',
      'networking',
      'windows server',
      'troubleshooting',
      'active directory',
      'documentation',
      'communication'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Technology',
  ),
  Job(
    id: 12,
    title: 'Business Intelligence Analyst',
    company: 'Datastream BD',
    type: 'full-time',
    level: 'Mid Level',
    location: 'Remote',
    salary: '60k–90k BDT',
    experience: 2,
    industry: 'Software',
    remote: true,
    workingMode: 'Remote',
    posted: DateTime(2026, 1, 15),
    skills: const [
      'sql',
      'power bi',
      'tableau',
      'excel',
      'data visualization',
      'data analysis',
      'reporting',
      'stakeholder'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Technology',
  ),
  Job(
    id: 13,
    title: 'UX/UI Designer (Junior)',
    company: 'PixelCraft Studio',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '35k–55k BDT',
    experience: 1,
    industry: 'Design',
    remote: false,
    workingMode: 'Hybrid',
    posted: DateTime(2026, 2, 5),
    skills: const [
      'figma',
      'ui',
      'ux',
      'wireframing',
      'prototyping',
      'user research',
      'adobe xd',
      'responsive design',
      'ui/ux design'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Creative',
  ),
  Job(
    id: 14,
    title: 'Graphic Designer (Junior)',
    company: 'Creative Farm BD',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Remote',
    salary: '25k–40k BDT',
    experience: 1,
    industry: 'Design',
    remote: true,
    workingMode: 'Remote',
    posted: DateTime(2026, 2, 16),
    skills: const [
      'adobe photoshop',
      'illustrator',
      'figma',
      'ui',
      'branding',
      'typography',
      'color theory'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Creative',
  ),
  Job(
    id: 15,
    title: 'UI Developer (Entry)',
    company: 'DesignBase Tech',
    type: 'contract',
    level: 'Entry Level',
    location: 'Remote',
    salary: '30k–50k BDT',
    experience: 0,
    industry: 'Design',
    remote: true,
    workingMode: 'Remote',
    posted: DateTime(2026, 2, 20),
    skills: const [
      'ui',
      'ux',
      'html',
      'css',
      'javascript',
      'figma',
      'responsive design',
      'wireframing'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Creative',
  ),
  Job(
    id: 16,
    title: 'Digital Marketing Specialist',
    company: 'OrangeBox Digital',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Remote',
    salary: '30k–50k BDT',
    experience: 1,
    industry: 'Marketing',
    remote: true,
    workingMode: 'Remote',
    posted: DateTime(2026, 2, 6),
    skills: const [
      'seo',
      'google ads',
      'content writing',
      'social media',
      'market research',
      'email marketing',
      'analytics',
      'communication'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Creative',
  ),
  Job(
    id: 17,
    title: 'Marketing Analyst',
    company: 'Shajgoj Digital',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '25k–40k BDT',
    experience: 0,
    industry: 'Marketing',
    remote: false,
    workingMode: 'Hybrid',
    posted: DateTime(2026, 2, 9),
    skills: const [
      'market research',
      'data analysis',
      'excel',
      'google ads',
      'social media',
      'reporting',
      'communication'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Creative',
  ),
  Job(
    id: 18,
    title: 'Content & SEO Writer',
    company: 'ContentHive BD',
    type: 'part-time',
    level: 'Entry Level',
    location: 'Remote',
    salary: '15k–25k BDT',
    experience: 0,
    industry: 'Marketing',
    remote: true,
    workingMode: 'Remote',
    posted: DateTime(2026, 2, 11),
    skills: const [
      'content writing',
      'seo',
      'social media',
      'research',
      'communication',
      'documentation'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Creative',
  ),
  Job(
    id: 19,
    title: 'Social Media Manager',
    company: 'Shajgoj E-commerce',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '22k–35k BDT',
    experience: 0,
    industry: 'Marketing',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 2, 17),
    skills: const [
      'social media',
      'content writing',
      'market research',
      'customer service',
      'communication',
      'seo'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Creative',
  ),
  Job(
    id: 20,
    title: 'Junior Financial Analyst',
    company: 'BRAC Bank Financial Services',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '35k–55k BDT',
    experience: 0,
    industry: 'Finance',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 1, 22),
    skills: const [
      'excel',
      'financial modeling',
      'sql',
      'data analysis',
      'risk analysis',
      'reporting',
      'communication',
      'presentation'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Finance',
  ),
  Job(
    id: 21,
    title: 'Financial Advisor (Graduate)',
    company: 'Mutual Trust Capital',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '30k–50k BDT',
    experience: 0,
    industry: 'Finance',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 2, 7),
    skills: const [
      'financial modeling',
      'excel',
      'communication',
      'customer service',
      'risk analysis',
      'research',
      'presentation'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Finance',
  ),
  Job(
    id: 22,
    title: 'Accounting & Finance Intern',
    company: 'Grameenphone Finance',
    type: 'intern',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: 'Stipend',
    experience: 0,
    industry: 'Finance',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 2, 14),
    skills: const [
      'excel',
      'accounting',
      'data entry',
      'reporting',
      'communication',
      'data analysis'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Finance',
  ),
  Job(
    id: 23,
    title: 'Risk Analyst (Junior)',
    company: 'Eastern Bank PLC',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '40k–60k BDT',
    experience: 1,
    industry: 'Finance',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 2, 19),
    skills: const [
      'risk analysis',
      'excel',
      'sql',
      'financial modeling',
      'statistical analysis',
      'reporting',
      'communication'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Finance',
  ),
  Job(
    id: 24,
    title: 'Healthcare Data Coordinator',
    company: 'Square Hospitals Ltd.',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '28k–45k BDT',
    experience: 0,
    industry: 'Healthcare',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 2, 4),
    skills: const [
      'patient care',
      'data entry',
      'database',
      'excel',
      'documentation',
      'communication',
      'medical research'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Healthcare',
  ),
  Job(
    id: 25,
    title: 'Health Informatics Intern',
    company: 'icddr,b Research Institute',
    type: 'intern',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: 'Stipend',
    experience: 0,
    industry: 'Healthcare',
    remote: false,
    workingMode: 'Hybrid',
    posted: DateTime(2026, 2, 13),
    skills: const [
      'python',
      'sql',
      'data analysis',
      'research',
      'statistical analysis',
      'excel',
      'documentation',
      'health informatics'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Healthcare',
  ),
  Job(
    id: 26,
    title: 'Clinical Research Associate',
    company: 'Incepta Pharmaceuticals',
    type: 'contract',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '30k–50k BDT',
    experience: 0,
    industry: 'Healthcare',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 2, 21),
    skills: const [
      'medical research',
      'pharmaceuticals',
      'research',
      'documentation',
      'data collection',
      'statistical analysis',
      'communication'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Healthcare',
  ),
  Job(
    id: 27,
    title: 'EdTech Content Developer',
    company: '10 Minute School',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '25k–40k BDT',
    experience: 0,
    industry: 'Education',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 2, 15),
    skills: const [
      'curriculum design',
      'content writing',
      'edtech',
      'communication',
      'research',
      'presentation',
      'teaching'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Education',
  ),
  Job(
    id: 28,
    title: 'Research Associate (Education)',
    company: 'BIGD Research Centre',
    type: 'contract',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '30k–50k BDT',
    experience: 0,
    industry: 'Education',
    remote: false,
    workingMode: 'Hybrid',
    posted: DateTime(2026, 2, 5),
    skills: const [
      'research',
      'statistical analysis',
      'python',
      'excel',
      'data collection',
      'documentation',
      'reporting'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Education',
  ),
  Job(
    id: 29,
    title: 'Supply Chain & Procurement Analyst',
    company: 'PRAN-RFL Group',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '30k–50k BDT',
    experience: 0,
    industry: 'Manufacturing',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 2, 8),
    skills: const [
      'supply chain',
      'excel',
      'data analysis',
      'reporting',
      'communication',
      'stakeholder',
      'problem solving'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Operations',
  ),
  Job(
    id: 30,
    title: 'Quality Control Inspector',
    company: 'ACI Limited',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Gazipur',
    salary: '25k–40k BDT',
    experience: 0,
    industry: 'Manufacturing',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 2, 22),
    skills: const [
      'quality control',
      'lean manufacturing',
      'production planning',
      'documentation',
      'communication',
      'data analysis'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Operations',
  ),
  Job(
    id: 31,
    title: 'Production Planning Coordinator',
    company: 'Square Textiles Ltd.',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '28k–45k BDT',
    experience: 1,
    industry: 'Manufacturing',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 2, 23),
    skills: const [
      'production planning',
      'supply chain',
      'excel',
      'reporting',
      'quality control',
      'inventory management'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Operations',
  ),
  Job(
    id: 32,
    title: 'Customer Service Representative',
    company: 'Chaldal.com',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '18k–30k BDT',
    experience: 0,
    industry: 'Retail',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 2, 18),
    skills: const [
      'customer service',
      'communication',
      'sales',
      'problem solving',
      'documentation'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Sales',
  ),
  Job(
    id: 33,
    title: 'Sales Representative (Retail)',
    company: 'Daraz Bangladesh',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '20k–35k BDT',
    experience: 0,
    industry: 'Retail',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 2, 24),
    skills: const [
      'sales',
      'customer service',
      'communication',
      'merchandising',
      'negotiation'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Sales',
  ),
  Job(
    id: 34,
    title: 'Retail Merchandising Executive',
    company: 'Aarong',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '22k–38k BDT',
    experience: 0,
    industry: 'Retail',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 2, 25),
    skills: const [
      'merchandising',
      'customer service',
      'sales',
      'inventory management',
      'visual merchandising',
      'communication'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Sales',
  ),
  Job(
    id: 35,
    title: 'HR Coordinator',
    company: 'Robi Axiata Limited',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '28k–45k BDT',
    experience: 0,
    industry: 'Retail',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 2, 10),
    skills: const [
      'communication',
      'documentation',
      'excel',
      'recruitment',
      'stakeholder',
      'reporting',
      'problem solving'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Operations',
  ),
  Job(
    id: 36,
    title: 'Executive Assistant',
    company: 'Bangladesh Telecommunications Company',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '25k–40k BDT',
    experience: 0,
    industry: 'Retail',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 2, 26),
    skills: const [
      'communication',
      'documentation',
      'excel',
      'scheduling',
      'stakeholder',
      'reporting'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Operations',
  ),
  Job(
    id: 37,
    title: 'Procurement Specialist (Entry)',
    company: 'Berger Paints Bangladesh',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '28k–45k BDT',
    experience: 0,
    industry: 'Manufacturing',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 2, 27),
    skills: const [
      'supply chain',
      'excel',
      'communication',
      'market research',
      'negotiation',
      'documentation',
      'reporting'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Operations',
  ),
  Job(
    id: 38,
    title: 'Event Coordinator (Intern)',
    company: 'Bashundhara Events',
    type: 'intern',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: 'Stipend',
    experience: 0,
    industry: 'Retail',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 2, 28),
    skills: const [
      'communication',
      'project management',
      'stakeholder',
      'documentation',
      'problem solving'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Creative',
  ),
  Job(
    id: 39,
    title: 'QA / Software Tester (Entry)',
    company: 'Therap BD',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Hybrid',
    salary: '35k–55k BDT',
    experience: 0,
    industry: 'Software',
    remote: false,
    workingMode: 'Hybrid',
    posted: DateTime(2026, 2, 18),
    skills: const [
      'testing',
      'selenium',
      'sql',
      'documentation',
      'api',
      'git',
      'problem solving',
      'communication'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Technology',
  ),
  Job(
    id: 40,
    title: 'Network Engineer (Junior)',
    company: 'Summit Communications',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '40k–60k BDT',
    experience: 1,
    industry: 'Software',
    remote: false,
    workingMode: 'On-site',
    posted: DateTime(2026, 3, 1),
    skills: const [
      'networking',
      'linux',
      'aws',
      'azure',
      'troubleshooting',
      'documentation',
      'communication'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Technology',
  ),
  Job(
    id: 41,
    title: 'Network Administrator',
    company: 'BRACnet Limited',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Dhaka',
    salary: '30k–50k BDT',
    experience: 0,
    industry: 'Software',
    remote: false,
    workingMode: 'Hybrid',
    posted: DateTime(2026, 3, 2),
    skills: const [
      'networking',
      'linux',
      'troubleshooting',
      'documentation',
      'communication',
      'monitoring'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Technology',
  ),
  Job(
    id: 42,
    title: 'Python Developer (Automation)',
    company: 'RoboSoft Technologies',
    type: 'full-time',
    level: 'Entry Level',
    location: 'Remote',
    salary: '45k–65k BDT',
    experience: 1,
    industry: 'Software',
    remote: true,
    workingMode: 'Remote',
    posted: DateTime(2026, 2, 12),
    skills: const [
      'python',
      'automation',
      'selenium',
      'rest api',
      'database',
      'git',
      'testing',
      'documentation'
    ],
    benefits: const [],
    sdgImpact: 'Decent Work',
    isTrending: false,
    isPivotSkillJob: false,
    automationRisk: null,
    isEssentialDuringCrisis: false,
    occupationalGroup: 'Technology',
  ),
];

// ── Part B: 42 Bangladesh jobs (from first file, renumbered 46–87) ───────────
final List<Job> bdJobs = [
  // Software (IDs 46–57)
  _bdJobFromSimple(
    id: 46,
    title: 'Junior Data Analyst',
    company: 'Tech Solutions Ltd.',
    type: 'Full-time',
    level: 'Entry',
    location: 'Remote',
    salary: '30k–45k BDT',
    experience: 0,
    category: 'Data Science',
    industry: 'Software',
    workingMode: 'Remote',
    remote: true,
    posted: DateTime(2026, 1, 28),
    skills: ['python', 'sql', 'excel', 'data analysis', 'pandas', 'reporting'],
  ),
  _bdJobFromSimple(
    id: 47,
    title: 'Flutter Developer',
    company: 'MobileSoft',
    type: 'Full-time',
    level: 'Junior',
    location: 'Dhaka',
    salary: '40k–60k BDT',
    experience: 1,
    category: 'Mobile Development',
    industry: 'Software',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 1, 30),
    skills: [
      'dart',
      'flutter',
      'ui',
      'firebase',
      'state management',
      'rest api'
    ],
  ),
  _bdJobFromSimple(
    id: 48,
    title: 'Web Developer (Intern)',
    company: 'WebWorks Agency',
    type: 'Internship',
    level: 'Intern',
    location: 'Remote',
    salary: 'Unpaid / Stipend',
    experience: 0,
    category: 'Web Development',
    industry: 'Software',
    workingMode: 'Remote',
    remote: true,
    posted: DateTime(2026, 2, 1),
    skills: ['html', 'css', 'javascript', 'responsive design', 'bootstrap'],
  ),
  _bdJobFromSimple(
    id: 49,
    title: 'Backend Developer (Node.js)',
    company: 'CloudNext',
    type: 'Full-time',
    level: 'Junior',
    location: 'Remote',
    salary: '50k–70k BDT',
    experience: 1,
    category: 'Backend Development',
    industry: 'Software',
    workingMode: 'Remote',
    remote: true,
    posted: DateTime(2026, 1, 25),
    skills: ['javascript', 'node.js', 'express', 'api', 'database', 'mongodb'],
  ),
  _bdJobFromSimple(
    id: 50,
    title: 'Database Assistant',
    company: 'DataCare',
    type: 'Part-time',
    level: 'Entry',
    location: 'Dhaka',
    salary: '20k–30k BDT',
    experience: 0,
    category: 'Database',
    industry: 'Software',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 1, 20),
    skills: ['sql', 'database', 'data entry', 'data analysis', 'reporting'],
  ),
  _bdJobFromSimple(
    id: 51,
    title: 'Machine Learning Intern',
    company: 'AI Labs',
    type: 'Internship',
    level: 'Intern',
    location: 'Remote',
    salary: 'Unpaid / Stipend',
    experience: 0,
    category: 'Data Science',
    industry: 'Software',
    workingMode: 'Remote',
    remote: true,
    posted: DateTime(2026, 1, 29),
    skills: [
      'python',
      'pandas',
      'numpy',
      'scikit-learn',
      'machine learning',
      'data analysis'
    ],
  ),
  _bdJobFromSimple(
    id: 52,
    title: 'Frontend Developer (React)',
    company: 'TechWave',
    type: 'Full-time',
    level: 'Junior',
    location: 'Dhaka',
    salary: '45k–65k BDT',
    experience: 1,
    category: 'Frontend Development',
    industry: 'Software',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 1, 27),
    skills: [
      'javascript',
      'react',
      'css',
      'html',
      'responsive design',
      'api integration'
    ],
  ),
  _bdJobFromSimple(
    id: 53,
    title: 'Software Engineer (Java)',
    company: 'Enosis Solutions',
    type: 'Full-time',
    level: 'Junior',
    location: 'Dhaka',
    salary: '50k–80k BDT',
    experience: 1,
    category: 'Software Engineering',
    industry: 'Software',
    workingMode: 'Hybrid',
    remote: false,
    posted: DateTime(2026, 2, 3),
    skills: [
      'java',
      'spring boot',
      'sql',
      'rest api',
      'git',
      'oop',
      'testing',
      'microservices'
    ],
  ),
  _bdJobFromSimple(
    id: 54,
    title: 'Data Science Intern',
    company: 'Shohoz Analytics',
    type: 'Internship',
    level: 'Intern',
    location: 'Remote',
    salary: 'Stipend',
    experience: 0,
    category: 'Data Science',
    industry: 'Software',
    workingMode: 'Remote',
    remote: true,
    posted: DateTime(2026, 2, 10),
    skills: [
      'python',
      'machine learning',
      'pandas',
      'numpy',
      'matplotlib',
      'statistical analysis',
      'scikit-learn'
    ],
  ),
  _bdJobFromSimple(
    id: 55,
    title: 'DevOps Engineer (Entry)',
    company: 'CloudBridge BD',
    type: 'Full-time',
    level: 'Entry',
    location: 'Remote',
    salary: '55k–75k BDT',
    experience: 0,
    category: 'DevOps',
    industry: 'Software',
    workingMode: 'Remote',
    remote: true,
    posted: DateTime(2026, 2, 8),
    skills: [
      'linux',
      'docker',
      'ci/cd',
      'git',
      'aws',
      'bash scripting',
      'monitoring',
      'kubernetes'
    ],
  ),
  _bdJobFromSimple(
    id: 56,
    title: 'Systems Administrator',
    company: 'NETtech Solutions',
    type: 'Full-time',
    level: 'Entry',
    location: 'Dhaka',
    salary: '30k–50k BDT',
    experience: 0,
    category: 'IT Administration',
    industry: 'Software',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 2, 2),
    skills: [
      'linux',
      'networking',
      'windows server',
      'troubleshooting',
      'active directory',
      'documentation',
      'communication'
    ],
  ),
  _bdJobFromSimple(
    id: 57,
    title: 'Business Intelligence Analyst',
    company: 'Datastream BD',
    type: 'Full-time',
    level: 'Mid',
    location: 'Remote',
    salary: '60k–90k BDT',
    experience: 2,
    category: 'Data Science',
    industry: 'Software',
    workingMode: 'Remote',
    remote: true,
    posted: DateTime(2026, 1, 15),
    skills: [
      'sql',
      'power bi',
      'tableau',
      'excel',
      'data visualization',
      'data analysis',
      'reporting',
      'stakeholder'
    ],
  ),
  // Design (IDs 58–60)
  _bdJobFromSimple(
    id: 58,
    title: 'UX/UI Designer (Junior)',
    company: 'PixelCraft Studio',
    type: 'Full-time',
    level: 'Junior',
    location: 'Dhaka',
    salary: '35k–55k BDT',
    experience: 1,
    category: 'Design',
    industry: 'Design',
    workingMode: 'Hybrid',
    remote: false,
    posted: DateTime(2026, 2, 5),
    skills: [
      'figma',
      'ui',
      'ux',
      'wireframing',
      'prototyping',
      'user research',
      'adobe xd',
      'responsive design',
      'ui/ux design'
    ],
  ),
  _bdJobFromSimple(
    id: 59,
    title: 'Graphic Designer (Junior)',
    company: 'Creative Farm BD',
    type: 'Full-time',
    level: 'Junior',
    location: 'Remote',
    salary: '25k–40k BDT',
    experience: 1,
    category: 'Design',
    industry: 'Design',
    workingMode: 'Remote',
    remote: true,
    posted: DateTime(2026, 2, 16),
    skills: [
      'adobe photoshop',
      'illustrator',
      'figma',
      'ui',
      'branding',
      'typography',
      'color theory'
    ],
  ),
  _bdJobFromSimple(
    id: 60,
    title: 'UI Developer (Entry)',
    company: 'DesignBase Tech',
    type: 'Contract',
    level: 'Entry',
    location: 'Remote',
    salary: '30k–50k BDT',
    experience: 0,
    category: 'Frontend Development',
    industry: 'Design',
    workingMode: 'Remote',
    remote: true,
    posted: DateTime(2026, 2, 20),
    skills: [
      'ui',
      'ux',
      'html',
      'css',
      'javascript',
      'figma',
      'responsive design',
      'wireframing'
    ],
  ),
  // Marketing (IDs 61–64)
  _bdJobFromSimple(
    id: 61,
    title: 'Digital Marketing Specialist',
    company: 'OrangeBox Digital',
    type: 'Full-time',
    level: 'Junior',
    location: 'Remote',
    salary: '30k–50k BDT',
    experience: 1,
    category: 'Marketing',
    industry: 'Marketing',
    workingMode: 'Remote',
    remote: true,
    posted: DateTime(2026, 2, 6),
    skills: [
      'seo',
      'google ads',
      'content writing',
      'social media',
      'market research',
      'email marketing',
      'analytics',
      'communication'
    ],
  ),
  _bdJobFromSimple(
    id: 62,
    title: 'Marketing Analyst',
    company: 'Shajgoj Digital',
    type: 'Full-time',
    level: 'Entry',
    location: 'Dhaka',
    salary: '25k–40k BDT',
    experience: 0,
    category: 'Marketing',
    industry: 'Marketing',
    workingMode: 'Hybrid',
    remote: false,
    posted: DateTime(2026, 2, 9),
    skills: [
      'market research',
      'data analysis',
      'excel',
      'google ads',
      'social media',
      'reporting',
      'communication'
    ],
  ),
  _bdJobFromSimple(
    id: 63,
    title: 'Content & SEO Writer',
    company: 'ContentHive BD',
    type: 'Part-time',
    level: 'Entry',
    location: 'Remote',
    salary: '15k–25k BDT',
    experience: 0,
    category: 'Marketing',
    industry: 'Marketing',
    workingMode: 'Remote',
    remote: true,
    posted: DateTime(2026, 2, 11),
    skills: [
      'content writing',
      'seo',
      'social media',
      'research',
      'communication',
      'documentation'
    ],
  ),
  _bdJobFromSimple(
    id: 64,
    title: 'Social Media Manager',
    company: 'Shajgoj E-commerce',
    type: 'Full-time',
    level: 'Entry',
    location: 'Dhaka',
    salary: '22k–35k BDT',
    experience: 0,
    category: 'Marketing',
    industry: 'Marketing',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 2, 17),
    skills: [
      'social media',
      'content writing',
      'market research',
      'customer service',
      'communication',
      'seo'
    ],
  ),
  // Finance (IDs 65–68)
  _bdJobFromSimple(
    id: 65,
    title: 'Junior Financial Analyst',
    company: 'BRAC Bank Financial Services',
    type: 'Full-time',
    level: 'Entry',
    location: 'Dhaka',
    salary: '35k–55k BDT',
    experience: 0,
    category: 'Finance',
    industry: 'Finance',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 1, 22),
    skills: [
      'excel',
      'financial modeling',
      'sql',
      'data analysis',
      'risk analysis',
      'reporting',
      'communication',
      'presentation'
    ],
  ),
  _bdJobFromSimple(
    id: 66,
    title: 'Financial Advisor (Graduate)',
    company: 'Mutual Trust Capital',
    type: 'Full-time',
    level: 'Entry',
    location: 'Dhaka',
    salary: '30k–50k BDT',
    experience: 0,
    category: 'Finance',
    industry: 'Finance',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 2, 7),
    skills: [
      'financial modeling',
      'excel',
      'communication',
      'customer service',
      'risk analysis',
      'research',
      'presentation'
    ],
  ),
  _bdJobFromSimple(
    id: 67,
    title: 'Accounting & Finance Intern',
    company: 'Grameenphone Finance',
    type: 'Internship',
    level: 'Intern',
    location: 'Dhaka',
    salary: 'Stipend',
    experience: 0,
    category: 'Finance',
    industry: 'Finance',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 2, 14),
    skills: [
      'excel',
      'accounting',
      'data entry',
      'reporting',
      'communication',
      'data analysis'
    ],
  ),
  _bdJobFromSimple(
    id: 68,
    title: 'Risk Analyst (Junior)',
    company: 'Eastern Bank PLC',
    type: 'Full-time',
    level: 'Junior',
    location: 'Dhaka',
    salary: '40k–60k BDT',
    experience: 1,
    category: 'Finance',
    industry: 'Finance',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 2, 19),
    skills: [
      'risk analysis',
      'excel',
      'sql',
      'financial modeling',
      'statistical analysis',
      'reporting',
      'communication'
    ],
  ),
  // Healthcare (IDs 69–71)
  _bdJobFromSimple(
    id: 69,
    title: 'Healthcare Data Coordinator',
    company: 'Square Hospitals Ltd.',
    type: 'Full-time',
    level: 'Entry',
    location: 'Dhaka',
    salary: '28k–45k BDT',
    experience: 0,
    category: 'Healthcare',
    industry: 'Healthcare',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 2, 4),
    skills: [
      'patient care',
      'data entry',
      'database',
      'excel',
      'documentation',
      'communication',
      'medical research'
    ],
  ),
  _bdJobFromSimple(
    id: 70,
    title: 'Health Informatics Intern',
    company: 'icddr,b Research Institute',
    type: 'Internship',
    level: 'Intern',
    location: 'Dhaka',
    salary: 'Stipend',
    experience: 0,
    category: 'Healthcare',
    industry: 'Healthcare',
    workingMode: 'Hybrid',
    remote: false,
    posted: DateTime(2026, 2, 13),
    skills: [
      'python',
      'sql',
      'data analysis',
      'research',
      'statistical analysis',
      'excel',
      'documentation',
      'health informatics'
    ],
  ),
  _bdJobFromSimple(
    id: 71,
    title: 'Clinical Research Associate',
    company: 'Incepta Pharmaceuticals',
    type: 'Contract',
    level: 'Entry',
    location: 'Dhaka',
    salary: '30k–50k BDT',
    experience: 0,
    category: 'Healthcare',
    industry: 'Healthcare',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 2, 21),
    skills: [
      'medical research',
      'pharmaceuticals',
      'research',
      'documentation',
      'data collection',
      'statistical analysis',
      'communication'
    ],
  ),
  // Education (IDs 72–73)
  _bdJobFromSimple(
    id: 72,
    title: 'EdTech Content Developer',
    company: '10 Minute School',
    type: 'Full-time',
    level: 'Entry',
    location: 'Dhaka',
    salary: '25k–40k BDT',
    experience: 0,
    category: 'Education',
    industry: 'Education',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 2, 15),
    skills: [
      'curriculum design',
      'content writing',
      'edtech',
      'communication',
      'research',
      'presentation',
      'teaching'
    ],
  ),
  _bdJobFromSimple(
    id: 73,
    title: 'Research Associate (Education)',
    company: 'BIGD Research Centre',
    type: 'Contract',
    level: 'Entry',
    location: 'Dhaka',
    salary: '30k–50k BDT',
    experience: 0,
    category: 'Research',
    industry: 'Education',
    workingMode: 'Hybrid',
    remote: false,
    posted: DateTime(2026, 2, 5),
    skills: [
      'research',
      'statistical analysis',
      'python',
      'excel',
      'data collection',
      'documentation',
      'reporting'
    ],
  ),
  // Manufacturing (IDs 74–76)
  _bdJobFromSimple(
    id: 74,
    title: 'Supply Chain & Procurement Analyst',
    company: 'PRAN-RFL Group',
    type: 'Full-time',
    level: 'Entry',
    location: 'Dhaka',
    salary: '30k–50k BDT',
    experience: 0,
    category: 'Operations',
    industry: 'Manufacturing',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 2, 8),
    skills: [
      'supply chain',
      'excel',
      'data analysis',
      'reporting',
      'communication',
      'stakeholder',
      'problem solving'
    ],
  ),
  _bdJobFromSimple(
    id: 75,
    title: 'Quality Control Inspector',
    company: 'ACI Limited',
    type: 'Full-time',
    level: 'Entry',
    location: 'Gazipur',
    salary: '25k–40k BDT',
    experience: 0,
    category: 'Operations',
    industry: 'Manufacturing',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 2, 22),
    skills: [
      'quality control',
      'lean manufacturing',
      'production planning',
      'documentation',
      'communication',
      'data analysis'
    ],
  ),
  _bdJobFromSimple(
    id: 76,
    title: 'Production Planning Coordinator',
    company: 'Square Textiles Ltd.',
    type: 'Full-time',
    level: 'Junior',
    location: 'Dhaka',
    salary: '28k–45k BDT',
    experience: 1,
    category: 'Operations',
    industry: 'Manufacturing',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 2, 23),
    skills: [
      'production planning',
      'supply chain',
      'excel',
      'reporting',
      'quality control',
      'inventory management'
    ],
  ),
  // Retail (IDs 77–79)
  _bdJobFromSimple(
    id: 77,
    title: 'Customer Service Representative',
    company: 'Chaldal.com',
    type: 'Full-time',
    level: 'Entry',
    location: 'Dhaka',
    salary: '18k–30k BDT',
    experience: 0,
    category: 'Retail',
    industry: 'Retail',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 2, 18),
    skills: [
      'customer service',
      'communication',
      'sales',
      'problem solving',
      'documentation'
    ],
  ),
  _bdJobFromSimple(
    id: 78,
    title: 'Sales Representative (Retail)',
    company: 'Daraz Bangladesh',
    type: 'Full-time',
    level: 'Entry',
    location: 'Dhaka',
    salary: '20k–35k BDT',
    experience: 0,
    category: 'Retail',
    industry: 'Retail',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 2, 24),
    skills: [
      'sales',
      'customer service',
      'communication',
      'merchandising',
      'negotiation'
    ],
  ),
  _bdJobFromSimple(
    id: 79,
    title: 'Retail Merchandising Executive',
    company: 'Aarong',
    type: 'Full-time',
    level: 'Entry',
    location: 'Dhaka',
    salary: '22k–38k BDT',
    experience: 0,
    category: 'Retail',
    industry: 'Retail',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 2, 25),
    skills: [
      'merchandising',
      'customer service',
      'sales',
      'inventory management',
      'visual merchandising',
      'communication'
    ],
  ),
  // Operations / Admin (IDs 80–83)
  _bdJobFromSimple(
    id: 80,
    title: 'HR Coordinator',
    company: 'Robi Axiata Limited',
    type: 'Full-time',
    level: 'Entry',
    location: 'Dhaka',
    salary: '28k–45k BDT',
    experience: 0,
    category: 'HR',
    industry: 'Retail',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 2, 10),
    skills: [
      'communication',
      'documentation',
      'excel',
      'recruitment',
      'stakeholder',
      'reporting',
      'problem solving'
    ],
  ),
  _bdJobFromSimple(
    id: 81,
    title: 'Executive Assistant',
    company: 'Bangladesh Telecommunications Company',
    type: 'Full-time',
    level: 'Entry',
    location: 'Dhaka',
    salary: '25k–40k BDT',
    experience: 0,
    category: 'Administration',
    industry: 'Retail',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 2, 26),
    skills: [
      'communication',
      'documentation',
      'excel',
      'scheduling',
      'stakeholder',
      'reporting'
    ],
  ),
  _bdJobFromSimple(
    id: 82,
    title: 'Procurement Specialist (Entry)',
    company: 'Berger Paints Bangladesh',
    type: 'Full-time',
    level: 'Entry',
    location: 'Dhaka',
    salary: '28k–45k BDT',
    experience: 0,
    category: 'Operations',
    industry: 'Manufacturing',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 2, 27),
    skills: [
      'supply chain',
      'excel',
      'communication',
      'market research',
      'negotiation',
      'documentation',
      'reporting'
    ],
  ),
  _bdJobFromSimple(
    id: 83,
    title: 'Event Coordinator (Intern)',
    company: 'Bashundhara Events',
    type: 'Internship',
    level: 'Intern',
    location: 'Dhaka',
    salary: 'Stipend',
    experience: 0,
    category: 'Events',
    industry: 'Retail',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 2, 28),
    skills: [
      'communication',
      'project management',
      'stakeholder',
      'documentation',
      'problem solving'
    ],
  ),
  // QA / Software Testing (ID 84)
  _bdJobFromSimple(
    id: 84,
    title: 'QA / Software Tester (Entry)',
    company: 'Therap BD',
    type: 'Full-time',
    level: 'Entry',
    location: 'Hybrid',
    salary: '35k–55k BDT',
    experience: 0,
    category: 'Software Engineering',
    industry: 'Software',
    workingMode: 'Hybrid',
    remote: false,
    posted: DateTime(2026, 2, 18),
    skills: [
      'testing',
      'selenium',
      'sql',
      'documentation',
      'api',
      'git',
      'problem solving',
      'communication'
    ],
  ),
  // Network / IT (IDs 85–86)
  _bdJobFromSimple(
    id: 85,
    title: 'Network Engineer (Junior)',
    company: 'Summit Communications',
    type: 'Full-time',
    level: 'Junior',
    location: 'Dhaka',
    salary: '40k–60k BDT',
    experience: 1,
    category: 'IT Administration',
    industry: 'Software',
    workingMode: 'On-site',
    remote: false,
    posted: DateTime(2026, 3, 1),
    skills: [
      'networking',
      'linux',
      'aws',
      'azure',
      'troubleshooting',
      'documentation',
      'communication'
    ],
  ),
  _bdJobFromSimple(
    id: 86,
    title: 'Network Administrator',
    company: 'BRACnet Limited',
    type: 'Full-time',
    level: 'Entry',
    location: 'Dhaka',
    salary: '30k–50k BDT',
    experience: 0,
    category: 'IT Administration',
    industry: 'Software',
    workingMode: 'Hybrid',
    remote: false,
    posted: DateTime(2026, 3, 2),
    skills: [
      'networking',
      'linux',
      'troubleshooting',
      'documentation',
      'communication',
      'monitoring'
    ],
  ),
  // Python / Automation (ID 87)
  _bdJobFromSimple(
    id: 87,
    title: 'Python Developer (Automation)',
    company: 'RoboSoft Technologies',
    type: 'Full-time',
    level: 'Junior',
    location: 'Remote',
    salary: '45k–65k BDT',
    experience: 1,
    category: 'Backend Development',
    industry: 'Software',
    workingMode: 'Remote',
    remote: true,
    posted: DateTime(2026, 2, 12),
    skills: [
      'python',
      'automation',
      'selenium',
      'rest api',
      'database',
      'git',
      'testing',
      'documentation'
    ],
  ),
];

// ── Merge all jobs ──────────────────────────────────────────────────────────
final List<Job> allJobs = [...globalJobs, ...bdJobs];

// Legacy alias
final List<Job> jobs = allJobs;

// =============================================================================
// HELPER FUNCTIONS (from first file, kept for compatibility)
// =============================================================================

List<Job> recommendJobsSimple(List<String> userSkills, {int? topN}) {
  final norm = userSkills.map((s) => s.toLowerCase()).toList();
  final ranked = allJobs.where((j) => j.matchScore(norm) > 0).toList()
    ..sort((a, b) => b.matchScore(norm).compareTo(a.matchScore(norm)));
  return topN != null ? ranked.take(topN).toList() : ranked;
}

List<Job> jobsByIndustry(String industry) =>
    allJobs.where((j) => j.industry == industry).toList();
List<Job> remoteJobs() => allJobs.where((j) => j.remote).toList();
List<Job> jobsByMaxExperience(int maxExperience) =>
    allJobs.where((j) => j.experience <= maxExperience).toList();
List<Job> jobsByWorkingMode(String workingMode) =>
    allJobs.where((j) => j.workingMode == workingMode).toList();
List<Job> jobsBySimScore(List<Job> scoredJobs) =>
    scoredJobs.toList()..sort((a, b) => b.simScore.compareTo(a.simScore));
List<Job> applySimScores(Map<int, double> scores) {
  return allJobs.map((j) => j.copyWith(simScore: scores[j.id] ?? 0.0)).toList()
    ..sort((a, b) => b.simScore.compareTo(a.simScore));
}

List<Job> entryLevelJobs() =>
    allJobs.where((j) => j.jobLevelEnum == JobLevel.entry).toList();

List<String> get allIndustriesSimple =>
    allJobs.map((j) => j.industry).toSet().toList()..sort();
List<String> get allLevelsSimple =>
    allJobs.map((j) => j.level).toSet().toList()..sort();
List<String> get allWorkingModesSimple =>
    allJobs.map((j) => j.workingMode).toSet().toList()..sort();

// =============================================================================
// CORE RECOMMENDATION & FILTER FUNCTIONS (from second file)
// =============================================================================

List<Job> recommendJobs(
  List<String> userSkills, {
  String industry = 'All',
  String level = 'All',
  bool remoteOnly = false,
  double? maxAutomationRisk,
  int? topN,
  JobFilter? filter,
}) {
  final effectiveFilter = filter ??
      JobFilter(
        industry: industry,
        level: level,
        remoteOnly: remoteOnly,
        maxAutomationRisk: maxAutomationRisk,
      );
  final ranked = allJobs
      .where(effectiveFilter.matches)
      .map((j) {
        final score = j.simScore > 0.0 ? j.simScore : j.matchScore(userSkills);
        final dist = j.computeTransitionDistance(userSkills);
        return (job: j.copyWith(transitionDistance: dist), score: score);
      })
      .where((e) => e.score > 0)
      .toList()
    ..sort((a, b) => b.score.compareTo(a.score));
  final results = ranked.map((e) => e.job).toList();
  return topN != null ? results.take(topN).toList() : results;
}

List<Job> filterJobs({
  String industry = 'All',
  String level = 'All',
  bool remoteOnly = false,
  String occupationalGroup = 'All',
  JobFilter? filter,
}) {
  final effectiveFilter = filter ??
      JobFilter(
        industry: industry,
        level: level,
        remoteOnly: remoteOnly,
        occupationalGroup: occupationalGroup,
      );
  return allJobs.where(effectiveFilter.matches).toList();
}

List<Job> sortJobs(List<Job> jobs, JobSortStrategy strategy) {
  final sorted = List<Job>.from(jobs);
  switch (strategy) {
    case JobSortStrategy.simScore:
      sorted.sort((a, b) => b.simScore.compareTo(a.simScore));
      break;
    case JobSortStrategy.postingGrowthRate:
      sorted.sort((a, b) =>
          (b.postingGrowthRate ?? 0.0).compareTo(a.postingGrowthRate ?? 0.0));
      break;
    case JobSortStrategy.postingFrequency:
      sorted.sort((a, b) =>
          (b.postingFrequency ?? 0.0).compareTo(a.postingFrequency ?? 0.0));
      break;
    case JobSortStrategy.automationRiskAsc:
      sorted.sort((a, b) =>
          (a.automationRisk ?? 0.5).compareTo(b.automationRisk ?? 0.5));
      break;
    case JobSortStrategy.transitionDistanceAsc:
      sorted
          .sort((a, b) => a.transitionDistance.compareTo(b.transitionDistance));
      break;
    case JobSortStrategy.mostRecent:
      sorted.sort((a, b) => b.posted.compareTo(a.posted));
      break;
    case JobSortStrategy.experienceAsc:
      sorted.sort((a, b) => a.experience.compareTo(b.experience));
      break;
    case JobSortStrategy.careerFitScore:
      sorted.sort((a, b) => (b.careerFitScore?.composite ?? 0.0)
          .compareTo(a.careerFitScore?.composite ?? 0.0));
      break;
  }
  return sorted;
}

List<Job> computeCareerFitScores(List<Job> jobs, List<String> userSkills) {
  return jobs
      .map((j) =>
          j.copyWith(careerFitScore: CareerFitScore.compute(j, userSkills)))
      .toList();
}

List<Job> attachSkillGapAnalysis(List<Job> jobs, List<String> userSkills) {
  return jobs
      .map((j) =>
          j.copyWith(skillGapAnalysis: SkillGapAnalysis.compute(j, userSkills)))
      .toList();
}

Map<String, int> skillDemandMap([List<Job>? jobs]) {
  final source = jobs ?? allJobs;
  final freq = <String, int>{};
  for (final j in source) {
    for (final s in j.skills) {
      final key = s.toLowerCase();
      freq[key] = (freq[key] ?? 0) + 1;
    }
  }
  return freq;
}

List<String> topSkillsByFrequency({int topN = 10, List<Job>? jobs}) {
  final freq = skillDemandMap(jobs);
  final entries = freq.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries.take(topN).map((e) => e.key).toList();
}

Map<String, List<Job>> clusterByOccupationalGroup([List<Job>? jobs]) {
  final source = jobs ?? allJobs;
  final map = <String, List<Job>>{};
  for (final j in source) {
    final key =
        j.occupationalGroup.isEmpty ? 'Unclassified' : j.occupationalGroup;
    map.putIfAbsent(key, () => []).add(j);
  }
  return map;
}

Map<PostingGrowthCategory, List<Job>> jobsByPostingGrowthCategory(
    [List<Job>? jobs]) {
  final source = jobs ?? allJobs;
  final map = <PostingGrowthCategory, List<Job>>{};
  for (final j in source) {
    final cat = j.postingGrowthCategory;
    map.putIfAbsent(cat, () => []).add(j);
  }
  return map;
}

List<Job> matchingJobsForSkillSet(List<String> skills,
    {int minMatchCount = 1, List<Job>? jobs}) {
  final source = jobs ?? allJobs;
  final lower = skills.map((s) => s.toLowerCase()).toSet();
  return source.where((j) {
    final matched =
        j.skills.where((s) => lower.contains(s.toLowerCase())).length;
    return matched >= minMatchCount;
  }).toList();
}

// ── Legacy session 2 helpers ─────────────────────────────────────────────────
List<Job> recentJobs({int days = 30}) {
  final cutoff = DateTime.now().subtract(Duration(days: days));
  return allJobs.where((j) => j.posted.isAfter(cutoff)).toList();
}

Map<String, int> jobCountByIndustry() {
  final map = <String, int>{};
  for (final j in allJobs) {
    map[j.industry] = (map[j.industry] ?? 0) + 1;
  }
  return map;
}

List<Job> trendingJobs({int? topN}) {
  final results = allJobs.where((j) => j.isTrending).toList();
  return topN != null ? results.take(topN).toList() : results;
}

List<Job> pivotSkillJobs({String industry = 'All'}) {
  return allJobs
      .where((j) =>
          (industry == 'All' || j.industry == industry) && j.isPivotSkillJob)
      .toList();
}

List<Job> sdgFilteredJobs(String sdgImpact) =>
    allJobs.where((j) => j.sdgImpact == sdgImpact).toList();

Map<String, List<Job>> jobsByAutomationRiskTier() {
  final map = <String, List<Job>>{
    'Low Risk': [],
    'Medium Risk': [],
    'High Risk': []
  };
  for (final j in allJobs) {
    map[j.automationRiskLabel]!.add(j);
  }
  return map;
}

List<Job> essentialJobs() =>
    allJobs.where((j) => j.isEssentialDuringCrisis).toList();

List<Job> fastestGrowingJobs({int? topN}) {
  final sorted = [...allJobs]..sort((a, b) =>
      (b.postingGrowthRate ?? 0.0).compareTo(a.postingGrowthRate ?? 0.0));
  return topN != null ? sorted.take(topN).toList() : sorted;
}

List<Job> jobsInDemandCity(String city) {
  final needle = city.toLowerCase();
  return allJobs.where((j) => j.topDemandCity.toLowerCase() == needle).toList();
}

List<Job> jobsByEducation(String educationLevel) {
  return allJobs
      .where((j) => j.primaryEducationRequirement == educationLevel)
      .toList();
}

JobStats allJobStats() => JobStats.fromJobs(allJobs);

List<Job> futureProofJobs({int? topN}) {
  final results = allJobs.where((j) => j.isFutureProof).toList();
  return topN != null ? results.take(topN).toList() : results;
}

List<Job> entryFriendlyJobs() =>
    allJobs.where((j) => j.isEntryFriendly).toList();
