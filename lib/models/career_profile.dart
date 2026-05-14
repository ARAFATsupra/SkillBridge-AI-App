// lib/models/career_profile.dart — SkillBridge AI (Upgraded v4 — Maximum Level)

// Research grounding:
// [AJJ26] Ajjam & Al-Raweshidy (2026) — AI semantic job matching (§3–4)
// [ZC22] Zhisheng Chen (2022) — P-J Fit, P-O Fit, 6-stage recruitment
// [ALA23] Alaql et al. (2023) — Multi-generational workforce insights
// [XZ25] Xiao & Zheng (2025) — Career confidence tracking
// [LH22] Li Huang (2022) — Employment intention evolution
// [TAV22] Tavakoli et al. (2022) — eDoer learner preference model
// [DAW21] Dawson et al. (2021) — Skill-driven job transition pathways

import 'package:flutter/material.dart';

// =============================================================================
// FIELD OF STUDY [AJJ26 §3.3] — Upgraded with static lookup tables
// =============================================================================
enum FieldOfStudy {
  science,
  engineering,
  business,
  arts,
  finance,
  it,
  education,
  healthcare,
  marketing,
  law,
  other;

  // ── Static lookup tables (maximum performance & maintainability) ──
  static const Map<FieldOfStudy, String> _labels = {
    FieldOfStudy.science: 'Science',
    FieldOfStudy.engineering: 'Engineering',
    FieldOfStudy.business: 'Business',
    FieldOfStudy.arts: 'Arts & Design',
    FieldOfStudy.finance: 'Finance',
    FieldOfStudy.it: 'Information Technology',
    FieldOfStudy.education: 'Education',
    FieldOfStudy.healthcare: 'Healthcare',
    FieldOfStudy.marketing: 'Marketing',
    FieldOfStudy.law: 'Law',
    FieldOfStudy.other: 'Other',
  };

  static const Map<FieldOfStudy, String> _shortLabels = {
    FieldOfStudy.science: 'Science',
    FieldOfStudy.engineering: 'Engineering',
    FieldOfStudy.business: 'Business',
    FieldOfStudy.arts: 'Arts',
    FieldOfStudy.finance: 'Finance',
    FieldOfStudy.it: 'IT',
    FieldOfStudy.education: 'Education',
    FieldOfStudy.healthcare: 'Healthcare',
    FieldOfStudy.marketing: 'Marketing',
    FieldOfStudy.law: 'Law',
    FieldOfStudy.other: 'Other',
  };

  static const Map<FieldOfStudy, List<String>> _recommendedIndustries = {
    FieldOfStudy.science: ['Software', 'Finance', 'Healthcare', 'Education'],
    FieldOfStudy.engineering: [
      'Finance',
      'Software',
      'Education',
      'Manufacturing'
    ],
    FieldOfStudy.business: ['Finance', 'Healthcare', 'Education', 'Retail'],
    FieldOfStudy.arts: ['Finance', 'Software', 'Healthcare', 'Marketing'],
    FieldOfStudy.law: ['Finance', 'Education', 'Software'],
    FieldOfStudy.it: ['Software', 'Finance', 'Healthcare', 'Manufacturing'],
    FieldOfStudy.finance: ['Finance', 'Retail', 'Software'],
    FieldOfStudy.healthcare: ['Healthcare', 'Education', 'Finance'],
    FieldOfStudy.marketing: ['Marketing', 'Retail', 'Software', 'Education'],
    FieldOfStudy.education: ['Education', 'Healthcare', 'Retail', 'Finance'],
    FieldOfStudy.other: ['Finance', 'Software', 'Marketing'],
  };

  static const Map<FieldOfStudy, List<String>> _coreSkills = {
    FieldOfStudy.engineering: [
      'python',
      'java',
      'c++',
      'sql',
      'git',
      'problem solving',
      'oop'
    ],
    FieldOfStudy.it: [
      'python',
      'java',
      'sql',
      'networking',
      'aws',
      'cloud computing',
      'linux'
    ],
    FieldOfStudy.business: [
      'excel',
      'data analysis',
      'communication skills',
      'financial modeling',
      'sql'
    ],
    FieldOfStudy.finance: [
      'excel',
      'financial modeling',
      'risk analysis',
      'sql',
      'python'
    ],
    FieldOfStudy.science: [
      'python',
      'data analysis',
      'statistics',
      'research',
      'sql'
    ],
    FieldOfStudy.healthcare: [
      'patient care',
      'medical research',
      'pharmaceuticals',
      'nursing',
      'communication skills'
    ],
    FieldOfStudy.marketing: [
      'seo',
      'social media',
      'content writing',
      'google ads',
      'analytics'
    ],
    FieldOfStudy.education: [
      'teaching',
      'curriculum design',
      'edtech',
      'research',
      'communication skills'
    ],
    FieldOfStudy.arts: [
      'ux design',
      'figma',
      'content writing',
      'copywriting',
      'adobe creative suite'
    ],
    FieldOfStudy.law: [
      'research',
      'communication skills',
      'risk analysis',
      'reporting',
      'negotiation'
    ],
    FieldOfStudy.other: [
      'communication skills',
      'excel',
      'data analysis',
      'problem solving',
      'sql'
    ],
  };

  static const Map<FieldOfStudy, double> _learningDomainWeights = {
    FieldOfStudy.engineering: 1.0,
    FieldOfStudy.it: 1.0,
    FieldOfStudy.science: 1.0,
    FieldOfStudy.finance: 0.8,
    FieldOfStudy.business: 0.8,
    FieldOfStudy.healthcare: 0.7,
    FieldOfStudy.law: 0.7,
    FieldOfStudy.marketing: 0.6,
    FieldOfStudy.arts: 0.6,
    FieldOfStudy.education: 0.6,
    FieldOfStudy.other: 0.5,
  };

