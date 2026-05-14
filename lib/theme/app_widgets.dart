// lib/theme/app_widgets.dart — SkillBridge AI
// ──────────────────────────────────────────────────────────────────────────────
// Production-grade, reusable widget library.

// Contains:
//   • AppWidgetMixin         — dark-mode helpers to mix into every State
//   • AppBtn                 — primary gradient, outlined, text, icon buttons
//   • AppCard                — elevated / flat card containers
//   • AppChip                — status, priority, skill, filter chips
//   • AppInput               — styled TextFormField wrapper
//   • AppBadge               — notification / count badges
//   • AppAvatar              — user / company avatar with fallback initials
//   • AppTag                 — coloured semantic tags (job type, etc.)
//   • AppStepBar             — multi-step progress indicator
//   • AppSectionHeader       — section title row with optional action
//   • AppEmptyState          — full empty / error state with CTA
//   • AppLoadingShimmer      — shimmer skeleton placeholder
//   • AppDividerLabel        — divider with centred label
//   • AppInfoRow             — icon + label + value row
//   • AppStatCard            — metric stat card (number + label)
//   • AppSnackbar            — themed snackbar helpers
//   • AppBottomSheet         — styled modal bottom sheet launcher
//   • AppProgressRing        — circular percentage indicator
//   • AppRatingBar           — read-only star rating display
//   • AppToggle              — custom animated toggle switch
//   • AppSearchBar           — styled search input with icon
//   • AppDarkToggle          — light/dark mode switcher button
//   • AppGradientIcon        — icon on a gradient circular background
//   • AppTextHighlight       — inline text with highlighted keyword
//   • AppCounterBadge        — floating notification counter
// ──────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import 'app_theme.dart'; // provides AppColors, AppTextStyles, AppShadows,
// AppGradients, AppRadii, AppSpacing, AppDurations

// ══════════════════════════════════════════════════════════════════════════════
// DARK-MODE MIXIN  —  add `with AppWidgetMixin` to every State<T>
// ══════════════════════════════════════════════════════════════════════════════

