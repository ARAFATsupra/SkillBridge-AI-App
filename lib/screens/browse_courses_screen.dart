// lib/screens/browse_courses_screen.dart — SkillBridge AI
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/courses.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'application_tracker_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kPrimaryBlue = AppTheme.primaryBlue;
const _kCardRadius = 18.0;
const _kChipHeight = 36.0;
const _kSearchRadius = 16.0;

Color _cardBg(bool d) => d ? const Color(0xFF1C1C2E) : Colors.white;
Color _borderC(bool d) => d ? const Color(0xFF2C2C42) : const Color(0xFFE2E8F0);
Color _textC(bool d) => d ? Colors.white : const Color(0xFF0F172A);
Color _subC(bool d) => d ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
Color _bgC(bool d) => d ? const Color(0xFF0A0A18) : const Color(0xFFF8FAFC);
Color _surfaceC(bool d) =>
    d ? const Color(0xFF13131F) : const Color(0xFFF1F5F9);

// ─── Debouncer ────────────────────────────────────────────────────────────────
class _Debouncer {
  final Duration duration;
  Timer? _timer;
  _Debouncer([this.duration = const Duration(milliseconds: 300)]);
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() => _timer?.cancel();
}

// ─── Sort options ─────────────────────────────────────────────────────────────
enum _SortMode { defaultOrder, bestMatch, rating }

extension _SortModeLabel on _SortMode {
  String get label {
    switch (this) {
      case _SortMode.bestMatch:
        return 'Best Match';
      case _SortMode.rating:
        return 'Top Rated';
      case _SortMode.defaultOrder:
        return 'Default';
    }
  }

  IconData get icon {
    switch (this) {
      case _SortMode.bestMatch:
        return Icons.auto_awesome_rounded;
      case _SortMode.rating:
        return Icons.star_rounded;
      case _SortMode.defaultOrder:
        return Icons.sort_rounded;
    }
  }
}

// ─── Filter labels ────────────────────────────────────────────────────────────
class _ContentFormatFilter {
  static const String all = 'All';
  static const String video = 'Video';
  static const String book = 'Book';
  static const String web = 'Web';
  static const String slide = 'Slides';
  static const List<String> values = [all, video, book, web, slide];

  static IconData icon(String v) {
    switch (v) {
      case video:
        return Icons.play_circle_outline_rounded;
      case book:
        return Icons.menu_book_outlined;
      case web:
        return Icons.language_rounded;
      case slide:
        return Icons.slideshow_rounded;
      default:
        return Icons.apps_rounded;
    }
  }

  static ContentFormat? toContentFormat(String filter) {
    switch (filter) {
      case video:
        return ContentFormat.video;
      case book:
        return ContentFormat.bookChapter;
      case web:
        return ContentFormat.webPage;
      case slide:
        return ContentFormat.slide;
      default:
        return null;
    }
  }
}

class _DetailFilter {
  static const String all = 'All Levels';
  static const String low = 'Overview';
  static const String medium = 'Standard';
  static const String high = 'In-Depth';
  static const List<String> values = [all, low, medium, high];

  static DetailLevel? toDetailLevel(String filter) {
    switch (filter) {
      case low:
        return DetailLevel.low;
      case medium:
        return DetailLevel.medium;
      case high:
        return DetailLevel.high;
      default:
        return null;
    }
  }
}

class _LengthFilter {
  static const String all = 'Any Length';
  static const String short = 'Short';
  static const String medium = 'Medium';
  static const String long = 'Long';
  static const List<String> values = [all, short, medium, long];

  static ContentLength? toContentLength(String filter) {
    switch (filter) {
      case short:
        return ContentLength.short;
      case medium:
        return ContentLength.medium;
      case long:
        return ContentLength.long;
      default:
        return null;
    }
  }
}

// ─── Category definitions ─────────────────────────────────────────────────────
const List<String> _kCategories = [
  'All',
  'Beginner',
  'Intermediate',
  'Video',
  'Bootcamp',
  'Data Science',
  'Marketing',
  'Cloud',
];

Color catColor(String category) {
  switch (category) {
    case 'Data Science':
      return const Color(0xFF2563EB);
    case 'Marketing':
      return const Color(0xFF7C3AED);
    case 'Cloud':
      return const Color(0xFFEA580C);
    case 'Bootcamp':
      return const Color(0xFFDB2777);
    default:
      return _kPrimaryBlue;
  }
}

