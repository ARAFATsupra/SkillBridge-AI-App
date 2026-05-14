// lib/screens/auth/chatbot_screen.dart  —  SkillBridge AI

import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:skillbridge_ai/services/gemini_chat_service.dart';

// ── Compile-time API key ──────────────────────────────────────────────────────
const String _geminiApiKey =
    String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

// ═════════════════════════════════════════════════════════════════════════════
// CV TEXT EXTRACTOR  (NEW)
// ═════════════════════════════════════════════════════════════════════════════

/// Extracts readable text from PDF, DOCX, DOC, and TXT files.
/// Returns null if extraction fails or produces insufficient text.
class _CvTextExtractor {
  static const int _minViableLength = 80;

  static Future<String?> extract(Uint8List bytes, String filename) async {
    final ext = filename.toLowerCase().split('.').last.trim();
    switch (ext) {
      case 'txt':
        return _fromTxt(bytes);
      case 'pdf':
        return _fromPdf(bytes);
      case 'docx':
        return await _fromDocx(bytes);
      case 'doc':
        return _fromDoc(bytes);
      default:
        return null;
    }
  }

  // ── TXT ─────────────────────────────────────────────────────────────────
  static String? _fromTxt(Uint8List bytes) {
    try {
      final text = utf8.decode(bytes, allowMalformed: true).trim();
      return text.length >= _minViableLength ? text : null;
    } catch (_) {
      return null;
    }
  }

  // ── PDF (syncfusion_flutter_pdf) ─────────────────────────────────────────
  static String? _fromPdf(Uint8List bytes) {
    try {
      final PdfDocument doc = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(doc);
      final String raw = extractor.extractText();
      doc.dispose();

      // Clean up extracted text
      final cleaned = raw
          .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();

      return cleaned.length >= _minViableLength ? cleaned : null;
    } catch (e) {
      debugPrint('[CvExtractor] PDF error: $e');
      return null;
    }
  }

