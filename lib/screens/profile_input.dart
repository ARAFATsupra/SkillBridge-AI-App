// lib/screens/profile_input.dart — SkillBridge AI

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'cv_upload_screen.dart';
import 'privacy_settings_screen.dart';
import 'skill_gap.dart';
import '../ml/recommender.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────
class _Pal {
  static const blue500 = Color(0xFF1E88E5);
  static const blue700 = Color(0xFF1565C0);
  static const green500 = Color(0xFF22C55E);
  static const green600 = Color(0xFF16A34A);
  static const red400 = Color(0xFFF87171);
  static const red500 = Color(0xFFEF4444);
  static const amber400 = Color(0xFFFBBF24);
  static const amber500 = Color(0xFFF59E0B);
  static const slate900 = Color(0xFF0F172A);
  static const slate800 = Color(0xFF1E293B);
  static const slate700 = Color(0xFF334155);
  static const slate600 = Color(0xFF475569);
  static const slate500 = Color(0xFF64748B);
  static const slate400 = Color(0xFF94A3B8);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate50 = Color(0xFFF8FAFC);
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool isDark;
  const _SectionHeader({
    required this.title,
    this.actionLabel = '',
    this.onAction,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : _Pal.slate900;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        if (actionLabel.isNotEmpty && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SkillChip({required this.label, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────
class ProfileInputScreen extends StatefulWidget {
  const ProfileInputScreen({super.key});

  @override
  State<ProfileInputScreen> createState() => _ProfileInputScreenState();
}

class _ProfileInputScreenState extends State<ProfileInputScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fieldCtrl = TextEditingController();
  final _gpaCtrl = TextEditingController();
  final _careerGoalCtrl = TextEditingController();

  int _yearOfStudy = 1;
  String _expLevel = 'No Experience';
  double _gpaValue = 0.0;
  bool _saving = false;
  bool _saved = false;

  File? _profilePhoto;
  String? _displayName;
  String? _displayEmail;
  String? _displayInstitution;

  late final AnimationController _entranceCtrl;
  late final AnimationController _btnCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _progressCtrl;
  late final Animation<double> _progressAnim;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _btnScaleAnim;
  late final List<Animation<double>> _cardFade;
  late final List<Animation<Offset>> _cardSlide;

  static const _expOptions = [
    'No Experience',
    'Internship',
    'Part-time',
    'Full-time',
  ];
  static const Map<String, IconData> _expIcons = {
    'No Experience': Icons.person_outline_rounded,
    'Internship': Icons.co_present_rounded,
    'Part-time': Icons.schedule_rounded,
    'Full-time': Icons.work_rounded,
  };
  static const Map<String, Color> _expColors = {
    'No Experience': Color(0xFF1E88E5),
    'Internship': Color(0xFF0EA5E9),
    'Part-time': Color(0xFF6366F1),
    'Full-time': Color(0xFF22C55E),
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedState();
      _loadRegistrationData();
      _entranceCtrl.forward();
      _progressCtrl.forward();
      _pulseCtrl.repeat(reverse: true);
    });
  }

  void _setupAnimations() {
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardFade = List.generate(4, (i) {
      final start = (i * 0.15).clamp(0.0, 1.0);
      final end = (start + 0.55).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _entranceCtrl,
            curve: Interval(start, end, curve: Curves.easeOut)),
      );
    });
    _cardSlide = List.generate(4, (i) {
      final start = (i * 0.15).clamp(0.0, 1.0);
      final end = (start + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _entranceCtrl,
              curve: Interval(start, end, curve: Curves.easeOutCubic)));
    });
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _progressAnim = Tween<double>(begin: 0, end: 2 / 3)
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _btnScaleAnim = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn));
  }

  void _loadSavedState() {
    final s = context.read<AppState>();
    _fieldCtrl.text = s.fieldOfStudy;
    _gpaCtrl.text = s.gpa > 0 ? s.gpa.toStringAsFixed(1) : '';
    _careerGoalCtrl.text = s.careerGoal;
    if (s.yearOfStudy >= 1 && s.yearOfStudy <= 5) {
      setState(() => _yearOfStudy = s.yearOfStudy);
    }
    if (s.experienceLevel.isNotEmpty) {
      final match = _expOptions.firstWhere(
        (o) => o.toLowerCase() == s.experienceLevel.toLowerCase(),
        orElse: () => 'No Experience',
      );
      setState(() => _expLevel = match);
    }
    _gpaCtrl.addListener(() {
      final v = double.tryParse(_gpaCtrl.text.trim()) ?? 0.0;
      setState(() => _gpaValue = v.clamp(0.0, 4.0));
    });
  }

  Future<void> _loadRegistrationData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('registeredName') ?? '';
    final email = prefs.getString('registeredEmail') ?? '';
    final institution = prefs.getString('registeredInstitution') ?? '';
    final photoPath = prefs.getString('profileImagePath') ?? '';

    File? photo;
    if (photoPath.isNotEmpty) {
      final f = File(photoPath);
      if (await f.exists()) photo = f;
    }

    if (!mounted) return;
    setState(() {
      _displayName = name.isNotEmpty ? name : null;
      _displayEmail = email.isNotEmpty ? email : null;
      _displayInstitution = institution.isNotEmpty ? institution : null;
      _profilePhoto = photo;
    });
  }

  Future<void> _pickPhoto() async {
    HapticFeedback.lightImpact();
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;
    final file = File(picked.path);
    if (!await file.exists()) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', picked.path);
    if (!mounted) return;
    setState(() => _profilePhoto = file);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text('Profile photo updated!',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: _Pal.green600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Edit profile information (name, email, institution)
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _editProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final nameController = TextEditingController(text: _displayName ?? '');
    final institutionController =
        TextEditingController(text: _displayInstitution ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: institutionController,
                decoration: const InputDecoration(labelText: 'Institution'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'name': nameController.text.trim(),
                'institution': institutionController.text.trim(),
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      // Persist to SharedPreferences (email is intentionally not updated)
      await prefs.setString('registeredName', result['name']!);
      await prefs.setString('registeredInstitution', result['institution']!);

      // Update local display state — email remains unchanged
      setState(() {
        _displayName = result['name']!;
        _displayInstitution = result['institution']!;
      });

      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Profile updated',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: _Pal.green600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fieldCtrl.dispose();
    _gpaCtrl.dispose();
    _careerGoalCtrl.dispose();
    _entranceCtrl.dispose();
    _btnCtrl.dispose();
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.lightImpact();
    final appState = context.read<AppState>();
    await _btnCtrl.forward();
    await _btnCtrl.reverse();
    setState(() => _saving = true);
    final gpa = double.tryParse(_gpaCtrl.text.trim()) ?? 0.0;
    await appState.setProfileInfo(
      fieldOfStudy: _fieldCtrl.text.trim(),
      gpa: gpa,
      experienceLevel: _expLevel,
      yearOfStudy: _yearOfStudy,
      careerGoal: _careerGoalCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text('Profile saved successfully!',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: _Pal.green600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    Navigator.pop(context);
  }

  // ── Achievement unlock logic ─────────────────────────────────────────────
  bool _isFirstApplyUnlocked(AppState s) =>
      s.jobApplications.isNotEmpty || s.activeApplicationCount > 0;

  bool _isCvUploadedUnlocked(AppState s) => s.cvUploaded;

  bool _isStreakUnlocked(AppState s) => s.learningStreak >= 5;

  bool _isHighMatchUnlocked(AppState s) => s.computeReadinessScore() >= 90;

  bool _isCourseUnlocked(AppState s) => s.completedCount > 0;

  // ── Profile completeness ──────────────────────────────────────────────────
  double _computeCompleteness(AppState s) {
    double score = 0.0;
    if (_displayName?.isNotEmpty == true) score += 0.15;
    if (_displayEmail?.isNotEmpty == true) score += 0.10;
    if (s.fieldOfStudy.isNotEmpty) score += 0.15;
    if (s.careerGoal.isNotEmpty) score += 0.15;
    if (s.gpa > 0) score += 0.10;
    if (s.userSkills.isNotEmpty) score += 0.20;
    if (s.cvUploaded) score += 0.15;
    return score.clamp(0.0, 1.0);
  }

  String _completenessHint(double v) {
    if (v >= 1.0) return 'Profile is complete! 🎉';
    if (v >= 0.8) return 'Almost there — upload your CV to finish';
    if (v >= 0.6) return 'Add skills or career goal to improve';
    if (v >= 0.4) return 'Upload your CV to boost your score';
    return 'Fill in your field of study and career goal';
  }

  Future<void> _navigateToSkillGap(AppState appState) async {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final List<JobRecommendation> jobs = recommendJobs(
        appState.userSkills,
        profile: null,
        config: const RecommendationConfig(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      if (jobs.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SkillGapScreen(
              job: jobs.first,
              userSkills: appState.userSkills,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No job recommendations available. Please update your profile.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load recommendations: $e'),
          backgroundColor: _Pal.red500,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? _Pal.slate900 : _Pal.slate50;
    final textColor = isDark ? Colors.white : _Pal.slate900;
    final subColor = isDark ? _Pal.slate400 : _Pal.slate600;
    final borderColor = isDark ? _Pal.slate700 : _Pal.slate200;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(isDark, bgColor, textColor, borderColor),
      bottomNavigationBar: _buildBottomBar(isDark, bgColor, borderColor),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: _buildScrollBody(
              isDark, textColor, subColor, borderColor, appState),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ══════════════════════════════════════════════════════════════════════════
  PreferredSizeWidget _buildAppBar(
      bool isDark, Color bg, Color text, Color border) {
    return AppBar(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle:
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: text),
        tooltip: 'Back',
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_Pal.blue500, _Pal.blue700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text('My Profile',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: text)),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.shield_rounded, size: 24, color: text),
          tooltip: 'Privacy & Data',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PrivacySettingsScreen())),
        ),
        ScaleTransition(
          scale: _pulseAnim,
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(colors: [_Pal.blue500, _Pal.blue700]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _Pal.blue500.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: const Text('Step 2 / 3',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.4)),
          ),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: AnimatedBuilder(
          animation: _progressAnim,
          builder: (_, __) => Stack(children: [
            Container(height: 4, color: isDark ? _Pal.slate700 : _Pal.slate200),
            FractionallySizedBox(
              widthFactor: _progressAnim.value,
              child: Container(
                height: 4,
                decoration: const BoxDecoration(
                  gradient:
                      LinearGradient(colors: [_Pal.blue500, _Pal.blue700]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BOTTOM BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBottomBar(bool isDark, Color bg, Color border) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? _Pal.slate800.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      child: ScaleTransition(
        scale: _btnScaleAnim,
        child: _SaveButton(saving: _saving, saved: _saved, onTap: _save),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SCROLL BODY
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildScrollBody(
      bool isDark, Color text, Color sub, Color border, AppState appState) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildProfileHeader(isDark, text, sub),
        const SizedBox(height: 20),
        _buildProfileDisplayCard(isDark, text, sub, border, appState),
        const SizedBox(height: 16),
        _buildStatsRow(isDark, appState),
        const SizedBox(height: 16),
        _buildAchievementsSection(isDark, text, appState),
        const SizedBox(height: 16),
        _buildMySkillsSection(isDark, text, sub, appState),
        const SizedBox(height: 16),
        _buildAnimatedCard(
          index: 0,
          child: _AcademicCard(
            isDark: isDark,
            textColor: text,
            subColor: sub,
            borderColor: border,
            fieldCtrl: _fieldCtrl,
            gpaCtrl: _gpaCtrl,
            gpaValue: _gpaValue,
            yearOfStudy: _yearOfStudy,
            onYearTap: (yr) => setState(() => _yearOfStudy = yr),
            inputDec: _inputDec,
          ),
        ),
        const SizedBox(height: 16),
        _buildAnimatedCard(
          index: 1,
          child: _CareerCard(
            isDark: isDark,
            textColor: text,
            subColor: sub,
            borderColor: border,
            careerCtrl: _careerGoalCtrl,
            expLevel: _expLevel,
            expOptions: _expOptions,
            expIcons: _expIcons,
            expColors: _expColors,
            onExpTap: (opt) => setState(() => _expLevel = opt),
            inputDec: _inputDec,
          ),
        ),
        const SizedBox(height: 16),
        _buildAnimatedCard(
          index: 2,
          child: _TipsCard(isDark: isDark, subColor: sub),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROFILE HEADER HERO
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildProfileHeader(bool isDark, Color text, Color sub) {
    return FadeTransition(
      opacity: _cardFade[0],
      child: SlideTransition(
        position: _cardSlide[0],
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_Pal.blue500, _Pal.blue700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _Pal.blue500.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tell us about yourself',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: text,
                      letterSpacing: -0.3)),
              const SizedBox(height: 3),
              Text('Your profile powers AI-matched skills & goals',
                  style: TextStyle(fontSize: 12.5, color: sub, height: 1.4)),
            ],
          )),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROFILE DISPLAY CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildProfileDisplayCard(bool isDark, Color textColor, Color subColor,
      Color borderColor, AppState appState) {
    final name = _displayName ?? appState.userName;
    final email = _displayEmail ?? appState.userEmail;
    final institution = _displayInstitution ?? '';
    final careerGoal =
        appState.careerGoal.isNotEmpty ? appState.careerGoal : 'Not set yet';
    final completeness = _computeCompleteness(appState);

    final initials = name.trim().isEmpty
        ? 'U'
        : name
            .trim()
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase();

    final cardColor = isDark ? _Pal.slate800 : Colors.white;
    final divColor = isDark ? _Pal.slate700 : const Color(0xFFE2E8F0);
    final hintBg = isDark ? _Pal.slate900 : const Color(0xFFF8FAFC);

    return FadeTransition(
      opacity: _cardFade[0],
      child: SlideTransition(
        position: _cardSlide[0],
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(children: [
            // ── Edit button row ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_rounded,
                      color: isDark ? _Pal.slate300 : _Pal.slate600, size: 20),
                  tooltip: 'Edit personal info',
                  onPressed: _editProfile,
                ),
              ],
            ),
            // ── Avatar + details row ───────────────────────────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: _pickPhoto,
                child: Stack(children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: _profilePhoto == null
                          ? const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)])
                          : null,
                      color: _profilePhoto != null ? Colors.transparent : null,
                      borderRadius: BorderRadius.circular(16),
                      border: _profilePhoto != null
                          ? Border.all(color: AppTheme.primaryBlue, width: 2)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: _Pal.blue500.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _profilePhoto != null
                          ? Image.file(_profilePhoto!,
                              fit: BoxFit.cover,
                              width: 64,
                              height: 64,
                              errorBuilder: (_, __, ___) =>
                                  _initialsWidget(initials))
                          : _initialsWidget(initials),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: AppTheme.primaryBlue, shape: BoxShape.circle),
                      child:
                          const Icon(Icons.edit, color: Colors.white, size: 10),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isNotEmpty ? name : 'Your Name',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : _Pal.slate900)),
                  if (email.isNotEmpty)
                    Text(email,
                        style: TextStyle(fontSize: 12, color: subColor)),
                  const SizedBox(height: 4),
                  if (institution.isNotEmpty)
                    Row(children: [
                      Icon(Icons.school_outlined,
                          size: 12, color: AppTheme.primaryBlue),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(institution,
                              style: TextStyle(fontSize: 11, color: subColor),
                              overflow: TextOverflow.ellipsis)),
                    ]),
                  if (appState.fieldOfStudy.isNotEmpty)
                    Row(children: [
                      Icon(Icons.auto_stories_rounded,
                          size: 12, color: subColor),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(appState.fieldOfStudy,
                              style: TextStyle(fontSize: 11, color: subColor),
                              overflow: TextOverflow.ellipsis)),
                    ]),
                ],
              )),
            ]),
            const SizedBox(height: 14),
            Divider(color: divColor),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hintBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: divColor),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Career Goal',
                        style: TextStyle(fontSize: 11, color: subColor)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Text(' '),
                      Expanded(
                          child: Text(careerGoal,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryBlue))),
                    ]),
                  ]),
            ),
            const SizedBox(height: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Profile Completeness',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? _Pal.slate300 : _Pal.slate600)),
                Text('${(completeness * 100).toInt()}%',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: completeness),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (_, val, __) => LinearProgressIndicator(
                    value: val,
                    minHeight: 7,
                    backgroundColor:
                        isDark ? _Pal.slate700 : const Color(0xFFE2E8F0),
                    valueColor:
                        const AlwaysStoppedAnimation(AppTheme.primaryBlue),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(_completenessHint(completeness),
                  style: TextStyle(fontSize: 11, color: subColor)),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CvUploadScreen()),
                  ).then((_) {
                    if (mounted) setState(() {});
                  });
                },
                icon: const Icon(Icons.upload_outlined, size: 18),
                label: Text(
                  appState.cvUploaded ? 'Update CV' : 'Upload CV',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: BorderSide(
                      color: appState.cvUploaded
                          ? AppTheme.accentGreen
                          : AppTheme.primaryBlue),
                  foregroundColor: appState.cvUploaded
                      ? AppTheme.accentGreen
                      : AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _initialsWidget(String initials) => Container(
        color: Colors.transparent,
        child: Center(
          child: Text(initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
        ),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // STATS ROW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsRow(bool isDark, AppState appState) {
    final matchScore = appState.computeReadinessScore();
    final items = [
      ('$matchScore%', 'Match Score', AppTheme.primaryBlue),
      (
        '${appState.activeApplicationCount}',
        'Jobs Applied',
        AppTheme.accentGreen
      ),
      (
        '${appState.userSkills.length}',
        'Skills Added',
        const Color(0xFFEA580C)
      ),
    ];
    return FadeTransition(
      opacity: _cardFade[1],
      child: SlideTransition(
        position: _cardSlide[1],
        child: Row(
          children: items.asMap().entries.map((e) {
            final item = e.value;
            return Expanded(
                child: _buildStatItem(item.$1, item.$2, item.$3, isDark,
                    isLast: e.key == items.length - 1));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color, bool isDark,
      {bool isLast = false}) {
    final cardColor = isDark ? _Pal.slate800 : Colors.white;
    final borderColor = isDark ? _Pal.slate700 : const Color(0xFFE2E8F0);
    return Container(
      margin: EdgeInsets.only(right: isLast ? 0 : 8),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: isDark ? _Pal.slate400 : _Pal.slate500),
            textAlign: TextAlign.center),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACHIEVEMENTS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAchievementsSection(
      bool isDark, Color textColor, AppState appState) {
    final cardColor = isDark ? _Pal.slate800 : Colors.white;
    final borderColor = isDark ? _Pal.slate700 : const Color(0xFFE2E8F0);
    final headerColor = isDark ? Colors.white : _Pal.slate900;

    final achievements = [
      _AchievementData(
        emoji: '🎯',
        label: 'First\nApply',
        unlocked: _isFirstApplyUnlocked(appState),
        hint: 'Apply to your first job',
        color: _Pal.blue500,
      ),
      _AchievementData(
        emoji: '📄',
        label: 'CV\nUploaded',
        unlocked: _isCvUploadedUnlocked(appState),
        hint: 'Upload your CV',
        color: _Pal.green500,
      ),
      _AchievementData(
        emoji: '🔥',
        label: '5 Day\nStreak',
        unlocked: _isStreakUnlocked(appState),
        hint: 'Login 5 days in a row',
        color: const Color(0xFFEA580C),
      ),
      _AchievementData(
        emoji: '⭐',
        label: '90%\nMatch',
        unlocked: _isHighMatchUnlocked(appState),
        hint: 'Reach 90% readiness',
        color: _Pal.amber500,
      ),
      _AchievementData(
        emoji: '🎓',
        label: 'Course\nDone',
        unlocked: _isCourseUnlocked(appState),
        hint: 'Complete a course',
        color: const Color(0xFF8B5CF6),
      ),
    ];

    final unlockedCount = achievements.where((a) => a.unlocked).length;

    return FadeTransition(
      opacity: _cardFade[2],
      child: SlideTransition(
        position: _cardSlide[2],
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Achievements',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: headerColor)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _Pal.amber400.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: _Pal.amber400.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Text(
                    '$unlockedCount/${achievements.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _Pal.amber500,
                    ),
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: unlockedCount / achievements.length,
                minHeight: 5,
                backgroundColor: isDark ? _Pal.slate700 : _Pal.slate100,
                valueColor: const AlwaysStoppedAnimation(_Pal.amber400),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              unlockedCount == achievements.length
                  ? 'All achievements unlocked! '
                  : '$unlockedCount of ${achievements.length} achievements unlocked',
              style: TextStyle(
                  fontSize: 11, color: isDark ? _Pal.slate400 : _Pal.slate500),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: achievements
                  .map((a) => _AchievementBadge(data: a, isDark: isDark))
                  .toList(),
            ),
            if (unlockedCount < achievements.length) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? _Pal.slate700.withValues(alpha: 0.4)
                      : _Pal.slate100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: isDark ? _Pal.slate400 : _Pal.slate500),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                    _nextAchievementHint(achievements),
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? _Pal.slate400 : _Pal.slate500),
                  )),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  String _nextAchievementHint(List<_AchievementData> achievements) {
    final next = achievements.firstWhere(
      (a) => !a.unlocked,
      orElse: () => achievements.first,
    );
    return 'Next: ${next.hint}';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MY SKILLS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMySkillsSection(
      bool isDark, Color textColor, Color subColor, AppState appState) {
    final cardColor = isDark ? _Pal.slate800 : Colors.white;
    final borderColor = isDark ? _Pal.slate700 : const Color(0xFFE2E8F0);
    final skills = appState.userSkills;

    return FadeTransition(
      opacity: _cardFade[3],
      child: SlideTransition(
        position: _cardSlide[3],
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SectionHeader(
              title: 'My Skills',
              actionLabel: 'View gap',
              isDark: isDark,
              onAction: () => _navigateToSkillGap(appState),
            ),
            const SizedBox(height: 12),
            if (skills.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                      : const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                    'No skills yet. Upload your CV or add skills in registration.',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? _Pal.slate300 : _Pal.slate600),
                  )),
                ]),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills
                    .take(12)
                    .map((s) => _SkillChip(
                        label: s[0].toUpperCase() + s.substring(1),
                        isDark: isDark))
                    .toList(),
              ),
            if (skills.length > 12)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('+${skills.length - 12} more',
                    style: TextStyle(
                        fontSize: 12,
                        color: subColor,
                        fontWeight: FontWeight.w500)),
              ),
          ]),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAnimatedCard({required int index, required Widget child}) {
    final i = index.clamp(0, _cardFade.length - 1);
    return FadeTransition(
      opacity: _cardFade[i],
      child: SlideTransition(position: _cardSlide[i], child: child),
    );
  }

  InputDecoration _inputDec(
    String label, {
    required IconData icon,
    required bool isDark,
    Color? iconColor,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon,
          size: 20,
          color: iconColor ?? (isDark ? _Pal.slate400 : _Pal.slate600)),
      filled: true,
      fillColor: isDark ? _Pal.slate900 : _Pal.slate50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? _Pal.slate700 : _Pal.slate200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _Pal.blue500, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _Pal.red500, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _Pal.red500, width: 2),
      ),
      labelStyle: TextStyle(
          color: isDark ? _Pal.slate400 : _Pal.slate600, fontSize: 14),
      hintStyle: TextStyle(
          color: isDark ? _Pal.slate600 : _Pal.slate400, fontSize: 14),
      errorStyle: const TextStyle(
          color: _Pal.red500, fontSize: 12, fontWeight: FontWeight.w500),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ACHIEVEMENT DATA MODEL