  static const Set<FieldOfStudy> _datasetBacked = {
    FieldOfStudy.science,
    FieldOfStudy.engineering,
    FieldOfStudy.business,
    FieldOfStudy.arts,
    FieldOfStudy.law,
  };

  // ── Public API (const-correct & zero-allocation) ──
  String get label => _labels[this]!;
  String get shortLabel => _shortLabels[this]!;
  String get key => name;
  List<String> get recommendedIndustries => _recommendedIndustries[this]!;
  List<String> get coreSkills => _coreSkills[this]!;
  double get learningDomainWeight => _learningDomainWeights[this]!;
  bool get isDatasetBacked => _datasetBacked.contains(this);

  // ── Parse (fast map lookup) ──
  static FieldOfStudy fromKey(String key) {
    final normalized = key.trim().toLowerCase();
    return _keyMap[normalized] ?? FieldOfStudy.other;
  }

  static FieldOfStudy fromLabel(String label) {
    final normalized = label.trim().toLowerCase();
    return _labelMap[normalized] ?? FieldOfStudy.other;
  }

  static const Map<String, FieldOfStudy> _keyMap = {
    'science': FieldOfStudy.science,
    'engineering': FieldOfStudy.engineering,
    'business': FieldOfStudy.business,
    'arts': FieldOfStudy.arts,
    'finance': FieldOfStudy.finance,
    'it': FieldOfStudy.it,
    'education': FieldOfStudy.education,
    'healthcare': FieldOfStudy.healthcare,
    'marketing': FieldOfStudy.marketing,
    'law': FieldOfStudy.law,
    'other': FieldOfStudy.other,
  };

  static const Map<String, FieldOfStudy> _labelMap = {
    'science': FieldOfStudy.science,
    'engineering': FieldOfStudy.engineering,
    'business': FieldOfStudy.business,
    'arts & design': FieldOfStudy.arts,
    'arts': FieldOfStudy.arts,
    'finance': FieldOfStudy.finance,
    'information technology': FieldOfStudy.it,
    'it': FieldOfStudy.it,
    'education': FieldOfStudy.education,
    'healthcare': FieldOfStudy.healthcare,
    'marketing': FieldOfStudy.marketing,
    'law': FieldOfStudy.law,
    'other': FieldOfStudy.other,
  };
}

// =============================================================================
// CAREER PATH — Upgraded with static lookup tables
// =============================================================================
enum CareerPath {
  business,
  design,
  finance,
  healthcare,
  tech,
  other;

  static const Map<CareerPath, String> _labels = {
    CareerPath.business: 'Business',
    CareerPath.design: 'Design',
    CareerPath.finance: 'Finance',
    CareerPath.healthcare: 'Healthcare',
    CareerPath.tech: 'Tech',
    CareerPath.other: 'Other',
  };

  static const Map<CareerPath, double> _avgSuccessProbabilities = {
    CareerPath.healthcare: 0.529,
    CareerPath.finance: 0.509,
    CareerPath.business: 0.503,
    CareerPath.design: 0.502,
    CareerPath.tech: 0.488,
    CareerPath.other: 0.504,
  };

  static const Map<CareerPath, double> _successBoosts = {
    CareerPath.healthcare: 0.025,
    CareerPath.finance: 0.005,
    CareerPath.business: -0.001,
    CareerPath.design: -0.002,
    CareerPath.tech: -0.016,
    CareerPath.other: 0.000,
  };

  static const Map<CareerPath, IconData> _icons = {
    CareerPath.business: Icons.business_rounded,
    CareerPath.design: Icons.palette_rounded,
    CareerPath.finance: Icons.account_balance_rounded,
    CareerPath.healthcare: Icons.health_and_safety_rounded,
    CareerPath.tech: Icons.computer_rounded,
    CareerPath.other: Icons.work_outline_rounded,
  };

  String get label => _labels[this]!;
  String get key => name;
  double get avgSuccessProbability => _avgSuccessProbabilities[this]!;
  double get successBoost => _successBoosts[this]!;
  IconData get icon => _icons[this]!;

  static CareerPath fromLabel(String? label) {
    if (label == null) return CareerPath.other;
    final key = label.toLowerCase().trim();
    return _labelMap[key] ?? CareerPath.other;
  }

  static CareerPath fromKey(String key) {
    final normalized = key.trim().toLowerCase();
    return _keyMap[normalized] ?? CareerPath.other;
  }

  static const Map<String, CareerPath> _labelMap = {
    'business': CareerPath.business,
    'design': CareerPath.design,
    'finance': CareerPath.finance,
    'healthcare': CareerPath.healthcare,
    'tech': CareerPath.tech,
  };

  static const Map<String, CareerPath> _keyMap = {
    'business': CareerPath.business,
    'design': CareerPath.design,
    'finance': CareerPath.finance,
    'healthcare': CareerPath.healthcare,
    'tech': CareerPath.tech,
    'other': CareerPath.other,
  };
}

// =============================================================================
// ENTREPRENEURIAL ASPIRATION — Upgraded
// =============================================================================
enum EntrepreneurialAspiration {
  high,
  medium,
  low;

  static const Map<EntrepreneurialAspiration, String> _labels = {
    EntrepreneurialAspiration.high: 'High',
    EntrepreneurialAspiration.medium: 'Medium',
    EntrepreneurialAspiration.low: 'Low',
  };

  static const Map<EntrepreneurialAspiration, double> _successBoosts = {
    EntrepreneurialAspiration.high: 0.024,
    EntrepreneurialAspiration.medium: -0.004,
    EntrepreneurialAspiration.low: -0.014,
  };

  static const Map<EntrepreneurialAspiration, double> _avgSuccessProbabilities =
      {
    EntrepreneurialAspiration.high: 0.5275,
    EntrepreneurialAspiration.medium: 0.4997,
    EntrepreneurialAspiration.low: 0.4900,
  };