mixin AppWidgetMixin<T extends StatefulWidget> on State<T> {
  bool _isDark = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDark = Theme.of(context).brightness == Brightness.dark;
  }

  // ── Toggle — delegates to AppState so the change propagates through ───────
  // MaterialApp(themeMode:) and persists across sessions.
  // Do NOT call setState here; didChangeDependencies() will update _isDark
  // automatically once the inherited theme rebuilds.
  void toggleDark() {
    context.read<AppState>().setThemeMode(
          _isDark ? ThemeMode.light : ThemeMode.dark,
        );
  }

  // ── Colour shorthands ────────────────────────────────────────────────────
  Color get appBg => _isDark ? AppColors.darkBg : AppColors.lightBg;
  Color get appCard => _isDark ? AppColors.darkCard : AppColors.lightCard;
  Color get appBorder => _isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get appText => _isDark ? AppColors.darkText : AppColors.lightText;
  Color get appSub => _isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
  Color get appIcon => _isDark ? AppColors.darkIcon : AppColors.lightIcon;
  Color get appSurface =>
      _isDark ? AppColors.darkSurface : AppColors.lightSurface;

  // ── Single canonical dark-mode toggle for AppBar.actions ────────────────
  //
  // Usage — add EXACTLY ONE of these to every AppBar's actions list:
  //
  //   AppBar(
  //     actions: [ buildDarkToggle() ],
  //   )
  //
  // Do NOT also add another toggle widget anywhere on the same screen —
  // that is what causes the duplicate button.
  Widget buildDarkToggle() => GestureDetector(
        onTap: toggleDark,
        child: AnimatedContainer(
          duration: AppDurations.normal,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isDark ? AppColors.darkSurface : AppColors.lightBlue,
            borderRadius: AppRadii.rsm,
            border: Border.all(
              color: _isDark ? AppColors.darkBorder : AppColors.skyBlue,
            ),
          ),
          child: AnimatedSwitcher(
            duration: AppDurations.fast,
            transitionBuilder: (child, animation) => RotationTransition(
              turns: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              _isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              key: ValueKey<bool>(_isDark),
              color: _isDark ? const Color(0xFFFBBF24) : AppColors.primary,
              size: 18,
            ),
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// APP BUTTON FAMILY
// ══════════════════════════════════════════════════════════════════════════════

/// Gradient primary button — full-width by default.
class AppPrimaryBtn extends StatelessWidget {
  const AppPrimaryBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.verticalPadding = 16,
    this.fontSize = 15,
    this.borderRadius = 14,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final double verticalPadding;
  final double fontSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.55 : 1.0,
        duration: AppDurations.fast,
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: fullWidth ? 0 : 24,
          ),
          decoration: BoxDecoration(
            gradient: onTap == null ? null : AppGradients.primary,
            color: onTap == null ? AppColors.lightIcon : null,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: onTap == null ? [] : AppShadows.button,
          ),
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: AppColors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Outlined secondary button — full-width by default.
class AppOutlineBtn extends StatelessWidget {
  const AppOutlineBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.fullWidth = true,
    this.color = AppColors.primary,
    this.borderRadius = 14,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool fullWidth;
  final Color color;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          vertical: 14,
          horizontal: fullWidth ? 0 : 24,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ghost text button — no background, no border.
class AppTextBtn extends StatelessWidget {
  const AppTextBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppColors.primary,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w600,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }
}

/// Small square/circular icon button with optional background.
class AppIconBtn extends StatelessWidget {
  const AppIconBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.iconSize = 18,
    this.isDark = false,
    this.filled = false,
    this.color,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final bool isDark;
  final bool filled;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        color ?? (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    Widget btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? bgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(size / 2.5),
          border: filled
              ? Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                )
              : null,
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP CARD
// ══════════════════════════════════════════════════════════════════════════════

/// Standard content card with border, shadow, and optional press effect.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    required this.isDark,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius = 16,
    this.borderColor,
    this.backgroundColor,
  });

  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg =
        backgroundColor ?? (isDark ? AppColors.darkCard : AppColors.lightCard);
    final border =
        borderColor ?? (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    Widget card = Container(
      margin: margin,
      padding: padding ?? AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border),
        boxShadow: AppShadows.card(isDark),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}

/// Gradient-bordered premium card (for featured jobs, AI suggestions, etc.)
class AppGradientCard extends StatelessWidget {
  const AppGradientCard({
    super.key,
    required this.child,
    required this.isDark,
    this.padding,
    this.margin,
    this.onTap,
    this.gradient = AppGradients.primary,
    this.borderWidth = 1.5,
    this.borderRadius = 16,
  });

  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Gradient gradient;
  final double borderWidth;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius + borderWidth),
        ),
        child: Container(
          padding: padding ?? AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP CHIP FAMILY
// ══════════════════════════════════════════════════════════════════════════════

/// Coloured status / semantic chip (e.g. "Full-time", "Remote", "Urgent").
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
    this.fontSize = 11,
    this.padding,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.rfull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable skill / filter tag pill.
class AppSkillTag extends StatelessWidget {
  const AppSkillTag({
    super.key,
    required this.label,
    required this.isDark,
    this.selected = false,
    this.onTap,
    this.fontSize = 12,
  });

  final String label;
  final bool isDark;
  final bool selected;
  final VoidCallback? onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppColors.primary
        : (isDark ? AppColors.darkSurface : AppColors.lightBlue);
    final border = selected
        ? AppColors.primary
        : (isDark ? AppColors.darkBorder : AppColors.skyBlue);
    final fg = selected
        ? AppColors.white
        : (isDark ? AppColors.darkSubtext : AppColors.primary);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 1.5),
          borderRadius: AppRadii.rfull,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// Job-type semantic tag (e.g. "Full-time", "Internship", "Remote").
class AppJobTag extends StatelessWidget {
  const AppJobTag(this.type, {super.key});

  final String type;

  static const _map = <String, _TagStyle>{
    'Full-time': _TagStyle(Color(0xFFEFF6FF), Color(0xFF1A56DB)),
    'Part-time': _TagStyle(Color(0xFFEDE9FE), Color(0xFF7C3AED)),
    'Internship': _TagStyle(Color(0xFFD1FAE5), Color(0xFF059669)),
    'Freelance': _TagStyle(Color(0xFFFEF3C7), Color(0xFFD97706)),
    'Remote': _TagStyle(Color(0xFFCCFBF1), Color(0xFF0D9488)),
    'Hybrid': _TagStyle(Color(0xFFFFEDD5), Color(0xFFEA580C)),
    'Contract': _TagStyle(Color(0xFFFEE2E2), Color(0xFFDC2626)),
  };

  @override
  Widget build(BuildContext context) {
    final style =
        _map[type] ?? const _TagStyle(AppColors.lightBlue, AppColors.primary);
    return AppChip(label: type, bg: style.bg, fg: style.fg);
  }
}

class _TagStyle {
  const _TagStyle(this.bg, this.fg);
  final Color bg;
  final Color fg;
}

// ══════════════════════════════════════════════════════════════════════════════
// APP INPUT
// ══════════════════════════════════════════════════════════════════════════════

/// Fully styled TextFormField with theme-aware decoration.
class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    required this.label,
    required this.isDark,
    this.controller,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.textInputAction,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
  });

  final String label;
  final bool isDark;
  final TextEditingController? controller;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int maxLines;
  final int? minLines;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final fill = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final sub = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      textInputAction: textInputAction,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkText : AppColors.lightText,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: sub),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: isDark ? AppColors.darkIcon : AppColors.lightIcon,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.primary, size: 20)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: AppRadii.rmd,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.rmd,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        // FIX: withOpacity → withValues(alpha:)
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.rmd,
          borderSide: BorderSide(color: border.withValues(alpha: 0.5)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP SEARCH BAR
// ══════════════════════════════════════════════════════════════════════════════

/// Styled search input with leading search icon and optional trailing filter.
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.isDark,
    this.controller,
    this.hint = 'Search jobs, skills, companies…',
    this.onChanged,
    this.onTap,
    this.onFilter,
    this.readOnly = false,
    this.autofocus = false,
  });

  final bool isDark;
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onFilter;
  final bool readOnly;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final fill = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: readOnly ? onTap : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: AppRadii.rmd,
                border: Border.all(color: border),
              ),
              child: readOnly
                  ? Row(
                      children: [
                        const Icon(Icons.search_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          hint,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkIcon
                                : AppColors.lightIcon,
                          ),
                        ),
                      ],
                    )
                  : TextField(
                      controller: controller,
                      onChanged: onChanged,
                      autofocus: autofocus,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color:
                            isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color:
                              isDark ? AppColors.darkIcon : AppColors.lightIcon,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.primary, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
            ),
          ),
        ),
        if (onFilter != null) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onFilter,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: AppRadii.rmd,
                boxShadow: AppShadows.button,
              ),
              child: const Icon(Icons.tune_rounded,
                  color: AppColors.white, size: 20),
            ),
          ),
        ],
      ],
    );
  }
}

