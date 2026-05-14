// lib/theme/app_theme.dart — SkillBridge AI
// ──────────────────────────────────────────────────────────────────────────────
// Centralised design-token library.
//
// ── COLOUR TOKEN REFERENCE (for all screens) ─────────────────────────────────
//
//   AppTheme.primaryBlue       = 0xFF1A56DB  — brand blue (all screens)
//   AppTheme.bgDark            = 0xFF0F172A  — dark scaffold bg (main.dart)
//   AppTheme.accentGreen       = 0xFF10B981  — success / skill ring / completion
//   AppTheme.accentTeal        = 0xFF14B8A6  — learning-style / preferences
//   AppTheme.textSecondary     = 0xFF64748B  — muted body text, no isDark needed
//   AppTheme.topicPassed       = 0xFF10B981  — completed topic indicator
//   AppTheme.topicInProgress   = 0xFF0EA5E9  — in-progress topic indicator
//   AppTheme.topicForthcoming  = 0xFF94A3B8  — upcoming / locked topic
//   AppTheme.scoreStrong       = 0xFF10B981  — cosine sim ≥ 0.70
//   AppTheme.scoreModerate     = 0xFFF59E0B  — cosine sim ≥ 0.40
//   AppTheme.scoreWeak         = 0xFFEF4444  — cosine sim < 0.40
//   AppTheme.readinessHigh     = 0xFF10B981  — readiness score ≥ 70
//   AppTheme.readinessMedium   = 0xFFF59E0B  — readiness score ≥ 40
//   AppTheme.readinessLow      = 0xFFEF4444  — readiness score < 40
//
// ── DO NOT add inline colour literals in screen files. ───────────────────────
//    Always use AppTheme.* aliases or AppColors.* constants instead.
// ─────────────────────────────────────────────────────────────────────────────
//
// Contains:
//   • AppColors      — every semantic & palette colour + contextual helpers
//   • AppTextStyles  — Plus Jakarta Sans / JetBrains Mono type scale
//   • AppShadows     — layered elevation shadows
//   • AppGradients   — reusable linear gradients
//   • AppRadii       — border-radius constants
//   • AppSpacing     — 4-pt grid spacing scale
//   • AppDurations   — animation duration constants
//   • AppTheme       — ThemeData + all screen-facing colour aliases
//
// USAGE IN main.dart:
//   MaterialApp(
//     theme:                AppTheme.lightTheme,
//     darkTheme:            AppTheme.darkTheme,
//     themeMode:            appState.themeMode,
//     scaffoldMessengerKey: AppTheme.messengerKey,
//   );
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════════════════════════════════════
// §1  COLOURS
// ══════════════════════════════════════════════════════════════════════════════

abstract final class AppColors {
  // ── Primary blues ────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A56DB);
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryDeep = Color(0xFF1E3A5F);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color accent = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFFEFF6FF);
  static const Color skyBlue = Color(0xFFDBEAFE);

  // ── Semantic colours ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF065F46);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFF92400E);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFF991B1B);
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoLight = Color(0xFFE0F2FE);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFEDE9FE);
  static const Color purpleDark = Color(0xFF4C1D95);
  static const Color teal = Color(0xFF14B8A6);
  static const Color tealLight = Color(0xFFCCFBF1);
  static const Color orange = Color(0xFFF97316);
  static const Color orangeLight = Color(0xFFFFEDD5);

  // ── Light-mode surfaces ──────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8FAFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDivider = Color(0xFFF1F5F9);
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightSubtext = Color(0xFF64748B);
  static const Color lightIcon = Color(0xFF94A3B8);
  static const Color lightOverlay = Color(0x0A000000);

  // ── Dark-mode surfaces ───────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkElevated = Color(0xFF263348);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF1E293B);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkSubtext = Color(0xFF94A3B8);
  static const Color darkIcon = Color(0xFF64748B);
  static const Color darkOverlay = Color(0x1AFFFFFF);

  // ── Utility ──────────────────────────────────────────────────────────────
  static const Color transparent = Color(0x00000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color scrim = Color(0x80000000);

  // ── Contextual helpers (pass isDark from Theme.of(context)) ─────────────
  static Color bg(bool d) => d ? darkBg : lightBg;
  static Color surface(bool d) => d ? darkSurface : lightSurface;
  static Color card(bool d) => d ? darkCard : lightCard;
  static Color borderC(bool d) => d ? darkBorder : lightBorder;
  static Color textC(bool d) => d ? darkText : lightText;
  static Color sub(bool d) => d ? darkSubtext : lightSubtext;
  static Color icon(bool d) => d ? darkIcon : lightIcon;
}