  // ── DOCX (ZIP → word/document.xml) ──────────────────────────────────────
  static Future<String?> _fromDocx(Uint8List bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final xmlFile = archive.findFile('word/document.xml');
      if (xmlFile == null) return null;

      final xml = utf8.decode(xmlFile.content as List<int>);
      final text = xml
          .replaceAll(RegExp(r'<w:p[ />]'), '\n') // paragraph breaks
          .replaceAll(RegExp(r'<w:br[^/]*/?>'), '\n') // line breaks
          .replaceAll(RegExp(r'<[^>]+>'), '') // strip all tags
          .replaceAll(RegExp(r'&amp;'), '&')
          .replaceAll(RegExp(r'&lt;'), '<')
          .replaceAll(RegExp(r'&gt;'), '>')
          .replaceAll(RegExp(r'&quot;'), '"')
          .replaceAll(RegExp(r'&apos;'), "'")
          .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();

      return text.length >= _minViableLength ? text : null;
    } catch (e) {
      debugPrint('[CvExtractor] DOCX error: $e');
      return null;
    }
  }

  // ── DOC (legacy binary — printable ASCII extraction) ────────────────────
  static String? _fromDoc(Uint8List bytes) {
    try {
      final chars = bytes
          .where((b) => (b >= 32 && b < 127) || b == 10 || b == 13)
          .map((b) => String.fromCharCode(b))
          .join();
      final cleaned = chars
          .replaceAll(RegExp(r'[^\w\s@.,;:/()\-+]'), ' ')
          .replaceAll(RegExp(r'\s{3,}'), ' ')
          .trim();
      return cleaned.length >= 200 ? cleaned : null;
    } catch (_) {
      return null;
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DATA LAYER — ChatbotContext & Flat Data Models
// ═════════════════════════════════════════════════════════════════════════════

class ChatbotContext {
  final String userName;
  final String currentRole;
  final String targetRole;
  final List<String> currentSkills;
  final List<String> missingSkills;
  final String location;
  final int experienceYears;
  final String educationLevel;
  final String? industryPreference;
  final String? extractedCvText;
  final String? cvFileName;
  final String? lifeAim; // ← NEW
  final List<ChatJobData> topJobMatches;
  final List<ChatCourseData> recommendedCourses;
  final List<ChatSkillGapData> skillGaps;
  final double? confidenceScore;
  final String? careerPathSummary;
  final int? totalApplications;
  final int? interviewsScheduled;
  final void Function(String screen, {Map<String, dynamic>? args})? navigateTo;

  const ChatbotContext({
    this.userName = '',
    this.currentRole = '',
    this.targetRole = '',
    this.currentSkills = const [],
    this.missingSkills = const [],
    this.location = 'Bangladesh',
    this.experienceYears = 0,
    this.educationLevel = '',
    this.industryPreference,
    this.extractedCvText,
    this.cvFileName,
    this.lifeAim, // ← NEW
    this.topJobMatches = const [],
    this.recommendedCourses = const [],
    this.skillGaps = const [],
    this.confidenceScore,
    this.careerPathSummary,
    this.totalApplications,
    this.interviewsScheduled,
    this.navigateTo,
  });

  bool get hasProfile => currentRole.isNotEmpty || userName.isNotEmpty;
  bool get hasCv => extractedCvText != null && extractedCvText!.isNotEmpty;
  bool get hasJobs => topJobMatches.isNotEmpty;
  bool get hasCourses => recommendedCourses.isNotEmpty;
  bool get hasSkillGap => skillGaps.isNotEmpty;

  /// Builds the system instruction sent with every Gemini request.
  /// [freshCvText] and [freshLifeAim] override stored values for that request.
  String buildSystemInstruction({
    String? freshCvText,
    String? freshLifeAim,
    String? freshTargetRole,
  }) {
    final cv = freshCvText ?? extractedCvText;
    final aim = freshLifeAim ?? lifeAim;
    final role =
        (freshTargetRole?.isNotEmpty == true) ? freshTargetRole! : targetRole;
    final sb = StringBuffer();

    sb.writeln('''
You are SkillBridge AI, an expert career assistant embedded in a Flutter app for Bangladeshi job seekers, aligned with UN SDG 8 (Decent Work and Economic Growth).

COMMUNICATION RULES:
- Write in plain, warm, conversational text only — absolutely no markdown, asterisks, or bullet symbols.
- Be specific, personal, and action-oriented. Ideal responses: 2–6 sentences.
- Reference the user's profile, CV content, job role, and life aim naturally.
- For detailed card results (jobs, courses, skill gaps), tell the user to tap quick-reply buttons.
- When the user asks to navigate, respond: "Opening [Screen] for you now."
- Salary figures in BDT unless asked otherwise.
- Know the Bangladeshi market: bKash, Chaldal, Pathao, Grameenphone, BRAC, Shohoz, 10 Minute School, etc.
''');

    if (hasProfile || role.isNotEmpty || aim != null) {
      sb.writeln('USER PROFILE:');
      if (userName.isNotEmpty) sb.writeln('Name: $userName');
      if (currentRole.isNotEmpty) sb.writeln('Current Role: $currentRole');
      if (role.isNotEmpty) sb.writeln('Target / Dream Role: $role');
      if (aim != null && aim.isNotEmpty) {
        sb.writeln('Life Aim / Goal: $aim');
      }
      if (location.isNotEmpty) sb.writeln('Location: $location');
      if (experienceYears > 0) sb.writeln('Experience: $experienceYears years');
      if (educationLevel.isNotEmpty) sb.writeln('Education: $educationLevel');
      if (industryPreference != null)
        sb.writeln('Industry Interest: $industryPreference');
      if (currentSkills.isNotEmpty) {
        sb.writeln('Current Skills: ${currentSkills.take(12).join(', ')}');
      }
      if (missingSkills.isNotEmpty) {
        sb.writeln(
            'Identified Skill Gaps: ${missingSkills.take(10).join(', ')}');
      }
      if (confidenceScore != null) {
        sb.writeln(
          'Career Confidence: ${(confidenceScore! * 100).toStringAsFixed(1)}% '
          '(${_confidenceLabel(confidenceScore!)})',
        );
      }
      if (careerPathSummary != null) {
        sb.writeln('Career Summary: $careerPathSummary');
      }
      if (totalApplications != null) {
        sb.writeln('Applications Sent: $totalApplications');
      }
      if (interviewsScheduled != null) {
        sb.writeln('Interviews Scheduled: $interviewsScheduled');
      }
      sb.writeln('');
    }

    if (cv != null && cv.isNotEmpty) {
      sb.writeln('UPLOADED CV (extracted text):');
      final snippet =
          cv.length > 3500 ? '${cv.substring(0, 3500)}\n[...truncated]' : cv;
      sb.writeln(snippet);
      sb.writeln('');
    }

    if (hasJobs) {
      sb.writeln('TOP JOB MATCHES:');
      for (final j in topJobMatches.take(5)) {
        sb.writeln(
            '${j.matchPct}% — ${j.title} at ${j.company}, ${j.location} (${j.salary})');
      }
      sb.writeln('');
    }

    if (hasCourses) {
      sb.writeln('RECOMMENDED COURSES:');
      for (final c in recommendedCourses.take(5)) {
        sb.writeln(
            '${c.title} by ${c.provider} — ${c.duration}, ⭐${c.rating}, ${c.format}');
      }
      sb.writeln('');
    }

    sb.writeln('''
NAVIGABLE SCREENS: jobs, courses, skillGap, careerGuide, confidence,
applications, cvUpload, profile, geoInsights, assessments, jobAlerts,
workforceInsights

SPECIALISATIONS: CV / resume review and rewriting, interview preparation,
salary negotiation, LinkedIn optimisation, career switching, skill-building
plans, job-search strategies, employer research, life-goal alignment.
''');

    return sb.toString();
  }

  static String _confidenceLabel(double score) {
    if (score >= 0.8) return 'High';
    if (score >= 0.6) return 'Moderate-High';
    if (score >= 0.4) return 'Moderate';
    return 'Needs Work';
  }
}

// ── Flat data transfer objects (unchanged) ────────────────────────────────────
class ChatJobData {
  final String id, title, company, location, salary;
  final int matchPct;
  final List<String> requiredSkills;
  final String? jobType;
  const ChatJobData({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.matchPct,
    this.requiredSkills = const [],
    this.jobType,
  });
}

class ChatCourseData {
  final String id, title, provider, duration, format;
  final double rating;
  final List<String> skills;
  const ChatCourseData({
    required this.id,
    required this.title,
    required this.provider,
    required this.duration,
    required this.format,
    required this.rating,
    this.skills = const [],
  });
}

class ChatSkillGapData {
  final String name, priority;
  final double importance;
  const ChatSkillGapData({
    required this.name,
    required this.priority,
    required this.importance,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// MESSAGE MODELS
// ═════════════════════════════════════════════════════════════════════════════

enum _Sender { user, bot }

enum _BotCardType {
  jobs,
  courses,
  skillGaps,
  cvFeedback,
  profileSummary,
  careerPath,
  cvDeepAnalysis, // ← NEW: deep analysis result
}

class _Attachment {
  final String filename;
  final Uint8List bytes;
  final String mimeType;
  final String? extractedText;
  const _Attachment({
    required this.filename,
    required this.bytes,
    required this.mimeType,
    this.extractedText,
  });
  bool get isPdf => mimeType == 'application/pdf';
}

class _Message {
  final String id;
  final _Sender sender;
  final String text;
  final DateTime time;
  final bool isError;
  final bool isLoading;
  final _BotCardType? cardType;
  final List<ChatJobData>? jobCards;
  final List<ChatCourseData>? courseCards;
  final List<ChatSkillGapData>? skillGapCards;
  final _Attachment? attachment;
  final String? actionLabel;
  final String? actionScreen;

  const _Message({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    this.isError = false,
    this.isLoading = false,
    this.cardType,
    this.jobCards,
    this.courseCards,
    this.skillGapCards,
    this.attachment,
    this.actionLabel,
    this.actionScreen,
  });

  _Message copyWith({
    String? text,
    bool? isError,
    bool? isLoading,
    _BotCardType? cardType,
    List<ChatJobData>? jobCards,
    List<ChatCourseData>? courseCards,
    List<ChatSkillGapData>? skillGapCards,
  }) =>
      _Message(
        id: id,
        sender: sender,
        time: time,
        text: text ?? this.text,
        isError: isError ?? this.isError,
        isLoading: isLoading ?? this.isLoading,
        cardType: cardType ?? this.cardType,
        jobCards: jobCards ?? this.jobCards,
        courseCards: courseCards ?? this.courseCards,
        skillGapCards: skillGapCards ?? this.skillGapCards,
        attachment: attachment,
        actionLabel: actionLabel,
        actionScreen: actionScreen,
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ═════════════════════════════════════════════════════════════════════════════

const _primaryBlue = Color(0xFF2563EB);
const _accentBlue = Color(0xFF3B82F6);
const _blue50 = Color(0xFFEFF6FF);
const _success = Color(0xFF10B981);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFEF4444);
const _purple = Color(0xFF8B5CF6); // ← used for deep-analysis badge

const _bgLight = Color(0xFFFFFFFF);
const _cardLight = Color(0xFFFFFFFF);
const _textLight = Color(0xFF0F172A);
const _subLight = Color(0xFF64748B);
const _borderLight = Color(0xFFE2E8F0);

const _bgDark = Color(0xFF0F172A);
const _cardDark = Color(0xFF1E293B);
const _textDark = Color(0xFFF1F5F9);
const _subDark = Color(0xFF94A3B8);
const _borderDark = Color(0xFF334155);

// ═════════════════════════════════════════════════════════════════════════════
// INTENT DETECTION  (enhanced)
// ═════════════════════════════════════════════════════════════════════════════

enum _Intent {
  jobs,
  courses,
  skillGap,
  careerPath,
  confidence,
  cvAnalysis,
  profileSummary,
  navigate,
  lifeGoal, // ← NEW: user is stating their life aim / dream role
  freeForm,
}

_Intent _detectIntent(String input) {
  final q = input.toLowerCase();

  // CV upload / analysis
  if (q.contains('upload') && (q.contains('cv') || q.contains('resume'))) {
    return _Intent.cvAnalysis;
  }
  if (q.contains('cv') || q.contains('resume')) return _Intent.cvAnalysis;

  // Life-goal / dream role statement
  final hasGoalVerb = q.contains('want to') ||
      q.contains('aim to') ||
      q.contains('dream') ||
      q.contains('aspire') ||
      q.contains('become') ||
      q.contains('goal') ||
      q.contains('life aim') ||
      q.contains('in life') ||
      q.contains('my goal') ||
      q.contains('hope to');
  final hasRoleKw = q.contains('engineer') ||
      q.contains('developer') ||
      q.contains('analyst') ||
      q.contains('manager') ||
      q.contains('designer') ||
      q.contains('scientist') ||
      q.contains('doctor') ||
      q.contains('nurse') ||
      q.contains('teacher') ||
      q.contains('entrepreneur') ||
      q.contains('accountant') ||
      q.contains('marketer') ||
      q.contains('career') ||
      q.contains('job') ||
      q.contains('role') ||
      q.contains('profession') ||
      q.contains('work as');
  if (hasGoalVerb && (hasRoleKw || q.contains('life'))) {
    return _Intent.lifeGoal;
  }

  // Other existing intents
  if (q.contains('top job') ||
      q.contains('job for me') ||
      q.contains('job match') ||
      q.contains('best job') ||
      q.contains('find job') ||
      q.contains('jobs')) {
    return _Intent.jobs;
  }
  if (q.contains('course') ||
      q.contains('learn') ||
      q.contains('study') ||
      q.contains('certification') ||
      q.contains('training')) {
    return _Intent.courses;
  }
  if (q.contains('skill gap') ||
      q.contains('missing skill') ||
      q.contains('what skill') ||
      q.contains('improve skill') ||
      q.contains('need to learn')) {
    return _Intent.skillGap;
  }
  if (q.contains('career path') ||
      q.contains('career advice') ||
      q.contains('roadmap') ||
      q.contains('next step') ||
      q.contains('transition') ||
      q.contains('switch career')) {
    return _Intent.careerPath;
  }
  if (q.contains('confidence') || q.contains('confidence score')) {
    return _Intent.confidence;
  }
  if (q.contains('my profile') ||
      q.contains('my background') ||
      q.contains('who am i')) {
    return _Intent.profileSummary;
  }
  if (q.contains('open ') ||
      q.contains('go to') ||
      q.contains('take me to') ||
      q.contains('show me') ||
      q.contains('navigate')) {
    return _Intent.navigate;
  }

  return _Intent.freeForm;
}

String? _parseNavigationTarget(String input) {
  final q = input.toLowerCase();
  if (q.contains('job alert') || q.contains('alerts')) return 'jobAlerts';
  if (q.contains('job') || q.contains('career')) return 'jobs';
  if (q.contains('course') || q.contains('learn')) return 'courses';
  if (q.contains('skill gap') || q.contains('skill')) return 'skillGap';
  if (q.contains('confidence')) return 'confidence';
  if (q.contains('application') || q.contains('tracker')) return 'applications';
  if (q.contains('cv') || q.contains('resume')) return 'cvUpload';
  if (q.contains('profile')) return 'profile';
  if (q.contains('geo') || q.contains('region') || q.contains('location')) {
    return 'geoInsights';
  }
  if (q.contains('assessment') || q.contains('quiz') || q.contains('test')) {
    return 'assessments';
  }
  if (q.contains('workforce') || q.contains('market insight')) {
    return 'workforceInsights';
  }
  if (q.contains('guide') || q.contains('career guide')) return 'careerGuide';
  if (q.contains('dashboard') || q.contains('home')) return 'jobs';
  return null;
}

// ═════════════════════════════════════════════════════════════════════════════
// ANIMATION HELPERS  (unchanged)
// ═════════════════════════════════════════════════════════════════════════════

class _PressScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _PressScaleWidget(
      {required this.child, required this.onTap, this.onLongPress});
  @override
  State<_PressScaleWidget> createState() => _PressScaleWidgetState();
}

class _PressScaleWidgetState extends State<_PressScaleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 100.ms);
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        onLongPress: widget.onLongPress,
        child: ScaleTransition(scale: _scale, child: widget.child),
      );
}

class _AnimatedBar extends StatelessWidget {
  final double value;
  final Color barColor;
  final Color bgColor;
  const _AnimatedBar(
      {required this.value, required this.barColor, required this.bgColor});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: value.clamp(0.0, 1.0)),
        duration: 900.ms,
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: v,
            minHeight: 6,
            backgroundColor: bgColor,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// QUICK REPLIES
// ═════════════════════════════════════════════════════════════════════════════

List<({String emoji, String label, String fullText})> _buildQuickReplies(
    ChatbotContext ctx, bool hasGoals) {
  return [
    (emoji: '', label: 'Top Jobs', fullText: 'Show me my top job matches'),
    (emoji: '', label: 'Skill Gaps', fullText: 'What skills am I missing?'),
    (emoji: '', label: 'Courses', fullText: 'Recommend courses for me'),
    (emoji: '', label: 'Career Path', fullText: 'Give me career path advice'),
    if (!ctx.hasCv)
      (emoji: '', label: 'Review CV', fullText: 'Analyse my CV')
    else
      (emoji: '', label: 'CV Tips', fullText: 'How can I improve my CV?'),
    (emoji: '', label: 'Confidence', fullText: 'Show my confidence score'),
    (emoji: '', label: 'Interview', fullText: 'Help me prepare for interviews'),
    (
      emoji: '',
      label: 'Salary',
      fullText: 'What salary should I negotiate for?'
    ),
    if (!hasGoals)
      (
        emoji: '',
        label: 'Set Goals',
        fullText:
            "I want to share my career goal and life aim with you so you can give me better advice."
      ),
  ];
}

// ═════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class ChatbotScreen extends StatefulWidget {
  final ChatbotContext chatContext;
  const ChatbotScreen({super.key, this.chatContext = const ChatbotContext()});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final List<_Message> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  bool _isTyping = false;
  bool _inputFocused = false;
  bool _showScrollFab = false;
  bool _showAttachMenu = false;
  bool _isExtractingCv = false; // ← NEW: shows "extracting…" in typing bubble
  int _msgIdx = 0;

  // ── CV state ───────────────────────────────────────────────────────────────
  String? _liveCvText;
  String? _liveCvFileName;

  // ── Goal state (collected through natural conversation) ────────────────────
  String _collectedRole = ''; // ← NEW
  String _collectedLifeAim = ''; // ← NEW

  late final GeminiChatService _gemini;
  ChatbotContext get _ctx => widget.chatContext;

  // ── Effective getters (local overrides chat-context values) ────────────────
  String get _effectiveRole =>
      _collectedRole.isNotEmpty ? _collectedRole : _ctx.targetRole;
  String get _effectiveAim =>
      _collectedLifeAim.isNotEmpty ? _collectedLifeAim : (_ctx.lifeAim ?? '');
  bool get _hasGoals => _effectiveRole.isNotEmpty || _effectiveAim.isNotEmpty;

  // ── Theme helpers ──────────────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _isDark ? _bgDark : _bgLight;
  Color get _card => _isDark ? _cardDark : _cardLight;
  Color get _text => _isDark ? _textDark : _textLight;
  Color get _sub => _isDark ? _subDark : _subLight;
  Color get _border => _isDark ? _borderDark : _borderLight;
  Color get _lb => _isDark ? const Color(0xFF1E3A5F) : _blue50;
  Color get _surf =>
      _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFF);

  // ── initState ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _liveCvText = _ctx.extractedCvText;
    _liveCvFileName = _ctx.cvFileName;

    _gemini =
        GeminiChatService(apiKey: _geminiApiKey, model: 'gemini-2.5-flash');

    // Pre-populate goals from context
    if (_ctx.targetRole.isNotEmpty) _collectedRole = _ctx.targetRole;
    if (_ctx.lifeAim != null) _collectedLifeAim = _ctx.lifeAim!;

    // Build greeting
    String greeting;
    if (_ctx.hasProfile) {
      final first =
          _ctx.userName.isNotEmpty ? _ctx.userName.split(' ').first : 'there';
      greeting = "Hi $first!  I'm your SkillBridge AI — I know your profile"
          "${_ctx.hasCv ? ', your CV' : ''}"
          "${_ctx.hasJobs ? ', your top job matches' : ''}"
          ". Ask me anything, or tap a quick reply below!";
    } else {
      greeting = "Hi! I'm SkillBridge AI, your personal career assistant"
          "${_geminiApiKey.isNotEmpty ? ' powered by Gemini 2.5 Flash' : ''}. "
          "To give you truly personalised advice, tell me: "
          "what job role are you aiming for, and what do you want to achieve in life? "
          "For example: \"I want to become a Data Scientist and use AI to improve "
          "healthcare in Bangladesh.\" You can also upload your CV anytime!";
    }

    _messages.add(_Message(
      id: 'welcome',
      sender: _Sender.bot,
      time: DateTime.now(),
      text: greeting,
    ));

    // Proactive skill-gap nudge
    if (_ctx.hasProfile && _ctx.hasSkillGap) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(1200.ms, () {
          if (!mounted) return;
          final topGap = _ctx.skillGaps.first;
          setState(() => _messages.add(_Message(
                id: 'proactive_${_msgIdx++}',
                sender: _Sender.bot,
                time: DateTime.now(),
                text:
                    " Quick insight: Your biggest skill gap is ${topGap.name} "
                    "(${(topGap.importance * 100).round()}% importance for "
                    "${_effectiveRole.isNotEmpty ? _effectiveRole : 'your target role'}). "
                    "Tap 'Courses' to find the best way to learn it.",
              )));
          _scrollToBottom();
        });
      });
    }

    _inputCtrl.addListener(() => setState(() {}));
    _inputFocus.addListener(() {
      if (mounted) setState(() => _inputFocused = _inputFocus.hasFocus);
    });
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final atBottom =
          _scroll.offset >= (_scroll.position.maxScrollExtent - 140);
      if (mounted && _showScrollFab == atBottom) {
        setState(() => _showScrollFab = !atBottom);
      }
    });
  }

  @override
  void dispose() {
    _gemini.dispose();
    _inputCtrl.dispose();
    _scroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GOAL EXTRACTION  (NEW)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Parses a free-text goal statement and stores role + life aim locally.
  void _storeUserGoal(String input) {
    // Extract role — patterns like "become a Data Analyst", "work as a developer"
    final rolePatterns = [
      RegExp(
          r'(?:become|be a|be an|work as|role as|job as|career as|aspire to be|want to be|hope to be)\s+(?:a\s+|an\s+)?([A-Za-z][A-Za-z\s]+?)(?:\s+and\b|\s+in\b|\s+at\b|\s+to\b|[,.\n]|$)',
          caseSensitive: false),
      RegExp(
          r'(?:target role|dream role|goal role|aiming for|aiming to be)\s*[:\-]?\s*([A-Za-z][A-Za-z\s]+?)(?:[,.\n]|$)',
          caseSensitive: false),
    ];

    for (final pattern in rolePatterns) {
      final match = pattern.firstMatch(input);
      final extracted = match?.group(1)?.trim();
      if (extracted != null &&
          extracted.length >= 3 &&
          extracted.length <= 60) {
        _collectedRole = _titleCase(extracted);
        break;
      }
    }

    // Store full statement as life aim (cap at 300 chars)
    if (_collectedLifeAim.isEmpty) {
      _collectedLifeAim = input.length > 300 ? input.substring(0, 300) : input;
    }
  }

  String _titleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  // ═══════════════════════════════════════════════════════════════════════════
  // DEEP CV ANALYSIS PROMPT  (NEW)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Builds the comprehensive career-alignment prompt sent to Gemini.
  String _buildDeepAnalysisPrompt(String cvText) {
    final name =
        _ctx.userName.isNotEmpty ? _ctx.userName.split(' ').first : 'you';
    final targetRole =
        _effectiveRole.isNotEmpty ? _effectiveRole : 'your target role';
    final lifeAim = _effectiveAim.isNotEmpty
        ? _effectiveAim
        : 'professional excellence and meaningful impact';
    final currentRole =
        _ctx.currentRole.isNotEmpty ? _ctx.currentRole : 'Not specified';
    final expYears = _ctx.experienceYears > 0
        ? '${_ctx.experienceYears} years'
        : 'Not specified';

    final cvSnippet = cvText.length > 4000
        ? '${cvText.substring(0, 4000)}\n[...truncated]'
        : cvText;

    return '''
Perform a comprehensive career-alignment analysis for $name.

CONTEXT:
  Target Job Role:  $targetRole
  Life Aim / Dream: $lifeAim
  Current Role:     $currentRole
  Experience:       $expYears
  Location:         ${_ctx.location}

CV TEXT:
$cvSnippet

Write a detailed, warm, personal, and actionable analysis addressed directly to $name.
Use plain conversational paragraphs — absolutely no markdown, no asterisks, no bullet symbols.
Reference specific content from the CV throughout. Aim for 420–520 words.

Structure as follows:

OPENING (2 sentences): Warmly acknowledge what you see — summarise who $name is professionally.

YOUR STRENGTHS FOR $targetRole: Identify 3–4 genuine strengths found in this CV that are relevant to $targetRole. Be specific — name actual skills, tools, projects, or experiences you found.

CRITICAL SKILL GAPS: Name the 3–5 most important gaps between their current profile and what $targetRole typically requires. For each gap, suggest one concrete way to close it — a course, certification, open-source project, or practical exercise.

CAREER ALIGNMENT SCORE: State "Your CV is [X]/10 aligned with $targetRole" and briefly explain the rating.

CONNECTING YOUR CAREER TO YOUR LIFE AIM: Specifically explain how building a career as $targetRole serves their life aim of "$lifeAim". Make this personal and motivating (2–3 sentences).

YOUR 90-DAY ACTION PLAN: The 4 highest-priority actions in sequence. Write this as a flowing narrative — not a list — so it feels like personalised coaching.

THIS WEEK'S QUICK WIN: One very specific, achievable action $name can complete within 7 days to create immediate momentum.

CLOSING: One encouraging sentence. Invite $name to ask follow-up questions about any part of the analysis.
''';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEND LOGIC
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _send(String text, {_Attachment? attachment}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && attachment == null) return;

    _inputCtrl.clear();
    _inputFocus.unfocus();
    setState(() => _showAttachMenu = false);
    HapticFeedback.mediumImpact();

    final userMsg = _Message(
      id: 'u${_msgIdx++}',
      sender: _Sender.user,
      time: DateTime.now(),
      text: trimmed.isNotEmpty ? trimmed : '📎 ${attachment!.filename}',
      attachment: attachment,
    );
    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _scrollToBottom();

    await Future.delayed(350.ms);

    try {
      final intent = _detectIntent(trimmed);
      _Message botMsg;

      // ── Attachment / CV upload ────────────────────────────────────────────
      if (attachment != null) {
        if (attachment.extractedText != null) {
          _liveCvText = attachment.extractedText;
          _liveCvFileName = attachment.filename;
        }
        botMsg = await _handleCvAnalysis(attachment, trimmed);
      }

      // ── Life-goal / dream-role statement ──────────────────────────────────
      else if (intent == _Intent.lifeGoal) {
        _storeUserGoal(trimmed);
        final role =
            _collectedRole.isNotEmpty ? _collectedRole : 'your target role';
        final hasCV = _liveCvText != null && _liveCvText!.isNotEmpty;

        final geminiAck = await _gemini.generateReply(
          history: _buildHistory(),
          systemInstruction: _ctx.buildSystemInstruction(
            freshCvText: _liveCvText,
            freshLifeAim: _collectedLifeAim,
            freshTargetRole: _collectedRole,
          ),
          temperature: 0.45,
          maxOutputTokens: 500,
        );

        final fallback =
            "That's a powerful goal — $role aligns really well with "
            "${_effectiveAim.isNotEmpty ? 'what you want to achieve in life' : 'your ambitions'}. "
            "${hasCV ? "I've already got your CV — let me do a full alignment analysis for you! Just say 'Analyse my CV'." : "Upload your CV next and I'll do a full alignment analysis to show exactly how close you are and what to do next."}";

        botMsg = _Message(
          id: 'b${_msgIdx++}',
          sender: _Sender.bot,
          time: DateTime.now(),
          text: geminiAck.isNotEmpty ? geminiAck : fallback,
          actionLabel: hasCV ? 'Analyse My CV →' : 'Upload CV →',
          actionScreen: 'cvUpload',
        );
      }

      // ── Existing intent handlers ──────────────────────────────────────────
      else if (intent == _Intent.jobs && _ctx.hasJobs) {
        await Future.delayed(400.ms);
        botMsg = _makeJobsMessage(trimmed);
      } else if (intent == _Intent.courses && _ctx.hasCourses) {
        await Future.delayed(400.ms);
        botMsg = _makeCoursesMessage(trimmed);
      } else if (intent == _Intent.skillGap && _ctx.hasSkillGap) {
        await Future.delayed(400.ms);
        botMsg = _makeSkillGapMessage();
      } else if (intent == _Intent.careerPath) {
        await Future.delayed(400.ms);
        botMsg = _makeCareerPathMessage();
      } else if (intent == _Intent.confidence && _ctx.confidenceScore != null) {
        await Future.delayed(300.ms);
        botMsg = _makeConfidenceMessage();
      } else if (intent == _Intent.profileSummary && _ctx.hasProfile) {
        await Future.delayed(300.ms);
        botMsg = _makeProfileSummaryMessage();
      } else if (intent == _Intent.navigate) {
        final screen = _parseNavigationTarget(trimmed);
        if (screen != null && _ctx.navigateTo != null) _ctx.navigateTo!(screen);
        final label = _screenDisplayName(screen ?? 'dashboard');
        botMsg = _Message(
          id: 'b${_msgIdx++}',
          sender: _Sender.bot,
          time: DateTime.now(),
          text: screen != null
              ? "Opening $label for you now."
              : "I'm not sure which screen you mean. Try: 'Open job results', "
                  "'Show courses', or 'Go to skill gap'.",
        );
      }

      // ── Free-form Gemini call ─────────────────────────────────────────────
      else {
        final reply = await _gemini.generateReply(
          history: _buildHistory(),
          systemInstruction: _ctx.buildSystemInstruction(
            freshCvText: _liveCvText,
            freshLifeAim: _effectiveAim.isNotEmpty ? _effectiveAim : null,
            freshTargetRole: _effectiveRole.isNotEmpty ? _effectiveRole : null,
          ),
          temperature: 0.45,
          maxOutputTokens: 800,
        );

        String? navScreen;
        if (reply.toLowerCase().contains('opening ')) {
          final target = _parseNavigationTarget(reply);
          if (target != null && _ctx.navigateTo != null) {
            navScreen = target;
            _ctx.navigateTo!(target);
          }
        }

        botMsg = _Message(
          id: 'b${_msgIdx++}',
          sender: _Sender.bot,
          time: DateTime.now(),
          text: reply.isEmpty
              ? "I didn't get a response. Please try again."
              : reply,
          actionLabel: navScreen != null
              ? 'View ${_screenDisplayName(navScreen)} →'
              : null,
          actionScreen: navScreen,
        );
      }

      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(botMsg);
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_Message(
          id: 'err${_msgIdx++}',
          sender: _Sender.bot,
          time: DateTime.now(),
          isError: true,
          text: "⚠️ Couldn't reach the AI service.\n"
              "Error: ${e.toString().split('\n').first}\n\n"
              "Check your API key or internet connection, "
              "or tap a quick reply for offline results.",
        ));
      });
      _scrollToBottom();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CV ANALYSIS HANDLER  (UPGRADED)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<_Message> _handleCvAnalysis(_Attachment att, String userText) async {
    final cvText = att.extractedText;

    // ── No goals yet — ask before analysing ──────────────────────────────────
    if (!_hasGoals && userText.isEmpty) {
      return _Message(
        id: 'b${_msgIdx++}',
        sender: _Sender.bot,
        time: DateTime.now(),
        text: "Great — I've received your CV (${att.filename})! "
            "Before I run the full analysis, tell me two things: "
            "what job role are you aiming for, and what's your bigger life goal or dream? "
            "For example: \"I want to become a Flutter Developer and build products "
            "that help small businesses in Bangladesh grow online.\" "
            "The more specific you are, the deeper my analysis will be.",
        actionLabel: 'Edit Profile →',
        actionScreen: 'profile',
      );
    }

    // ── Extraction failed — give helpful fallback ─────────────────────────────
    if (cvText == null || cvText.trim().length < 80) {
      final fallbackPrompt =
          "The user uploaded a CV file named '${att.filename}'. "
          "Text extraction was unsuccessful. "
          "Provide helpful advice on: "
          "1) How to format their CV for better parsing, "
          "2) The typical skills needed for ${_effectiveRole.isNotEmpty ? _effectiveRole : 'their target role'}, "
          "3) How to manually share their CV details with you in chat.";

      final reply = await _gemini.generateReply(
        history: [GeminiTurn(role: 'user', text: fallbackPrompt)],
        systemInstruction: _ctx.buildSystemInstruction(
          freshLifeAim: _effectiveAim.isNotEmpty ? _effectiveAim : null,
          freshTargetRole: _effectiveRole.isNotEmpty ? _effectiveRole : null,
        ),
        temperature: 0.35,
        maxOutputTokens: 600,
      );

      return _Message(
        id: 'b${_msgIdx++}',
        sender: _Sender.bot,
        time: DateTime.now(),
        isError: false,
        text: reply.isNotEmpty
            ? reply
            : "I received your CV (${att.filename}) but couldn't extract the text — "
                "this can happen with scanned PDFs or image-based documents. "
                "Try copying and pasting your CV text directly in the chat, "
                "or save it as a plain PDF and upload again.",
        actionLabel: 'Open CV Uploader →',
        actionScreen: 'cvUpload',
      );
    }

    // ── Full deep analysis ────────────────────────────────────────────────────
    final prompt = _buildDeepAnalysisPrompt(cvText);

    final reply = await _gemini.generateReply(
      history: [GeminiTurn(role: 'user', text: prompt)],
      systemInstruction: _ctx.buildSystemInstruction(
        freshCvText: cvText,
        freshLifeAim: _effectiveAim.isNotEmpty ? _effectiveAim : null,
        freshTargetRole: _effectiveRole.isNotEmpty ? _effectiveRole : null,
      ),
      temperature: 0.30, // lower = more precise analysis
      maxOutputTokens: 1500, // generous limit for full analysis
    );

    return _Message(
      id: 'b${_msgIdx++}',
      sender: _Sender.bot,
      time: DateTime.now(),
      cardType: _BotCardType.cvDeepAnalysis,
      text: reply.isNotEmpty
          ? reply
          : "I've reviewed your CV but couldn't generate a full analysis right now. "
              "Please try again in a moment.",
      actionLabel: 'View Skill Gap Analysis →',
      actionScreen: 'skillGap',
    );
  }

  // ─── Existing message factories (unchanged) ───────────────────────────────

  _Message _makeJobsMessage(String query) {
    final jobs = _ctx.topJobMatches.take(3).toList();
    return _Message(
      id: 'b${_msgIdx++}',
      sender: _Sender.bot,
      time: DateTime.now(),
      text: _ctx.currentRole.isNotEmpty
          ? 'Based on your ${_ctx.currentRole} background, here are your top ${jobs.length} job matches:'
          : 'Here are the top job matches in the app:',
      cardType: _BotCardType.jobs,
      jobCards: jobs,
      actionLabel: 'Browse All Jobs →',
      actionScreen: 'jobs',
    );
  }

  _Message _makeCoursesMessage(String query) {
    final courses = _ctx.recommendedCourses.take(3).toList();
    return _Message(
      id: 'b${_msgIdx++}',
      sender: _Sender.bot,
      time: DateTime.now(),
      text: _ctx.missingSkills.isNotEmpty
          ? 'Here are the best courses to close your top skill gaps '
              '(${_ctx.missingSkills.take(3).join(', ')}):'
          : 'Here are your top recommended courses:',
      cardType: _BotCardType.courses,
      courseCards: courses,
      actionLabel: 'Browse All Courses →',
      actionScreen: 'courses',
    );
  }

  _Message _makeSkillGapMessage() {
    final gaps = _ctx.skillGaps.take(5).toList();
    return _Message(
      id: 'b${_msgIdx++}',
      sender: _Sender.bot,
      time: DateTime.now(),
      text: _effectiveRole.isNotEmpty
          ? 'To become a $_effectiveRole, here are your top ${gaps.length} skill gaps:'
          : 'Based on your profile, here are your top skill gaps:',
      cardType: _BotCardType.skillGaps,
      skillGapCards: gaps,
      actionLabel: 'Full Skill Gap Analysis →',
      actionScreen: 'skillGap',
    );
  }

  _Message _makeCareerPathMessage() {
    final hasData = _ctx.currentRole.isNotEmpty && _effectiveRole.isNotEmpty;
    final timeEst = _ctx.skillGaps.length > 4 ? '9–12 months' : '4–6 months';
    final aimSuffix = _effectiveAim.isNotEmpty
        ? "\n\nThis path directly supports your life goal: $_effectiveAim"
        : '';
    final text = hasData
        ? 'Your path from ${_ctx.currentRole} to $_effectiveRole will take '
            'approximately $timeEst. Focus first on '
            '${_ctx.missingSkills.isNotEmpty ? _ctx.missingSkills.first : "your top skill gap"}, '
            'then progressively tackle deeper technical skills. '
            'I recommend 1–2 hours of focused learning per day.$aimSuffix'
        : "Complete your profile with your current and target roles and I'll map out "
            "a precise path with timelines. Tap 'Profile' to fill in your details.";

    return _Message(
      id: 'b${_msgIdx++}',
      sender: _Sender.bot,
      time: DateTime.now(),
      cardType: _BotCardType.careerPath,
      text: text,
      actionLabel: 'View Full Roadmap →',
      actionScreen: 'careerGuide',
    );
  }

  _Message _makeConfidenceMessage() {
    final score = _ctx.confidenceScore!;
    final pct = (score * 100).round();
    final label = ChatbotContext._confidenceLabel(score);
    final weakArea = _ctx.missingSkills.isNotEmpty
        ? _ctx.missingSkills.last
        : 'salary negotiation';
    return _Message(
      id: 'b${_msgIdx++}',
      sender: _Sender.bot,
      time: DateTime.now(),
      text: "Your career confidence score is $pct% — $label. "
          "Your biggest opportunity is strengthening $weakArea, "
          "which could push your score above ${(pct + 15).clamp(0, 99)}%. "
          "Tap 'Confidence Tracker' to see the full breakdown.",
      actionLabel: 'Open Confidence Tracker →',
      actionScreen: 'confidence',
    );
  }

  _Message _makeProfileSummaryMessage() {
    final sb = StringBuffer();
    if (_ctx.userName.isNotEmpty) sb.write("Name: ${_ctx.userName}. ");
    if (_ctx.currentRole.isNotEmpty)
      sb.write("Current Role: ${_ctx.currentRole}. ");
    if (_effectiveRole.isNotEmpty) sb.write("Target Role: $_effectiveRole. ");
    if (_effectiveAim.isNotEmpty) sb.write("Life Aim: $_effectiveAim. ");
    if (_ctx.experienceYears > 0)
      sb.write("${_ctx.experienceYears} yrs experience. ");
    if (_ctx.currentSkills.isNotEmpty) {
      sb.write("Top skills: ${_ctx.currentSkills.take(5).join(', ')}. ");
    }
    if (_liveCvFileName != null) sb.write("CV: $_liveCvFileName. ");
    if (_ctx.confidenceScore != null) {
      sb.write("Confidence: ${(_ctx.confidenceScore! * 100).round()}%. ");
    }
    if (sb.isEmpty) {
      sb.write("Your profile isn't complete yet. ");
    }
    sb.write(
        "Want me to find jobs, analyse your skill gaps, or suggest courses?");

    return _Message(
      id: 'b${_msgIdx++}',
      sender: _Sender.bot,
      time: DateTime.now(),
      cardType: _BotCardType.profileSummary,
      text: sb.toString(),
      actionLabel: 'Edit Profile →',
      actionScreen: 'profile',
    );
  }

  List<GeminiTurn> _buildHistory({int maxTurns = 20}) {
    final window = _messages.length > maxTurns
        ? _messages.sublist(_messages.length - maxTurns)
        : _messages;
    return window
        .where((m) => m.text.trim().isNotEmpty && !m.isError)
        .map((m) => GeminiTurn(
              role: m.sender == _Sender.user ? 'user' : 'model',
              text: m.text.trim(),
            ))
        .toList();
  }

  // ─── File picker (UPGRADED) ────────────────────────────────────────────────

  Future<void> _pickCvFile() async {
    setState(() => _showAttachMenu = false);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) return;

      // ── Show extraction spinner ────────────────────────────────────────────
      setState(() {
        _isExtractingCv = true;
        _isTyping = true;
      });
      _scrollToBottom();

      // ── Extract text ───────────────────────────────────────────────────────
      String? extractedText;
      String mimeType;
      final ext = (file.extension ?? '').toLowerCase();

      switch (ext) {
        case 'txt':
          mimeType = 'text/plain';
          extractedText = utf8.decode(file.bytes!, allowMalformed: true);
          break;
        case 'pdf':
          mimeType = 'application/pdf';
          extractedText =
              await _CvTextExtractor.extract(file.bytes!, file.name);
          break;
        case 'docx':
          mimeType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          extractedText =
              await _CvTextExtractor.extract(file.bytes!, file.name);
          break;
        case 'doc':
          mimeType = 'application/msword';
          extractedText =
              await _CvTextExtractor.extract(file.bytes!, file.name);
          break;
        default:
          mimeType = 'application/octet-stream';
      }

      // Update live CV state
      if (extractedText != null && extractedText.trim().length >= 80) {
        _liveCvText = extractedText;
        _liveCvFileName = file.name;
      }

      setState(() {
        _isExtractingCv = false;
        _isTyping = false;
      });

      final att = _Attachment(
        filename: file.name,
        bytes: file.bytes!,
        mimeType: mimeType,
        extractedText: extractedText,
      );

      await _send(
        _hasGoals
            ? 'Please analyse my CV and give me a detailed career alignment analysis.'
            : '',
        attachment: att,
      );
    } catch (e) {
      setState(() {
        _isExtractingCv = false;
        _isTyping = false;
      });
      if (mounted) _showSnack('Could not open file: $e');
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static String _screenDisplayName(String screen) {
    const map = {
      'jobs': 'Job Results',
      'courses': 'Browse Courses',
      'skillGap': 'Skill Gap Analysis',
      'careerGuide': 'Career Guide',
      'confidence': 'Confidence Tracker',
      'applications': 'Application Tracker',
      'cvUpload': 'CV Upload',
      'profile': 'Profile',
      'geoInsights': 'Geo Insights',
      'assessments': 'Assessment Hub',
      'jobAlerts': 'Job Alerts',
      'workforceInsights': 'Workforce Insights',
    };
    return map[screen] ?? screen;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final hasText = _inputCtrl.text.trim().isNotEmpty;
    return GestureDetector(
      onTap: () {
        if (_showAttachMenu) setState(() => _showAttachMenu = false);
      },
      child: AnimatedContainer(
        duration: 300.ms,
        color: _bg,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(),
          floatingActionButton: _showScrollFab ? _buildScrollFab() : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: Column(children: [
            // ── Goals banner (NEW) ──────────────────────────────────────────
            if (_hasGoals) _buildGoalsBanner(),
            Expanded(child: _buildChatArea()),
            _buildQuickReplyBar(),
            _buildInputRow(hasText),
          ]),
        ),
      ),
    );
  }

  // ── Goals Banner  (NEW) ────────────────────────────────────────────────────
  Widget _buildGoalsBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _isDark
          ? _purple.withValues(alpha: 0.12)
          : _purple.withValues(alpha: 0.07),
      child: Row(children: [
        const Icon(Icons.flag_rounded, color: _purple, size: 14),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            [
              if (_effectiveRole.isNotEmpty) ' $_effectiveRole',
              if (_effectiveAim.isNotEmpty)
                ' ${_effectiveAim.length > 60 ? "${_effectiveAim.substring(0, 60)}…" : _effectiveAim}',
            ].join('   '),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _purple,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: () => _send(
              "I want to update my career goal and life aim. Here's what I'm aiming for:"),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _purple.withValues(alpha: 0.3)),
            ),
            child: Text('Edit',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, fontWeight: FontWeight.w700, color: _purple)),
          ),
        ),
      ]),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _text,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: _text, size: 22),
          onPressed: () => Navigator.maybePop(context),
        ),
        titleSpacing: 0,
        title: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryBlue, _accentBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryBlue.withValues(alpha: 0.40),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Center(
                child: Text('AI',
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800))),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
              duration: 3000.ms, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SkillBridge Assistant',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w700, color: _text)),
            Row(children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _geminiApiKey.isNotEmpty ? _success : _warning,
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn(duration: 800.ms)
                  .then()
                  .fadeOut(duration: 800.ms),
              const SizedBox(width: 4),
              Text(
                _geminiApiKey.isNotEmpty
                    ? (_ctx.hasProfile
                        ? 'Gemini · Profile loaded'
                        : 'Gemini 2.5 Flash')
                    : 'Built-in mode',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _sub),
              ),
            ]),
          ]),
        ]),
        actions: [
          if (_ctx.hasProfile)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _lb,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: _primaryBlue.withValues(alpha: 0.25)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.person_rounded,
                      size: 11, color: _primaryBlue),
                  const SizedBox(width: 3),
                  Text('Profile',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _primaryBlue)),
                ]),
              ),
            ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: _sub, size: 22),
            onPressed: _showOptionsMenu,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      );

  void _showOptionsMenu() {
    final cardColor = _card;
    final borderColor = _border;
    final textColor = _text;
    final subColor = _sub;
    final isDark = _isDark;
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => _OptionsSheet(
        cardColor: cardColor,
        borderColor: borderColor,
        textColor: textColor,
        subColor: subColor,
        isDark: isDark,
        hasCv: _liveCvText != null,
        cvFileName: _liveCvFileName,
        hasNav: _ctx.navigateTo != null,
        jobCount: _ctx.topJobMatches.length,
        courseCount: _ctx.recommendedCourses.length,
        hasProfile: _ctx.hasProfile,
        onClearChat: _clearChat,
        onUploadCv: () {
          Navigator.pop(sheetCtx);
          _pickCvFile();
        },
        onBrowseJobs: _ctx.navigateTo != null
            ? () {
                Navigator.pop(sheetCtx);
                _ctx.navigateTo!('jobs');
              }
            : null,
        onBrowseCourses: _ctx.navigateTo != null
            ? () {
                Navigator.pop(sheetCtx);
                _ctx.navigateTo!('courses');
              }
            : null,
        onEditProfile: _ctx.navigateTo != null
            ? () {
                Navigator.pop(sheetCtx);
                _ctx.navigateTo!('profile');
              }
            : null,
        onViewSkillGap: _ctx.navigateTo != null
            ? () {
                Navigator.pop(sheetCtx);
                _ctx.navigateTo!('skillGap');
              }
            : null,
        onOpenAssessments: _ctx.navigateTo != null
            ? () {
                Navigator.pop(sheetCtx);
                _ctx.navigateTo!('assessments');
              }
            : null,
        onCopyLastMessage: _messages.isNotEmpty
            ? () {
                Navigator.pop(sheetCtx);
                final last = _messages.lastWhere(
                  (m) => m.sender == _Sender.bot && m.text.isNotEmpty,
                  orElse: () => _messages.last,
                );
                Clipboard.setData(ClipboardData(text: last.text));
                _showSnack('Last message copied to clipboard');
              }
            : null,
      ),
    );
  }

  void _clearChat() {
    Navigator.pop(context);
    setState(() {
      _messages.clear();
      _messages.add(_Message(
        id: 'cleared',
        sender: _Sender.bot,
        time: DateTime.now(),
        text: 'Chat cleared. How can I help you today?',
      ));
    });
  }

  Widget _buildScrollFab() => Padding(
        padding: const EdgeInsets.only(bottom: 140),
        child: _PressScaleWidget(
          onTap: _scrollToBottom,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _card,
              shape: BoxShape.circle,
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isDark ? 0.40 : 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child:
                Icon(Icons.keyboard_arrow_down_rounded, color: _sub, size: 22),
          ),
        ),
      );

  // ── Chat Area ──────────────────────────────────────────────────────────────
  Widget _buildChatArea() => ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length + (_isTyping ? 1 : 0),
        itemBuilder: (_, i) {
          if (_isTyping && i == _messages.length) {
            return _buildTypingBubble();
          }
          final msg = _messages[i];
          return _buildBubble(msg)
              .animate()
              .fadeIn(duration: 280.ms)
              .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
        },
      );

  // ── Message Bubble ─────────────────────────────────────────────────────────
  Widget _buildBubble(_Message msg) {
    final isUser = msg.sender == _Sender.user;
    final isDeepAnalysis = msg.cardType == _BotCardType.cvDeepAnalysis;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[_buildAvatar(32), const SizedBox(width: 8)],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // ── Deep-analysis badge (NEW) ──────────────────────────────
                if (isDeepAnalysis)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_purple, Color(0xFF6D28D9)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _purple.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 11),
                      const SizedBox(width: 5),
                      Text('Deep CV Analysis',
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),

                _PressScaleWidget(
                  onTap: () {},
                  onLongPress: () => _onLongPressMessage(msg),
                  child: Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.74),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      // ✅ color lives here only — never alongside decoration
                      color: isUser
                          ? null
                          : isDeepAnalysis
                              ? null
                              : (msg.isError
                                  ? _danger.withValues(alpha: 0.08)
                                  : _card),
                      gradient: isUser
                          ? const LinearGradient(
                              colors: [_primaryBlue, _accentBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : isDeepAnalysis
                              ? LinearGradient(colors: [
                                  _purple.withValues(
                                      alpha: _isDark ? 0.20 : 0.06),
                                  _primaryBlue.withValues(
                                      alpha: _isDark ? 0.10 : 0.04),
                                ])
                              : null,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 18),
                      ),
                      border: isUser
                          ? null
                          : Border.all(
                              color: isDeepAnalysis
                                  ? _purple.withValues(alpha: 0.35)
                                  : (msg.isError
                                      ? _danger.withValues(alpha: 0.30)
                                      : _border),
                              width: 1,
                            ),
                      boxShadow: isUser
                          ? [
                              BoxShadow(
                                  color: _primaryBlue.withValues(alpha: 0.28),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5))
                            ]
                          : [
                              BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: _isDark ? 0.20 : 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2))
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (msg.attachment != null)
                          _buildAttachmentBadge(msg.attachment!),
                        if (msg.text.isNotEmpty)
                          Text(msg.text,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.65,
                                color: isUser
                                    ? Colors.white
                                    : (msg.isError ? _danger : _text),
                              )),
                        if (msg.jobCards != null &&
                            msg.jobCards!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ...msg.jobCards!.map(_buildJobCard),
                        ],
                        if (msg.courseCards != null &&
                            msg.courseCards!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ...msg.courseCards!.map(_buildCourseCard),
                        ],
                        if (msg.skillGapCards != null &&
                            msg.skillGapCards!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ...msg.skillGapCards!.map(_buildSkillGapCard),
                        ],
                        if (msg.actionLabel != null) ...[
                          const SizedBox(height: 12),
                          _buildCtaButton(msg.actionLabel!, msg.actionScreen),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 4),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_fmt(msg.time),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10, color: _sub)),
                  if (isUser) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all_rounded,
                        size: 13, color: _accentBlue),
                  ],
                ]),
              ],
            ),
          ),
          if (isUser) ...[const SizedBox(width: 8), _buildUserAvatar()],
        ],
      ),
    );
  }

  void _onLongPressMessage(_Message msg) {
    HapticFeedback.mediumImpact();
    final cardColor = _card;
    final borderColor = _border;
    final textColor = _text;
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: borderColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(
            leading:
                const Icon(Icons.copy_rounded, color: _primaryBlue, size: 22),
            title: Text('Copy Message',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
            onTap: () {
              Navigator.pop(sheetCtx);
              Clipboard.setData(ClipboardData(text: msg.text));
              _showSnack('Copied to clipboard');
            },
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          if (msg.sender == _Sender.user)
            ListTile(
              leading: const Icon(Icons.refresh_rounded,
                  color: _primaryBlue, size: 22),
              title: Text('Resend',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _send(msg.text);
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
        ]),
      ),
    );
  }

  Widget _buildAttachmentBadge(_Attachment att) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
              att.isPdf
                  ? Icons.picture_as_pdf_rounded
                  : Icons.description_rounded,
              color: Colors.white,
              size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(att.filename,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );

  Widget _buildCtaButton(String label, String? screen) => _PressScaleWidget(
        onTap: () {
          if (screen != null && _ctx.navigateTo != null)
            _ctx.navigateTo!(screen);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_primaryBlue, _accentBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: _primaryBlue.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Text(label,
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
      );

  Widget _buildAvatar(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF1E3A5F), _primaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: _primaryBlue.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Center(
            child: Text('AI',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: size * 0.34,
                    fontWeight: FontWeight.w800))),
      );

  Widget _buildUserAvatar() {
    final initials = _ctx.userName.isNotEmpty
        ? _ctx.userName
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : 'ME';
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [_primaryBlue, _accentBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        shape: BoxShape.circle,
      ),
      child: Center(
          child: Text(initials,
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700))),
    );
  }

  // ── Job Card ───────────────────────────────────────────────────────────────
  Widget _buildJobCard(ChatJobData card) {
    final matchColor = card.matchPct >= 90
        ? _success
        : card.matchPct >= 80
            ? _primaryBlue
            : _sub;
    return _PressScaleWidget(
      onTap: () => _ctx.navigateTo?.call('jobs', args: {'jobId': card.id}),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surf,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _primaryBlue.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: _isDark ? 0.20 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _lb,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryBlue.withValues(alpha: 0.15)),
            ),
            child: const Icon(Icons.business_rounded,
                color: _primaryBlue, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(card.title,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.location_on_outlined, size: 10, color: _sub),
                  const SizedBox(width: 2),
                  Expanded(
                      child: Text('${card.company} · ${card.location}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, color: _sub),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 5),
                Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                        color: _success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(card.salary,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _success)),
                  ),
                  if (card.jobType != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                          color: _lb, borderRadius: BorderRadius.circular(8)),
                      child: Text(card.jobType!,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _primaryBlue)),
                    ),
                  ],
                ]),
              ])),
          const SizedBox(width: 8),
          Column(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: matchColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                    color: matchColor.withValues(alpha: 0.35), width: 1.5),
              ),
              child: Center(
                  child: Text('${card.matchPct}%',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: matchColor))),
            ),
            const SizedBox(height: 3),
            Text('match',
                style: GoogleFonts.plusJakartaSans(fontSize: 9, color: _sub)),
          ]),
        ]),
      ),
    );
  }

  // ── Course Card ────────────────────────────────────────────────────────────
  Widget _buildCourseCard(ChatCourseData card) {
    final full = card.rating.floor();
    final half = (card.rating - full) >= 0.5;
    return _PressScaleWidget(
      onTap: () =>
          _ctx.navigateTo?.call('courses', args: {'courseId': card.id}),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surf,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _primaryBlue.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: _isDark ? 0.20 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _lb,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryBlue.withValues(alpha: 0.15)),
            ),
            child: const Icon(Icons.play_circle_outline_rounded,
                color: _primaryBlue, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(card.title,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${card.provider} · ${card.duration}',
                    style:
                        GoogleFonts.plusJakartaSans(fontSize: 11, color: _sub),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Row(children: [
                  ...List.generate(5, (i) {
                    final ico = i < full
                        ? Icons.star_rounded
                        : (i == full && half)
                            ? Icons.star_half_rounded
                            : Icons.star_outline_rounded;
                    return Icon(ico, size: 12, color: _warning);
                  }),
                  const SizedBox(width: 4),
                  Text(card.rating.toStringAsFixed(1),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _text)),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: _lb, borderRadius: BorderRadius.circular(6)),
                    child: Text(card.format,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: _primaryBlue)),
                  ),
                ]),
              ])),
        ]),
      ),
    );
  }

  // ── Skill Gap Card ─────────────────────────────────────────────────────────
  Widget _buildSkillGapCard(ChatSkillGapData card) {
    Color pc(String p) {
      if (p.contains('🔴')) return const Color(0xFFDC2626);
      if (p.contains('🟠')) return const Color(0xFFEA580C);
      if (p.contains('🟡')) return const Color(0xFFD97706);
      return _primaryBlue;
    }

    final color = pc(card.priority);
    final barBg =
        _isDark ? Colors.white.withValues(alpha: 0.10) : Colors.grey.shade200;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 8, top: 2),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.40), blurRadius: 4)
            ],
          ),
        ),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(card.name,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _text))),
            Text('${(card.importance * 100).round()}%',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 2),
          Text(card.priority,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _sub)),
          const SizedBox(height: 6),
          _AnimatedBar(value: card.importance, barColor: color, bgColor: barBg),
        ])),
      ]),
    );
  }

  // ── Typing Indicator  (UPGRADED: shows "extracting" state) ────────────────
  Widget _buildTypingBubble() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _buildAvatar(32),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: _border, width: 1),
              boxShadow: [
                BoxShadow(
                    color:
                        Colors.black.withValues(alpha: _isDark ? 0.20 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2))
              ],
            ),
            child: _isExtractingCv
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(_primaryBlue),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Extracting CV text…',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: _sub)),
                  ])
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: _primaryBlue, shape: BoxShape.circle),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .scaleXY(
                              delay: Duration(milliseconds: i * 180),
                              duration: 400.ms,
                              begin: 0.6,
                              end: 1.0,
                              curve: Curves.easeInOut)
                          .then()
                          .scaleXY(
                              duration: 400.ms,
                              begin: 1.0,
                              end: 0.6,
                              curve: Curves.easeInOut),
                    ),
                  ),
          ),
        ]),
      );

  // ── Quick Reply Bar ────────────────────────────────────────────────────────
  Widget _buildQuickReplyBar() {
    final chips = _buildQuickReplies(_ctx, _hasGoals);
    return Container(
      // ✅ Remove color: _bg from here
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _bg, // ✅ color inside BoxDecoration
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: chips
              .map((chip) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _PressScaleWidget(
                      onTap: () => _send(chip.fullText),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: _border, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: _isDark ? 0.15 : 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(chip.emoji,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 5),
                          Text(chip.label,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _text)),
                        ]),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // ── Input Row ──────────────────────────────────────────────────────────────
  Widget _buildInputRow(bool hasText) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPad = (bottomInset + 16).clamp(16.0, double.infinity);
    return AnimatedContainer(
      duration: 200.ms,
      // ✅ Remove top-level color: _bg
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPad),
      decoration: BoxDecoration(
        color: _bg, // ✅ color lives here only
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_showAttachMenu) _buildAttachMenu(),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          // Attach button
          _PressScaleWidget(
            onTap: () => setState(() => _showAttachMenu = !_showAttachMenu),
            child: AnimatedContainer(
              duration: 200.ms,
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _showAttachMenu ? _primaryBlue : _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _showAttachMenu ? _primaryBlue : _border,
                    width: 1.5),
              ),
              child: Icon(
                  _showAttachMenu
                      ? Icons.close_rounded
                      : Icons.attach_file_rounded,
                  color: _showAttachMenu ? Colors.white : _sub,
                  size: 20),
            ),
          ),
          const SizedBox(width: 8),
          // Text field
          Expanded(
            child: AnimatedContainer(
              duration: 200.ms,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _inputFocused ? _primaryBlue : _border,
                  width: 1.5,
                ),
                boxShadow: _inputFocused
                    ? [
                        BoxShadow(
                          color: _primaryBlue.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _inputFocus,
                minLines: 1,
                maxLines: 4,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _text),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: _send,
                decoration: InputDecoration(
                  hintText: _hasGoals
                      ? 'Ask anything — jobs, skills, interview tips…'
                      : 'Tell me your dream role or ask anything…',
                  hintStyle:
                      GoogleFonts.plusJakartaSans(fontSize: 14, color: _sub),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          _PressScaleWidget(
            onTap: () => _send(_inputCtrl.text),
            child: AnimatedContainer(
              duration: 250.ms,
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: hasText
                    ? const LinearGradient(
                        colors: [_primaryBlue, _accentBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: hasText
                    ? null
                    : _card, // ✅ safe — only one is non-null at a time
                borderRadius: BorderRadius.circular(15),
                border: hasText ? null : Border.all(color: _border, width: 1.5),
                boxShadow: hasText
                    ? [
                        BoxShadow(
                            color: _primaryBlue.withValues(alpha: 0.40),
                            blurRadius: 14,
                            offset: const Offset(0, 5))
                      ]
                    : [],
              ),
              child: Icon(Icons.send_rounded,
                  color: hasText ? Colors.white : _sub, size: 20),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Attachment Menu ────────────────────────────────────────────────────────
  Widget _buildAttachMenu() => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: _isDark ? 0.30 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(children: [
          _attachOption(Icons.picture_as_pdf_rounded, 'Upload CV',
              subtitle: _liveCvFileName ?? 'PDF, DOCX, TXT',
              color: _danger,
              onTap: _pickCvFile),
          const SizedBox(width: 8),
          if (_ctx.navigateTo != null)
            _attachOption(Icons.work_outline_rounded, 'Browse Jobs',
                subtitle: '${_ctx.topJobMatches.length} matches',
                color: _primaryBlue, onTap: () {
              setState(() => _showAttachMenu = false);
              _ctx.navigateTo!('jobs');
            }),
          if (_ctx.navigateTo != null) ...[
            const SizedBox(width: 8),
            _attachOption(Icons.school_outlined, 'Courses',
                subtitle: '${_ctx.recommendedCourses.length} recommended',
                color: _success, onTap: () {
              setState(() => _showAttachMenu = false);
              _ctx.navigateTo!('courses');
            }),
          ],
        ]),
      ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);

  Widget _attachOption(
    IconData icon,
    String label, {
    required Color color,
    required VoidCallback onTap,
    String? subtitle,
  }) =>
      Expanded(
        child: _PressScaleWidget(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.20)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              if (subtitle != null)
                Text(subtitle,
                    style:
                        GoogleFonts.plusJakartaSans(fontSize: 9, color: _sub),
                    overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// OPTIONS SHEET  (unchanged from original)
// ═════════════════════════════════════════════════════════════════════════════

class _OptionsSheet extends StatelessWidget {
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color subColor;
  final bool isDark;

  final bool hasCv;
  final String? cvFileName;
  final bool hasNav;
  final int jobCount;
  final int courseCount;
  final bool hasProfile;

  final VoidCallback onClearChat;
  final VoidCallback onUploadCv;
  final VoidCallback? onBrowseJobs;
  final VoidCallback? onBrowseCourses;
  final VoidCallback? onEditProfile;
  final VoidCallback? onViewSkillGap;
  final VoidCallback? onOpenAssessments;
  final VoidCallback? onCopyLastMessage;

  const _OptionsSheet({
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.subColor,
    required this.isDark,
    required this.hasCv,
    required this.cvFileName,
    required this.hasNav,
    required this.jobCount,
    required this.courseCount,
    required this.hasProfile,
    required this.onClearChat,
    required this.onUploadCv,
    this.onBrowseJobs,
    this.onBrowseCourses,
    this.onEditProfile,
    this.onViewSkillGap,
    this.onOpenAssessments,
    this.onCopyLastMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: borderColor, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 16),
          Text('Chat Options',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 4),
          Text('Manage your SkillBridge session',
              style:
                  GoogleFonts.plusJakartaSans(fontSize: 12, color: subColor)),
          const SizedBox(height: 12),
          _sectionLabel('Chat', subColor),
          _tile(Icons.delete_outline_rounded, 'Clear Chat History',
              subtitle: 'Start a fresh conversation',
              color: const Color(0xFFEF4444),
              textColor: textColor,
              onTap: onClearChat),
          if (onCopyLastMessage != null)
            _tile(Icons.copy_all_rounded, 'Copy Last AI Message',
                subtitle: 'Copy the latest response to clipboard',
                color: const Color(0xFF2563EB),
                textColor: textColor,
                onTap: onCopyLastMessage!),
          const SizedBox(height: 8),
          _sectionLabel('Documents', subColor),
          _tile(Icons.upload_file_rounded, 'Upload / Replace CV',
              subtitle: hasCv
                  ? 'Current: ${cvFileName ?? "uploaded"}'
                  : 'PDF, DOCX, TXT supported',
              color: const Color(0xFFEF4444),
              textColor: textColor,
              onTap: onUploadCv),
          if (hasNav) ...[
            const SizedBox(height: 8),
            _sectionLabel('Navigate', subColor),
            if (onBrowseJobs != null)
              _tile(Icons.work_outline_rounded, 'Browse Job Matches',
                  subtitle: jobCount > 0
                      ? '$jobCount matches available'
                      : 'View all jobs',
                  color: const Color(0xFF2563EB),
                  textColor: textColor,
                  onTap: onBrowseJobs!),
            if (onBrowseCourses != null)
              _tile(Icons.school_outlined, 'Browse Courses',
                  subtitle: courseCount > 0
                      ? '$courseCount recommended for you'
                      : 'View all courses',
                  color: const Color(0xFF10B981),
                  textColor: textColor,
                  onTap: onBrowseCourses!),
            if (onViewSkillGap != null)
              _tile(Icons.bar_chart_rounded, 'Skill Gap Analysis',
                  subtitle: 'See which skills to build next',
                  color: const Color(0xFFF59E0B),
                  textColor: textColor,
                  onTap: onViewSkillGap!),
            if (onOpenAssessments != null)
              _tile(Icons.quiz_outlined, 'Assessments',
                  subtitle: 'Test and verify your skills',
                  color: const Color(0xFF8B5CF6),
                  textColor: textColor,
                  onTap: onOpenAssessments!),
            if (onEditProfile != null)
              _tile(Icons.person_outline_rounded, 'Edit Profile',
                  subtitle: hasProfile
                      ? 'Update your career details'
                      : 'Complete your profile',
                  color: const Color(0xFF2563EB),
                  textColor: textColor,
                  onTap: onEditProfile!),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 4, left: 4),
        child: Text(label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.8)),
      );

  Widget _tile(
    IconData icon,
    String title, {
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
    String? subtitle,
  }) =>
      ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        title: Text(title,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style:
                    GoogleFonts.plusJakartaSans(fontSize: 11, color: subColor))
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}