// ══════════════════════════════════════════════════════════════════════════════

class _AchievementData {
  final String emoji;
  final String label;
  final bool unlocked;
  final String hint;
  final Color color;

  const _AchievementData({
    required this.emoji,
    required this.label,
    required this.unlocked,
    required this.hint,
    required this.color,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// ACHIEVEMENT BADGE
// ══════════════════════════════════════════════════════════════════════════════

class _AchievementBadge extends StatefulWidget {
  final _AchievementData data;
  final bool isDark;

  const _AchievementBadge({required this.data, required this.isDark});

  @override
  State<_AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<_AchievementBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _shimmerAnim =
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut);
    if (widget.data.unlocked) {
      _shimmerCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_AchievementBadge old) {
    super.didUpdateWidget(old);
    if (widget.data.unlocked && !_shimmerCtrl.isAnimating) {
      _shimmerCtrl.repeat(reverse: true);
    } else if (!widget.data.unlocked && _shimmerCtrl.isAnimating) {
      _shimmerCtrl.stop();
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.data.unlocked;
    final color = widget.data.color;
    final isDark = widget.isDark;

    final ringColor =
        unlocked ? color : (isDark ? _Pal.slate600 : _Pal.slate300);

    final bgColor = unlocked
        ? color.withValues(alpha: isDark ? 0.18 : 0.12)
        : (isDark ? _Pal.slate700.withValues(alpha: 0.5) : _Pal.slate100);

    final labelColor =
        unlocked ? color : (isDark ? _Pal.slate500 : _Pal.slate400);

    return Tooltip(
      message: widget.data.hint,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _shimmerAnim,
            builder: (_, child) {
              return Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: unlocked
                        ? Color.lerp(ringColor, color.withValues(alpha: 0.4),
                            _shimmerAnim.value)!
                        : ringColor,
                    width: unlocked ? 2.5 : 1.5,
                  ),
                  boxShadow: unlocked
                      ? [
                          BoxShadow(
                            color: color.withValues(
                                alpha: 0.25 + 0.15 * _shimmerAnim.value),
                            blurRadius: 10 + 6 * _shimmerAnim.value,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: child,
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: unlocked ? 1.0 : 0.28,
                  child: Text(
                    widget.data.emoji,
                    style: TextStyle(fontSize: unlocked ? 28 : 24),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: unlocked
                        ? Container(
                            key: const ValueKey('unlocked'),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _Pal.green500,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? _Pal.slate800 : Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _Pal.green500.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                          )
                        : Container(
                            key: const ValueKey('locked'),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isDark ? _Pal.slate600 : _Pal.slate300,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? _Pal.slate800 : Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              size: 9,
                              color: isDark ? _Pal.slate400 : _Pal.slate500,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: 58,
            child: Text(
              widget.data.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: unlocked ? FontWeight.w700 : FontWeight.w500,
                color: labelColor,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 3),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: unlocked ? 1.0 : 0.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: _Pal.green500.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '✓ Done',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: _Pal.green500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Card Shell
// ─────────────────────────────────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.isDark,
    required this.child,
    this.accentColor = _Pal.blue500,
  });
  final bool isDark;
  final Widget child;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? _Pal.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color:
                isDark ? _Pal.slate700.withValues(alpha: 0.6) : _Pal.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  accentColor.withValues(alpha: 0.0),
                  accentColor.withValues(alpha: 0.8),
                  accentColor.withValues(alpha: 0.0),
                ]),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header inside cards
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeaderLocal extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color textColor;
  final Color accentColor;
  const _SectionHeaderLocal({
    required this.icon,
    required this.title,
    required this.textColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: accentColor, size: 18),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.2)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Academic Card
// ─────────────────────────────────────────────────────────────────────────────
class _AcademicCard extends StatelessWidget {
  const _AcademicCard({
    required this.isDark,
    required this.textColor,
    required this.subColor,
    required this.borderColor,
    required this.fieldCtrl,
    required this.gpaCtrl,
    required this.gpaValue,
    required this.yearOfStudy,
    required this.onYearTap,
    required this.inputDec,
  });
  final bool isDark;
  final Color textColor, subColor, borderColor;
  final TextEditingController fieldCtrl, gpaCtrl;
  final double gpaValue;
  final int yearOfStudy;
  final ValueChanged<int> onYearTap;
  final InputDecoration Function(String,
      {required IconData icon,
      required bool isDark,
      Color? iconColor,
      String? hint}) inputDec;

  Color get _gpaColor {
    if (gpaValue >= 3.5) return _Pal.green500;
    if (gpaValue >= 2.5) return _Pal.amber400;
    return _Pal.red400;
  }

  String get _gpaLabel {
    if (gpaValue >= 3.7) return 'Excellent';
    if (gpaValue >= 3.3) return 'Great';
    if (gpaValue >= 2.7) return 'Good';
    if (gpaValue > 0) return 'Fair';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      isDark: isDark,
      accentColor: _Pal.blue500,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHeaderLocal(
            icon: Icons.school_rounded,
            title: 'Academic Background',
            textColor: textColor,
            accentColor: _Pal.blue500),
        Divider(color: isDark ? _Pal.slate700 : _Pal.slate100, height: 28),
        TextFormField(
          controller: fieldCtrl,
          style: TextStyle(
              color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: inputDec('Field of Study',
              icon: Icons.auto_stories_rounded,
              isDark: isDark,
              hint: 'e.g. Information Technology'),
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Please enter your field of study'
              : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: gpaCtrl,
          style: TextStyle(
              color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: inputDec('CGPA  (0.0 – 4.0)',
              icon: Icons.grade_rounded, isDark: isDark, hint: '3.5'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            final g = double.tryParse(v.trim());
            if (g == null || g < 0 || g > 4.0) {
              return 'Enter a valid CGPA between 0.0 and 4.0';
            }
            return null;
          },
        ),
        if (gpaValue > 0) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (gpaValue / 4.0).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: isDark ? _Pal.slate700 : _Pal.slate100,
                valueColor: AlwaysStoppedAnimation<Color>(_gpaColor),
              ),
            )),
            const SizedBox(width: 10),
            Text(_gpaLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _gpaColor,
                    letterSpacing: 0.3)),
          ]),
        ],
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Year of Study',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: subColor)),
          _YearBadge(year: yearOfStudy),
        ]),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final yr = i + 1;
            final sel = yearOfStudy == yr;
            return _YearChip(
              year: yr,
              selected: sel,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                onYearTap(yr);
              },
            );
          }),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Year Chip + Badge