  static const Map<EntrepreneurialAspiration, String> _descriptions = {
    EntrepreneurialAspiration.high: 'Eager to launch or co-found a venture.',
    EntrepreneurialAspiration.medium:
        'Open to entrepreneurship as a future option.',
    EntrepreneurialAspiration.low:
        'Prefers structured employment over self-employment.',
  };

  String get label => _labels[this]!;
  String get key => name;
  double get successBoost => _successBoosts[this]!;
  double get avgSuccessProbability => _avgSuccessProbabilities[this]!;
  String get description => _descriptions[this]!;

  static EntrepreneurialAspiration fromLabel(String? label) {
    if (label == null) return EntrepreneurialAspiration.low;
    final key = label.toLowerCase().trim();
    return _labelMap[key] ?? EntrepreneurialAspiration.low;
  }

  static EntrepreneurialAspiration fromKey(String key) {
    final normalized = key.trim().toLowerCase();
    return _keyMap[normalized] ?? EntrepreneurialAspiration.low;
  }

  static const Map<String, EntrepreneurialAspiration> _labelMap = {
    'high': EntrepreneurialAspiration.high,
    'medium': EntrepreneurialAspiration.medium,
    'low': EntrepreneurialAspiration.low,
  };

  static const Map<String, EntrepreneurialAspiration> _keyMap = {
    'high': EntrepreneurialAspiration.high,
    'medium': EntrepreneurialAspiration.medium,
    'low': EntrepreneurialAspiration.low,
  };
}

// =============================================================================
// EXPERIENCE TYPE — Upgraded
// =============================================================================
enum ExperienceType {
  none,
  internship,
  partTime,
  fullTime;

  static const Map<ExperienceType, String> _labels = {
    ExperienceType.none: 'No Experience',
    ExperienceType.internship: 'Internship',
    ExperienceType.partTime: 'Part-time',
    ExperienceType.fullTime: 'Full-time',
  };

  static const Map<ExperienceType, double> _yearsEquivalent = {
    ExperienceType.none: 0.0,
    ExperienceType.internship: 0.5,
    ExperienceType.partTime: 1.0,
    ExperienceType.fullTime: 2.0,
  };

  static const Map<ExperienceType, double> _successBoosts = {
    ExperienceType.partTime: 0.007,
    ExperienceType.internship: 0.001,
    ExperienceType.fullTime: -0.003,
    ExperienceType.none: -0.010,
  };

  static const Map<ExperienceType, double> _matchBoosts = {
    ExperienceType.none: 0.00,
    ExperienceType.internship: 0.03,
    ExperienceType.partTime: 0.05,
    ExperienceType.fullTime: 0.08,
  };

  static const Map<ExperienceType, IconData> _icons = {
    ExperienceType.none: Icons.person_outline_rounded,
    ExperienceType.internship: Icons.school_outlined,
    ExperienceType.partTime: Icons.access_time_rounded,
    ExperienceType.fullTime: Icons.business_center_rounded,
  };

  String get label => _labels[this]!;
  String get key => name;
  double get yearsEquivalent => _yearsEquivalent[this]!;
  double get successBoost => _successBoosts[this]!;
  double get matchBoost => _matchBoosts[this]!;
  IconData get icon => _icons[this]!;

  static ExperienceType fromKey(String key) {
    final normalized = key.trim();
    return _keyMap[normalized] ?? ExperienceType.none;
  }

  static ExperienceType fromDatasetLabel(String? label) {
    final l = label?.toLowerCase().trim() ?? '';
    if (l == 'full-time' ||
        l == 'fulltime' ||
        l == 'contract' ||
        l == 'temporary') {
      return ExperienceType.fullTime;
    }
    if (l == 'part-time' || l == 'parttime') return ExperienceType.partTime;
    if (l == 'internship' || l == 'intern') return ExperienceType.internship;
    return ExperienceType.none;
  }

  static const Map<String, ExperienceType> _keyMap = {
    'none': ExperienceType.none,
    'internship': ExperienceType.internship,
    'partTime': ExperienceType.partTime,
    'fullTime': ExperienceType.fullTime,
  };
}

// =============================================================================
// WORKFORCE GENERATION [ALA23] — Upgraded
// =============================================================================
enum WorkforceGeneration {
  genZ,
  millennial,
  genX,
  babyBoomer;

  static const Map<WorkforceGeneration, String> _labels = {
    WorkforceGeneration.genZ: 'Gen Z',
    WorkforceGeneration.millennial: 'Millennial',
    WorkforceGeneration.genX: 'Gen X',
    WorkforceGeneration.babyBoomer: 'Baby Boomer',
  };

  static const Map<WorkforceGeneration, String> _yearRanges = {
    WorkforceGeneration.genZ: '1997–2012',
    WorkforceGeneration.millennial: '1981–1996',
    WorkforceGeneration.genX: '1965–1980',
    WorkforceGeneration.babyBoomer: '1946–1964',
  };

  static const Map<WorkforceGeneration, String> _workPreferences = {
    WorkforceGeneration.genZ:
        'Remote-first, purpose-driven, tech-enabled, entrepreneurial',
    WorkforceGeneration.millennial:
        'Work-life balance, career development, collaborative culture',
    WorkforceGeneration.genX:
        'Autonomy, stability, results-oriented, cross-functional skills',
    WorkforceGeneration.babyBoomer:
        'Mentoring, traditional roles, institutional loyalty, face-to-face',
  };

  static const Map<WorkforceGeneration, List<String>> _preferredJobCategories =
      {
    WorkforceGeneration.genZ: [
      'Software',
      'Marketing',
      'Education',
      'Healthcare'
    ],
    WorkforceGeneration.millennial: [
      'Software',
      'Finance',
      'Marketing',
      'Healthcare'
    ],
    WorkforceGeneration.genX: [
      'Finance',
      'Manufacturing',
      'Software',
      'Healthcare'
    ],
    WorkforceGeneration.babyBoomer: [
      'Healthcare',
      'Education',
      'Finance',
      'Manufacturing'
    ],
  };

