// lib/screens/main_nav.dart — SkillBridge AI

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../ml/recommender.dart' show JobRecommendation;
import '../services/app_state.dart';
import '../models/career_profile.dart';
import '../theme/app_theme.dart';
import '../data/jobs.dart';
import '../data/courses.dart';
// ── Bottom nav screens ────────────────────────────────────────────────────────
import 'home.dart';
import 'job_result.dart';
import 'learning.dart';
import 'dashboard_screen.dart';
import 'chatbot_screen.dart';
// ── Drawer screens — Career Tools ─────────────────────────────────────────────
import 'job_transition_screen.dart';
import 'skill_trends_screen.dart' as trends;
import 'workforce_insights_screen.dart';
import 'geo_insights_screen.dart';
// ── Drawer screens — My Progress ──────────────────────────────────────────────
import 'skill_gap.dart';
import 'assessment_hub_screen.dart' as assessment;
import 'confidence_tracker_screen.dart';
import 'application_tracker_screen.dart';
// ── Drawer screens — Learning ─────────────────────────────────────────────────
import 'browse_courses_screen.dart';
import 'career_guide.dart';
// ── Drawer screens — Settings ─────────────────────────────────────────────────
import 'job_alerts_screen.dart';
import 'privacy_settings_screen.dart';
import 'profile_input.dart';
import 'cv_upload_screen.dart';

/// Returns the user's ExperienceType from AppState.
/// Falls back to ExperienceType.none so CareerProfile never receives null.
ExperienceType _safeEmploymentType(AppState s) {
  try {
    final dynamic val = (s as dynamic).experienceType;
    if (val is ExperienceType) return val;
  } catch (_) {}
  try {
    final dynamic val = (s as dynamic).employmentType;
    if (val is ExperienceType) return val;
  } catch (_) {}
  try {
    final dynamic val = (s as dynamic).expType;
    if (val is ExperienceType) return val;
  } catch (_) {}
  return ExperienceType.none;
}

// ── ADDED: Safe accessors for ChatbotContext ──────────────────────────────────

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

String _safeJobSalaryRange(dynamic job) {
  try {
    if (job is Job) return job.salary;
    final v = (job as dynamic).salaryRange;
    if (v is String && v.isNotEmpty) return v;
  } catch (_) {}
  return '30,000–60,000';
}

List<String> _safeJobRequiredSkills(dynamic job) {
  try {
    if (job is Job) return job.skills;
    final v = (job as dynamic).requiredSkills;
    if (v is List) return v.map((e) => e.toString()).toList();
  } catch (_) {}
  return const [];
}

String safeCoursePlatform(dynamic course) {
  try {
    if (course is Course) return course.provider;
    final v = (course as dynamic).platform;
    if (v is String) return v;
  } catch (_) {}
  return '';
}

String safeCourseFormat(dynamic course) {
  try {
    if (course is Course) return course.type;
    final v = (course as dynamic).format;
    if (v is String && v.isNotEmpty) return v;
  } catch (_) {}
  return 'Video';
}

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
        if (name.isNotEmpty)
          result.add(ChatSkillGapData(
              name: name, priority: priority, importance: importance));
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
        if (s.userSkills.isNotEmpty)
          return (job.matchScore(s.userSkills) * 100).round();
        return 60;
      }(),
      requiredSkills: _safeJobRequiredSkills(job),
      jobType: jobType.isEmpty ? null : jobType,
    );
  }).toList();
}

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
        rating: rating);
  }).toList();
}