IconData catIcon(String category) {
  switch (category) {
    case 'Data Science':
      return Icons.analytics_outlined;
    case 'Marketing':
      return Icons.campaign_outlined;
    case 'Cloud':
      return Icons.cloud_outlined;
    case 'Bootcamp':
      return Icons.rocket_launch_outlined;
    case 'Video':
      return Icons.play_circle_outline_rounded;
    case 'Beginner':
      return Icons.emoji_events_outlined;
    case 'Intermediate':
      return Icons.trending_up_rounded;
    default:
      return Icons.apps_rounded;
  }
}

// ─── Level colour helper ──────────────────────────────────────────────────────
Color _levelColor(String level) {
  final l = level.toLowerCase();
  if (l.contains('beginner')) return const Color(0xFF16A34A);
  if (l.contains('intermediate')) return const Color(0xFFD97706);
  if (l.contains('advanced')) return const Color(0xFFDC2626);
  return _kPrimaryBlue;
}

// ══════════════════════════════════════════════════════════════════════════════
// SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class BrowseCoursesScreen extends StatefulWidget {
  /// When provided (e.g. from the Career GPS "Start →" or "Find Courses →"
  /// buttons), the search field is pre-populated with this skill name so the
  /// user lands directly on relevant course results.
  final String? initialQuery;

  const BrowseCoursesScreen({super.key, this.initialQuery});

  @override
  State<BrowseCoursesScreen> createState() => _BrowseCoursesScreenState();
}