  static const Map<WorkforceGeneration, Color> _colors = {
    WorkforceGeneration.genZ: Color(0xFF6A1B9A),
    WorkforceGeneration.millennial: Color(0xFF1565C0),
    WorkforceGeneration.genX: Color(0xFF2E7D32),
    WorkforceGeneration.babyBoomer: Color(0xFFE65100),
  };

  static const Map<WorkforceGeneration, IconData> _icons = {
    WorkforceGeneration.genZ: Icons.phone_android_rounded,
    WorkforceGeneration.millennial: Icons.laptop_rounded,
    WorkforceGeneration.genX: Icons.business_center_rounded,
    WorkforceGeneration.babyBoomer: Icons.account_balance_rounded,
  };

  String get label => _labels[this]!;
  String get key => name;
  String get yearRange => _yearRanges[this]!;
  String get workPreference => _workPreferences[this]!;
  List<String> get preferredJobCategories => _preferredJobCategories[this]!;
  Color get color => _colors[this]!;
  IconData get icon => _icons[this]!;

  static WorkforceGeneration fromBirthYear(int year) {
    if (year >= 1997) return WorkforceGeneration.genZ;
    if (year >= 1981) return WorkforceGeneration.millennial;
    if (year >= 1965) return WorkforceGeneration.genX;
    return WorkforceGeneration.babyBoomer;
  }

  static WorkforceGeneration fromKey(String key) {
    final normalized = key.trim();
    return _keyMap[normalized] ?? WorkforceGeneration.millennial;
  }

  static const Map<String, WorkforceGeneration> _keyMap = {
    'genZ': WorkforceGeneration.genZ,
    'millennial': WorkforceGeneration.millennial,
    'genX': WorkforceGeneration.genX,
    'babyBoomer': WorkforceGeneration.babyBoomer,
  };
}

// =============================================================================
// CAREER CONFIDENCE CATEGORY [XZ25] — Upgraded
// =============================================================================
enum CareerConfidenceCategory {
  technicalSkills,
  communication,
  jobSearch,
  interview,
  salaryNegotiation;

  static const Map<CareerConfidenceCategory, String> _labels = {
    CareerConfidenceCategory.technicalSkills: 'Technical Skills',
    CareerConfidenceCategory.communication: 'Communication',
    CareerConfidenceCategory.jobSearch: 'Job Search',
    CareerConfidenceCategory.interview: 'Interview',
    CareerConfidenceCategory.salaryNegotiation: 'Salary Negotiation',
  };

  static const Map<CareerConfidenceCategory, String> _boostTips = {
    CareerConfidenceCategory.technicalSkills:
        'Complete one skill-specific course or project this week to reinforce your technical foundation.',
    CareerConfidenceCategory.communication:
        'Practice the STAR method for behavioural questions and record a 2-minute self-introduction video.',
    CareerConfidenceCategory.jobSearch:
        'Set daily application targets and use keyword-optimised résumés tailored to each role.',
    CareerConfidenceCategory.interview:
        'Run 3 mock interviews this week — even self-recorded ones measurably improve performance.',
    CareerConfidenceCategory.salaryNegotiation:
        'Research salary benchmarks for your target role and practise counter-offer scripts out loud.',
  };

  static const Map<CareerConfidenceCategory, IconData> _icons = {
    CareerConfidenceCategory.technicalSkills: Icons.code_rounded,
    CareerConfidenceCategory.communication: Icons.record_voice_over_rounded,
    CareerConfidenceCategory.jobSearch: Icons.search_rounded,
    CareerConfidenceCategory.interview: Icons.people_outlined,
    CareerConfidenceCategory.salaryNegotiation: Icons.attach_money_rounded,
  };

  static const Map<CareerConfidenceCategory, Color> _colors = {
    CareerConfidenceCategory.technicalSkills: Color(0xFF1565C0),
    CareerConfidenceCategory.communication: Color(0xFF2E7D32),
    CareerConfidenceCategory.jobSearch: Color(0xFFE65100),
    CareerConfidenceCategory.interview: Color(0xFF6A1B9A),
    CareerConfidenceCategory.salaryNegotiation: Color(0xFF00695C),
  };

  String get label => _labels[this]!;
  String get key => name;
  String get boostTip => _boostTips[this]!;
  IconData get icon => _icons[this]!;
  Color get color => _colors[this]!;

  static CareerConfidenceCategory fromKey(String key) {
    final normalized = key.trim();
    return _keyMap[normalized] ?? CareerConfidenceCategory.technicalSkills;
  }

  static const Map<String, CareerConfidenceCategory> _keyMap = {
    'technicalSkills': CareerConfidenceCategory.technicalSkills,
    'communication': CareerConfidenceCategory.communication,
    'jobSearch': CareerConfidenceCategory.jobSearch,
    'interview': CareerConfidenceCategory.interview,
    'salaryNegotiation': CareerConfidenceCategory.salaryNegotiation,
  };
}

// =============================================================================
// GPA TIER — Upgraded
// =============================================================================
enum GpaTier {
  distinction,
  merit,
  pass,
  developing;

  static const Map<GpaTier, String> _labels = {
    GpaTier.distinction: 'Distinction',
    GpaTier.merit: 'Merit',
    GpaTier.pass: 'Pass',
    GpaTier.developing: 'Developing',
  };

  static const Map<GpaTier, Color> _colors = {
    GpaTier.distinction: Color(0xFF1565C0),
    GpaTier.merit: Color(0xFF2E7D32),
    GpaTier.pass: Color(0xFFE65100),
    GpaTier.developing: Color(0xFF757575),
  };

  static const Map<GpaTier, IconData> _icons = {
    GpaTier.distinction: Icons.star_rounded,
    GpaTier.merit: Icons.star_half_rounded,
    GpaTier.pass: Icons.check_circle_outline_rounded,
    GpaTier.developing: Icons.trending_up_rounded,
  };