// ADDED: Build full ChatbotContext from AppState for the Assistant tab
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
      // Tab-level navigation: handled by _MainNavState directly via _onTabSelected.
      // Full-route navigation: push the appropriate screen.
      final fos = FieldOfStudy.values.firstWhere(
        (e) => e.name.toLowerCase() == s.fieldOfStudy.toLowerCase(),
        orElse: () => FieldOfStudy.values.first,
      );
      final profile = CareerProfile(
        name: s.userName.isEmpty ? 'User' : s.userName,
        fieldOfStudy: fos,
        gpa: s.gpa,
        yearOfStudy: s.yearOfStudy,
        employmentType: _safeEmploymentType(s),
        skills: List<String>.from(s.userSkills),
      );
      Widget? dest;
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
        case 'skillGap':
          if (s.recommendedJobs.isNotEmpty) {
            dest = SkillGapScreen(
                job: s.recommendedJobs.first as JobRecommendation,
                userSkills: List<String>.from(s.userSkills));
          }
        case 'careerGuide':
          dest = CareerGuideScreen(profile: profile);
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
        case 'assessments':
          dest = const assessment.AssessmentHubScreen();
        case 'jobAlerts':
          dest = JobAlertsScreen(onViewJobs: () {});
        case 'workforceInsights':
          dest = const WorkforceInsightsScreen();
        case 'skillTrends':
          dest = const trends.SkillTrendsScreen();
        default:
          dest = null;
      }
      if (dest != null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => dest!));
      }
    },
  );
}

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kNavBlue = Color(0xFF1A56DB);
const _kNavCyan = Color(0xFF0EA5E9);
const _kGreen = Color(0xFF10B981);
const _kAmber = Color(0xFFF59E0B);
const _kRed = Color(0xFFEF4444);

Color _navBg(bool d) => d ? const Color(0xFF0F172A) : Colors.white;
Color _borderC(bool d) => d ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
Color _textC(bool d) => d ? Colors.white : const Color(0xFF0F172A);
Color _subC(bool d) => d ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
Color _iconBgC(bool d) => d ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);

// ─── Readiness colour helper (shared) ─────────────────────────────────────────
Color _readinessColor(int score) {
  if (score >= 70) {
    return _kGreen;
  }
  if (score >= 40) {
    return _kAmber;
  }
  return _kRed;
}

// =============================================================================
// MAIN NAV
// =============================================================================

class MainNav extends StatefulWidget {
  final int initialTab;
  const MainNav({super.key, this.initialTab = 0});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> with TickerProviderStateMixin {
  late int _currentIndex;
  DateTime? _lastBackPress;
  static const int _tabCount = 5;

  late final List<AnimationController> _tabCtrls;
  late final List<Animation<double>> _tabAnims;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab.clamp(0, _tabCount - 1);
    _tabCtrls = List.generate(
      _tabCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 320),
      ),
    );
    _tabAnims = _tabCtrls
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
        .toList();
    _tabCtrls[_currentIndex].value = 1.0;
  }

  @override
  void dispose() {
    for (final c in _tabCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  // ── FIX: Safe CareerProfile builder now includes skills from AppState ──────
  CareerProfile _safeProfile(AppState appState) {
    final fos = FieldOfStudy.values.firstWhere(
      (e) => e.name.toLowerCase() == appState.fieldOfStudy.toLowerCase(),
      orElse: () => FieldOfStudy.values.first,
    );
    return CareerProfile(
      name: appState.userName.isEmpty ? 'User' : appState.userName,
      fieldOfStudy: fos,
      gpa: appState.gpa,
      yearOfStudy: appState.yearOfStudy,
      employmentType: _safeEmploymentType(appState),
      // FIX: pass the user's actual skills so recommendJobs() returns results
      skills: List<String>.from(appState.userSkills),
    );
  }

  // ── Screen builder ────────────────────────────────────────────────────────
  Widget _buildScreen(int index) {
    final appState = context.read<AppState>();
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        // FIX: JobResultScreen now receives a profile with real skills
        return JobResultScreen(
          profile: _safeProfile(appState),
          selectedIndustry: appState.lastIndustryFilter.isEmpty
              ? 'All'
              : appState.lastIndustryFilter,
          selectedLevel: appState.lastLevelFilter.isEmpty
              ? 'All'
              : appState.lastLevelFilter,
          remoteOnly: false,
        );
      case 2:
        return LearningScreen(
          missingSkills: appState.userSkills.isEmpty
              ? const []
              : List<String>.from(appState.userSkills),
          industry: appState.lastIndustryFilter.isEmpty
              ? 'General'
              : appState.lastIndustryFilter,
        );
      case 3:
        return const DashboardScreen();
      case 4:
        // ADDED: ChatbotScreen now receives the full ChatbotContext built from AppState
        return ChatbotScreen(
          chatContext: _buildChatbotContext(context, appState),
        );
      default:
        return const HomeScreen();
    }
  }

  // ── Tab switching ─────────────────────────────────────────────────────────
  void _onTabSelected(int index) {
    if (index == _currentIndex) {
      return;
    }
    HapticFeedback.selectionClick();
    _tabCtrls[_currentIndex].reverse();
    setState(() => _currentIndex = index);
    _tabCtrls[index].forward(from: 0.0);
  }

  /// Public helper so drawer/sheets can jump to the Learn tab (index 2).
  void switchToLearnTab() => _onTabSelected(2);

  /// Public helper so drawer/sheets can jump to the Jobs tab (index 1).
  void switchToJobsTab() => _onTabSelected(1);

  // ── Double-back-tap to exit ───────────────────────────────────────────────
  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      _onTabSelected(0);
      return false;
    }
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 16),
              SizedBox(width: 10),
              Text('Press back again to exit SkillBridge AI'),
            ]),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1E293B),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return false;
    }
    return true;
  }

  // ── Drawer navigation helper ──────────────────────────────────────────────
  void _navigateTo(BuildContext ctx, Widget screen) {
    Navigator.pop(ctx);
    Navigator.push(ctx, _FadeSlideRoute(child: screen));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final should = await _onWillPop();
          if (should && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: _navBg(isDark),
        drawer: _AppDrawer(
          onNavigate: _navigateTo,
          appState: appState,
          onGoToLearnTab: switchToLearnTab, // FIX: wire Learn tab
          onGoToJobsTab: switchToJobsTab, // FIX: wire Jobs tab
        ),
        body: Stack(
          children: List.generate(_tabCount, (i) {
            return FadeTransition(
              opacity: _tabAnims[i],
              child: Offstage(
                offstage: _currentIndex != i,
                child: _buildScreen(i),
              ),
            );
          }),
        ),
        bottomNavigationBar: _BottomNavBar(
          currentIndex: _currentIndex,
          appState: appState,
          onSelected: _onTabSelected,
        ),
      ),
    );
  }
}