class _BrowseCoursesScreenState extends State<BrowseCoursesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  final _debouncer = _Debouncer(const Duration(milliseconds: 300));
  final _scrollCtrl = ScrollController();
  String _searchQuery = '';
  bool _searchFocused = false;
  final _searchFocus = FocusNode();

  // ── Filter / sort state ──────────────────────────────────────────────
  String _formatFilter = _ContentFormatFilter.all;
  String _detailFilter = _DetailFilter.all;
  String _lengthFilter = _LengthFilter.all;
  _SortMode _sortMode = _SortMode.defaultOrder;

  // ── Active category (chip row) ───────────────────────────────────────
  String _activeCategory = 'All';

  // ── Bookmarks ────────────────────────────────────────────────────────
  final Set<String> _bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _kCategories.length, vsync: this);
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    // ── Pre-populate search from Career GPS ──────────────────────────
    // If an initialQuery was passed (e.g. "Java" from the Start button),
    // set both the controller text and the live query immediately so the
    // results list is already filtered when the screen opens.
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchQuery = widget.initialQuery!.trim().toLowerCase();
      _searchCtrl.text = widget.initialQuery!.trim();
    }

    _searchCtrl.addListener(() {
      _debouncer.run(() {
        if (mounted) {
          setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
        }
      });
    });
    _searchFocus.addListener(() {
      if (mounted) setState(() => _searchFocused = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _debouncer.dispose();
    _scrollCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Preference vector ────────────────────────────────────────────────
  Map<String, double> _getPrefVector(AppState appState) {
    try {
      final dynamic raw = (appState as dynamic).preferenceVector;
      if (raw is Map<String, double>) return raw;
      return const <String, double>{};
    } catch (_) {
      return const <String, double>{};
    }
  }

  // ── Filtering + sorting ──────────────────────────────────────────────
  List<Course> _filtered(Map<String, double> prefVector) {
    final tab = _kCategories[_tabCtrl.index];

    List<Course> result = courses.where((c) {
      // ── Tab / category filter ──────────────────────────────────────
      final passTab = switch (tab) {
        'Beginner' => c.level.toLowerCase().contains('beginner'),
        'Intermediate' => c.level.toLowerCase().contains('intermediate'),
        'Video' => c.contentFormat == ContentFormat.video,
        'Bootcamp' => c.courseTypeEnum == CourseType.bootcamp,
        'Data Science' => c.category.toLowerCase().contains('data'),
        'Marketing' => c.category.toLowerCase().contains('marketing'),
        'Cloud' => c.category.toLowerCase().contains('cloud') ||
            c.category.toLowerCase().contains('aws'),
        _ => true,
      };
      if (!passTab) return false;

      // ── Search filter ──────────────────────────────────────────────
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        final hit = c.title.toLowerCase().contains(q) ||
            c.provider.toLowerCase().contains(q) ||
            c.category.toLowerCase().contains(q) ||
            c.skills.any((s) => s.toLowerCase().contains(q));
        if (!hit) return false;
      }

      // ── Format filter ──────────────────────────────────────────────
      final fmtEnum = _ContentFormatFilter.toContentFormat(_formatFilter);
      if (fmtEnum != null && c.contentFormat != fmtEnum) return false;

      // ── Detail level filter ────────────────────────────────────────
      final detEnum = _DetailFilter.toDetailLevel(_detailFilter);
      if (detEnum != null && c.detailLevel != detEnum) return false;

      // ── Content length filter ──────────────────────────────────────
      final lenEnum = _LengthFilter.toContentLength(_lengthFilter);
      if (lenEnum != null && c.contentLength != lenEnum) return false;

      return true;
    }).toList();

    // ── Sort ───────────────────────────────────────────────────────────
    switch (_sortMode) {
      case _SortMode.bestMatch:
        if (prefVector.isNotEmpty) {
          result.sort((a, b) {
            final dA = a.dotProductWith(prefVector);
            final dB = b.dotProductWith(prefVector);
            return dB.compareTo(dA);
          });
        }
        break;
      case _SortMode.rating:
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _SortMode.defaultOrder:
        break;
    }
    return result;
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnack('Could not open this link.');
      }
    } catch (_) {
      _showSnack('Could not open: $url');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toggleBookmark(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_bookmarkedIds.contains(id)) {
        _bookmarkedIds.remove(id);
      } else {
        _bookmarkedIds.add(id);
      }
    });
  }

  int get _activeFilterCount {
    int n = 0;
    if (_formatFilter != _ContentFormatFilter.all) n++;
    if (_detailFilter != _DetailFilter.all) n++;
    if (_lengthFilter != _LengthFilter.all) n++;
    if (_sortMode != _SortMode.defaultOrder) n++;
    return n;
  }

  void _clearFilters() {
    HapticFeedback.selectionClick();
    setState(() {
      _formatFilter = _ContentFormatFilter.all;
      _detailFilter = _DetailFilter.all;
      _lengthFilter = _LengthFilter.all;
      _sortMode = _SortMode.defaultOrder;
    });
  }

  void _showFilterSheet(bool isDark) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        formatFilter: _formatFilter,
        detailFilter: _detailFilter,
        lengthFilter: _lengthFilter,
        sortMode: _sortMode,
        isDark: isDark,
        onFormatChanged: (v) => setState(() => _formatFilter = v),
        onDetailChanged: (v) => setState(() => _detailFilter = v),
        onLengthChanged: (v) => setState(() => _lengthFilter = v),
        onSortChanged: (v) => setState(() => _sortMode = v),
        onClear: _clearFilters,
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = context.watch<AppThemeProvider>().isDark;
    final prefVector = _getPrefVector(appState);
    final filtered = _filtered(prefVector);
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 720 ? 3 : 2;
    final childAspectRatio = crossAxisCount == 3 ? 0.75 : 0.68;

    final featuredCourse = courses.cast<Course?>().firstWhere(
          (c) => c!.isFree && c.level.toLowerCase().contains('beginner'),
          orElse: () => courses.isNotEmpty ? courses.first : null,
        );

    return Scaffold(
      backgroundColor: _bgC(isDark),
      appBar: _buildAppBar(isDark),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: _SearchBar(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                focused: _searchFocused,
                query: _searchQuery,
                isDark: isDark,
              ),
            ),
            SliverToBoxAdapter(
              child: _CategoryChips(
                categories: _kCategories,
                activeCategory: _activeCategory,
                isDark: isDark,
                onSelect: (cat) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _activeCategory = cat;
                    _tabCtrl.animateTo(_kCategories.indexOf(cat));
                  });
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _QuickFilterBar(
                activeFilterCount: _activeFilterCount,
                sortMode: _sortMode,
                isDark: isDark,
                onOpenSheet: () => _showFilterSheet(isDark),
                onClearFilters: _activeFilterCount > 0 ? _clearFilters : null,
              ),
            ),
            // Only show the featured banner when no search query is active,
            // so it doesn't clash with filtered results from Career GPS.
            if (featuredCourse != null && _searchQuery.isEmpty)
              SliverToBoxAdapter(
                child: _FeaturedBanner(
                  course: featuredCourse,
                  isDark: isDark,
                  onEnroll: () => _openUrl(featuredCourse.url),
                ),
              ),
            SliverToBoxAdapter(
              child: _SectionHeader(
                count: filtered.length,
                sortMode: _sortMode,
                isDark: isDark,
                // Show an active-search label so users know why results are
                // narrowed when arriving from Career GPS.
                activeQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                child: _EmptyState(
                  query: _searchQuery,
                  hasFilters: _activeFilterCount > 0,
                  isDark: isDark,
                  onClearFilters: _clearFilters,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final course = filtered[i];
                      return _GridCourseCard(
                        key: ValueKey('course_${course.id}'),
                        course: course,
                        appState: appState,
                        prefVector: prefVector,
                        sortMode: _sortMode,
                        isDark: isDark,
                        isBookmarked:
                            _bookmarkedIds.contains(course.id.toString()),
                        onOpen: () => _openUrl(course.url),
                        onBookmark: () => _toggleBookmark(course.id.toString()),
                      );
                    },
                    childCount: filtered.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: _cardBg(isDark),
      foregroundColor: _textC(isDark),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      // Show a back button when navigated to directly (e.g. from Career GPS).
      // When embedded in the main tab scaffold automaticallyImplyLeading is
      // false by convention; when pushed via Navigator it shows automatically.
      titleSpacing: 20,
      title: Text(
        'Browse Courses',
        style: TextStyle(
          color: _textC(isDark),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        PopupMenuButton<_SortMode>(
          onSelected: (m) {
            HapticFeedback.selectionClick();
            setState(() => _sortMode = m);
          },
          tooltip: 'Sort courses',
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          icon: _SortIconWithDot(mode: _sortMode, isDark: isDark),
          itemBuilder: (_) => _SortMode.values
              .map((m) => _buildSortMenuItem(m, isDark))
              .toList(),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _activeFilterCount > 0
              ? Padding(
                  key: const ValueKey('clear-btn'),
                  padding: const EdgeInsets.only(right: 4),
                  child: TextButton(
                    onPressed: _clearFilters,
                    style: TextButton.styleFrom(
                      foregroundColor: _kPrimaryBlue,
                      minimumSize: const Size(48, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      'Clear ($_activeFilterCount)',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              : const SizedBox(key: ValueKey('empty')),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: _borderC(isDark)),
      ),
    );
  }

  PopupMenuItem<_SortMode> _buildSortMenuItem(_SortMode m, bool isDark) {
    final sel = m == _sortMode;
    return PopupMenuItem<_SortMode>(
      value: m,
      child: Row(children: [
        Icon(m.icon, size: 16, color: sel ? _kPrimaryBlue : _subC(isDark)),
        const SizedBox(width: 10),
        Text(m.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              color: sel ? _kPrimaryBlue : _textC(isDark),
            )),
        if (sel) ...[
          const Spacer(),
          const Icon(Icons.check_rounded, size: 14, color: _kPrimaryBlue),
        ],
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SEARCH BAR
// ══════════════════════════════════════════════════════════════════════════════
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final String query;
  final bool isDark;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.query,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = _cardBg(isDark);
    final borderColor = focused ? _kPrimaryBlue : _borderC(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(_kSearchRadius),
          border: Border.all(
            color: borderColor,
            width: focused ? 1.5 : 1.0,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: focused
                        ? _kPrimaryBlue.withAlpha(25)
                        : Colors.black.withAlpha(8),
                    blurRadius: focused ? 12 : 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(children: [
          const SizedBox(width: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.search_rounded,
              key: ValueKey(focused),
              color: focused ? _kPrimaryBlue : _subC(isDark),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              label: 'Search courses and skills',
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.search,
                style: TextStyle(fontSize: 14, color: _textC(isDark)),
                cursorColor: _kPrimaryBlue,
                decoration: InputDecoration(
                  hintText: 'Search courses, skills, providers…',
                  hintStyle: TextStyle(fontSize: 14, color: _subC(isDark)),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: query.isNotEmpty
                ? GestureDetector(
                    key: const ValueKey('clear'),
                    onTap: controller.clear,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(Icons.close_rounded,
                          color: _subC(isDark), size: 18),
                    ),
                  )
                : const SizedBox(key: ValueKey('empty'), width: 12),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CATEGORY CHIPS
// ══════════════════════════════════════════════════════════════════════════════
class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String activeCategory;
  final bool isDark;
  final ValueChanged<String> onSelect;

  const _CategoryChips({
    required this.categories,
    required this.activeCategory,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: categories.map((cat) {
            final isActive = activeCategory == cat;
            final color = catColor(cat);
            final icon = catIcon(cat);
            return Semantics(
              label: '$cat category',
              selected: isActive,
              button: true,
              child: GestureDetector(
                onTap: () => onSelect(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  height: _kChipHeight,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isActive ? color : _cardBg(isDark),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isActive ? Colors.transparent : _borderC(isDark),
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: color.withAlpha(70),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cat != 'All') ...[
                        Icon(icon,
                            size: 14,
                            color: isActive ? Colors.white : _subC(isDark)),
                        const SizedBox(width: 5),
                      ],
                      Text(cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : _textC(isDark),
                          )),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// QUICK FILTER BAR
// ══════════════════════════════════════════════════════════════════════════════
class _QuickFilterBar extends StatelessWidget {
  final int activeFilterCount;
  final _SortMode sortMode;
  final bool isDark;
  final VoidCallback onOpenSheet;
  final VoidCallback? onClearFilters;

  const _QuickFilterBar({
    required this.activeFilterCount,
    required this.sortMode,
    required this.isDark,
    required this.onOpenSheet,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final hasActive = activeFilterCount > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(children: [
        _PillButton(
          label: hasActive ? 'Filters ($activeFilterCount)' : 'Filters',
          icon: Icons.tune_rounded,
          isDark: isDark,
          active: hasActive,
          onTap: onOpenSheet,
        ),
        const SizedBox(width: 8),
        if (sortMode != _SortMode.defaultOrder)
          _PillButton(
            label: sortMode.label,
            icon: sortMode.icon,
            isDark: isDark,
            active: true,
            onTap: onOpenSheet,
          ),
        const Spacer(),
        if (hasActive && onClearFilters != null)
          GestureDetector(
            onTap: onClearFilters,
            child: const Text(
              'Clear all',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kPrimaryBlue,
              ),
            ),
          ),
      ]),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final bool active;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? _kPrimaryBlue : _surfaceC(isDark),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
                color: active ? Colors.transparent : _borderC(isDark)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: active ? Colors.white : _subC(isDark)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : _textC(isDark),
                )),
          ]),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// FEATURED BANNER
// ══════════════════════════════════════════════════════════════════════════════
class _FeaturedBanner extends StatelessWidget {
  final Course course;
  final bool isDark;
  final VoidCallback onEnroll;

  const _FeaturedBanner({
    required this.course,
    required this.isDark,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF0891B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _kPrimaryBlue.withAlpha(70),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(12),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(8),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(45),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  '★ FEATURED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                course.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 5),
              const Row(children: [
                Icon(Icons.lock_open_rounded, color: Colors.white70, size: 12),
                SizedBox(width: 4),
                Text('Free · Beginner Friendly',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: course.url.isNotEmpty ? onEnroll : null,
                child: Container(
                  width: 148,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.white.withAlpha(60)),
                  ),
                  child: const Center(
                    child: Text(
                      'Enroll Free →',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ══════════════════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final int count;
  final _SortMode sortMode;
  final bool isDark;
  /// When set, shows a pill indicating the active search term.
  final String? activeQuery;

  const _SectionHeader({
    required this.count,
    required this.sortMode,
    required this.isDark,
    this.activeQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active skill-search banner from Career GPS
          if (activeQuery != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _kPrimaryBlue.withAlpha(18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kPrimaryBlue.withAlpha(50)),
              ),
              child: Row(children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 13, color: _kPrimaryBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Showing courses for "$activeQuery" from Career GPS',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kPrimaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 10),
          ],
          Row(children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                key: ValueKey(count),
                '$count ${count == 1 ? 'course' : 'courses'}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textC(isDark),
                ),
              ),
            ),
            const Spacer(),
            if (sortMode != _SortMode.defaultOrder)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kPrimaryBlue.withAlpha(18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(sortMode.icon, size: 11, color: _kPrimaryBlue),
                    const SizedBox(width: 4),
                    Text(sortMode.label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _kPrimaryBlue,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
          ]),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SORT ICON WITH DOT
// ══════════════════════════════════════════════════════════════════════════════
class _SortIconWithDot extends StatelessWidget {
  final _SortMode mode;
  final bool isDark;

  const _SortIconWithDot({required this.mode, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final active = mode != _SortMode.defaultOrder;
    return Stack(clipBehavior: Clip.none, children: [
      Icon(mode.icon, color: active ? _kPrimaryBlue : _subC(isDark), size: 22),
      if (active)
        Positioned(
          top: -1,
          right: -1,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _kPrimaryBlue,
              shape: BoxShape.circle,
            ),
          ),
        ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GRID COURSE CARD
// ══════════════════════════════════════════════════════════════════════════════
class _GridCourseCard extends StatefulWidget {
  final Course course;
  final AppState appState;
  final Map<String, double> prefVector;
  final _SortMode sortMode;
  final bool isDark;
  final bool isBookmarked;
  final VoidCallback onOpen;
  final VoidCallback onBookmark;

  const _GridCourseCard({
    super.key,
    required this.course,
    required this.appState,
    required this.prefVector,
    required this.sortMode,
    required this.isDark,
    required this.isBookmarked,
    required this.onOpen,
    required this.onBookmark,
  });

  @override
  State<_GridCourseCard> createState() => _GridCourseCardState();
}

class _GridCourseCardState extends State<_GridCourseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Color get _catColor {
    final cat = widget.course.category.toLowerCase();
    if (cat.contains('data')) return const Color(0xFF2563EB);
    if (cat.contains('market')) return const Color(0xFF7C3AED);
    if (cat.contains('cloud') || cat.contains('aws')) {
      return const Color(0xFFEA580C);
    }
    if (cat.contains('finance')) return const Color(0xFF16A34A);
    if (cat.contains('health')) return const Color(0xFFDC2626);
    if (cat.contains('mobile')) return const Color(0xFF0891B2);
    if (cat.contains('web')) return const Color(0xFF7C3AED);
    if (cat.contains('design')) return const Color(0xFFDB2777);
    return _kPrimaryBlue;
  }

  IconData get _catIcon {
    final cat = widget.course.category.toLowerCase();
    if (cat.contains('data')) return Icons.analytics_outlined;
    if (cat.contains('market')) return Icons.campaign_outlined;
    if (cat.contains('cloud') || cat.contains('aws')) {
      return Icons.cloud_outlined;
    }
    if (cat.contains('finance')) return Icons.account_balance_outlined;
    if (cat.contains('health')) return Icons.local_hospital_outlined;
    if (cat.contains('mobile')) return Icons.phone_android_outlined;
    if (cat.contains('web')) return Icons.web_outlined;
    if (cat.contains('design')) return Icons.palette_outlined;
    if (cat.contains('soft')) return Icons.people_outline_rounded;
    return Icons.menu_book_rounded;
  }

  bool get _isCompleted {
    try {
      return widget.appState.isCourseCompleted(widget.course.id);
    } catch (_) {
      return false;
    }
  }

  bool get _isEnrolled {
    try {
      return widget.appState.isCourseEnrolled(widget.course.id);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final isDark = widget.isDark;
    final isCompleted = _isCompleted;
    final isEnrolled = _isEnrolled;

    final double? matchScore =
        (widget.sortMode == _SortMode.bestMatch && widget.prefVector.isNotEmpty)
            ? c.dotProductWith(widget.prefVector)
            : null;

    final levelColor = _levelColor(c.level);

    return Semantics(
      label: '${c.title} by ${c.provider}. '
          'Rating ${c.rating.toStringAsFixed(1)}. '
          '${c.isFree ? 'Free' : 'Paid'}. '
          '${isCompleted ? 'Completed.' : ''}',
      button: true,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTapDown: (_) => _pressCtrl.forward(),
          onTapUp: (_) => _pressCtrl.reverse(),
          onTapCancel: () => _pressCtrl.reverse(),
          onTap: widget.onOpen,
          child: Container(
            decoration: BoxDecoration(
              color: _cardBg(isDark),
              borderRadius: BorderRadius.circular(_kCardRadius),
              border: Border.all(
                color: isCompleted ? const Color(0x5016A34A) : _borderC(isDark),
                width: isCompleted ? 1.5 : 1.0,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Icon banner ──────────────────────────────────────
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(_kCardRadius)),
                  child: Container(
                    width: double.infinity,
                    height: 72,
                    color: _catColor.withAlpha(28),
                    child: Stack(children: [
                      Center(
                        child: Icon(_catIcon, color: _catColor, size: 32),
                      ),
                      // Bookmark
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: widget.onBookmark,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              key: ValueKey(widget.isBookmarked),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black38
                                    : Colors.white.withAlpha(200),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(20),
                                    blurRadius: 6,
                                  )
                                ],
                              ),
                              child: Icon(
                                widget.isBookmarked
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                size: 14,
                                color: widget.isBookmarked
                                    ? _kPrimaryBlue
                                    : _subC(isDark),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Free badge
                      if (c.isFree)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withAlpha(230),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'FREE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
                // ── Content ──────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _textC(isDark),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.provider,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: _subC(isDark)),
                        ),
                        const SizedBox(height: 5),
                        Row(children: [
                          Icon(Icons.star_rounded,
                              color: Colors.amber.shade600, size: 11),
                          const SizedBox(width: 2),
                          Text(
                            c.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 10,
                              color: _subC(isDark),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: levelColor.withAlpha(22),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              c.level,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: levelColor,
                              ),
                            ),
                          ),
                        ]),
                        if (matchScore != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome_rounded,
                                  size: 9, color: _kPrimaryBlue),
                              const SizedBox(width: 2),
                              Text(
                                matchScore.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: _kPrimaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 3),
                        _QualityBadge(score: c.qualityScore ?? 0.0),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: ElevatedButton(
                            onPressed: isCompleted
                                ? () =>
                                    widget.appState.toggleCourseCompleted(c.id)
                                : widget.onOpen,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCompleted
                                  ? const Color(0xFF16A34A)
                                  : _kPrimaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9)),
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              isCompleted
                                  ? '✓ Done'
                                  : isEnrolled
                                      ? 'Continue'
                                      : (c.isFree ? 'Enroll Free' : 'Enroll'),
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
// FILTER BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════════════
class _FilterSheet extends StatelessWidget {
  final String formatFilter;
  final String detailFilter;
  final String lengthFilter;
  final _SortMode sortMode;
  final bool isDark;
  final ValueChanged<String> onFormatChanged;
  final ValueChanged<String> onDetailChanged;
  final ValueChanged<String> onLengthChanged;
  final ValueChanged<_SortMode> onSortChanged;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.formatFilter,
    required this.detailFilter,
    required this.lengthFilter,
    required this.sortMode,
    required this.isDark,
    required this.onFormatChanged,
    required this.onDetailChanged,
    required this.onLengthChanged,
    required this.onSortChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: _cardBg(isDark),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _borderC(isDark),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Row(children: [
                Text('Filters & Sort',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _textC(isDark),
                    )),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    onClear();
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(foregroundColor: _kPrimaryBlue),
                  child: const Text('Clear all',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 4),
              _SheetSection(
                title: 'SORT BY',
                isDark: isDark,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _SortMode.values
                      .map((m) => _SheetChip(
                            label: m.label,
                            icon: m.icon,
                            selected: sortMode == m,
                            isDark: isDark,
                            onTap: () {
                              onSortChanged(m);
                              HapticFeedback.selectionClick();
                            },
                          ))
                      .toList(),
                ),
              ),
              _SheetSection(
                title: 'FORMAT',
                isDark: isDark,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _ContentFormatFilter.values
                      .map((f) => _SheetChip(
                            label: f,
                            icon: _ContentFormatFilter.icon(f),
                            selected: formatFilter == f,
                            isDark: isDark,
                            onTap: () {
                              onFormatChanged(f);
                              HapticFeedback.selectionClick();
                            },
                          ))
                      .toList(),
                ),
              ),
              _SheetSection(
                title: 'DETAIL LEVEL',
                isDark: isDark,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _DetailFilter.values
                      .map((d) => _SheetChip(
                            label: d,
                            icon: _detailIcon(d),
                            selected: detailFilter == d,
                            isDark: isDark,
                            onTap: () {
                              onDetailChanged(
                                  detailFilter == d ? _DetailFilter.all : d);
                              HapticFeedback.selectionClick();
                            },
                          ))
                      .toList(),
                ),
              ),
              _SheetSection(
                title: 'CONTENT LENGTH',
                isDark: isDark,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _LengthFilter.values
                      .map((l) => _SheetChip(
                            label: l,
                            icon: _lengthIcon(l),
                            selected: lengthFilter == l,
                            isDark: isDark,
                            onTap: () {
                              onLengthChanged(
                                  lengthFilter == l ? _LengthFilter.all : l);
                              HapticFeedback.selectionClick();
                            },
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Apply Filters',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _detailIcon(String d) {
    switch (d) {
      case _DetailFilter.low:
        return Icons.remove_red_eye_outlined;
      case _DetailFilter.medium:
        return Icons.library_books_outlined;
      case _DetailFilter.high:
        return Icons.biotech_outlined;
      default:
        return Icons.tune_rounded;
    }
  }

  static IconData _lengthIcon(String l) {
    switch (l) {
      case _LengthFilter.short:
        return Icons.timer_outlined;
      case _LengthFilter.medium:
        return Icons.access_time_rounded;
      case _LengthFilter.long:
        return Icons.hourglass_bottom_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }
}

class _SheetSection extends StatelessWidget {
  final String title;
  final bool isDark;
  final Widget child;

  const _SheetSection({
    required this.title,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _subC(isDark),
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 10),
          child,
        ],
      );
}

class _SheetChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _SheetChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _kPrimaryBlue : _surfaceC(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _kPrimaryBlue : _borderC(isDark),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 13, color: selected ? Colors.white : _subC(isDark)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _textC(isDark),
                )),
          ]),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// QUALITY BADGE
// ══════════════════════════════════════════════════════════════════════════════
class _QualityBadge extends StatelessWidget {
  final double score;

  const _QualityBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final String label;
    final IconData badgeIcon;
    if (score >= 0.85) {
      bg = const Color(0xFF16A34A);
      label = 'Excellent';
      badgeIcon = Icons.verified_rounded;
    } else if (score >= 0.70) {
      bg = _kPrimaryBlue;
      label = 'Good';
      badgeIcon = Icons.verified_rounded;
    } else if (score >= 0.50) {
      bg = const Color(0xFFD97706);
      label = 'Okay';
      badgeIcon = Icons.info_outline_rounded;
    } else {
      bg = const Color(0xFFDC2626);
      label = 'Low';
      badgeIcon = Icons.warning_amber_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bg.withAlpha(70)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(badgeIcon, size: 9, color: bg),
        const SizedBox(width: 3),
        Text(label,
            style:
                TextStyle(fontSize: 9, color: bg, fontWeight: FontWeight.w700)),
        const SizedBox(width: 3),
        Text('${(score * 100).round()}%',
            style: TextStyle(fontSize: 9, color: bg.withAlpha(190))),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ══════════════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final String query;
  final bool hasFilters;
  final bool isDark;
  final VoidCallback onClearFilters;

  const _EmptyState({
    required this.query,
    required this.hasFilters,
    required this.isDark,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: _borderC(isDark),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_off_rounded,
                    size: 42, color: _subC(isDark)),
              ),
              const SizedBox(height: 18),
              Text(
                query.isNotEmpty
                    ? 'No results for "$query"'
                    : hasFilters
                        ? 'No courses match your filters.'
                        : 'No courses in this category.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textC(isDark)),
              ),
              const SizedBox(height: 8),
              if (query.isNotEmpty || hasFilters) ...[
                Text(
                  query.isNotEmpty
                      ? 'Try different keywords or browse a category.'
                      : 'Adjust the format, detail or length filters.',
                  style: TextStyle(fontSize: 13, color: _subC(isDark)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                  label: const Text('Clear filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: onClearFilters,
                ),
              ],
            ],
          ),
        ),
      );
}