  static const Map<GpaTier, String> _advice = {
    GpaTier.distinction:
        'Dataset insight: GPA ≥3.5 has the highest self-employment rate (40%) but the lowest formal employment rate (27%). Build a portfolio alongside your grades.',
    GpaTier.merit:
        'Your GPA range (3.0–3.5) has the highest formal employment rate in our dataset (34%). Complement with projects and certifications to maintain that edge.',
    GpaTier.pass:
        'GPA 2.5–3.0 has a 33% employment rate — only 1 pp behind the highest band. Practical skills and experience matter more than GPA alone.',
    GpaTier.developing:
        'Dataset: GPA <2.5 still achieves 30% formal employment. Internships, certifications, and projects compensate significantly for lower grades.',
  };

  String get label => _labels[this]!;
  Color get color => _colors[this]!;
  IconData get icon => _icons[this]!;
  String get advice => _advice[this]!;

  static GpaTier fromGpa(double gpa) {
    if (gpa >= 3.7) return GpaTier.distinction;
    if (gpa >= 3.3) return GpaTier.merit;
    if (gpa >= 2.7) return GpaTier.pass;
    return GpaTier.developing;
  }
}

// =============================================================================
// POST-GRAD STATS (unchanged — already optimal)
// =============================================================================
@immutable
class PostGradStats {
  final double employed;
  final double selfEmployed;
  final double unemployed;

  const PostGradStats({
    required this.employed,
    required this.selfEmployed,
    required this.unemployed,
  });

  static const PostGradStats overall = PostGradStats(
    employed: 0.311,
    selfEmployed: 0.343,
    unemployed: 0.346,
  );

  String get summary =>
      'Employed ${(employed * 100).round()}% · Self-employed ${(selfEmployed * 100).round()}% · Unemployed ${(unemployed * 100).round()}%';

  Map<String, double> toMap() => {
        'employed': employed,
        'selfEmployed': selfEmployed,
        'unemployed': unemployed,
      };

  factory PostGradStats.fromMap(Map<String, dynamic> map) => PostGradStats(
        employed: (map['employed'] as num? ?? 0.0).toDouble(),
        selfEmployed: (map['selfEmployed'] as num? ?? 0.0).toDouble(),
        unemployed: (map['unemployed'] as num? ?? 0.0).toDouble(),
      );
}

// =============================================================================
// WEIGHTED SKILL (unchanged — already optimal)
// =============================================================================
@immutable
class WeightedSkill {
  final String skill;
  final double weight;

  const WeightedSkill({required this.skill, this.weight = 1.0});

  String get normalised => skill.trim().toLowerCase();

  Map<String, dynamic> toMap() => {'skill': skill, 'weight': weight};

  factory WeightedSkill.fromMap(Map<String, dynamic> m) => WeightedSkill(
        skill: (m['skill'] as String? ?? '').trim(),
        weight: (m['weight'] as num? ?? 1.0).toDouble().clamp(0.0, 1.0),
      );

  @override
  bool operator ==(Object other) =>
      other is WeightedSkill && other.normalised == normalised;

  @override
  int get hashCode => normalised.hashCode;
}

// =============================================================================
// CAREER PROFILE — Maximum Level (v4)
// =============================================================================
@immutable
class CareerProfile {
  // ── Core profile ─────────────────────────────────────────
  final String name;
  final FieldOfStudy fieldOfStudy;
  final int yearOfStudy;
  final double gpa;
  final ExperienceType employmentType;
  final bool hasEntrepreneurialExperience;
  final List<String> careerInterests;
  final List<String> skills;
  final EntrepreneurialAspiration entrepreneurialAspiration;

  // ── Generation & Transition ───────────────────────────────
  final int? birthYear;
  final String targetJobTitle;
  final List<String> preferredOrgValues;

  // ── Confidence & Intention ────────────────────────────────
  final Map<String, double> confidenceScores;
  final String employmentIntention;

  // ── CV & Raw Data ─────────────────────────────────────────
  final String cvText;

  const CareerProfile({
    required this.name,
    required this.fieldOfStudy,
    required this.yearOfStudy,
    required this.gpa,
    required this.employmentType,
    this.hasEntrepreneurialExperience = false,
    this.careerInterests = const [],
    this.skills = const [],
    this.entrepreneurialAspiration = EntrepreneurialAspiration.low,
    this.birthYear,
    this.targetJobTitle = '',
    this.preferredOrgValues = const [],
    this.confidenceScores = const {},
    this.employmentIntention = 'undecided',
    this.cvText = '',
  });

  // ── Factory with full normalisation & validation (v4) ─────
  factory CareerProfile.build({
    required String name,
    required FieldOfStudy fieldOfStudy,
    required int yearOfStudy,
    required double gpa,
    required ExperienceType employmentType,
    bool hasEntrepreneurialExperience = false,
    List<String> careerInterests = const [],
    List<String> skills = const [],
    EntrepreneurialAspiration entrepreneurialAspiration =
        EntrepreneurialAspiration.low,
    int? birthYear,
    String targetJobTitle = '',
    List<String> preferredOrgValues = const [],
    Map<String, double> confidenceScores = const {},
    String employmentIntention = 'undecided',
    String cvText = '',
  }) {
    // Normalisation (zero-duplication, lowercase, trimmed)
    final normSkills = skills
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final normInterests = careerInterests
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final normValues = preferredOrgValues
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final normConf = Map<String, double>.unmodifiable(
      confidenceScores.map((k, v) => MapEntry(k, v.clamp(1.0, 5.0))),
    );

    return CareerProfile(
      name: name.trim(),
      fieldOfStudy: fieldOfStudy,
      yearOfStudy: yearOfStudy.clamp(1, 5),
      gpa: gpa.clamp(0.0, 4.0),
      employmentType: employmentType,
      hasEntrepreneurialExperience: hasEntrepreneurialExperience,
      careerInterests: normInterests,
      skills: normSkills,
      entrepreneurialAspiration: entrepreneurialAspiration,
      birthYear: birthYear,
      targetJobTitle: targetJobTitle.trim(),
      preferredOrgValues: normValues,
      confidenceScores: normConf,
      employmentIntention: employmentIntention.trim(),
      cvText: cvText.trim(),
    );
  }