// ══════════════════════════════════════════════════════════════════════════════
// §2  TEXT STYLES  (Plus Jakarta Sans + JetBrains Mono)
// ══════════════════════════════════════════════════════════════════════════════

abstract final class AppTextStyles {
  // ── Display ──────────────────────────────────────────────────────────────
  static TextStyle displayXL(bool d) => GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        height: 1.15,
        color: AppColors.textC(d),
      );

  static TextStyle displayLarge(bool d) => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.2,
        color: AppColors.textC(d),
      );

  static TextStyle displayMedium(bool d) => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.25,
        color: AppColors.textC(d),
      );

  // ── Headings ─────────────────────────────────────────────────────────────
  static TextStyle headingXL(bool d) => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.textC(d),
      );

  static TextStyle headingLarge(bool d) => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: AppColors.textC(d),
      );

  static TextStyle headingMedium(bool d) => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textC(d),
      );

  static TextStyle headingSmall(bool d) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textC(d),
      );

  // ── Body ─────────────────────────────────────────────────────────────────
  static TextStyle bodyLarge(bool d) => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.6,
        color: AppColors.textC(d),
      );

  static TextStyle bodyMedium(bool d) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.sub(d),
      );

  static TextStyle bodySmall(bool d) => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.sub(d),
      );

  // ── Labels ───────────────────────────────────────────────────────────────
  static TextStyle labelXL(bool d) => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: AppColors.textC(d),
      );

  static TextStyle labelLarge(bool d) => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: AppColors.textC(d),
      );

  static TextStyle labelMedium(bool d) => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.sub(d),
      );

  static TextStyle labelSmall(bool d) => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.sub(d),
      );

  // ── Specialised ──────────────────────────────────────────────────────────
  static TextStyle caption(bool d) => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0.3,
        color: AppColors.icon(d),
      );

  static TextStyle overline(bool d) => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.sub(d),
      );

  static TextStyle monoMedium(bool d) => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.textC(d),
      );

  static TextStyle monoSmall(bool d) => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.sub(d),
      );

  /// White version of any style — convenience for buttons / chips on dark bg.
  static TextStyle white(TextStyle base) =>
      base.copyWith(color: AppColors.white);

  /// Primary-colour version of any style.
  static TextStyle primary(TextStyle base) =>
      base.copyWith(color: AppColors.primary);
}

// ══════════════════════════════════════════════════════════════════════════════
// §3  SHADOWS
// ══════════════════════════════════════════════════════════════════════════════

abstract final class AppShadows {
  static List<BoxShadow> card(bool d) => d
      ? const []
      : const [
          BoxShadow(
              color: Color(0x0A1A56DB), blurRadius: 20, offset: Offset(0, 4)),
          BoxShadow(
              color: Color(0x061A56DB), blurRadius: 6, offset: Offset(0, 1)),
        ];

  static List<BoxShadow> elevated(bool d) => d
      ? const []
      : const [
          BoxShadow(
              color: Color(0x181A56DB), blurRadius: 32, offset: Offset(0, 8)),
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ];