// AppDarkToggle has been consolidated into AppWidgetMixin.buildDarkToggle().
// Use buildDarkToggle() from the mixin — do not add a second toggle widget.

// ══════════════════════════════════════════════════════════════════════════════
// APP AVATAR
// ══════════════════════════════════════════════════════════════════════════════

/// User / company avatar with image URL, fallback initials, and online dot.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 44,
    this.isDark = false,
    this.showOnline = false,
    this.borderColor,
    this.onTap,
  });

  final String? imageUrl;
  final String name;
  final double size;
  final bool isDark;
  final bool showOnline;
  final Color? borderColor;
  final VoidCallback? onTap;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: imageUrl == null ? AppGradients.primary : null,
              border: borderColor != null
                  ? Border.all(color: borderColor!, width: 2)
                  : null,
            ),
            child: imageUrl != null
                ? ClipOval(
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initialsWidget,
                    ),
                  )
                : _initialsWidget,
          ),
          if (showOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkBg : AppColors.lightBg,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget get _initialsWidget => Center(
        child: Text(
          _initials,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.white,
            fontSize: (size * 0.35).clamp(10, 18),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// APP BADGE
// ══════════════════════════════════════════════════════════════════════════════

/// Notification dot badge to overlay on icons.
class AppCounterBadge extends StatelessWidget {
  const AppCounterBadge({
    super.key,
    required this.child,
    this.count = 0,
    this.showZero = false,
    this.color = AppColors.error,
  });

  final Widget child;
  final int count;
  final bool showZero;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final show = count > 0 || showZero;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (show)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: count > 9
                  ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
                  : const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadii.rfull,
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP STEP BAR
// ══════════════════════════════════════════════════════════════════════════════

/// Horizontal segmented progress bar for multi-step flows.
class AppStepBar extends StatelessWidget {
  const AppStepBar({
    super.key,
    required this.current,
    required this.total,
    required this.isDark,
    this.height = 4,
    this.gap = 4,
  });

  final int current; // 0-indexed
  final int total;
  final bool isDark;
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(total, (i) {
          final active = i <= current;
          return Expanded(
            child: AnimatedContainer(
              duration: AppDurations.normal,
              margin: EdgeInsets.only(right: i < total - 1 ? gap : 0),
              height: height,
              decoration: BoxDecoration(
                gradient: active ? AppGradients.primary : null,
                color: active
                    ? null
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                borderRadius: AppRadii.rfull,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP SECTION HEADER
// ══════════════════════════════════════════════════════════════════════════════

/// Title row with optional "See all" / action link.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    required this.isDark,
    this.action,
    this.onAction,
    this.icon,
    this.padding,
  });

  final String title;
  final bool isDark;
  final String? action;
  final VoidCallback? onAction;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? AppSpacing.pagePadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: AppRadii.rxs,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 14),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ],
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                children: [
                  Text(
                    action!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.primary, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP EMPTY STATE
// ══════════════════════════════════════════════════════════════════════════════

/// Full-screen / in-area empty / error state with optional CTA button.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.btnLabel,
    this.onBtn,
    this.iconColor = AppColors.primary,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final String? btnLabel;
  final VoidCallback? onBtn;
  final Color iconColor;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightBlue;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTextStyles.headingLarge(isDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium(isDark),
              textAlign: TextAlign.center,
            ),
            if (btnLabel != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: 200,
                child: AppPrimaryBtn(
                  label: btnLabel!,
                  onTap: onBtn ?? () {},
                  verticalPadding: 14,
                  fontSize: 14,
                  borderRadius: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP LOADING SHIMMER
// ══════════════════════════════════════════════════════════════════════════════

/// Animated shimmer skeleton for loading placeholders.
class AppShimmer extends StatefulWidget {
  const AppShimmer({
    super.key,
    required this.isDark,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final bool isDark;
  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: widget.isDark
                  ? const [
                      Color(0xFF334155),
                      Color(0xFF3D4F6A),
                      Color(0xFF334155),
                    ]
                  : const [
                      Color(0xFFE2E8F0),
                      Color(0xFFF1F5F9),
                      Color(0xFFE2E8F0),
                    ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Pre-built shimmer card skeleton (matches AppCard layout).
class AppShimmerCard extends StatelessWidget {
  const AppShimmerCard({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: AppSpacing.cardPadding,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: AppRadii.rlg,
        border: Border.all(color: border),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppShimmer(
                  isDark: isDark, width: 44, height: 44, borderRadius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppShimmer(isDark: isDark, height: 14, borderRadius: 6),
                    const SizedBox(height: 6),
                    AppShimmer(
                        isDark: isDark,
                        width: 120,
                        height: 11,
                        borderRadius: 6),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppShimmer(isDark: isDark, height: 12, borderRadius: 6),
          const SizedBox(height: 6),
          AppShimmer(isDark: isDark, width: 160, height: 12, borderRadius: 6),
          const SizedBox(height: 14),
          Row(
            children: [
              AppShimmer(
                  isDark: isDark, width: 72, height: 24, borderRadius: 100),
              const SizedBox(width: 8),
              AppShimmer(
                  isDark: isDark, width: 56, height: 24, borderRadius: 100),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP DIVIDER WITH LABEL
// ══════════════════════════════════════════════════════════════════════════════

/// Horizontal rule with centred text label (e.g. "or continue with").
class AppDividerLabel extends StatelessWidget {
  const AppDividerLabel({
    super.key,
    required this.label,
    required this.isDark,
  });

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: AppTextStyles.labelSmall(isDark),
          ),
        ),
        Expanded(child: Divider(color: color, thickness: 1)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP INFO ROW
// ══════════════════════════════════════════════════════════════════════════════

/// Icon + label–value pair used in job details, profiles, etc.
class AppInfoRow extends StatelessWidget {
  const AppInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.isDark,
    this.value,
    this.valueWidget,
    this.iconColor = AppColors.primary,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool isDark;
  final Color iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            // FIX: withOpacity → withValues(alpha:)
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: AppRadii.rxs,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelSmall(isDark)),
              const SizedBox(height: 2),
              valueWidget ??
                  Text(
                    value ?? '',
                    style: AppTextStyles.bodyLarge(isDark).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP STAT CARD
// ══════════════════════════════════════════════════════════════════════════════

/// Single metric tile — number + label + optional icon.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.isDark,
    this.icon,
    this.color = AppColors.primary,
    this.bgGradient,
    this.onTap,
  });

  final String value;
  final String label;
  final bool isDark;
  final IconData? icon;
  final Color color;
  final Gradient? bgGradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isGradient = bgGradient != null;
    final bg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isGradient ? bgGradient : null,
          color: isGradient ? null : bg,
          borderRadius: AppRadii.rlg,
          border: isGradient ? null : Border.all(color: border),
          boxShadow: isGradient
              ? AppShadows.elevated(isDark)
              : AppShadows.card(isDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, color: isGradient ? AppColors.white : color, size: 22),
              const SizedBox(height: 10),
            ],
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isGradient
                    ? AppColors.white
                    : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                // FIX: withOpacity → withValues(alpha:)
                color: isGradient
                    ? AppColors.white.withValues(alpha: 0.8)
                    : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP PROGRESS RING
// ══════════════════════════════════════════════════════════════════════════════

/// Circular percentage / score ring.
class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    super.key,
    required this.value, // 0.0 – 1.0
    required this.isDark,
    this.size = 72,
    this.strokeWidth = 6,
    this.color = AppColors.primary,
    this.label,
    this.centerText,
  });

  final double value;
  final bool isDark;
  final double size;
  final double strokeWidth;
  final Color color;
  final String? label;
  final String? centerText;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  progress: value.clamp(0.0, 1.0),
                  color: color,
                  bgColor: bg,
                  strokeWidth: strokeWidth,
                ),
              ),
              if (centerText != null)
                Text(
                  centerText!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
            ],
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 6),
          Text(label!, style: AppTextStyles.labelSmall(isDark)),
        ],
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color bgColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2;

    // Background arc
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * progress,
        false,
        Paint()
          ..shader = LinearGradient(
            // FIX: withOpacity → withValues(alpha:)
            colors: [color, color.withValues(alpha: 0.6)],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ══════════════════════════════════════════════════════════════════════════════
// APP RATING BAR
// ══════════════════════════════════════════════════════════════════════════════

/// Read-only star rating display (supports half-stars).
class AppRatingBar extends StatelessWidget {
  const AppRatingBar({
    super.key,
    required this.rating,
    this.starSize = 16,
    this.color = const Color(0xFFFBBF24),
    this.count,
    this.isDark = false,
  });

  final double rating;
  final double starSize;
  final Color color;
  final int? count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final filled = rating - i;
          IconData icon;
          if (filled >= 1) {
            icon = Icons.star_rounded;
          } else if (filled >= 0.5) {
            icon = Icons.star_half_rounded;
          } else {
            icon = Icons.star_outline_rounded;
          }
          return Icon(icon, size: starSize, color: color);
        }),
        if (count != null) ...[
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: starSize * 0.8,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP TOGGLE SWITCH
// ══════════════════════════════════════════════════════════════════════════════

/// Custom animated toggle switch with branded colours.
class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.isDark = false,
    this.activeColor = AppColors.primary,
    this.width = 44,
    this.height = 24,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;
  final Color activeColor;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final trackColor = value
        ? activeColor
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final thumbLeft = value ? width - height + 2 : 2.0;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: width,
        height: height,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: AppRadii.rfull,
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: AppDurations.fast,
              curve: Curves.easeInOut,
              left: thumbLeft,
              child: Container(
                width: height - 4,
                height: height - 4,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP GRADIENT ICON
// ══════════════════════════════════════════════════════════════════════════════

/// Icon on a gradient rounded-square background (for feature highlights).
class AppGradientIcon extends StatelessWidget {
  const AppGradientIcon({
    super.key,
    required this.icon,
    this.gradient = AppGradients.primary,
    this.size = 48,
    this.iconSize = 22,
    this.borderRadius = 12,
  });

  final IconData icon;
  final Gradient gradient;
  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppShadows.button,
      ),
      child: Icon(icon, color: AppColors.white, size: iconSize),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP SNACKBAR HELPERS
// ══════════════════════════════════════════════════════════════════════════════

/// Centralized snackbar utilities with semantic styles.
abstract final class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.info_outline_rounded,
    Color color = AppColors.primary,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: AppColors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.rmd),
          margin: const EdgeInsets.all(16),
          duration: duration,
          elevation: 4,
        ),
      );
  }

  static void success(BuildContext context, String message) => show(
        context,
        message: message,
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.success,
      );

  static void error(BuildContext context, String message) => show(
        context,
        message: message,
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
      );

  static void warning(BuildContext context, String message) => show(
        context,
        message: message,
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
      );

  static void info(BuildContext context, String message) => show(
        context,
        message: message,
        icon: Icons.info_outline_rounded,
        color: AppColors.primary,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// APP BOTTOM SHEET LAUNCHER
// ══════════════════════════════════════════════════════════════════════════════

/// Launches a styled modal bottom sheet with drag handle & branded decoration.
abstract final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    required bool isDark,
    bool isScrollControlled = true,
    double maxHeightFraction = 0.92,
    String? title,
    bool showDragHandle = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      useSafeArea: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * maxHeightFraction,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.xxl),
          ),
          boxShadow: AppShadows.modal(isDark),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDragHandle) ...[
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: AppRadii.rfull,
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: AppTextStyles.headingLarge(isDark)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          borderRadius: AppRadii.rxs,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Divider(
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                height: 1,
              ),
            ],
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP TEXT HIGHLIGHT
// ══════════════════════════════════════════════════════════════════════════════

/// Inline text with a highlighted keyword (for search result emphasis).
class AppTextHighlight extends StatelessWidget {
  const AppTextHighlight({
    super.key,
    required this.text,
    required this.highlight,
    required this.isDark,
    this.style,
    this.highlightColor = const Color(0xFFFEF3C7),
    this.highlightTextColor = const Color(0xFFD97706),
  });

  final String text;
  final String highlight;
  final bool isDark;
  final TextStyle? style;
  final Color highlightColor;
  final Color highlightTextColor;

  @override
  Widget build(BuildContext context) {
    if (highlight.isEmpty) {
      return Text(text, style: style ?? AppTextStyles.bodyMedium(isDark));
    }

    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final query = highlight.toLowerCase();
    int start = 0;

    while (true) {
      final idx = lower.indexOf(query, start);
      if (idx < 0) {
        spans.add(TextSpan(
          text: text.substring(start),
          style: style ?? AppTextStyles.bodyMedium(isDark),
        ));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(
          text: text.substring(start, idx),
          style: style ?? AppTextStyles.bodyMedium(isDark),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + highlight.length),
        style: (style ?? AppTextStyles.bodyMedium(isDark)).copyWith(
          color: highlightTextColor,
          backgroundColor: highlightColor,
          fontWeight: FontWeight.w700,
        ),
      ));
      start = idx + highlight.length;
    }

    return RichText(text: TextSpan(children: spans));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP COMPANY LOGO TILE
// ══════════════════════════════════════════════════════════════════════════════

/// Company logo square with rounded corners, fallback letter, and subtle border.
class AppCompanyLogo extends StatelessWidget {
  const AppCompanyLogo({
    super.key,
    this.imageUrl,
    required this.name,
    required this.isDark,
    this.size = 48,
    this.borderRadius = 10,
  });

  final String? imageUrl;
  final String name;
  final bool isDark;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border),
      ),
      child: imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius - 1),
              child: Image.network(
                imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _fallback(initial),
              ),
            )
          : _fallback(initial),
    );
  }

  Widget _fallback(String initial) => Center(
        child: Text(
          initial,
          style: GoogleFonts.plusJakartaSans(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// APP MATCH SCORE BADGE
// ══════════════════════════════════════════════════════════════════════════════

/// AI-match percentage badge (green → yellow → red gradient semantics).
class AppMatchBadge extends StatelessWidget {
  const AppMatchBadge({
    super.key,
    required this.score, // 0–100
  });

  final int score;

  Color get _color {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  Color get _bgColor {
    if (score >= 75) return AppColors.successLight;
    if (score >= 50) return AppColors.warningLight;
    return AppColors.errorLight;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: AppRadii.rfull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 11, color: _color),
          const SizedBox(width: 4),
          Text(
            '$score% Match',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP SALARY DISPLAY
// ══════════════════════════════════════════════════════════════════════════════

/// Formatted salary range text with currency symbol.
class AppSalaryDisplay extends StatelessWidget {
  const AppSalaryDisplay({
    super.key,
    required this.min,
    required this.max,
    required this.isDark,
    this.currency = '৳',
    this.period = '/mo',
    this.fontSize = 14,
    this.highlight = false,
  });

  final num min;
  final num max;
  final bool isDark;
  final String currency;
  final String period;
  final double fontSize;
  final bool highlight;

  String _format(num n) {
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = highlight
        ? AppColors.success
        : (isDark ? AppColors.darkText : AppColors.lightText);

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$currency${_format(min)} – ${_format(max)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          TextSpan(
            text: period,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize - 2,
              fontWeight: FontWeight.w400,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP DEADLINE CHIP
// ══════════════════════════════════════════════════════════════════════════════

/// Shows days-remaining with colour urgency cues.
class AppDeadlineChip extends StatelessWidget {
  const AppDeadlineChip({
    super.key,
    required this.deadline,
  });

  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = deadline.difference(now).inDays;

    Color bg;
    Color fg;
    String label;
    IconData icon;

    if (diff < 0) {
      bg = AppColors.errorLight;
      fg = AppColors.error;
      label = 'Expired';
      icon = Icons.event_busy_rounded;
    } else if (diff == 0) {
      bg = AppColors.errorLight;
      fg = AppColors.error;
      label = 'Today';
      icon = Icons.timelapse_rounded;
    } else if (diff <= 3) {
      bg = AppColors.warningLight;
      fg = AppColors.warning;
      label = '$diff d left';
      icon = Icons.timelapse_rounded;
    } else {
      bg = AppColors.successLight;
      fg = AppColors.success;
      label = '$diff d left';
      icon = Icons.event_available_rounded;
    }

    return AppChip(label: label, bg: bg, fg: fg, icon: icon);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP EXPANDABLE TEXT
// ══════════════════════════════════════════════════════════════════════════════

/// "Read more / less" collapsible text widget.
class AppExpandableText extends StatefulWidget {
  const AppExpandableText({
    super.key,
    required this.text,
    required this.isDark,
    this.maxLines = 3,
    this.style,
  });

  final String text;
  final bool isDark;
  final int maxLines;
  final TextStyle? style;

  @override
  State<AppExpandableText> createState() => _AppExpandableTextState();
}

class _AppExpandableTextState extends State<AppExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? AppTextStyles.bodyMedium(widget.isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: AppDurations.normal,
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: Text(
            widget.text,
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
          secondChild: Text(widget.text, style: style),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Show less' : 'Read more',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP NOTIFICATION TILE
// ══════════════════════════════════════════════════════════════════════════════

/// Standard notification list item.
class AppNotificationTile extends StatelessWidget {
  const AppNotificationTile({
    super.key,
    required this.title,
    required this.body,
    required this.time,
    required this.isDark,
    this.icon = Icons.notifications_outlined,
    this.iconColor = AppColors.primary,
    this.isRead = false,
    this.onTap,
  });

  final String title;
  final String body;
  final String time;
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final bool isRead;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkCard : AppColors.lightCard;
    // FIX: withOpacity → withValues(alpha:)
    final unreadBg = isDark
        ? AppColors.darkSurface
        : AppColors.lightBlue.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: isRead ? bg : unreadBg,
        padding: AppSpacing.listTilePadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                // FIX: withOpacity → withValues(alpha:)
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: AppRadii.rsm,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: AppTextStyles.labelLarge(isDark)),
                      ),
                      Text(time, style: AppTextStyles.caption(isDark)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall(isDark)),
                ],
              ),
            ),
            if (!isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP LIST ITEM (generic)
// ══════════════════════════════════════════════════════════════════════════════

/// Generic list tile with leading widget, title, subtitle, and trailing.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.isDark,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.contentPadding,
  });

  final bool isDark;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: contentPadding ?? AppSpacing.listTilePadding,
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 14)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.bodyLarge(isDark)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: AppTextStyles.bodySmall(isDark)),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP PAGE WRAPPER
// ══════════════════════════════════════════════════════════════════════════════

/// Consistent page scaffold wrapper with AppBar, sliver support, and theming.
class AppPageWrapper extends StatelessWidget {
  const AppPageWrapper({
    super.key,
    required this.child,
    required this.isDark,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = true,
    this.padding,
  });

  final Widget child;
  final bool isDark;
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: title != null || actions != null || leading != null
          ? AppBar(
              backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
              elevation: 0,
              scrolledUnderElevation: 1,
              shadowColor: const Color(0x0A1A56DB),
              leading: leading,
              title: title != null
                  ? Text(title!, style: AppTextStyles.headingLarge(isDark))
                  : null,
              actions: actions,
              bottom: bottom,
            )
          : null,
      body: padding != null ? Padding(padding: padding!, child: child) : child,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP FILTER BOTTOM BAR
// ══════════════════════════════════════════════════════════════════════════════

/// Horizontally scrollable filter chip row (for job listings, search, etc.)
class AppFilterBar extends StatelessWidget {
  const AppFilterBar({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelect,
    required this.isDark,
    this.padding,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelect;
  final bool isDark;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filters[i];
          final isSelected = f == selected;
          return GestureDetector(
            onTap: () => onSelect(f),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppGradients.primary : null,
                color: isSelected
                    ? null
                    : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                borderRadius: AppRadii.rfull,
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                boxShadow: isSelected ? AppShadows.chip : [],
              ),
              child: Text(
                f,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.white
                      : (isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