  factory CareerProfile.empty() => const CareerProfile(
        name: '',
        fieldOfStudy: FieldOfStudy.other,
        yearOfStudy: 1,
        gpa: 0.0,
        employmentType: ExperienceType.none,
      );

  bool get isEmpty => name.isEmpty && gpa == 0.0 && skills.isEmpty;
  bool get isComplete =>
      name.isNotEmpty &&
      gpa > 0.0 &&
      skills.isNotEmpty &&
      careerInterests.isNotEmpty;

  // ── Field delegates (const-safe) ─────────────────────────
  String get fieldLabel => fieldOfStudy.label;
  String get experienceLabel => employmentType.label;
  double get experienceYears => employmentType.yearsEquivalent;
  List<String> get recommendedIndustries => fieldOfStudy.recommendedIndustries;
  List<String> get missingCoreSkills {
    final userSet = skills.toSet();
    return fieldOfStudy.coreSkills
        .where((s) => !userSet.contains(s))
        .toList(growable: false);
  }

  bool isRecommendedIndustry(String industry) => recommendedIndustries
      .any((i) => i.toLowerCase() == industry.toLowerCase());

  // ── GPA & Generation ─────────────────────────────────────
  GpaTier get gpaTier => GpaTier.fromGpa(gpa);
  bool get gpaInDatasetRange => gpa >= 2.0 && gpa <= 4.0;

  WorkforceGeneration? get workforceGeneration =>
      birthYear != null ? WorkforceGeneration.fromBirthYear(birthYear!) : null;
  int? get age => birthYear != null ? DateTime.now().year - birthYear! : null;
  List<String> get generationPreferredCategories =>
      workforceGeneration?.preferredJobCategories ?? const [];

  // ── Career Path Helpers ──────────────────────────────────
  CareerPath get primaryCareerPath {
    for (final interest in careerInterests) {
      final path = CareerPath.fromLabel(interest);
      if (path != CareerPath.other) return path;
    }
    return CareerPath.other;
  }

  bool get interestPathAligned =>
      careerInterests.any((i) => CareerPath.fromLabel(i) != CareerPath.other);

  // ── Post-grad stats ──────────────────────────────────────
  PostGradStats? get postGradStats {
    switch (fieldOfStudy) {
      case FieldOfStudy.arts:
        return const PostGradStats(
            employed: 0.31, selfEmployed: 0.38, unemployed: 0.31);
      case FieldOfStudy.business:
        return const PostGradStats(
            employed: 0.29, selfEmployed: 0.36, unemployed: 0.35);
      case FieldOfStudy.engineering:
        return const PostGradStats(
            employed: 0.34, selfEmployed: 0.33, unemployed: 0.33);
      case FieldOfStudy.law:
        return const PostGradStats(
            employed: 0.31, selfEmployed: 0.35, unemployed: 0.34);
      case FieldOfStudy.science:
        return const PostGradStats(
            employed: 0.30, selfEmployed: 0.31, unemployed: 0.39);
      default:
        return null; // legacy fields only
    }
  }

  PostGradStats get overallPostGradStats => PostGradStats.overall;

  // ── SUCCESS PROBABILITY (dataset-backed, clamped) ────────
  double get successProbability {
    var p = 0.504; // dataset mean
    p += employmentType.successBoost;
    p += entrepreneurialAspiration.successBoost;
    if (interestPathAligned) p += 0.023;
    p += primaryCareerPath.successBoost;
    p += (yearOfStudy - 1) * 0.002;
    if (hasEntrepreneurialExperience) p += 0.007;
    if (gpa >= 3.8) p += 0.010;
    return p.clamp(0.0, 0.95);
  }

  String get successLabel {
    final p = successProbability;
    if (p >= 0.58) return 'High';
    if (p >= 0.53) return 'Good';
    if (p >= 0.50) return 'Moderate';
    return 'Building';
  }

  String get successAdvice {
    final p = successProbability;
    if (p >= 0.58) {
      return 'Strong profile — follow career recommendations (dataset: +0.5 pp success for followers).';
    }
    if (p >= 0.53) {
      return 'Good foundation. Raise aspiration to High: dataset shows +3.75 pp success vs Low.';
    }
    if (p >= 0.50) {
      return 'Part-time experience is the strongest single signal — seek one now.';
    }
    return 'Any work experience (even an internship) has the largest dataset-backed impact on your success probability.';
  }

  // ── CAREER CONFIDENCE [XZ25] ─────────────────────────────
  double get overallConfidenceScore {
    if (confidenceScores.isEmpty) return 0.0;
    final sum = confidenceScores.values.fold(0.0, (a, b) => a + b);
    return (sum / confidenceScores.length).clamp(0.0, 5.0);
  }

  double get normalizedConfidenceScore =>
      (overallConfidenceScore / 5.0).clamp(0.0, 1.0);

  String get confidenceLabel {
    final s = overallConfidenceScore;
    if (s >= 4.0) return 'Excellent';
    if (s >= 3.0) return 'Good';
    if (s >= 2.0) return 'Developing';
    return 'Needs Support';
  }

  bool get isConfident => overallConfidenceScore >= 3.5;

  CareerConfidenceCategory? get weakestConfidenceCategory {
    if (confidenceScores.isEmpty) return null;
    String? lowestKey;
    var lowestVal = double.infinity;
    for (final e in confidenceScores.entries) {
      if (e.value < lowestVal) {
        lowestVal = e.value;
        lowestKey = e.key;
      }
    }
    return lowestKey != null
        ? CareerConfidenceCategory.fromKey(lowestKey)
        : null;
  }

