// screens/home.dart — SkillBridge AI

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:skillbridge_ai/models/career_profile.dart';
import '../data/jobs.dart';
import '../data/courses.dart';
import '../services/app_state.dart';
import 'application_tracker_screen.dart';
import 'auth/login_screen.dart';
import 'confidence_tracker_screen.dart' show ConfidenceTrackerScreen;
import 'cv_upload_screen.dart' show CvUploadScreen;
import 'profile_input.dart';
import 'job_result.dart';
import 'browse_courses_screen.dart';
import 'geo_insights_screen.dart';
import 'workforce_insights_screen.dart';
import 'skill_trends_screen.dart';
import 'chatbot_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ══════════════════════════════════════════════════════════════════════════════

const _kPrimaryBlue = Color(0xFF1A56DB);
const _kPurple = Color(0xFF7C3AED);
const _kGreen = Color(0xFF10B981);
const _kOrange = Color(0xFFF59E0B);
const _kError = Color(0xFFEF4444);
const _kMatchGreen = Color(0xFF10B981);
const _kMatchGreenBg = Color(0xFFD1FAE5);
const _kDarkBg = Color(0xFF0F172A);
const _kDarkCard = Color(0xFF1E293B);
const _kDarkBorder = Color(0xFF334155);
const _kLightBg = Colors.white;
const _kLightBorder = Color(0xFFE2E8F0);

// ══════════════════════════════════════════════════════════════════════════════
// UTILITIES
// ══════════════════════════════════════════════════════════════════════════════

Color _withA(Color c, double opacity) =>
    c.withValues(alpha: opacity.clamp(0.0, 1.0));