// ─────────────────────────────────────────────────────────────────────────────
class _YearChip extends StatefulWidget {
  const _YearChip(
      {required this.year,
      required this.selected,
      required this.isDark,
      required this.onTap});
  final int year;
  final bool selected, isDark;
  final VoidCallback onTap;

  @override
  State<_YearChip> createState() => _YearChipState();
}

class _YearChipState extends State<_YearChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    await _ctrl.forward();
    await _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    return GestureDetector(
      onTap: _tap,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: sel
                ? const LinearGradient(
                    colors: [_Pal.blue500, _Pal.blue700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: sel ? null : (widget.isDark ? _Pal.slate900 : Colors.white),
            border: sel
                ? null
                : Border.all(
                    color: widget.isDark ? _Pal.slate700 : _Pal.slate200,
                    width: 1.5,
                  ),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: _Pal.blue500.withValues(alpha: 0.42),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Center(
              child: Text('${widget.year}',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: sel
                          ? Colors.white
                          : (widget.isDark ? _Pal.slate400 : _Pal.slate600)))),
        ),
      ),
    );
  }
}

class _YearBadge extends StatelessWidget {
  const _YearBadge({required this.year});
  final int year;
  static const _suffixes = ['st', 'nd', 'rd', 'th', 'th'];

  String get _label {
    final s = _suffixes[(year - 1).clamp(0, 4)];
    return '$year$s Year';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: Container(
        key: ValueKey(year),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _Pal.blue500.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(_label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _Pal.blue500)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Career Card
// ─────────────────────────────────────────────────────────────────────────────
class _CareerCard extends StatelessWidget {
  const _CareerCard({
    required this.isDark,
    required this.textColor,
    required this.subColor,
    required this.borderColor,
    required this.careerCtrl,
    required this.expLevel,
    required this.expOptions,
    required this.expIcons,
    required this.expColors,
    required this.onExpTap,
    required this.inputDec,
  });
  final bool isDark;
  final Color textColor, subColor, borderColor;
  final TextEditingController careerCtrl;
  final String expLevel;
  final List<String> expOptions;
  final Map<String, IconData> expIcons;
  final Map<String, Color> expColors;
  final ValueChanged<String> onExpTap;
  final InputDecoration Function(String,
      {required IconData icon,
      required bool isDark,
      Color? iconColor,
      String? hint}) inputDec;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      isDark: isDark,
      accentColor: _Pal.green500,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHeaderLocal(
            icon: Icons.rocket_launch_rounded,
            title: 'Career Goal',
            textColor: textColor,
            accentColor: _Pal.green500),
        Divider(color: isDark ? _Pal.slate700 : _Pal.slate100, height: 28),
        TextFormField(
          controller: careerCtrl,
          style: TextStyle(
              color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: inputDec('Dream job title',
              icon: Icons.work_outline_rounded,
              isDark: isDark,
              hint: 'e.g. Senior Software Engineer'),
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Experience Level',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: subColor)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Container(
              key: ValueKey(expLevel),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (expColors[expLevel] ?? _Pal.blue500)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(expLevel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: expColors[expLevel] ?? _Pal.blue500)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.5,
          children: expOptions.map((opt) {
            final sel = expLevel == opt;
            final color = expColors[opt] ?? _Pal.blue500;
            return _ExpChip(
              label: opt,
              icon: expIcons[opt] ?? Icons.work_outline_rounded,
              color: color,
              isDark: isDark,
              selected: sel,
              onTap: () {
                HapticFeedback.selectionClick();
                onExpTap(opt);
              },
            );
          }).toList(),
        ),
      ]),
    );
  }
}