  CareerConfidenceCategory? get strongestConfidenceCategory {
    if (confidenceScores.isEmpty) return null;
    String? highestKey;
    var highestVal = double.negativeInfinity;
    for (final e in confidenceScores.entries) {
      if (e.value > highestVal) {
        highestVal = e.value;
        highestKey = e.key;
      }
    }
    return highestKey != null
        ? CareerConfidenceCategory.fromKey(highestKey)
        : null;
  }

  double confidenceScoreFor(CareerConfidenceCategory cat) =>
      confidenceScores[cat.key] ?? 0.0;

  // ── PERSON-JOB FIT [ZC22 + AJJ26] ────────────────────────
  double pjFitScore(List<WeightedSkill> weightedJobSkills) {
    if (skills.isEmpty || weightedJobSkills.isEmpty) return 0.0;
    final userSet = skills.toSet();
    var totalWeight = 0.0;
    var matchWeight = 0.0;
    for (final ws in weightedJobSkills) {
      totalWeight += ws.weight;
      if (userSet.contains(ws.normalised)) matchWeight += ws.weight;
    }
    return totalWeight == 0 ? 0.0 : (matchWeight / totalWeight).clamp(0.0, 1.0);
  }

  double pjFitScoreSimple(List<String> jobSkills) {
    if (skills.isEmpty || jobSkills.isEmpty) return 0.0;
    final userSet = skills.toSet();
    final matched =
        jobSkills.where((s) => userSet.contains(s.toLowerCase().trim())).length;
    return (matched / jobSkills.length).clamp(0.0, 1.0);
  }

  String pjFitLabel(List<WeightedSkill> weightedJobSkills) {
    final s = pjFitScore(weightedJobSkills);
    if (s >= 0.75) return 'Strong Fit';
    if (s >= 0.50) return 'Good Fit';
    if (s >= 0.30) return 'Partial Fit';
    return 'Skill Gap';
  }

  // ── PERSON-ORGANISATION FIT [ZC22] ───────────────────────
  double poFitScore(List<String> orgValues) {
    if (preferredOrgValues.isEmpty || orgValues.isEmpty) return 0.0;
    final userSet = preferredOrgValues.toSet();
    final orgSet = orgValues.map((v) => v.toLowerCase().trim()).toSet();
    final intersect = userSet.intersection(orgSet).length;
    final union = userSet.union(orgSet).length;
    return union == 0 ? 0.0 : (intersect / union).clamp(0.0, 1.0);
  }

  String poFitLabel(List<String> orgValues) {
    final s = poFitScore(orgValues);
    if (s >= 0.60) return 'High Alignment';
    if (s >= 0.35) return 'Moderate Alignment';
    if (s >= 0.15) return 'Some Alignment';
    return 'Low Alignment';
  }

  // ── TRANSITION READINESS [DAW21] ─────────────────────────
  double transitionReadinessScore(List<WeightedSkill> targetRoleSkills) {
    final fit = pjFitScore(targetRoleSkills);
    final expBoost = (employmentType.matchBoost / 0.08).clamp(0.0, 1.0);
    final conf = normalizedConfidenceScore;
    return ((fit * 0.6) + (expBoost * 0.2) + (conf * 0.2)).clamp(0.0, 1.0);
  }

  String transitionReadinessLabel(List<WeightedSkill> targetRoleSkills) {
    final s = transitionReadinessScore(targetRoleSkills);
    if (s >= 0.75) return 'Ready';
    if (s >= 0.50) return 'Almost Ready';
    if (s >= 0.30) return 'Building Towards';
    return 'Early Stage';
  }

  // ── SDG-8 ALIGNMENT (enhanced v4) ────────────────────────
  double get sdg8AlignmentScore {
    var score = 0.0;
    const sdg8Fields = {
      FieldOfStudy.finance,
      FieldOfStudy.business,
      FieldOfStudy.it,
      FieldOfStudy.engineering,
      FieldOfStudy.marketing,
    };
    if (sdg8Fields.contains(fieldOfStudy)) score += 0.35;

    switch (entrepreneurialAspiration) {
      case EntrepreneurialAspiration.high:
        score += 0.25;
      case EntrepreneurialAspiration.medium:
        score += 0.12;
      case EntrepreneurialAspiration.low:
        break;
    }

    if (skills.length >= 5) {
      score += 0.20;
    } else if (skills.length >= 3) {
      score += 0.10;
    }

    if (employmentType != ExperienceType.none) score += 0.20;
    return score.clamp(0.0, 1.0);
  }

  // ── LEARNER FEATURE VECTOR [TAV22 §3.5.1] — cold-start ──
  Map<String, double> get learnerColdStartVector => {
        'length_short': fieldOfStudy.learningDomainWeight < 0.7 ? 0.50 : 0.25,
        'length_medium': 0.40,
        'length_long': fieldOfStudy.learningDomainWeight >= 0.8 ? 0.35 : 0.25,
        'detail_low': yearOfStudy <= 2 ? 0.40 : 0.20,
        'detail_medium': 0.40,
        'detail_high': yearOfStudy >= 4 ? 0.40 : 0.20,
        'strategy_theory': fieldOfStudy == FieldOfStudy.arts ? 0.40 : 0.30,
        'strategy_example': (fieldOfStudy == FieldOfStudy.engineering ||
                fieldOfStudy == FieldOfStudy.it)
            ? 0.45
            : 0.35,
        'strategy_both': 0.35,
        'class_based': employmentType == ExperienceType.none ? 0.55 : 0.35,
        'non_class_based': employmentType != ExperienceType.none ? 0.65 : 0.45,
        'format_video': 0.40,
        'format_book': fieldOfStudy == FieldOfStudy.law ? 0.50 : 0.25,
        'format_web_page': 0.25,
        'format_slide': 0.25,
      };