// ─── Custom page route ─────────────────────────────────────────────────────
class _FadeSlideRoute extends PageRouteBuilder<void> {
  final Widget child;
  _FadeSlideRoute({required this.child})
      : super(
          pageBuilder: (_, __, ___) => child,
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (_, anim, __, child) {
            final curved =
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

// =============================================================================
// BOTTOM NAVIGATION BAR
// =============================================================================

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final AppState appState;
  final ValueChanged<int> onSelected;

  const _BottomNavBar({
    required this.currentIndex,
    required this.appState,
    required this.onSelected,
  });

  static const _items = [
    _NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavItem(
      label: 'Jobs',
      icon: Icons.work_outline_rounded,
      activeIcon: Icons.work_rounded,
    ),
    _NavItem(
      label: 'Learn',
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
    ),
    _NavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    _NavItem(
      label: 'Assistant',
      icon: Icons.smart_toy_outlined,
      activeIcon: Icons.smart_toy_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final savedCount = appState.savedJobIds.length;
    final missingCount = appState.skillsMissingCount;
    final readiness = appState.readinessScore;

    final badges = <int, String>{
      1: savedCount > 0 ? '$savedCount' : '',
      2: missingCount > 0 ? '$missingCount' : '',
      3: '$readiness%',
    };

    final badgeColors = <int, Color>{
      1: _kGreen,
      2: _kAmber,
      3: _readinessColor(readiness),
    };

    return Container(
      decoration: BoxDecoration(
        color: _navBg(isDark),
        border: Border(
          top: BorderSide(color: _borderC(isDark), width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: _kNavBlue.withAlpha(isDark ? 35 : 20),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isActive = currentIndex == i;
              final badgeText = badges[i] ?? '';
              final badgeColor = badgeColors[i];

              return Expanded(
                child: _NavItemTile(
                  item: item,
                  isActive: isActive,
                  badgeText: badgeText,
                  badgeColor: badgeColor,
                  isDark: isDark,
                  onTap: () => onSelected(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Nav item data class ──────────────────────────────────────────────────────
class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

// ─── Individual nav tile ──────────────────────────────────────────────────────
class _NavItemTile extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final String badgeText;
  final Color? badgeColor;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItemTile({
    required this.item,
    required this.isActive,
    required this.badgeText,
    required this.badgeColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavItemTile> createState() => _NavItemTileState();
}

class _NavItemTileState extends State<_NavItemTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _dotAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.12)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _dotAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    if (widget.isActive) {
      _ctrl.forward();
    }
  }

  @override
  void didUpdateWidget(_NavItemTile old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _ctrl.forward(from: 0);
    } else if (!widget.isActive && old.isActive) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    final isDark = widget.isDark;
    final color = active ? _kNavBlue : _subC(isDark);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: active ? 52 : 36,
                  height: 32,
                  decoration: BoxDecoration(
                    color: active
                        ? _kNavBlue.withAlpha(isDark ? 38 : 22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                Transform.scale(
                  scale: _scaleAnim.value,
                  child: Icon(
                    active ? widget.item.activeIcon : widget.item.icon,
                    color: color,
                    size: 22,
                  ),
                ),
                if (widget.badgeText.isNotEmpty)
                  Positioned(
                    top: -4,
                    right: -10,
                    child: _NavBadge(
                      text: widget.badgeText,
                      color: widget.badgeColor ?? _kGreen,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              child: Text(widget.item.label),
            ),
            const SizedBox(height: 2),
            SizeTransition(
              sizeFactor: _dotAnim,
              axis: Axis.horizontal,
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                    color: _kNavBlue, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nav badge ────────────────────────────────────────────────────────────────
class _NavBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _NavBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(80),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}

// =============================================================================
// SIDE DRAWER
// =============================================================================

class _AppDrawer extends StatelessWidget {
  final void Function(BuildContext ctx, Widget screen) onNavigate;
  final AppState appState;
  final VoidCallback onGoToLearnTab; // FIX: callback to switch Learn tab
  final VoidCallback onGoToJobsTab; // FIX: callback to switch Jobs tab

  const _AppDrawer({
    required this.onNavigate,
    required this.appState,
    required this.onGoToLearnTab,
    required this.onGoToJobsTab,
  });

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Build a CareerProfile with skills for use in drawer-launched screens.
  CareerProfile _drawerProfile(AppState appState) {
    final fos = FieldOfStudy.values.firstWhere(
      (e) => e.name.toLowerCase() == appState.fieldOfStudy.toLowerCase(),
      orElse: () => FieldOfStudy.values.first,
    );
    return CareerProfile(
      name: appState.userName.isEmpty ? 'User' : appState.userName,
      fieldOfStudy: fos,
      gpa: appState.gpa,
      yearOfStudy: appState.yearOfStudy,
      employmentType: _safeEmploymentType(appState),
      skills: List<String>.from(appState.userSkills),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = appState.userName.isEmpty ? 'User' : appState.userName;
    final email = appState.userEmail.isEmpty ? '' : appState.userEmail;
    final initials = _initials(name);
    final readiness = appState.readinessScore;
    final confidence = appState.overallConfidenceScore;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: _navBg(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DrawerHeader(
            initials: initials,
            name: name,
            email: email,
            readiness: readiness,
            confidenceScore: confidence,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                // 🎯 CAREER TOOLS
                _DrawerSection(
                  label: 'CAREER TOOLS',
                  isDark: isDark,
                  accentColor: _kNavBlue,
                  children: [
                    _DrawerTile(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Career Transition',
                      subtitle: 'Explore new paths',
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: _kNavBlue,
                      isDark: isDark,
                      onTap: () => onNavigate(
                        context,
                        // FIX: pass onGoToLearnTab so "Find Courses" inside
                        // the transition screen can jump to the Learn tab.
                        JobTransitionScreen(onGoToLearning: onGoToLearnTab),
                      ),
                    ),
                    _DrawerTile(
                      icon: Icons.trending_up_rounded,
                      label: 'Skill Trends',
                      subtitle: 'In-demand skills today',
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: _kNavBlue,
                      isDark: isDark,
                      onTap: () =>
                          onNavigate(context, const trends.SkillTrendsScreen()),
                    ),
                    _DrawerTile(
                      icon: Icons.groups_outlined,
                      label: 'Workforce Insights',
                      subtitle: 'Industry intelligence',
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: _kNavBlue,
                      isDark: isDark,
                      onTap: () =>
                          onNavigate(context, const WorkforceInsightsScreen()),
                    ),
                    _DrawerTile(
                      icon: Icons.location_on_outlined,
                      label: 'Geographic Demand',
                      subtitle: 'Location-based market data',
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: _kNavBlue,
                      isDark: isDark,
                      onTap: () =>
                          onNavigate(context, const GeoInsightsScreen()),
                    ),
                  ],
                ),

                // 📊 MY PROGRESS
                _DrawerSection(
                  label: 'MY PROGRESS',
                  isDark: isDark,
                  accentColor: _kAmber,
                  children: [
                    _DrawerTile(
                      icon: Icons.bar_chart_rounded,
                      label: 'Skill Gap Analysis',
                      subtitle: 'See what you\'re missing',
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: _kAmber,
                      isDark: isDark,
                      onTap: () {
                        if (appState.recommendedJobs.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(children: [
                                Icon(Icons.info_outline,
                                    color: Colors.white, size: 15),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Run a job search first to see your skill gaps.',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ]),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF1E293B),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          return;
                        }
                        final topJob =
                            appState.recommendedJobs.first as JobRecommendation;
                        onNavigate(
                          context,
                          SkillGapScreen(
                            job: topJob,
                            userSkills: List<String>.from(appState.userSkills),
                          ),
                        );
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.quiz_outlined,
                      label: 'Assessment Hub',
                      subtitle: 'Test your knowledge',
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: _kAmber,
                      isDark: isDark,
                      onTap: () => onNavigate(
                          context, const assessment.AssessmentHubScreen()),
                    ),
                    _DrawerTile(
                      icon: Icons.psychology_outlined,
                      label: 'Confidence Tracker',
                      subtitle: 'Track your self-belief',
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: _kAmber,
                      isDark: isDark,
                      onTap: () =>
                          onNavigate(context, const ConfidenceTrackerScreen()),
                    ),
                    _DrawerTile(
                      icon: Icons.track_changes_rounded,
                      label: 'Application Tracker',
                      subtitle: 'Monitor your pipeline',
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: _kAmber,
                      isDark: isDark,
                      onTap: () =>
                          onNavigate(context, const ApplicationTrackerScreen()),
                    ),
                  ],
                ),

                // 📚 LEARNING
                _DrawerSection(
                  label: 'LEARNING',
                  isDark: isDark,
                  accentColor: _kGreen,
                  children: [
                    _DrawerTile(
                      icon: Icons.play_circle_outline_rounded,
                      label: 'My Courses',
                      subtitle: 'Continue your progress',
                      iconBg: const Color(0xFFD1FAE5),
                      iconColor: _kGreen,
                      isDark: isDark,
                      onTap: () => onNavigate(
                        context,
                        LearningScreen(
                          missingSkills: List<String>.from(appState.userSkills),
                          industry: appState.lastIndustryFilter.isEmpty
                              ? 'General'
                              : appState.lastIndustryFilter,
                        ),
                      ),
                    ),
                    _DrawerTile(
                      icon: Icons.explore_outlined,
                      label: 'Browse All Courses',
                      subtitle: 'Discover new skills',
                      iconBg: const Color(0xFFD1FAE5),
                      iconColor: _kGreen,
                      isDark: isDark,
                      onTap: () =>
                          onNavigate(context, const BrowseCoursesScreen()),
                    ),
                    _DrawerTile(
                      icon: Icons.map_outlined,
                      label: 'Career Guide',
                      subtitle: 'Personalised roadmap',
                      iconBg: const Color(0xFFD1FAE5),
                      iconColor: _kGreen,
                      isDark: isDark,
                      onTap: () {
                        onNavigate(
                          context,
                          CareerGuideScreen(profile: _drawerProfile(appState)),
                        );
                      },
                    ),
                  ],
                ),

                // ⚙️ SETTINGS
                _DrawerSection(
                  label: 'SETTINGS',
                  isDark: isDark,
                  accentColor: _subC(isDark),
                  children: [
                    _DrawerTile(
                      icon: Icons.notifications_outlined,
                      label: 'Job Alerts',
                      subtitle: 'Stay notified',
                      iconBg: _iconBgC(isDark),
                      iconColor: _subC(isDark),
                      isDark: isDark,
                      onTap: () => onNavigate(
                        context,
                        // FIX: pass onGoToJobsTab so "View Job →" in alerts
                        // can jump back to the Jobs tab.
                        JobAlertsScreen(onViewJobs: onGoToJobsTab),
                      ),
                    ),
                    _DrawerTile(
                      icon: Icons.lock_outline_rounded,
                      label: 'Privacy Settings',
                      subtitle: 'Control your data',
                      iconBg: _iconBgC(isDark),
                      iconColor: _subC(isDark),
                      isDark: isDark,
                      onTap: () =>
                          onNavigate(context, const PrivacySettingsScreen()),
                    ),
                    _DrawerTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Edit Profile',
                      subtitle: 'Update your info',
                      iconBg: _iconBgC(isDark),
                      iconColor: _subC(isDark),
                      isDark: isDark,
                      onTap: () =>
                          onNavigate(context, const ProfileInputScreen()),
                    ),
                    _DrawerTile(
                      icon: Icons.upload_file_outlined,
                      label: 'Upload CV',
                      subtitle: 'Keep it up to date',
                      iconBg: _iconBgC(isDark),
                      iconColor: _subC(isDark),
                      isDark: isDark,
                      onTap: () => onNavigate(context, const CvUploadScreen()),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: _borderC(isDark), height: 1),
                ),
                const SizedBox(height: 4),

                _DarkModeToggle(isDark: isDark),

                const SizedBox(height: 4),

                _SignOutTile(appState: appState),

                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'SkillBridge AI  v2.0',
                    style: TextStyle(
                        fontSize: 11, color: _subC(isDark), letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dark mode toggle ─────────────────────────────────────────────────────────
class _DarkModeToggle extends StatelessWidget {
  final bool isDark;
  const _DarkModeToggle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                RotationTransition(turns: anim, child: child),
            child: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              key: ValueKey(isDark),
              color: isDark ? const Color(0xFFFBBF24) : AppTheme.primaryBlue,
              size: 22,
            ),
          ),
          title: Text(
            'Dark Mode',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textC(isDark),
            ),
          ),
          trailing: Switch.adaptive(
            value: isDark,
            activeThumbColor: AppTheme.primaryBlue,
            onChanged: (val) => context.read<AppState>().setThemeMode(
                  val ? ThemeMode.dark : ThemeMode.light,
                ),
          ),
        ),
      ),
    );
  }
}

// ─── Sign out tile ────────────────────────────────────────────────────────────
class _SignOutTile extends StatelessWidget {
  final AppState appState;
  const _SignOutTile({required this.appState});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            Navigator.pop(context);
            await context.read<AppState>().logout();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: _kRed.withAlpha(12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kRed.withAlpha(35)),
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded, color: _kRed, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kRed,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: _kRed.withAlpha(120), size: 18),
            ]),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// DRAWER HEADER
// =============================================================================

class _DrawerHeader extends StatelessWidget {
  final String initials;
  final String name;
  final String email;
  final int readiness;
  final double confidenceScore;

  const _DrawerHeader({
    required this.initials,
    required this.name,
    required this.email,
    required this.readiness,
    required this.confidenceScore,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A3A6B), _kNavBlue, _kNavCyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(12),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 40,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(8),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withAlpha(40),
                        Colors.white.withAlpha(20),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withAlpha(100), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),
                Row(children: [
                  _HeaderStat(
                    label: 'Readiness',
                    value: '$readiness%',
                    color: _readinessColor(readiness),
                  ),
                  const SizedBox(width: 8),
                  _HeaderStat(
                    label: 'Confidence',
                    value: '${(confidenceScore * 100).round()}%',
                    color: confidenceScore >= 0.7
                        ? _kGreen
                        : confidenceScore >= 0.4
                            ? _kAmber
                            : _kRed,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _HeaderStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ]),
    );
  }
}

// =============================================================================
// DRAWER SECTION
// =============================================================================

class _DrawerSection extends StatelessWidget {
  final String label;
  final bool isDark;
  final Color accentColor;
  final List<Widget> children;

  const _DrawerSection({
    required this.label,
    required this.isDark,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: _subC(isDark),
              ),
            ),
          ]),
        ),
        ...children,
        const SizedBox(height: 4),
      ],
    );
  }
}

// =============================================================================
// DRAWER TILE
// =============================================================================

class _DrawerTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconBg;
  final Color iconColor;
  final bool isDark;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconBg,
    required this.iconColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_DrawerTile> createState() => _DrawerTileState();
}

class _DrawerTileState extends State<_DrawerTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: _pressed
                ? (isDark
                    ? Colors.white.withAlpha(8)
                    : Colors.black.withAlpha(5))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textC(isDark),
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: _subC(isDark),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: _subC(isDark).withAlpha(120),
            ),
          ]),
        ),
      ),
    );
  }
}