class _ExpChip extends StatefulWidget {
  const _ExpChip(
      {required this.label,
      required this.icon,
      required this.color,
      required this.isDark,
      required this.selected,
      required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark, selected;
  final VoidCallback onTap;

  @override
  State<_ExpChip> createState() => _ExpChipState();
}

class _ExpChipState extends State<_ExpChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    await _ctrl.forward();
    await _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    final color = widget.color;
    return GestureDetector(
      onTap: _tap,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: sel
                ? color.withValues(alpha: 0.12)
                : (widget.isDark ? _Pal.slate900 : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  sel ? color : (widget.isDark ? _Pal.slate700 : _Pal.slate200),
              width: sel ? 2 : 1,
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: sel ? color.withValues(alpha: 0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.icon,
                  color: sel
                      ? color
                      : (widget.isDark ? _Pal.slate400 : _Pal.slate500),
                  size: 17),
            ),
            const SizedBox(width: 7),
            Flexible(
                child: Text(widget.label,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
                        color: sel
                            ? color
                            : (widget.isDark ? _Pal.slate300 : _Pal.slate700)),
                    overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tips Card
// ─────────────────────────────────────────────────────────────────────────────
class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.isDark, required this.subColor});
  final bool isDark;
  final Color subColor;

  static const _tips = [
    (Icons.bolt_rounded, 'Accurate data improves AI skill recommendations'),
    (
      Icons.trending_up_rounded,
      'Update your profile as you progress each year'
    ),
    (Icons.star_rounded, 'Add a career goal to unlock personalised roadmaps'),
  ];

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      isDark: isDark,
      accentColor: _Pal.amber400,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.lightbulb_rounded, color: _Pal.amber400, size: 18),
          SizedBox(width: 8),
          Text('Pro Tips',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _Pal.amber400,
                  letterSpacing: 0.2)),
        ]),
        const SizedBox(height: 14),
        ..._tips.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(t.$1,
                    size: 15, color: isDark ? _Pal.slate400 : _Pal.slate500),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(t.$2,
                        style: TextStyle(
                            fontSize: 12.5, color: subColor, height: 1.45))),
              ]),
            )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Save Button
// ─────────────────────────────────────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  const _SaveButton(
      {required this.saving, required this.saved, required this.onTap});
  final bool saving, saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: saved
                ? [_Pal.green500, _Pal.green600]
                : [_Pal.blue500, _Pal.blue700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (saved ? _Pal.green500 : _Pal.blue500)
                  .withValues(alpha: 0.38),
              blurRadius: 16,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: ElevatedButton(
          onPressed: (saving || saved) ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: saving
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : saved
                    ? const Row(
                        key: ValueKey('saved'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            Icon(Icons.check_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Saved!',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ])
                    : const Row(
                        key: ValueKey('idle'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            Icon(Icons.save_rounded,
                                color: Colors.white, size: 19),
                            SizedBox(width: 8),
                            Text('Save Profile',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3)),
                          ]),
          ),
        ),
      ),
    );
  }
}