  // ── Copy-with (full field support + clearBirthYear flag) ──
  CareerProfile copyWith({
    String? name,
    FieldOfStudy? fieldOfStudy,
    int? yearOfStudy,
    double? gpa,
    ExperienceType? employmentType,
    bool? hasEntrepreneurialExperience,
    List<String>? careerInterests,
    List<String>? skills,
    EntrepreneurialAspiration? entrepreneurialAspiration,
    int? birthYear,
    String? targetJobTitle,
    List<String>? preferredOrgValues,
    Map<String, double>? confidenceScores,
    String? employmentIntention,
    String? cvText,
    bool clearBirthYear = false,
  }) =>
      CareerProfile(
        name: name ?? this.name,
        fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
        yearOfStudy: ((yearOfStudy ?? this.yearOfStudy).clamp(1, 5)),
        gpa: ((gpa ?? this.gpa).clamp(0.0, 4.0)),
        employmentType: employmentType ?? this.employmentType,
        hasEntrepreneurialExperience:
            hasEntrepreneurialExperience ?? this.hasEntrepreneurialExperience,
        careerInterests:
            careerInterests ?? List<String>.unmodifiable(this.careerInterests),
        skills: skills ?? List<String>.unmodifiable(this.skills),
        entrepreneurialAspiration:
            entrepreneurialAspiration ?? this.entrepreneurialAspiration,
        birthYear: clearBirthYear ? null : (birthYear ?? this.birthYear),
        targetJobTitle: targetJobTitle ?? this.targetJobTitle,
        preferredOrgValues: preferredOrgValues ??
            List<String>.unmodifiable(this.preferredOrgValues),
        confidenceScores: confidenceScores ??
            Map<String, double>.unmodifiable(this.confidenceScores),
        employmentIntention: employmentIntention ?? this.employmentIntention,
        cvText: cvText ?? this.cvText,
      );

  // ── Serialisation (fully robust) ─────────────────────────
  Map<String, dynamic> toMap() => {
        'name': name,
        'fieldOfStudy': fieldOfStudy.key,
        'yearOfStudy': yearOfStudy,
        'gpa': gpa,
        'employmentType': employmentType.key,
        'hasEntrepreneurialExperience': hasEntrepreneurialExperience,
        'careerInterests': careerInterests,
        'skills': skills,
        'entrepreneurialAspiration': entrepreneurialAspiration.key,
        'birthYear': birthYear,
        'targetJobTitle': targetJobTitle,
        'preferredOrgValues': preferredOrgValues,
        'confidenceScores': confidenceScores,
        'employmentIntention': employmentIntention,
        'cvText': cvText,
      };

  factory CareerProfile.fromMap(Map<String, dynamic> map) =>
      CareerProfile.build(
        name: (map['name'] as String? ?? '').trim(),
        fieldOfStudy:
            FieldOfStudy.fromKey(map['fieldOfStudy'] as String? ?? ''),
        yearOfStudy: (map['yearOfStudy'] as int? ?? 1).clamp(1, 5),
        gpa: (map['gpa'] as num? ?? 0.0).toDouble().clamp(0.0, 4.0),
        employmentType:
            ExperienceType.fromKey(map['employmentType'] as String? ?? ''),
        hasEntrepreneurialExperience:
            map['hasEntrepreneurialExperience'] as bool? ?? false,
        careerInterests:
            List<String>.from(map['careerInterests'] as List? ?? const []),
        skills: List<String>.from(map['skills'] as List? ?? const []),
        entrepreneurialAspiration: EntrepreneurialAspiration.fromKey(
          map['entrepreneurialAspiration'] as String? ?? 'low',
        ),
        birthYear: map['birthYear'] as int?,
        targetJobTitle: (map['targetJobTitle'] as String? ?? '').trim(),
        preferredOrgValues:
            List<String>.from(map['preferredOrgValues'] as List? ?? const []),
        confidenceScores: _parseDoubleMap(map['confidenceScores']),
        employmentIntention:
            (map['employmentIntention'] as String? ?? 'undecided').trim(),
        cvText: (map['cvText'] as String? ?? '').trim(),
      );

  factory CareerProfile.fromJson(Map<String, dynamic> json) =>
      CareerProfile.fromMap(json);
  Map<String, dynamic> toJson() => toMap();

  // ── Equality & hashing (selective but complete for value equality) ──
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CareerProfile &&
          other.name == name &&
          other.fieldOfStudy == fieldOfStudy &&
          other.gpa == gpa &&
          other.employmentType == employmentType &&
          other.yearOfStudy == yearOfStudy &&
          other.entrepreneurialAspiration == entrepreneurialAspiration &&
          other.birthYear == birthYear &&
          other.targetJobTitle == targetJobTitle);

  @override
  int get hashCode => Object.hash(
        name,
        fieldOfStudy,
        gpa,
        employmentType,
        yearOfStudy,
        entrepreneurialAspiration,
        birthYear,
        targetJobTitle,
      );

  @override
  String toString() => 'CareerProfile('
      'name: $name, '
      'field: ${fieldOfStudy.label}, '
      'year: $yearOfStudy, '
      'gpa: $gpa, '
      'exp: ${employmentType.label}, '
      'aspiration: ${entrepreneurialAspiration.label}, '
      'generation: ${workforceGeneration?.label ?? "unknown"}, '
      'confidence: ${overallConfidenceScore.toStringAsFixed(1)}/5, '
      'success: ${(successProbability * 100).toStringAsFixed(1)}%, '
      'sdg8: ${(sdg8AlignmentScore * 100).toStringAsFixed(0)}%)';
}

// =============================================================================
// PRIVATE HELPERS (unchanged — already robust)
// =============================================================================
Map<String, double> _parseDoubleMap(dynamic raw) {
  if (raw == null) return const {};
  if (raw is Map<String, double>) return Map<String, double>.unmodifiable(raw);

  try {
    return Map<String, double>.unmodifiable(
      (raw as Map).map((key, value) => MapEntry(
            key.toString(),
            (value as num).toDouble(),
          )),
    );
  } catch (_) {
    return const {};
  }
}