BoxDecoration _cardDeco(
  bool dark, {
  double radius = 16,
  Color? bg,
  Color? borderColor,
  List<BoxShadow>? shadows,
}) =>
    BoxDecoration(
      color: bg ?? (dark ? _kDarkCard : _kLightBg),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? (dark ? _kDarkBorder : _kLightBorder),
      ),
      boxShadow: dark
          ? [
              BoxShadow(
                color: _withA(Colors.black, 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : shadows ??
              [
                BoxShadow(
                  color: _withA(Colors.black, 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
    );

// ══════════════════════════════════════════════════════════════════════════════
// SAFE PROPERTY ACCESSORS
// ══════════════════════════════════════════════════════════════════════════════

String _safeJobSalaryRange(dynamic job) {
  try {
    if (job is Job) return job.salary;
    final dynamic v = job.salaryRange;
    if (v is String && v.isNotEmpty) return v;
  } catch (_) {}
  return '30,000–60,000';
}

List<String> _safeJobRequiredSkills(dynamic job) {
  try {
    if (job is Job) return job.skills;
    final dynamic v = job.requiredSkills;
    if (v is List) return v.map((e) => e.toString()).toList();
  } catch (_) {}
  return const <String>[];
}

String _safeCoursePlatform(dynamic course) {
  try {
    if (course is Course) return course.provider;
    final dynamic v = course.platform;
    if (v is String) return v;
  } catch (_) {}
  return '';
}

String _safeCourseFormat(dynamic course) {
  try {
    if (course is Course) return course.type;
    final dynamic v = course.format;
    if (v is String && v.isNotEmpty) return v;
  } catch (_) {}
  return 'Video';
}

int _safeMissingSkillCount(AppState s) {
  try {
    final dynamic v = (s as dynamic).missingSkillCount;
    if (v is int) return v;
  } catch (_) {}
  return 0;
}

List<String> _safeEnrolledCourseIds(AppState s) {
  try {
    final dynamic v = (s as dynamic).enrolledCourseIds;
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is Set) return v.map((e) => e.toString()).toList();
    if (v is int) return List.generate(v, (i) => 'course_$i');
  } catch (_) {}
  return const <String>[];
}

Map<String, double> _safeCourseProgress(AppState s) {
  try {
    final dynamic v = (s as dynamic).courseProgress;
    if (v is Map) {
      return v.map<String, double>(
        (k, val) => MapEntry(k.toString(), val is num ? val.toDouble() : 0.0),
      );
    }
  } catch (_) {}
  return const <String, double>{};
}

ExperienceType _safeEmploymentType(AppState s) {
  const accessors = [
    'experienceType',
    'employmentType',
    'preferredEmploymentType',
    'expType',
  ];
  for (final key in accessors) {
    try {
      final dynamic val = (s as dynamic)[key] ??
          (s as dynamic).noSuchMethod(Invocation.getter(Symbol(key)));
      if (val is ExperienceType) return val;
    } catch (_) {}
  }
  return ExperienceType.none;
}

// ══════════════════════════════════════════════════════════════════════════════
// ADDED: Safe accessors for ChatbotContext fields
// ══════════════════════════════════════════════════════════════════════════════

String _safeCvText(AppState s) {
  try {
    final v = (s as dynamic).cvText;
    if (v is String) return v;
  } catch (_) {}
  return '';
}

String _safeCvFileName(AppState s) {
  try {
    final v = (s as dynamic).cvFileName;
    if (v is String) return v;
  } catch (_) {}
  return '';
}

String _safeCurrentRole(AppState s) {
  for (final key in ['currentRole', 'jobRole', 'role']) {
    try {
      final v = (s as dynamic).noSuchMethod(Invocation.getter(Symbol(key)));
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
  }
  return s.fieldOfStudy;
}

String _safeTargetRole(AppState s) {
  for (final key in ['targetRole', 'desiredRole', 'dreamRole']) {
    try {
      final v = (s as dynamic).noSuchMethod(Invocation.getter(Symbol(key)));
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
  }
  return '';
}

int _safeExperienceYears(AppState s) {
  for (final key in ['experienceYears', 'yearsOfExperience']) {
    try {
      final v = (s as dynamic).noSuchMethod(Invocation.getter(Symbol(key)));
      if (v is int) return v;
      if (v is double) return v.round();
    } catch (_) {}
  }
  return s.yearOfStudy > 1 ? (s.yearOfStudy - 1).clamp(0, 20) : 0;
}

String _safeCareerPathSummary(AppState s) {
  for (final key in ['careerPathSummary', 'careerPath', 'roadmapSummary']) {
    try {
      final v = (s as dynamic).noSuchMethod(Invocation.getter(Symbol(key)));
      if (v is String && v.isNotEmpty) return v;
      if (v != null) {
        try {
          return v.summary as String;
        } catch (_) {}
      }
    } catch (_) {}
  }
  return '';
}

List<String> _safeMissingSkills(AppState s) {
  for (final key in ['missingSkills', 'skillGapsNames']) {
    try {
      final v = (s as dynamic).noSuchMethod(Invocation.getter(Symbol(key)));
      if (v is List) return v.map((e) => e.toString()).toList();
    } catch (_) {}
  }
  return const [];
}

int _safeTotalApplications(AppState s) {
  for (final key in ['totalApplications', 'appliedJobsCount']) {
    try {
      final v = (s as dynamic).noSuchMethod(Invocation.getter(Symbol(key)));
      if (v is int) return v;
    } catch (_) {}
  }
  try {
    final v = (s as dynamic).appliedJobIds;
    if (v is List) return v.length;
    if (v is Set) return v.length;
  } catch (_) {}
  return 0;
}

// ADDED: Build ChatSkillGapData list from AppState
List<ChatSkillGapData> _buildChatSkillGapData(AppState s) {
  try {
    final raw = (s as dynamic).skillGaps;
    if (raw is List && raw.isNotEmpty) {
      final result = <ChatSkillGapData>[];
      for (final g in raw.take(8)) {
        String name = '';
        String priority = '🟠 Learn Soon';
        double importance = 0.70;
        try {
          name = (g.name as String?) ?? (g.skill as String?) ?? '';
        } catch (_) {}
        try {
          priority = (g.priority as String?) ??
              (g.priorityLabel as String?) ??
              '🟠 Learn Soon';
        } catch (_) {}
        try {
          final dynamic v = (g as dynamic).importance ?? (g as dynamic).score;
          if (v is num) importance = v.toDouble().clamp(0.0, 1.0);
        } catch (_) {}
        if (name.isNotEmpty) {
          result.add(ChatSkillGapData(
              name: name, priority: priority, importance: importance));
        }
      }
      if (result.isNotEmpty) return result;
    }
  } catch (_) {}
  final missing = _safeMissingSkills(s);
  return missing.take(8).toList().asMap().entries.map((e) {
    final importance = (0.95 - e.key * 0.07).clamp(0.50, 0.95);
    final priority = importance > 0.87
        ? '🔴 Must Learn'
        : importance > 0.72
            ? '🟠 Learn Soon'
            : '🟡 Nice to Have';
    return ChatSkillGapData(
        name: e.value, priority: priority, importance: importance);
  }).toList();
}

// ADDED: Build ChatJobData list from AppState
List<ChatJobData> _buildChatJobData(AppState s) {
  final jobs = s.recommendedJobs.isNotEmpty
      ? s.recommendedJobs
      : allJobs.take(6).toList();
  return jobs.take(6).map((job) {
    String location = 'Dhaka';
    String jobType = '';
    String id = UniqueKey().toString();
    try {
      final v = (job as dynamic).location;
      if (v is String && v.isNotEmpty) location = v;
    } catch (_) {}
    try {
      final v = (job as dynamic).jobType ?? (job as dynamic).type;
      if (v is String && v.isNotEmpty) jobType = v;
    } catch (_) {}
    try {
      final v = (job as dynamic).id;
      if (v != null) id = v.toString();
    } catch (_) {}
    String title = 'Job';
    String company = '';
    title = job.title;
    company = job.company;
    return ChatJobData(
      id: id,
      title: title,
      company: company,
      location: location,
      salary: _safeJobSalaryRange(job),
      matchPct: () {
        if (job.simScore > 0) return (job.simScore * 100).round();
        if (s.userSkills.isNotEmpty) {
          return (job.matchScore(s.userSkills) * 100).round();
        }
        return 60;
      }(),
      requiredSkills: _safeJobRequiredSkills(job),
      jobType: jobType.isEmpty ? null : jobType,
    );
  }).toList();
}

// ADDED: Build ChatCourseData list from AppState
List<ChatCourseData> _buildChatCourseData(AppState s) {
  final courseList = s.recommendedCourses.isNotEmpty
      ? s.recommendedCourses
      : (List<Course>.from(courses)
            ..sort((a, b) => b.rating.compareTo(a.rating)))
          .take(6)
          .toList();
  return courseList.take(6).map((course) {
    String id = UniqueKey().toString();
    String duration = '6 weeks';
    try {
      final v = (course as dynamic).id;
      if (v != null) id = v.toString();
    } catch (_) {}
    try {
      final v = (course as dynamic).duration;
      if (v is String && v.isNotEmpty) duration = v;
    } catch (_) {}
    double rating = 4.5;
    String title = 'Course';
    String provider = '';
    String format = 'Video';
    title = course.title;
    provider = course.provider;
    format = course.type;
    rating = course.rating;
    return ChatCourseData(
      id: id,
      title: title,
      provider: provider,
      duration: duration,
      format: format,
      rating: rating,
    );
  }).toList();
}

// ADDED: Build ChatbotContext from AppState — the single entry point
ChatbotContext _buildChatbotContext(BuildContext context, AppState s) {
  return ChatbotContext(
    userName: s.userName,
    currentRole: _safeCurrentRole(s),
    targetRole: _safeTargetRole(s),
    location: 'Bangladesh',
    experienceYears: _safeExperienceYears(s),
    educationLevel: s.fieldOfStudy,
    currentSkills: List<String>.from(s.userSkills),
    missingSkills: _safeMissingSkills(s),
    extractedCvText: _safeCvText(s).isEmpty ? null : _safeCvText(s),
    cvFileName: _safeCvFileName(s).isEmpty ? null : _safeCvFileName(s),
    topJobMatches: _buildChatJobData(s),
    recommendedCourses: _buildChatCourseData(s),
    skillGaps: _buildChatSkillGapData(s),
    confidenceScore:
        s.overallConfidenceScore > 0 ? s.overallConfidenceScore : null,
    careerPathSummary:
        _safeCareerPathSummary(s).isEmpty ? null : _safeCareerPathSummary(s),
    totalApplications: _safeTotalApplications(s),
    navigateTo: (screen, {args}) {
      Widget? dest;
      final appState = s;
      final FieldOfStudy fos = FieldOfStudy.values.firstWhere(
        (e) => e.name.toLowerCase() == appState.fieldOfStudy.toLowerCase(),
        orElse: () => FieldOfStudy.values.first,
      );
      final profile = CareerProfile(
        name: appState.userName.isEmpty ? 'User' : appState.userName,
        fieldOfStudy: fos,
        gpa: appState.gpa,
        yearOfStudy: appState.yearOfStudy,
        skills: List<String>.from(appState.userSkills),
        careerInterests: const [],
        hasEntrepreneurialExperience: false,
        employmentType: _safeEmploymentType(appState),
      );
      switch (screen) {
        case 'jobs':
          dest = JobResultScreen(
              profile: profile,
              selectedIndustry: 'All',
              selectedLevel: 'All',
              remoteOnly: false);
        case 'courses':
          dest = ChangeNotifierProvider<AppThemeProvider>(
            create: (_) => AppThemeProvider(
                isDark: Theme.of(context).brightness == Brightness.dark),
            child: const BrowseCoursesScreen(),
          );
        case 'confidence':
          dest = const ConfidenceTrackerScreen();
        case 'applications':
          dest = const ApplicationTrackerScreen();
        case 'cvUpload':
          dest = const CvUploadScreen();
        case 'profile':
          dest = const ProfileInputScreen();
        case 'geoInsights':
          dest = const GeoInsightsScreen();
        case 'workforceInsights':
          dest = const WorkforceInsightsScreen();
        case 'skillTrends':
          dest = const SkillTrendsScreen();
        default:
          dest = null;
      }
      if (dest != null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => dest!));
      }
    },
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// FALLBACK DATA HELPERS
// ══════════════════════════════════════════════════════════════════════════════

List<dynamic> _resolveDisplayJobs(List<dynamic> recommendedJobs) {
  if (recommendedJobs.isNotEmpty) return recommendedJobs;
  return allJobs.take(8).toList();
}

List<dynamic> _resolveDisplayCourses(List<dynamic> recommendedCourses) {
  if (recommendedCourses.isNotEmpty) return recommendedCourses;
  final sorted = List<Course>.from(courses)
    ..sort((a, b) => b.rating.compareTo(a.rating));
  return sorted.take(6).toList();
}

int _resolveMatchScore(dynamic job, List<String> userSkills) {
  if (job is Job) {
    if (job.simScore > 0) return (job.simScore * 100).round();
    if (userSkills.isNotEmpty) {
      return (job.matchScore(userSkills) * 100).round();
    }
    return 60;
  }
  try {
    final dynamic v = job.simScore;
    if (v is num) return (v * 100).round();
  } catch (_) {}
  return 60;
}

double _resolveCourseRating(dynamic course) {
  if (course is Course) return course.rating;
  try {
    final dynamic v = course.rating;
    if (v is num) return v.toDouble();
  } catch (_) {}
  return 4.5;
}

String _resolveCourseTitle(dynamic course) {
  if (course is Course) return course.title;
  try {
    return course.title as String;
  } catch (_) {}
  return 'Course';
}

String _resolveJobTitle(dynamic job) {
  if (job is Job) return job.title;
  try {
    return job.title as String;
  } catch (_) {}
  return 'Job';
}

String _resolveJobCompany(dynamic job) {
  if (job is Job) return job.company;
  try {
    return job.industry as String;
  } catch (_) {}
  return '';
}

void _goToBrowseCourses(BuildContext context) {
  HapticFeedback.mediumImpact();
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<AppThemeProvider>(
        create: (_) => AppThemeProvider(
            isDark: Theme.of(context).brightness == Brightness.dark),
        child: const BrowseCoursesScreen(),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// HOME SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const HomeScreen({super.key, this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _heroCtrl;
  late final AnimationController _contentCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _statCtrl;

  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _contentFade;

  static const List<String> _trendingSkills = [
    ' Prompt Engineering',
    ' Power BI',
    ' Python',
    ' AWS',
    ' Flutter',
    ' Cybersecurity',
    ' Data Analytics',
    ' Machine Learning',
  ];

  @override
  void initState() {
    super.initState();

    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _statCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut));
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _contentCtrl.dispose();
    _pulseCtrl.dispose();
    _statCtrl.dispose();
    super.dispose();
  }

  void _doToggleTheme() {
    HapticFeedback.selectionClick();
    final appState = context.read<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    appState.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  void _doLogout() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 10),
            Text('Sign Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of SkillBridge AI?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              await context.read<AppState>().logout();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _openSearch(BuildContext context) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.read<AppState>();
    final profile = _buildProfileFromState(appState);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: _HomeSearchScreen(
            isDark: isDark,
            profile: profile,
            userSkills: appState.userSkills,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  // ADDED: Open chatbot as a full-page route with full app context
  void _openChatbot(BuildContext context, AppState appState) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => ChatbotScreen(
          chatContext: _buildChatbotContext(context, appState),
        ),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        transitionsBuilder: (_, anim, __, child) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  String _greeting() {
    final int h = DateTime.now().hour;
    if (h < 12) return 'Good morning ';
    if (h < 17) return 'Good afternoon ';
    return 'Good evening ';
  }

  Color _textColor(bool dark) => dark ? Colors.white : const Color(0xFF0F172A);
  Color subColor(bool dark) =>
      dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  CareerProfile _buildProfileFromState(AppState s) {
    final FieldOfStudy fos = FieldOfStudy.values.firstWhere(
      (e) => e.name.toLowerCase() == s.fieldOfStudy.toLowerCase(),
      orElse: () => FieldOfStudy.values.first,
    );
    return CareerProfile(
      name: s.userName.isNotEmpty ? s.userName : 'User',
      fieldOfStudy: fos,
      gpa: s.gpa,
      yearOfStudy: s.yearOfStudy,
      skills: s.userSkills,
      careerInterests: const [],
      hasEntrepreneurialExperience: false,
      employmentType: _safeEmploymentType(s),
    );
  }

  Widget _buildDarkToggle(bool isDark, {bool onGradient = false}) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: _doToggleTheme,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: onGradient ? _withA(Colors.white, 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: onGradient
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutBtn({bool onGradient = false}) {
    return Tooltip(
      message: 'Sign Out',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: _doLogout,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  onGradient ? _withA(Colors.white, 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.logout_rounded,
              color: onGradient ? Colors.white : const Color(0xFFEF4444),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext ctx,
    String title, {
    String? action,
    VoidCallback? onAction,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _textColor(isDark),
                letterSpacing: -0.3,
              ),
            ),
          ),
          Container(
            height: 1,
            width: 40,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_withA(_kPrimaryBlue, 0.6), Colors.transparent],
              ),
            ),
          ),
          if (action != null)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onAction?.call();
                },
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _withA(_kPrimaryBlue, isDark ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    action,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kPrimaryBlue,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppState appState = context.watch<AppState>();

    final String userName =
        appState.userName.isNotEmpty ? appState.userName : 'Student';
    final String initials = userName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    final int readinessScore = appState.readinessScore;
    final int savedCount = appState.savedJobIds.length;
    final int completedCount = appState.completedTopics.length;
    final int learningStreak = appState.learningStreak;
    final List<String> enrolledIds = _safeEnrolledCourseIds(appState);
    final bool hasContinueLearning = enrolledIds.isNotEmpty;
    final int missingSkills = _safeMissingSkillCount(appState);
    final Map<String, double> progMap = _safeCourseProgress(appState);
    final CareerProfile profile = _buildProfileFromState(appState);
    final List<String> userSkills = appState.userSkills;

    final List<dynamic> displayJobs =
        _resolveDisplayJobs(appState.recommendedJobs);
    final List<dynamic> displayCourses =
        _resolveDisplayCourses(appState.recommendedCourses);

    return Scaffold(
      backgroundColor: isDark ? _kDarkBg : _kLightBg,
      // ADDED: AI Assistant floating action button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openChatbot(context, appState),
        backgroundColor: _kPrimaryBlue,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.smart_toy_rounded, size: 20),
        label: const Text(
          'Ask AI',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: true,
            snap: true,
            pinned: false,
            automaticallyImplyLeading: false,
            backgroundColor: isDark ? _kDarkCard : _kLightBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: null,
            actions: const [],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: RepaintBoundary(
                child: FadeTransition(
                  opacity: _heroFade,
                  child: SlideTransition(
                    position: _heroSlide,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _greeting(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _withA(Colors.white, 0.85),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  _buildDarkToggle(isDark, onGradient: true),
                                  const SizedBox(width: 6),
                                  _buildLogoutBtn(onGradient: true),
                                  const SizedBox(width: 8),
                                  Material(
                                    color: Colors.transparent,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ProfileInputScreen(),
                                          ),
                                        );
                                      },
                                      customBorder: const CircleBorder(),
                                      child: Ink(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _withA(Colors.white, 0.2),
                                          border: Border.all(
                                            color: _withA(Colors.white, 0.6),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            initials.isNotEmpty
                                                ? initials
                                                : 'SK',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: GestureDetector(
                                onTap: () => _openSearch(context),
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _withA(Colors.black, 0.12),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 16),
                                      const Icon(Icons.search_rounded,
                                          color: _kPrimaryBlue, size: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Search jobs, skills, courses...',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _withA(_kPrimaryBlue, 0.08),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Filter',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _kPrimaryBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: RepaintBoundary(
              child: FadeTransition(
                opacity: _contentFade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _AnimatedStatCard(
                          index: 0,
                          value: '$readinessScore%',
                          label: 'Readiness',
                          icon: Icons.rocket_launch_rounded,
                          iconColor: _kPrimaryBlue,
                          isDark: isDark,
                          anim: _statCtrl,
                        ),
                        const SizedBox(width: 10),
                        _AnimatedStatCard(
                          index: 1,
                          value: '$savedCount',
                          label: 'Saved',
                          icon: Icons.bookmark_rounded,
                          iconColor: _kPurple,
                          isDark: isDark,
                          anim: _statCtrl,
                        ),
                        const SizedBox(width: 10),
                        _AnimatedStatCard(
                          index: 2,
                          value: '$completedCount',
                          label: 'Completed',
                          icon: Icons.check_circle_rounded,
                          iconColor: _kGreen,
                          isDark: isDark,
                          anim: _statCtrl,
                        ),
                        const SizedBox(width: 10),
                        _AnimatedStatCard(
                          index: 3,
                          value: '$learningStreak',
                          label: 'Streak ',
                          icon: Icons.local_fire_department_rounded,
                          iconColor: _kOrange,
                          isDark: isDark,
                          anim: _statCtrl,
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (hasContinueLearning)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _contentFade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _ContinueLearningBanner(
                    courseId: enrolledIds.first,
                    courseProgressMap: progMap,
                    onResume: () => _goToBrowseCourses(context),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _contentFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _DailyActivityCard(
                  readiness: readinessScore,
                  streak: learningStreak,
                  courseDone: completedCount,
                  isDark: isDark,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _contentFade,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: _sectionHeader(
                  context,
                  'Explore Insights',
                  isDark: isDark,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _contentFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _InsightShortcutCard(
                          title: 'Geo\nInsights',
                          subtitle: 'Jobs by city',
                          icon: Icons.location_on_rounded,
                          gradientColors: const [
                            Color(0xFF0EA5E9),
                            Color(0xFF1A56DB)
                          ],
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const GeoInsightsScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InsightShortcutCard(
                          title: 'Workforce\nInsights',
                          subtitle: 'AI & generations',
                          icon: Icons.people_alt_rounded,
                          gradientColors: const [
                            Color(0xFF8B5CF6),
                            Color(0xFF6366F1)
                          ],
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const WorkforceInsightsScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InsightShortcutCard(
                          title: 'Skill\nTrends',
                          subtitle: 'Market demand',
                          icon: Icons.trending_up_rounded,
                          gradientColors: const [
                            Color(0xFF10B981),
                            Color(0xFF059669)
                          ],
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SkillTrendsScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _contentFade,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: _sectionHeader(
                  context,
                  'Top Job Matches',
                  action: 'See All',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobResultScreen(
                        profile: profile,
                        selectedIndustry: 'All',
                        selectedLevel: 'All',
                        remoteOnly: false,
                      ),
                    ),
                  ),
                  isDark: isDark,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _contentFade,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  height: 192,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: displayJobs.length.clamp(0, 8),
                    itemBuilder: (ctx, i) {
                      final dynamic job = displayJobs[i];
                      final int score = _resolveMatchScore(job, userSkills);
                      return _JobCard(
                        heroTag: 'job_card_$i',
                        jobTitle: _resolveJobTitle(job),
                        company: _resolveJobCompany(job),
                        matchScore: score,
                        salary: _safeJobSalaryRange(job),
                        skills: _safeJobRequiredSkills(job),
                        isDark: isDark,
                        onApply: () {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobResultScreen(
                                profile: profile,
                                selectedIndustry: 'All',
                                selectedLevel: 'All',
                                remoteOnly: false,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (missingSkills > 0)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _contentFade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _SkillGapBanner(
                    count: missingSkills,
                    isDark: isDark,
                    pulse: _pulseCtrl,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileInputScreen()),
                      );
                    },
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _contentFade,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child:
                    _sectionHeader(context, 'Trending Skills', isDark: isDark),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _contentFade,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _trendingSkills.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _TrendingChip(
                          label: _trendingSkills[i], isDark: isDark),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _contentFade,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: _sectionHeader(
                  context,
                  'Recommended Courses',
                  action: 'Browse All',
                  onAction: () => _goToBrowseCourses(context),
                  isDark: isDark,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _contentFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                child: Column(
                  children: displayCourses
                      .take(3)
                      .map(
                        (course) => _CourseCard(
                          courseTitle: _resolveCourseTitle(course),
                          platform: _safeCoursePlatform(course),
                          rating: _resolveCourseRating(course),
                          format: _safeCourseFormat(course),
                          isDark: isDark,
                          onEnroll: () => _goToBrowseCourses(context),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HOME SEARCH SCREEN  — FIX: single border only (no double outline)
// ══════════════════════════════════════════════════════════════════════════════

class _HomeSearchScreen extends StatefulWidget {
  final bool isDark;
  final CareerProfile profile;
  final List<String> userSkills;

  const _HomeSearchScreen({
    required this.isDark,
    required this.profile,
    required this.userSkills,
  });

  @override
  State<_HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<_HomeSearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  String _query = '';
  bool _isFocused = false;

  String _activeTab = 'All';
  static const List<String> _tabs = ['All', 'Jobs', 'Courses', 'Skills'];

  // ── Comprehensive skills catalogue ─────────────────────────────────────────
  static const List<String> _allSkills = [
    // Programming Languages
    'Python', 'JavaScript', 'TypeScript', 'Java', 'Kotlin', 'Swift',
    'C', 'C++', 'C#', 'Go', 'Rust', 'Ruby', 'PHP', 'Scala', 'R',
    'MATLAB', 'Perl', 'Dart', 'Lua', 'Shell Scripting', 'Bash',
    'Assembly', 'Haskell', 'Erlang', 'Elixir', 'Clojure', 'F#',

    // Web Frontend
    'HTML', 'CSS', 'React', 'Vue.js', 'Angular', 'Svelte', 'Next.js',
    'Nuxt.js', 'Gatsby', 'Tailwind CSS', 'Bootstrap', 'SASS/SCSS',
    'jQuery', 'Redux', 'GraphQL', 'WebAssembly', 'Three.js', 'D3.js',

    // Web Backend
    'Node.js', 'Express.js', 'Django', 'Flask', 'FastAPI', 'Spring Boot',
    'Laravel', 'Ruby on Rails', 'ASP.NET', 'NestJS', 'Gin', 'Fiber',
    'REST API', 'gRPC', 'Microservices', 'WebSockets',

    // Mobile Development
    'Flutter', 'React Native', 'Android Development', 'iOS Development',
    'SwiftUI', 'Jetpack Compose', 'Xamarin', 'Ionic', 'Cordova',
    'Expo', 'Firebase', 'App Store Optimization',

    // Data Science & ML
    'Machine Learning', 'Deep Learning', 'Natural Language Processing',
    'Computer Vision', 'Data Science', 'Data Analysis', 'Data Mining',
    'Statistical Analysis', 'Predictive Modeling', 'Feature Engineering',
    'Model Deployment', 'MLOps', 'A/B Testing', 'Time Series Analysis',
    'Reinforcement Learning', 'Transfer Learning', 'Neural Networks',
    'Generative AI', 'Prompt Engineering', 'LLM Fine-tuning',

    // ML Libraries & Frameworks
    'TensorFlow', 'PyTorch', 'Keras', 'Scikit-learn', 'XGBoost',
    'LightGBM', 'Hugging Face', 'spaCy', 'NLTK', 'OpenCV',
    'Pandas', 'NumPy', 'SciPy', 'Matplotlib', 'Seaborn', 'Plotly',

    // Databases
    'SQL', 'MySQL', 'PostgreSQL', 'SQLite', 'Oracle', 'Microsoft SQL Server',
    'MongoDB', 'Redis', 'Cassandra', 'DynamoDB', 'Elasticsearch',
    'Neo4j', 'CouchDB', 'InfluxDB', 'Supabase', 'PlanetScale',
    'Database Design', 'Database Administration', 'Query Optimization',

    // Cloud & DevOps
    'AWS', 'Google Cloud Platform', 'Microsoft Azure', 'Heroku',
    'DigitalOcean', 'Vercel', 'Netlify', 'Cloudflare',
    'Docker', 'Kubernetes', 'Terraform', 'Ansible', 'Vagrant',
    'CI/CD', 'Jenkins', 'GitHub Actions', 'GitLab CI', 'CircleCI',
    'Linux', 'Unix', 'Nginx', 'Apache', 'Load Balancing',
    'Serverless', 'AWS Lambda', 'Cloud Functions',

    // Cybersecurity
    'Cybersecurity', 'Ethical Hacking', 'Penetration Testing',
    'Network Security', 'Application Security', 'OWASP', 'SIEM',
    'Cryptography', 'PKI', 'Identity & Access Management',
    'Incident Response', 'Digital Forensics', 'Malware Analysis',
    'Vulnerability Assessment', 'Zero Trust Security', 'SOC',
    'CISSP', 'CEH', 'Security+', 'Firewall Management',

    // Data Engineering & BI
    'Data Engineering', 'ETL/ELT Pipelines', 'Apache Spark',
    'Apache Kafka', 'Apache Airflow', 'Hadoop', 'Hive', 'Flink',
    'Data Warehousing', 'Snowflake', 'BigQuery', 'Redshift',
    'dbt', 'Data Modeling', 'Data Governance', 'Data Quality',
    'Power BI', 'Tableau', 'Looker', 'Metabase', 'Grafana', 'Kibana',

    // Design & UX
    'UI/UX Design', 'Figma', 'Adobe XD', 'Sketch', 'InVision',
    'Prototyping', 'Wireframing', 'User Research', 'Usability Testing',
    'Design Systems', 'Accessibility', 'Information Architecture',
    'Interaction Design', 'Visual Design', 'Motion Design',
    'Adobe Photoshop', 'Adobe Illustrator', 'Adobe After Effects',
    'Canva', 'Blender', '3D Modeling', 'Animation',

    // Project Management & Agile
    'Project Management', 'Agile', 'Scrum', 'Kanban', 'SAFe',
    'Product Management', 'Product Roadmapping', 'Jira', 'Confluence',
    'Trello', 'Asana', 'Notion', 'Monday.com', 'ClickUp',
    'PMP', 'Prince2', 'Risk Management', 'Stakeholder Management',
    'Sprint Planning', 'Retrospectives', 'OKRs', 'KPIs',

    // Marketing & Growth
    'Digital Marketing', 'SEO', 'SEM', 'Google Ads', 'Facebook Ads',
    'Content Marketing', 'Email Marketing', 'Social Media Marketing',
    'Influencer Marketing', 'Affiliate Marketing', 'Growth Hacking',
    'Marketing Analytics', 'Conversion Rate Optimization', 'A/B Testing',
    'Copywriting', 'Brand Strategy', 'Market Research',
    'HubSpot', 'Salesforce', 'Mailchimp', 'Google Analytics',

    // Finance & Accounting
    'Financial Modeling', 'Financial Analysis', 'Valuation',
    'Investment Banking', 'Equity Research', 'Portfolio Management',
    'Risk Management', 'Derivatives', 'Fixed Income', 'Corporate Finance',
    'Accounting', 'Bookkeeping', 'Tax Planning', 'Auditing',
    'QuickBooks', 'SAP', 'Oracle Financials', 'Excel Financial Modeling',
    'Blockchain', 'DeFi', 'Cryptocurrency', 'Smart Contracts',
    'Solidity', 'Web3', 'NFT Development',

    // Business & Soft Skills
    'Communication', 'Leadership', 'Teamwork', 'Problem Solving',
    'Critical Thinking', 'Creativity', 'Adaptability', 'Time Management',
    'Negotiation', 'Conflict Resolution', 'Public Speaking',
    'Presentation Skills', 'Business Analysis', 'Strategic Planning',
    'Supply Chain Management', 'Operations Management', 'Lean Six Sigma',
    'Customer Service', 'Sales', 'Account Management', 'CRM',

    // Version Control & Collaboration
    'Git', 'GitHub', 'GitLab', 'Bitbucket', 'Code Review',
    'Technical Writing', 'API Documentation', 'Swagger/OpenAPI',

    // Testing & QA
    'Software Testing', 'Unit Testing', 'Integration Testing',
    'End-to-End Testing', 'Test Automation', 'Selenium', 'Cypress',
    'Jest', 'Pytest', 'JUnit', 'Postman', 'Performance Testing',
    'Load Testing', 'QA Engineering', 'TDD', 'BDD',

    // Networking
    'Networking', 'TCP/IP', 'DNS', 'HTTP/HTTPS', 'VPN', 'SDN',
    'Network Administration', 'Cisco', 'CompTIA Network+', 'CCNA',

    // Healthcare & Life Sciences
    'Healthcare IT', 'Medical Imaging', 'Bioinformatics',
    'Clinical Data Management', 'HIPAA Compliance', 'HL7/FHIR',
    'Epidemiology', 'Public Health', 'Pharmaceutical Research',

    // Education & Training
    'Curriculum Development', 'E-learning', 'Instructional Design',
    'LMS Administration', 'Training & Development',

    // Miscellaneous Tech
    'IoT', 'Embedded Systems', 'Raspberry Pi', 'Arduino',
    'AR/VR Development', 'Unity', 'Unreal Engine', 'Game Development',
    'Robotics', 'ROS', 'Autonomous Systems', 'Edge Computing',
    'Quantum Computing', 'Computer Graphics', 'OpenGL', 'Vulkan',
  ];

  bool get _hasQuery => _query.trim().isNotEmpty;

  List<Job> get _filteredJobs {
    if (!_hasQuery) return allJobs.take(6).toList();
    final q = _query.trim().toLowerCase();
    return allJobs
        .where((j) {
          return j.title.toLowerCase().contains(q) ||
              j.company.toLowerCase().contains(q) ||
              j.industry.toLowerCase().contains(q) ||
              j.skills.any((s) => s.toLowerCase().contains(q));
        })
        .take(20)
        .toList();
  }

  List<Course> get _filteredCourses {
    if (!_hasQuery) return courses.take(6).toList();
    final q = _query.trim().toLowerCase();
    return courses
        .where((c) {
          return c.title.toLowerCase().contains(q) ||
              c.provider.toLowerCase().contains(q) ||
              c.category.toLowerCase().contains(q) ||
              c.skills.any((s) => s.toLowerCase().contains(q));
        })
        .take(20)
        .toList();
  }

  List<String> get _filteredSkills {
    if (!_hasQuery) return _allSkills.take(16).toList();
    final q = _query.trim().toLowerCase();
    return _allSkills
        .where((s) => s.toLowerCase().contains(q))
        .take(30)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
    _ctrl.addListener(() {
      setState(() => _query = _ctrl.text);
    });
    // ── FIX: track focus so we can redraw the border colour ───────────────────
    _focus.addListener(() {
      if (mounted) setState(() => _isFocused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Color get _bg => widget.isDark ? _kDarkBg : const Color(0xFFF8FAFC);
  Color get _cardBg => widget.isDark ? _kDarkCard : Colors.white;
  Color get _textC => widget.isDark ? Colors.white : const Color(0xFF0F172A);
  Color get _subC =>
      widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get _borderC => widget.isDark ? _kDarkBorder : const Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search bar row ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderC),
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          color: _textC, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ── FIXED SEARCH FIELD ────────────────────────────────
                  // The double-border was caused by:
                  // 1. The AnimatedContainer having Border.all()
                  // 2. The TextField's focusedBorder adding its own blue ring
                  // Fix: set ALL TextField border variants to InputBorder.none
                  // and let the AnimatedContainer handle the border exclusively.
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 46,
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          // Only this border is ever shown — TextField draws none.
                          color: _isFocused ? _kPrimaryBlue : _borderC,
                          width: _isFocused ? 1.5 : 1.0,
                        ),
                        boxShadow: widget.isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: _isFocused
                                      ? _withA(_kPrimaryBlue, 0.12)
                                      : _withA(Colors.black, 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(
                            Icons.search_rounded,
                            color: _isFocused ? _kPrimaryBlue : _subC,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              focusNode: _focus,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              // Explicit text & cursor colours
                              style: TextStyle(fontSize: 14, color: _textC),
                              cursorColor: _kPrimaryBlue,
                              decoration: InputDecoration(
                                hintText: 'Search jobs, skills, courses...',
                                hintStyle:
                                    TextStyle(fontSize: 14, color: _subC),
                                // ── KEY FIX: suppress every border variant ──
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                // Transparent fill so _cardBg shows through
                                filled: true,
                                fillColor: Colors.transparent,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 13),
                              ),
                            ),
                          ),
                          if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _ctrl.clear();
                                setState(() => _query = '');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Icon(Icons.close_rounded,
                                    color: _subC, size: 16),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab Filter row ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _tabs.map((tab) {
                    final isActive = _activeTab == tab;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _activeTab = tab);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? _kPrimaryBlue : _cardBg,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isActive ? _kPrimaryBlue : _borderC,
                          ),
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : _textC,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── Result count hint ───────────────────────────────────────
            if (_hasQuery)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _resultCountLabel,
                    style: TextStyle(
                        fontSize: 12,
                        color: _subC,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),

            // ── Results list ────────────────────────────────────────────
            Expanded(
              child: _query.trim().isEmpty && _activeTab == 'All'
                  ? _buildSuggestionsView()
                  : _buildResultsView(),
            ),
          ],
        ),
      ),
    );
  }

  String get _resultCountLabel {
    final jobs = (_activeTab == 'All' || _activeTab == 'Jobs')
        ? _filteredJobs.length
        : 0;
    final crss = (_activeTab == 'All' || _activeTab == 'Courses')
        ? _filteredCourses.length
        : 0;
    final skls = (_activeTab == 'All' || _activeTab == 'Skills')
        ? _filteredSkills.length
        : 0;
    final total = jobs + crss + skls;
    return '$total result${total == 1 ? '' : 's'} for "$_query"';
  }

  Widget _buildSuggestionsView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        _SectionLabel(label: 'Trending Searches', subC: _subC),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Python',
            'Flutter',
            'SQL',
            'Machine Learning',
            'React',
            'Data Analysis',
            'AWS',
            'Figma',
            'Cybersecurity',
            'Power BI',
            'Prompt Engineering',
            'Docker',
          ]
              .map((s) => _SuggestionChip(
                    label: s,
                    isDark: widget.isDark,
                    onTap: () {
                      _ctrl.text = s;
                      _ctrl.selection = TextSelection.fromPosition(
                          TextPosition(offset: s.length));
                      setState(() => _query = s);
                    },
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Popular Jobs', subC: _subC),
        const SizedBox(height: 8),
        ...allJobs.take(4).map((j) => _SearchJobTile(
              job: j,
              isDark: widget.isDark,
              onTap: () => _navigateToJobs(),
            )),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Top Courses', subC: _subC),
        const SizedBox(height: 8),
        ...courses.take(3).map((c) => _SearchCourseTile(
              course: c,
              isDark: widget.isDark,
              onTap: () => _navigateToCourses(),
            )),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Browse Skills', subC: _subC),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allSkills
              .take(24)
              .map((s) => _SuggestionChip(
                    label: s,
                    isDark: widget.isDark,
                    onTap: () {
                      _ctrl.text = s;
                      _ctrl.selection = TextSelection.fromPosition(
                          TextPosition(offset: s.length));
                      setState(() => _query = s);
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    final showJobs = _activeTab == 'All' || _activeTab == 'Jobs';
    final showCourses = _activeTab == 'All' || _activeTab == 'Courses';
    final showSkills = _activeTab == 'All' || _activeTab == 'Skills';

    final jobs = showJobs ? _filteredJobs : <Job>[];
    final crss = showCourses ? _filteredCourses : <Course>[];
    final skills = showSkills ? _filteredSkills : <String>[];

    final isEmpty = jobs.isEmpty && crss.isEmpty && skills.isEmpty;

    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: _subC.withValues(alpha: 0.5)),
            const SizedBox(height: 14),
            Text(
              'No results for "$_query"',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _textC),
            ),
            const SizedBox(height: 6),
            Text('Try different keywords',
                style: TextStyle(fontSize: 13, color: _subC)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
      children: [
        if (jobs.isNotEmpty) ...[
          _SectionLabel(label: 'Jobs (${jobs.length})', subC: _subC),
          const SizedBox(height: 8),
          ...jobs.map((j) => _SearchJobTile(
                job: j,
                isDark: widget.isDark,
                onTap: () => _navigateToJobs(),
              )),
          const SizedBox(height: 20),
        ],
        if (crss.isNotEmpty) ...[
          _SectionLabel(label: 'Courses (${crss.length})', subC: _subC),
          const SizedBox(height: 8),
          ...crss.map((c) => _SearchCourseTile(
                course: c,
                isDark: widget.isDark,
                onTap: () => _navigateToCourses(),
              )),
          const SizedBox(height: 20),
        ],
        if (skills.isNotEmpty) ...[
          _SectionLabel(label: 'Skills (${skills.length})', subC: _subC),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills
                .map((s) => _SuggestionChip(
                      label: s,
                      isDark: widget.isDark,
                      onTap: () {
                        _ctrl.text = s;
                        setState(() => _query = s);
                      },
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  void _navigateToJobs() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobResultScreen(
          profile: widget.profile,
          selectedIndustry: 'All',
          selectedLevel: 'All',
          remoteOnly: false,
        ),
      ),
    );
  }

  void _navigateToCourses() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<AppThemeProvider>(
          create: (_) => AppThemeProvider(isDark: widget.isDark),
          child: const BrowseCoursesScreen(),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color subC;
  const _SectionLabel({required this.label, required this.subC});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: subC,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Suggestion chip ───────────────────────────────────────────────────────────
class _SuggestionChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _SuggestionChip(
      {required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? _kDarkCard : Colors.white;
    final borderC = isDark ? _kDarkBorder : const Color(0xFFE2E8F0);
    final textC = isDark ? Colors.white : const Color(0xFF0F172A);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: borderC),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 12, color: _kPrimaryBlue),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: textC)),
          ],
        ),
      ),
    );
  }
}

// ── Search job tile ───────────────────────────────────────────────────────────
class _SearchJobTile extends StatelessWidget {
  final Job job;
  final bool isDark;
  final VoidCallback onTap;
  const _SearchJobTile(
      {required this.job, required this.isDark, required this.onTap});

  Color get _industryColor {
    switch (job.industry) {
      case 'Software':
        return _kPrimaryBlue;
      case 'Finance':
        return _kGreen;
      case 'Healthcare':
        return _kError;
      case 'Marketing':
        return _kPurple;
      case 'Design':
        return const Color(0xFFDB2777);
      default:
        return _kOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? _kDarkCard : Colors.white;
    final borderC = isDark ? _kDarkBorder : const Color(0xFFE2E8F0);
    final textC = isDark ? Colors.white : const Color(0xFF0F172A);
    final subC = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderC),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: _withA(Colors.black, 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _withA(_industryColor, 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  job.company.isNotEmpty ? job.company[0].toUpperCase() : '?',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _industryColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textC),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${job.company} · ${job.industry}',
                      style: TextStyle(fontSize: 11, color: subC),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    _MiniChip(label: job.level, color: _kPrimaryBlue),
                    const SizedBox(width: 6),
                    _MiniChip(label: job.workingMode, color: _kGreen),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: subC),
                const SizedBox(height: 4),
                Text(
                  '৳ ${job.salary}',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _kPrimaryBlue),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search course tile ────────────────────────────────────────────────────────
class _SearchCourseTile extends StatelessWidget {
  final Course course;
  final bool isDark;
  final VoidCallback onTap;
  const _SearchCourseTile(
      {required this.course, required this.isDark, required this.onTap});

  Color get _catColor {
    final c = course.category.toLowerCase();
    if (c.contains('data')) return _kPrimaryBlue;
    if (c.contains('market')) return _kPurple;
    if (c.contains('finance')) return _kGreen;
    if (c.contains('cloud') || c.contains('aws')) return _kOrange;
    return _kPrimaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? _kDarkCard : Colors.white;
    final borderC = isDark ? _kDarkBorder : const Color(0xFFE2E8F0);
    final textC = isDark ? Colors.white : const Color(0xFF0F172A);
    final subC = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderC),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: _withA(Colors.black, 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _withA(_catColor, 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.play_lesson_rounded, color: _catColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textC),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(course.provider,
                      style: TextStyle(fontSize: 11, color: subC),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: _kOrange, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      course.rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kOrange),
                    ),
                    if (course.isFree) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _withA(_kGreen, 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('FREE',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _kGreen)),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: subC),
          ],
        ),
      ),
    );
  }
}

// ── Mini chip ─────────────────────────────────────────────────────────────────
class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _withA(color, 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// INSIGHT SHORTCUT CARD
// ══════════════════════════════════════════════════════════════════════════════

class _InsightShortcutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isDark;
  final VoidCallback onTap;

  const _InsightShortcutCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _withA(gradientColors.first, 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _withA(Colors.white, 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 10,
                            color: _withA(Colors.white, 0.75),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ANIMATED STAT CARD
// ══════════════════════════════════════════════════════════════════════════════

class _AnimatedStatCard extends StatelessWidget {
  final int index;
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final AnimationController anim;

  const _AnimatedStatCard({
    required this.index,
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, Widget? child) {
        final double delay = (index * 0.12).clamp(0.0, 0.88);
        final double t = ((anim.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        return Transform.scale(
          scale: Curves.elasticOut.transform(t),
          child: child,
        );
      },
      child: Container(
        width: 104,
        height: 100,
        decoration: _cardDeco(isDark, radius: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _withA(iconColor, isDark ? 0.16 : 0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5)),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CONTINUE LEARNING BANNER
// ══════════════════════════════════════════════════════════════════════════════

class _ContinueLearningBanner extends StatelessWidget {
  final String courseId;
  final Map<String, double> courseProgressMap;
  final VoidCallback onResume;

  const _ContinueLearningBanner({
    required this.courseId,
    required this.courseProgressMap,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final String courseName = courseId.isNotEmpty ? courseId : 'Your Course';
    final double progress =
        (courseProgressMap[courseId] ?? 0.0).clamp(0.0, 1.0);
    final String pctText = '${(progress * 100).round()}% complete';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF1A56DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _withA(const Color(0xFF1A56DB), 0.24),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _withA(Colors.white, 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.play_circle_filled_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Continue Learning',
                    style: TextStyle(
                        fontSize: 12, color: _withA(Colors.white, 0.7))),
                Text(courseName,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, double val, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: val,
                          backgroundColor: _withA(Colors.white, 0.2),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(pctText,
                          style: TextStyle(
                              fontSize: 10, color: _withA(Colors.white, 0.7))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _withA(Colors.white, 0.15),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onResume,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text('Resume',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DAILY ACTIVITY CARD
// ══════════════════════════════════════════════════════════════════════════════

class _DailyActivityCard extends StatelessWidget {
  final int readiness;
  final int streak;
  final int courseDone;
  final bool isDark;

  const _DailyActivityCard({
    required this.readiness,
    required this.streak,
    required this.courseDone,
    required this.isDark,
  });

  Color get _ringColor {
    if (readiness >= 75) return _kGreen;
    if (readiness >= 45) return _kOrange;
    return _kError;
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDeco(isDark, radius: 20),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: readiness / 100),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (_, double val, __) => SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: 20.0,
                      strokeWidth: 8,
                      color: _withA(_ringColor, 0.14),
                    ),
                  ),
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: val,
                      strokeWidth: 8,
                      color: _ringColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(val * 100).round()}%',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _ringColor,
                            height: 1),
                      ),
                      Text('Ready',
                          style: TextStyle(fontSize: 9, color: subColor)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Activity',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ActivityPill(
                        icon: Icons.local_fire_department_rounded,
                        color: _kOrange,
                        value: '${streak}d',
                        label: 'Streak',
                        isDark: isDark),
                    const SizedBox(width: 10),
                    _ActivityPill(
                        icon: Icons.check_circle_rounded,
                        color: _kGreen,
                        value: '$courseDone',
                        label: 'Done',
                        isDark: isDark),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  streak == 0
                      ? 'Start a course to build your streak! '
                      : streak >= 7
                          ? ' Outstanding! $streak-day streak!'
                          : ' Keep going — $streak days and counting!',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final bool isDark;

  const _ActivityPill({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _withA(color, 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _withA(color, 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text('$value $label',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// JOB CARD
// ══════════════════════════════════════════════════════════════════════════════

class _JobCard extends StatelessWidget {
  final String heroTag;
  final String jobTitle;
  final String company;
  final int matchScore;
  final String salary;
  final List<String> skills;
  final bool isDark;
  final VoidCallback onApply;

  const _JobCard({
    required this.heroTag,
    required this.jobTitle,
    required this.company,
    required this.matchScore,
    required this.salary,
    required this.skills,
    required this.isDark,
    required this.onApply,
  });

  String get _initials {
    final List<String> words = company.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : '?';
    }
    return '${words[0].isNotEmpty ? words[0][0] : ''}${words[1].isNotEmpty ? words[1][0] : ''}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final Color surfaceBg =
        isDark ? _withA(_kDarkBg, 0.47) : const Color(0xFFF1F5F9);
    final Color subColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Hero(
      tag: heroTag,
      child: Container(
        width: 278,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(isDark, radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _withA(_kPrimaryBlue, 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(_initials,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kPrimaryBlue)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(company,
                          style: TextStyle(fontSize: 11, color: subColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(jobTitle,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                _MatchChip(score: matchScore),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _InfoChip(label: ' Dhaka', bg: surfaceBg, fg: subColor),
                _InfoChip(label: ' Full-time', bg: surfaceBg, fg: subColor),
              ],
            ),
            const SizedBox(height: 8),
            if (skills.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ...skills.take(2).map((s) => _SkillBadge(label: s)),
                  if (skills.length > 2)
                    _SkillBadge(label: '+${skills.length - 2}'),
                ],
              ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Salary',
                        style: TextStyle(fontSize: 10, color: subColor)),
                    Text('৳ $salary',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kPrimaryBlue)),
                  ],
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  child: InkWell(
                    onTap: onApply,
                    borderRadius: BorderRadius.circular(100),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: _withA(_kPrimaryBlue, 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text('Apply →',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SKILL GAP BANNER
// ══════════════════════════════════════════════════════════════════════════════

class _SkillGapBanner extends StatelessWidget {
  final int count;
  final bool isDark;
  final AnimationController pulse;
  final VoidCallback onTap;

  const _SkillGapBanner({
    required this.count,
    required this.isDark,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return AnimatedBuilder(
      animation: pulse,
      builder: (_, Widget? child) {
        final double borderOpacity = 0.3 + 0.5 * pulse.value;
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? _kDarkCard : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _withA(const Color(0xFF1A56DB), borderOpacity),
                  width: 1.5,
                ),
              ),
              child: child,
            ),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _withA(_kPrimaryBlue, 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.trending_up_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Skill Gap Detected ',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor)),
                const SizedBox(height: 2),
                Text(
                  'Learn $count skill${count == 1 ? '' : 's'} to boost job matches by up to 40%',
                  style: TextStyle(fontSize: 13, color: subColor),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: subColor),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TRENDING CHIP
// ══════════════════════════════════════════════════════════════════════════════

class _TrendingChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _TrendingChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: () => HapticFeedback.selectionClick(),
        borderRadius: BorderRadius.circular(100),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? _kDarkCard : _kLightBg,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: isDark ? _kDarkBorder : _kLightBorder),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: _withA(Colors.black, 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A))),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MATCH CHIP
// ══════════════════════════════════════════════════════════════════════════════

class _MatchChip extends StatelessWidget {
  final int score;
  const _MatchChip({required this.score});

  Color get _color {
    if (score >= 75) return _kMatchGreen;
    if (score >= 50) return _kOrange;
    return _kError;
  }

  Color get _bg {
    if (score >= 75) return _kMatchGreenBg;
    if (score >= 50) return const Color(0xFFFEF3C7);
    return const Color(0xFFFEE2E2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: _bg,
          borderRadius: const BorderRadius.all(Radius.circular(20))),
      child: Text('$score%',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: _color)),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// INFO CHIP
// ══════════════════════════════════════════════════════════════════════════════

class _InfoChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _InfoChip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: const BorderRadius.all(Radius.circular(20))),
      child: Text(label, style: TextStyle(fontSize: 11, color: fg)),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SKILL BADGE
// ══════════════════════════════════════════════════════════════════════════════

class _SkillBadge extends StatelessWidget {
  final String label;
  const _SkillBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _withA(_kPrimaryBlue, 0.07),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        border: Border.all(color: _withA(_kPrimaryBlue, 0.2)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimaryBlue)),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COURSE CARD
// ══════════════════════════════════════════════════════════════════════════════

class _CourseCard extends StatelessWidget {
  final String courseTitle;
  final String platform;
  final double rating;
  final String format;
  final bool isDark;
  final VoidCallback onEnroll;

  const _CourseCard({
    required this.courseTitle,
    required this.platform,
    required this.rating,
    required this.format,
    required this.isDark,
    required this.onEnroll,
  });

  Color get _platformColor {
    final String p = platform.toLowerCase();
    if (p.contains('coursera')) return const Color(0xFF0056D2);
    if (p.contains('udemy')) return const Color(0xFFEC5252);
    if (p.contains('edx')) return const Color(0xFF02262B);
    if (p.contains('linkedin')) return const Color(0xFF0077B5);
    if (p.contains('youtube') || p.contains('freecodecamp')) {
      return const Color(0xFFFF0000);
    }
    if (p.contains('google')) return const Color(0xFF4285F4);
    if (p.contains('aws')) return const Color(0xFFFF9900);
    return _kPrimaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color formatBg =
        isDark ? _withA(_kPrimaryBlue, 0.16) : const Color(0xFFDBEAFE);

    final double ratingVal = rating > 0 ? rating : 4.5;
    final String ratingStr = ratingVal.toStringAsFixed(1);
    final int starsFull = ratingVal.floor();
    final bool hasHalf = (ratingVal - starsFull) >= 0.5;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(isDark, radius: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _platformColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _withA(_platformColor, 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.play_lesson_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(courseTitle,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(platform.isNotEmpty ? platform : 'Coursera',
                    style: TextStyle(fontSize: 12, color: subColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      if (i < starsFull) {
                        return const Icon(Icons.star_rounded,
                            color: _kOrange, size: 13);
                      }
                      if (i == starsFull && hasHalf) {
                        return const Icon(Icons.star_half_rounded,
                            color: _kOrange, size: 13);
                      }
                      return Icon(Icons.star_outline_rounded,
                          color: _withA(_kOrange, 0.35), size: 13);
                    }),
                    const SizedBox(width: 5),
                    Text(ratingStr,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _kOrange)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: formatBg,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
                child: Text(format.isNotEmpty ? format : 'Video',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kPrimaryBlue)),
              ),
              const SizedBox(height: 8),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: onEnroll,
                  borderRadius: BorderRadius.circular(8),
                  child: Ink(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Enroll →',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