  static List<BoxShadow> modal(bool d) => d
      ? const [
          BoxShadow(
              color: Color(0x40000000), blurRadius: 40, offset: Offset(0, 16)),
        ]
      : const [
          BoxShadow(
              color: Color(0x201A56DB), blurRadius: 48, offset: Offset(0, 16)),
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 4)),
        ];

  static const List<BoxShadow> button = [
    BoxShadow(color: Color(0x401A56DB), blurRadius: 20, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x201A56DB), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> chip = [
    BoxShadow(color: Color(0x151A56DB), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> fab = [
    BoxShadow(color: Color(0x501A56DB), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x201A56DB), blurRadius: 8, offset: Offset(0, 3)),
  ];

  static const List<BoxShadow> tooltip = [
    BoxShadow(color: Color(0x30000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> none = [];
}

// ══════════════════════════════════════════════════════════════════════════════
// §4  GRADIENTS
// ══════════════════════════════════════════════════════════════════════════════

abstract final class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF1A56DB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryVertical = LinearGradient(
    colors: [Color(0xFF1A56DB), Color(0xFF3B82F6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient primaryDeep = LinearGradient(
    colors: [Color(0xFF1E3A5F), Color(0xFF1A56DB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warning = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient error = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purple = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient teal = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerLight = LinearGradient(
    colors: [Color(0xFFE2E8F0), Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient shimmerDark = LinearGradient(
    colors: [Color(0xFF334155), Color(0xFF3D4F6A), Color(0xFF334155)],
    stops: [0.0, 0.5, 1.0],
  );

  static LinearGradient shimmer(bool d) => d ? shimmerDark : shimmerLight;

  static LinearGradient cardGlass(bool d) => LinearGradient(
        colors: d
            ? const [Color(0xFF1E293B), Color(0xFF263348)]
            : const [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// §5  RADII
// ══════════════════════════════════════════════════════════════════════════════

abstract final class AppRadii {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double full = 999;

  static BorderRadius get rxs => BorderRadius.circular(xs);
  static BorderRadius get rsm => BorderRadius.circular(sm);
  static BorderRadius get rmd => BorderRadius.circular(md);
  static BorderRadius get rlg => BorderRadius.circular(lg);
  static BorderRadius get rxl => BorderRadius.circular(xl);
  static BorderRadius get rxxl => BorderRadius.circular(xxl);
  static BorderRadius get rxxxl => BorderRadius.circular(xxxl);
  static BorderRadius get rfull => BorderRadius.circular(full);
}

// ══════════════════════════════════════════════════════════════════════════════
// §6  SPACING  (4-pt grid)
// ══════════════════════════════════════════════════════════════════════════════

abstract final class AppSpacing {
  static const double x2 = 2;
  static const double x4 = 4;
  static const double x6 = 6;
  static const double x8 = 8;
  static const double x10 = 10;
  static const double x12 = 12;
  static const double x16 = 16;
  static const double x20 = 20;
  static const double x24 = 24;
  static const double x28 = 28;
  static const double x32 = 32;
  static const double x40 = 40;
  static const double x48 = 48;
  static const double x56 = 56;
  static const double x64 = 64;

  /// Standard horizontal page inset.
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 20);

  /// Standard card inner padding.
  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  /// Comfortable list-item padding.
  static const EdgeInsets listTilePadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);
}

// ══════════════════════════════════════════════════════════════════════════════
// §7  ANIMATION DURATIONS
// ══════════════════════════════════════════════════════════════════════════════

abstract final class AppDurations {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration medium = Duration(milliseconds: 380);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration xslow = Duration(milliseconds: 700);
  static const Duration page = Duration(milliseconds: 350);
  static const Duration modal = Duration(milliseconds: 420);
}

// ══════════════════════════════════════════════════════════════════════════════
// §8  THEME DATA  +  ALL SCREEN-FACING COLOUR ALIASES
// ══════════════════════════════════════════════════════════════════════════════

abstract final class AppTheme {
  // ── Global messenger key ─────────────────────────────────────────────────
  /// Passed to MaterialApp.scaffoldMessengerKey.
  /// Must be `final` (not `const`) — GlobalKey is a runtime object.
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // ── ThemeData property getters ───────────────────────────────────────────
  /// Used as MaterialApp.theme / MaterialApp.darkTheme (property, not call).
  static ThemeData get lightTheme => light();
  static ThemeData get darkTheme => dark();

  // ══════════════════════════════════════════════════════════════════════════
  // COLOUR ALIASES
  // All screen files MUST use these aliases instead of inline Color literals.
  // Add new aliases here whenever a screen introduces a new semantic token.
  // ══════════════════════════════════════════════════════════════════════════

  // ── Brand ─────────────────────────────────────────────────────────────────
  /// Primary brand blue — all screens.
  static const Color primaryBlue = AppColors.primary; // 0xFF1A56DB

  /// Dark scaffold background — main.dart SystemUiOverlayStyle.
  static const Color bgDark = AppColors.darkBg; // 0xFF0F172A

  // ── Accent colours ────────────────────────────────────────────────────────
  /// Green accent — skill rings, course completion, success states.
  static const Color accentGreen = AppColors.success; // 0xFF10B981

  /// Teal accent — learning-style indicators, content preferences.
  static const Color accentTeal = AppColors.teal; // 0xFF14B8A6

  // ── Fixed-context text ────────────────────────────────────────────────────
  /// Secondary body text — slate-500, readable on both light & dark surfaces
  /// without needing an isDark check. Use for subtitles, captions, footnotes.
  static const Color textSecondary = AppColors.lightSubtext; // 0xFF64748B

  // ── Topic-status tokens  (TopicStatusExt — main.dart) ────────────────────
  /// Completed topic node — green.
  static const Color topicPassed = AppColors.success; // 0xFF10B981

  /// In-progress topic node — sky blue.
  static const Color topicInProgress = AppColors.info; // 0xFF0EA5E9

  /// Upcoming / locked topic node — slate icon.
  static const Color topicForthcoming = AppColors.lightIcon; // 0xFF94A3B8

  // ── Semantic-similarity score tokens  (simScoreColor — main.dart) ────────
  /// Strong match  (score ≥ 0.70).
  static const Color scoreStrong = AppColors.success; // 0xFF10B981

  /// Moderate match (score ≥ 0.40).
  static const Color scoreModerate = AppColors.warning; // 0xFFF59E0B

  /// Weak match    (score < 0.40).
  static const Color scoreWeak = AppColors.error; // 0xFFEF4444

  // ── Career-readiness tokens  (readinessColor — main.dart) ────────────────
  /// Job-ready tier  (score ≥ 70).
  static const Color readinessHigh = AppColors.success; // 0xFF10B981

  /// Developing tier (score ≥ 40).
  static const Color readinessMedium = AppColors.warning; // 0xFFF59E0B

  /// Needs-work tier (score < 40).
  static const Color readinessLow = AppColors.error; // 0xFFEF4444

  // ── Shared text theme ────────────────────────────────────────────────────
  static TextTheme _textTheme(bool d) => TextTheme(
        displayLarge: AppTextStyles.displayLarge(d),
        displayMedium: AppTextStyles.displayMedium(d),
        displaySmall: AppTextStyles.headingXL(d),
        headlineLarge: AppTextStyles.headingLarge(d),
        headlineMedium: AppTextStyles.headingMedium(d),
        headlineSmall: AppTextStyles.headingSmall(d),
        titleLarge: AppTextStyles.labelXL(d),
        titleMedium: AppTextStyles.labelLarge(d),
        titleSmall: AppTextStyles.labelMedium(d),
        bodyLarge: AppTextStyles.bodyLarge(d),
        bodyMedium: AppTextStyles.bodyMedium(d),
        bodySmall: AppTextStyles.bodySmall(d),
        labelLarge: AppTextStyles.labelLarge(d),
        labelMedium: AppTextStyles.labelMedium(d),
        labelSmall: AppTextStyles.labelSmall(d),
      );

  // ── Shared input decoration theme ────────────────────────────────────────
  static InputDecorationTheme _inputTheme(bool d) => InputDecorationTheme(
        filled: true,
        fillColor: d ? AppColors.darkSurface : AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: AppRadii.rmd,
          borderSide: BorderSide(
              color: d ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.rmd,
          borderSide: BorderSide(
              color: d ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.rmd,
          borderSide: BorderSide(
              color: d ? AppColors.primaryLight : AppColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: AppTextStyles.bodyMedium(d),
        hintStyle: TextStyle(
            color: d ? AppColors.darkIcon : AppColors.lightIcon, fontSize: 14),
      );

  // ── Light theme ──────────────────────────────────────────────────────────
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.lightSurface,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.lightBg,
        textTheme: _textTheme(false),
        inputDecorationTheme: _inputTheme(false),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.lightBg,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: const Color(0x0A1A56DB),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: AppTextStyles.headingLarge(false),
          iconTheme: const IconThemeData(color: AppColors.lightText),
        ),
        cardTheme: CardThemeData(
          color: AppColors.lightCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.rlg,
            side: const BorderSide(color: AppColors.lightBorder),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.lightDivider,
          thickness: 1,
          space: 1,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: AppRadii.rlg),
            textStyle:
                AppTextStyles.labelXL(false).copyWith(color: AppColors.white),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: AppRadii.rlg),
            textStyle: AppTextStyles.labelXL(false),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.lightSurface,
          side: const BorderSide(color: AppColors.lightBorder),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.rfull),
          labelStyle: AppTextStyles.labelMedium(false),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.lightBg,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.lightIcon,
          elevation: 0,
        ),
        iconTheme: const IconThemeData(color: AppColors.lightIcon),
      );

  // ── Dark theme ───────────────────────────────────────────────────────────
  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primaryLight,
          secondary: AppColors.accent,
          surface: AppColors.darkSurface,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.darkBg,
        textTheme: _textTheme(true),
        inputDecorationTheme: _inputTheme(true),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkBg,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: const Color(0x20000000),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: AppTextStyles.headingLarge(true),
          iconTheme: const IconThemeData(color: AppColors.darkText),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.rlg,
            side: const BorderSide(color: AppColors.darkBorder),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkDivider,
          thickness: 1,
          space: 1,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: AppRadii.rlg),
            textStyle:
                AppTextStyles.labelXL(true).copyWith(color: AppColors.white),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: AppRadii.rlg),
            textStyle: AppTextStyles.labelXL(true),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.darkSurface,
          side: const BorderSide(color: AppColors.darkBorder),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.rfull),
          labelStyle: AppTextStyles.labelMedium(true),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkSurface,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.darkIcon,
          elevation: 0,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkIcon),
      );
}
