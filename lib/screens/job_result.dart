// lib/screens/job_result.dart — SkillBridge AI

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/career_profile.dart';
import '../ml/recommender.dart';
import '../services/app_state.dart';
import '../ml/sbert.dart';
import '../theme/app_theme.dart';
import 'skill_gap.dart';
import 'job_alerts_screen.dart';
import 'job_transition_screen.dart';

// ─── Industry color ────────────────────────────────────────────────────────

Color _industryColor(String ind) {
  switch (ind) {
    case 'Software':
      return const Color(0xFF2563EB);
    case 'Finance':
      return const Color(0xFF059669);
    case 'Healthcare':
      return const Color(0xFFDC2626);
    case 'Marketing':
      return const Color(0xFF7C3AED);
    case 'Manufacturing':
      return const Color(0xFFD97706);
    case 'Retail':
      return const Color(0xFFDB2777);
    case 'Education':
      return const Color(0xFF0D9488);
    default:
      return const Color(0xFF475569);
  }
}

// ─── Industry icon ─────────────────────────────────────────────────────────

IconData _industryIcon(String ind) {
  switch (ind) {
    case 'Software':
      return Icons.code_rounded;
    case 'Finance':
      return Icons.account_balance_rounded;
    case 'Healthcare':
      return Icons.local_hospital_rounded;
    case 'Marketing':
      return Icons.campaign_rounded;
    case 'Manufacturing':
      return Icons.precision_manufacturing_rounded;
    case 'Retail':
      return Icons.storefront_rounded;
    case 'Education':
      return Icons.school_rounded;
    default:
      return Icons.work_rounded;
  }
}

// ─── Automation risk helpers ────────────────────────────────────────────────
// FIX 1: Removed unsafe dynamic cast. `automationRiskLabel` should be a
// proper field on JobRecommendation. Accessing it via `(job as dynamic)`
// always silently falls through to 'Unknown'. Added a null-safe getter
// that calls the field directly (add `automationRiskLabel` to your model).

String _automationLabel(JobRecommendation job) {
  // Access the field directly — add `String? automationRiskLabel` to
  // JobRecommendation, then this works correctly without any dynamic cast.
  return job.automationRiskLabel ?? 'Unknown';
}

Color _automationColor(String label) {
  switch (label.toLowerCase()) {
    case 'low':
      return const Color(0xFF16A34A);
    case 'medium':
      return const Color(0xFFCA8A04);
    case 'high':
      return const Color(0xFFDC2626);
    default:
      return const Color(0xFF64748B);
  }
}

IconData _automationIcon(String label) {
  switch (label.toLowerCase()) {
    case 'low':
      return Icons.verified_outlined;
    case 'medium':
      return Icons.warning_amber_rounded;
    case 'high':
      return Icons.dangerous_outlined;
    default:
      return Icons.help_outline_rounded;
  }
}

// ─── Cross-domain detection ─────────────────────────────────────────────────

const _domainKeywords = <String, List<String>>{
  'Software': [
    'python', 'java', 'flutter', 'dart', 'react', 'docker', 'kubernetes',
    'ml', 'ai', 'api', 'git', 'sql', 'cloud'
  ],
  'Finance': [
    'excel', 'accounting', 'bloomberg', 'valuation', 'audit', 'cfa',
    'risk', 'compliance', 'vba', 'quickbooks'
  ],
  'Healthcare': [
    'nursing', 'ehr', 'hipaa', 'icd', 'cpr', 'emr', 'clinical',
    'pharmacy', 'anatomy', 'diagnosis'
  ],
  'Marketing': [
    'seo', 'sem', 'content', 'branding', 'analytics', 'instagram',
    'ads', 'copywriting', 'email', 'crm'
  ],
  'Manufacturing': [
    'lean', 'six sigma', 'cad', 'autocad', 'plc', 'erp',
    'supply chain', 'iso', 'quality', 'kaizen'
  ],
  'Education': [
    'curriculum', 'pedagogy', 'lms', 'assessment', 'lesson',
    'classroom', 'edtech', 'instructional'
  ],
};

Map<String, String> _detectCrossDomainTransfers(
  List<String> userSkills,
  List<String> matchingSkills,
  String jobIndustry,
) {
  final transfers = <String, String>{};
  for (final matched in matchingSkills) {
    final mLower = matched.toLowerCase();
    for (final entry in _domainKeywords.entries) {
      if (entry.key == jobIndustry) continue;
      if (entry.value.any((kw) => mLower.contains(kw))) {
        final userMatch = userSkills.firstWhere(
          (u) =>
              u.toLowerCase().contains(mLower) ||
              mLower.contains(u.toLowerCase()),
          orElse: () => '',
        );
        if (userMatch.isNotEmpty) {
          transfers[userMatch] = matched;
          if (transfers.length >= 2) return transfers;
        }
      }
    }
  }
  return transfers;
}

// ─── Keyword contribution weights ──────────────────────────────────────────

List<_SkillWeight> _buildContributions(List<String> skills, {int max = 5}) {
  if (skills.isEmpty) return const [];
  final capped = skills.take(max).toList();
  const rawWeights = <double>[32.0, 24.0, 18.0, 14.0, 12.0];
  double total = 0;
  final weights = <double>[];
  for (var i = 0; i < capped.length; i++) {
    final w = i < rawWeights.length ? rawWeights[i] : 8.0;
    weights.add(w);
    total += w;
  }
  return List.generate(capped.length, (i) {
    final pct = (weights[i] / total * 100).roundToDouble();
    return _SkillWeight(skill: capped[i], pct: pct);
  });
}

// FIX 2: Removed the redundant _buildYouBringBars wrapper — it was identical
// to calling _buildContributions(matching, max: 3) directly. Inlined at call
// site in _WhyMatchedSection to avoid the misleading duplication with
// `contributions` (max: 5). If the two lists need to remain separate, the
// call site is the right place to express that distinction.

List<_SkillWeight> _buildAttractedBars(
  JobRecommendation job,
  CareerProfile profile,
) {
  // FIX 3: Removed the unsafe `(job as dynamic).salary` cast. `job.salary`
  // is already typed on JobRecommendation; access it directly.
  final features = <_SkillWeight>[];
  final salary = double.tryParse(job.salary) ?? 0.0;

final salaryScore = (salary / 80000.0 * 60.0)
    .clamp(10.0, 100.0);

  features.add(_SkillWeight(skill: 'Salary Fit', pct: salaryScore.roundToDouble()));
  features.add(_SkillWeight(skill: 'Remote Work', pct: job.remote ? 90.0 : 40.0));

  const levelScores = <String, double>{
    'Junior': 70.0,
    'Mid': 90.0,
    'Senior': 80.0,
    'Lead': 75.0,
    'Executive': 60.0,
  };
  features.add(
    _SkillWeight(skill: 'Exp. Level', pct: levelScores[job.level] ?? 65.0),
  );
  return features;
}

class _SkillWeight {
  const _SkillWeight({required this.skill, required this.pct});
  final String skill;
  final double pct;
}

// ─── Design System Helpers ─────────────────────────────────────────────────

Color _bgC(bool d) => d ? const Color(0xFF0B1120) : const Color(0xFFF8FAFF);
Color _cardC(bool d) => d ? const Color(0xFF141E2E) : Colors.white;
Color _borderC(bool d) =>
    d ? const Color(0xFF1E3A5A) : const Color(0xFFE1E8F0);
Color _textC(bool d) => d ? Colors.white : const Color(0xFF0F172A);
Color _subC(bool d) =>
    d ? const Color(0xFF8BA3C0) : const Color(0xFF64748B);
Color _surfC(bool d) =>
    d ? const Color(0xFF1A2840) : const Color(0xFFF1F5F9);

Color _matchFgColor(double pct) {
  if (pct >= 75) return const Color(0xFF10B981);
  if (pct >= 45) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

Widget _pillChip(String label, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );

Widget _infoChipW(
        String emoji, String label, Color textColor, bool isDark) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _surfC(isDark),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );

Widget _skillTagW(String skill, bool isDark) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1D4ED8).withValues(alpha: 0.35)
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Text(skill,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF93C5FD) : AppTheme.primaryBlue,
          )),
    );

// ─── Arc Painter ───────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _ArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    const startAngle = math.pi * 0.75;
    const sweepTotal = math.pi * 1.5;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = 4.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepTotal * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor;
}

// ─── Screen ────────────────────────────────────────────────────────────────

class JobResultScreen extends StatefulWidget {
  final CareerProfile profile;
  final String selectedIndustry;
  final String selectedLevel;
  final bool remoteOnly;

  const JobResultScreen({
    super.key,
    required this.profile,
    this.selectedIndustry = 'All',
    this.selectedLevel = 'All',
    this.remoteOnly = false,
  });

  @override
  State<JobResultScreen> createState() => _JobResultScreenState();
}

class _JobResultScreenState extends State<JobResultScreen>
    with SingleTickerProviderStateMixin {
  late List<JobRecommendation> _results;
  late List<JobRecommendation> _filtered;

  String _sortBy = 'simScore';
  String _activeIndustry = 'All';
  bool _showHighMatchOnly = false;
  bool _searchActive = false;
  String _searchQuery = '';
  bool _showScrollTop = false;

  // ── SBERT hybrid re-ranking state ─────────────────────────────────────
  bool _sbertLoading = false;
  bool _sbertActive = false;
  String _sbertBadge = '';

  late final AnimationController _listCtrl;
  late final ScrollController _scrollCtrl;
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _activeIndustry = widget.selectedIndustry;
    _searchCtrl = TextEditingController();
    _scrollCtrl = ScrollController()..addListener(_onScroll);
    _listCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loadResults();
  }

  void _onScroll() {
    final show = _scrollCtrl.offset > 400;
    if (show != _showScrollTop) setState(() => _showScrollTop = show);
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Stage 1: synchronous TF-IDF results ─────────────────────────────────
  void _loadResults() {
    List<String> effectiveSkills = widget.profile.skills;

    if (effectiveSkills.isEmpty && mounted) {
      final appState = context.read<AppState>();
      effectiveSkills = List<String>.from(appState.userSkills);
    }

    if (effectiveSkills.isEmpty) {
      effectiveSkills = const [
        'Python',
        'SQL',
        'Data Analysis',
        'Excel',
        'Communication',
      ];
    }

    _results = recommendJobs(
      effectiveSkills,
      profile: widget.profile,
      config: RecommendationConfig(
        remoteOnly: widget.remoteOnly ? true : null,
        industry:
            widget.selectedIndustry == 'All' ? null : widget.selectedIndustry,
        level: widget.selectedLevel == 'All' ? null : widget.selectedLevel,
        withExplainability: true,
      ),
    );

    _applyFiltersAndSort();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().setJobsMatchedCount(_results.length);
        _listCtrl.forward(from: 0);
        _reRankWithSbert(effectiveSkills);
      }
    });
  }

  // ── Stage 2: async SBERT re-ranking ──────────────────────────────────────
  // FIX 4: Separated the two setState calls so _applyFiltersAndSort (which
  // also calls setState internally) is not nested inside another setState.
  // The previous code called setState { ... } then immediately called
  // _applyFiltersAndSort() inside the same block, causing a redundant
  // nested setState rebuild.
  Future<void> _reRankWithSbert(List<String> userSkills) async {
    if (!mounted) return;

    final userQuery = [
      ...userSkills,
      if (widget.selectedIndustry != 'All') widget.selectedIndustry,
      if (widget.selectedLevel != 'All') widget.selectedLevel,
    ].where((s) => s.trim().isNotEmpty).join(' ').toLowerCase();

    setState(() => _sbertLoading = true);

    final t0 = DateTime.now();
    final hybridResults = await LocalSbertService().rerank(
      _results,
      userQuery: userQuery,
      candidatePool: 50,
    );
    final ms = DateTime.now().difference(t0).inMilliseconds;

    if (!mounted) return;

    // FIX 4 (cont.): Update state fields first, then call
    // _applyFiltersAndSort separately — it will call setState on its own.
    _results = hybridResults;
    _sbertLoading = false;
    _sbertActive = true;
    _sbertBadge = 'Hybrid AI · ${ms}ms';

    _applyFiltersAndSort(); // calls setState internally
  }

  void _applyFiltersAndSort() {
    var list = List<JobRecommendation>.from(_results);

    if (_activeIndustry != 'All') {
      list = list.where((j) => j.industry == _activeIndustry).toList();
    }
    if (widget.selectedLevel != 'All') {
      list = list.where((j) => j.level == widget.selectedLevel).toList();
    }
    if (widget.remoteOnly) {
      list = list.where((j) => j.remote).toList();
    }
    if (_showHighMatchOnly) {
      list = list.where((j) => j.score * 100 >= 65).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((j) =>
              j.title.toLowerCase().contains(q) ||
              j.company.toLowerCase().contains(q) ||
              j.industry.toLowerCase().contains(q) ||
              j.matching.any((s) => s.toLowerCase().contains(q)))
          .toList();
    }

    if (_sortBy == 'salary') {
      list.sort((a, b) => b.salary.compareTo(a.salary));
    } else if (_sortBy == 'score') {
      list.sort((a, b) => b.score.compareTo(a.score));
    } else {
      list.sort((a, b) => b.simScore.compareTo(a.simScore));
    }

    setState(() => _filtered = list);
    _listCtrl.forward(from: 0);
  }

  // ── Computed helpers ─────────────────────────────────────────────────────

  Map<String, int> get _industryCounts {
    final counts = <String, int>{};
    for (final j in _results) {
      counts[j.industry] = (counts[j.industry] ?? 0) + 1;
    }
    return counts;
  }

  List<String> get _industries {
    final set = <String>{'All'};
    for (final j in _results) {
      set.add(j.industry);
    }
    return set.toList();
  }

  double get _avgMatch {
    if (_filtered.isEmpty) return 0.0;
    return _filtered.fold<double>(0.0, (acc, j) => acc + j.score * 100) /
        _filtered.length;
  }

  int get _highMatchCount =>
      _filtered.where((j) => j.score * 100 >= 75).length;

  void _scrollToTop() => _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );

  // ── Navigation ────────────────────────────────────────────────────────────

  void _openJobAlerts() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const JobAlertsScreen()),
    );
  }

  void _openJobTransition() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const JobTransitionScreen()),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgClr = _bgC(isDark);
    final textClr = _textC(isDark);
    final subClr = _subC(isDark);

    return Scaffold(
      backgroundColor: bgClr,
      floatingActionButton: AnimatedSlide(
        offset: _showScrollTop ? Offset.zero : const Offset(0, 2),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _showScrollTop ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: FloatingActionButton(
            mini: true,
            onPressed: _scrollToTop,
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 6,
            child: const Icon(Icons.keyboard_arrow_up_rounded),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: bgClr,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textClr),
          onPressed: () => Navigator.pop(context),
        ),
        title: _searchActive
            ? _SearchField(
                controller: _searchCtrl,
                isDark: isDark,
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                  _applyFiltersAndSort();
                },
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Job Matches',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textClr,
                          letterSpacing: -0.3)),
                  Text('${_filtered.length} positions found',
                      style: TextStyle(fontSize: 12, color: subClr)),
                  if (_sbertLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('Applying Hybrid AI...',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.primaryBlue)),
                        ],
                      ),
                    )
                  else if (_sbertActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              size: 10, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(_sbertBadge,
                              style:
                                  const TextStyle(fontSize: 10, color: Colors.amber)),
                        ],
                      ),
                    ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              _searchActive
                  ? Icons.search_off_rounded
                  : Icons.search_rounded,
              color: _searchActive ? AppTheme.primaryBlue : textClr,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _searchActive = !_searchActive;
                if (!_searchActive) {
                  _searchQuery = '';
                  _searchCtrl.clear();
                  _applyFiltersAndSort();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: _showHighMatchOnly ? Colors.amber : textClr,
            ),
            // FIX 5: Tooltip text now matches the actual filter threshold (≥65%)
            // consistently with _showHighMatchOnly filter logic.
            tooltip: _showHighMatchOnly ? 'Show all' : 'High matches only (≥65%)',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _showHighMatchOnly = !_showHighMatchOnly);
              _applyFiltersAndSort();
            },
          ),
          _SortMenuButton(
            sortBy: _sortBy,
            textColor: textClr,
            onSelected: (val) {
              setState(() => _sortBy = val);
              _applyFiltersAndSort();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: _borderC(isDark)),
        ),
      ),
      body: Column(
        children: [
          _QuickActionBar(
            isDark: isDark,
            onJobAlerts: _openJobAlerts,
            onJobTransition: _openJobTransition,
          ),
          _FilterChipBar(
            industries: _industries,
            industryCounts: _industryCounts,
            active: _activeIndustry,
            isDark: isDark,
            onSelect: (ind) {
              setState(() => _activeIndustry = ind);
              _applyFiltersAndSort();
            },
          ),
          if (_filtered.isNotEmpty)
            _StatsSummaryBar(
              total: _filtered.length,
              avgMatch: _avgMatch,
              highMatch: _highMatchCount,
              isDark: isDark,
            ),
          if (_showHighMatchOnly)
            _ActiveFilterBanner(
              label: 'Showing high matches (≥65%) only',
              onClear: () {
                setState(() => _showHighMatchOnly = false);
                _applyFiltersAndSort();
              },
              isDark: isDark,
            ),
          Expanded(
            child: _filtered.isEmpty
                ? _EmptyState(
                    onClearFilters: () {
                      setState(() {
                        _activeIndustry = 'All';
                        _showHighMatchOnly = false;
                        _searchQuery = '';
                        _searchActive = false;
                        _searchCtrl.clear();
                      });
                      _applyFiltersAndSort();
                    },
                    isDark: isDark,
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) => _AnimatedJobCard(
                      job: _filtered[i],
                      index: i,
                      listAnim: _listCtrl,
                      isDark: isDark,
                      profile: widget.profile,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Action Bar ──────────────────────────────────────────────────────

class _QuickActionBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onJobAlerts;
  final VoidCallback onJobTransition;

  const _QuickActionBar({
    required this.isDark,
    required this.onJobAlerts,
    required this.onJobTransition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgC(isDark),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: _ActionBtn(
              icon: Icons.notifications_active_rounded,
              label: 'Job Alerts',
              color: const Color(0xFF7C3AED),
              isDark: isDark,
              onTap: onJobAlerts,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionBtn(
              icon: Icons.swap_horiz_rounded,
              label: 'Career GPS',
              color: AppTheme.primaryBlue,
              isDark: isDark,
              onTap: onJobTransition,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.10, end: 0);
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: widget.isDark
                ? c.withValues(alpha: 0.12)
                : c.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.withValues(alpha: 0.30), width: 1.5),
            boxShadow: widget.isDark
                ? const []
                : [
                    BoxShadow(
                      color: c.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 16, color: c),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Search Field ──────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final void Function(String) onChanged;

  const _SearchField({
    required this.controller,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      style: TextStyle(fontSize: 15, color: _textC(isDark)),
      decoration: InputDecoration(
        hintText: 'Search jobs, skills, companies…',
        hintStyle: TextStyle(fontSize: 14, color: _subC(isDark)),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

// ─── Sort Menu Button ──────────────────────────────────────────────────────

class _SortMenuButton extends StatelessWidget {
  final String sortBy;
  final Color textColor;
  final void Function(String) onSelected;

  const _SortMenuButton({
    required this.sortBy,
    required this.textColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.sort_rounded, color: textColor),
      tooltip: 'Sort results',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      onSelected: onSelected,
      itemBuilder: (_) => [
        _sortItem('simScore', 'Similarity Score', Icons.auto_graph_rounded),
        _sortItem('score', 'Match Score', Icons.bar_chart_rounded),
        _sortItem('salary', 'Salary', Icons.payments_rounded),
      ],
    );
  }

  PopupMenuItem<String> _sortItem(
      String value, String label, IconData icon) {
    final isActive = sortBy == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                size: 18,
                color: isActive ? AppTheme.primaryBlue : Colors.grey),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppTheme.primaryBlue : null,
                )),
          ),
          if (isActive)
            const Icon(Icons.check_rounded,
                size: 16, color: AppTheme.primaryBlue),
        ],
      ),
    );
  }
}

// ─── Filter Chip Bar ───────────────────────────────────────────────────────

class _FilterChipBar extends StatelessWidget {
  final List<String> industries;
  final Map<String, int> industryCounts;
  final String active;
  final bool isDark;
  final void Function(String) onSelect;

  const _FilterChipBar({
    required this.industries,
    required this.industryCounts,
    required this.active,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgC(isDark),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: industries.map((ind) {
                final isActive = ind == active;
                final count = ind == 'All' ? null : industryCounts[ind];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(ind);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                    decoration: BoxDecoration(
                      color:
                          isActive ? AppTheme.primaryBlue : _cardC(isDark),
                      border: Border.all(
                        color: isActive
                            ? AppTheme.primaryBlue
                            : _borderC(isDark),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryBlue
                                    .withValues(alpha: 0.32),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : const [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ind,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.white
                                  : _subC(isDark),
                            )),
                        if (count != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : AppTheme.primaryBlue
                                      .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text('$count',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isActive
                                      ? Colors.white
                                      : AppTheme.primaryBlue,
                                )),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: _borderC(isDark)),
        ],
      ),
    );
  }
}

// ─── Active Filter Banner ──────────────────────────────────────────────────

class _ActiveFilterBanner extends StatelessWidget {
  final String label;
  final VoidCallback onClear;
  final bool isDark;

  const _ActiveFilterBanner({
    required this.label,
    required this.onClear,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.amber.withValues(alpha: 0.09)
            : const Color(0xFFFFFBEB),
        border: Border(
            bottom:
                BorderSide(color: Colors.amber.withValues(alpha: 0.20))),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded,
              color: Colors.amber, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style:
                    const TextStyle(fontSize: 12, color: Colors.amber)),
          ),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Clear',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.amber,
                      fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Summary Bar ─────────────────────────────────────────────────────

class _StatsSummaryBar extends StatelessWidget {
  final int total;
  final double avgMatch;
  final int highMatch;
  final bool isDark;

  const _StatsSummaryBar({
    required this.total,
    required this.avgMatch,
    required this.highMatch,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF141E2E), Color(0xFF1A2840)]
              : const [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderC(isDark)),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Row(
        children: [
          _statCell(
            value: '$total',
            label: 'Found',
            color: AppTheme.primaryBlue,
            icon: Icons.work_outline_rounded,
            isDark: isDark,
          ),
          _divider(isDark),
          _statCell(
            value: '${avgMatch.round()}%',
            label: 'Avg Match',
            color: _matchFgColor(avgMatch),
            icon: Icons.analytics_outlined,
            isDark: isDark,
          ),
          _divider(isDark),
          _statCell(
            value: '$highMatch',
            label: 'Top Picks',
            color: const Color(0xFF10B981),
            icon: Icons.star_outline_rounded,
            isDark: isDark,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15, end: 0);
  }

  Widget _divider(bool isDark) => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: _borderC(isDark),
      );

  Widget _statCell({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1)),
            ],
          ),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(fontSize: 10, color: _subC(isDark))),
        ],
      ),
    );
  }
}

// ─── Animated Job Card (wrapper) ───────────────────────────────────────────
// FIX 6: Removed the unused `delay` parameter. It was computed and passed
// in the call site but never consumed inside the widget, causing misleading
// dead code. The staggered animation is handled entirely by the
// AnimationController interval calculation using `index`.

class _AnimatedJobCard extends StatelessWidget {
  final JobRecommendation job;
  final int index;
  final AnimationController listAnim;
  final bool isDark;
  final CareerProfile profile;

  const _AnimatedJobCard({
    required this.job,
    required this.index,
    required this.listAnim,
    required this.isDark,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: listAnim,
      curve: Interval(
        (index * 0.06).clamp(0.0, 0.9),
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(anim),
          child: _JobCard(job: job, isDark: isDark, profile: profile),
        ),
      ),
    );
  }
}

// ─── Job Card ──────────────────────────────────────────────────────────────

class _JobCard extends StatefulWidget {
  final JobRecommendation job;
  final bool isDark;
  final CareerProfile profile;

  const _JobCard({
    required this.job,
    required this.isDark,
    required this.profile,
  });

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  bool _whyExpanded = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final isDark = widget.isDark;
    final pct = job.score * 100;
    final mFg = _matchFgColor(pct);
    final iColor = _industryColor(job.industry);
    final iIcon = _industryIcon(job.industry);

    final crossDomain = _detectCrossDomainTransfers(
        widget.profile.skills, job.matching, job.industry);
    final hasCrossDomain = crossDomain.isNotEmpty;
    final autoLabel = _automationLabel(job);
    final autoColor = _automationColor(autoLabel);
    final autoIcon = _automationIcon(autoLabel);

    final words = job.company.trim().split(' ');
    final initials = words.length >= 2
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : job.company
            .substring(0, math.min(2, job.company.length))
            .toUpperCase();
    final isHighMatch = pct >= 80;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => SkillGapScreen(
              job: job,
              userSkills: widget.profile.skills,
            ),
          ),
        );
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: _cardC(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderC(isDark)),
            boxShadow: isDark
                ? const []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 18,
                      spreadRadius: 0,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                if (isHighMatch)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            iColor.withValues(
                                alpha: isDark ? 0.07 : 0.04),
                            Colors.transparent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          iColor,
                          iColor.withValues(alpha: 0.35)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Avatar + Title + Score
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  iColor.withValues(alpha: 0.16),
                                  iColor.withValues(alpha: 0.07),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: iColor.withValues(alpha: 0.28),
                                  width: 1.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(iIcon, size: 17, color: iColor),
                                const SizedBox(height: 2),
                                Text(initials,
                                    style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        color: iColor,
                                        height: 1)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(job.company,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: _subC(isDark)),
                                          overflow:
                                              TextOverflow.ellipsis),
                                    ),
                                    if (job.remote) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentTeal
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text('Remote',
                                            style: TextStyle(
                                                fontSize: 9,
                                                color: AppTheme.accentTeal,
                                                fontWeight:
                                                    FontWeight.w800)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(job.title,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: _textC(isDark),
                                        letterSpacing: -0.2,
                                        height: 1.2),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _CircularMatchScore(
                              pct: pct, color: mFg, isDark: isDark),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 2: Info chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _infoChipW('', job.location,
                              _subC(isDark), isDark),
                          _infoChipW('', '${job.type} · ${job.level}',
                              _subC(isDark), isDark),
                          _infoChipW('', job.formattedSalary,
                              AppTheme.primaryBlue, isDark),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 3: Matching skills
                      if (job.matching.isNotEmpty) ...[
                        _SkillsRow(
                            skills: job.matching, isDark: isDark),
                        const SizedBox(height: 10),
                      ],

                      // Row 4: Missing skills
                      if (job.missing.isNotEmpty) ...[
                        _MissingSkillsRow(
                            skills: job.missing, isDark: isDark),
                        const SizedBox(height: 10),
                      ],

                      Divider(height: 16, color: _borderC(isDark)),

                      if (autoLabel != 'Unknown') ...[
                        _AutomationRiskChip(
                            label: autoLabel,
                            color: autoColor,
                            icon: autoIcon),
                        const SizedBox(height: 8),
                      ],

                      if (hasCrossDomain) ...[
                        _CrossDomainBadge(
                            transfers: crossDomain, isDark: isDark),
                        const SizedBox(height: 8),
                      ],

                      _WhyMatchedSection(
                        job: job,
                        profile: widget.profile,
                        isDark: isDark,
                        expanded: _whyExpanded,
                        onToggle: () => setState(
                            () => _whyExpanded = !_whyExpanded),
                      ),
                      const SizedBox(height: 14),

                      // Actions row
                      Row(
                        children: [
                          Consumer<AppState>(
                            builder: (_, appState, __) {
                              final saved = appState.isJobSaved(job.id);
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  appState.toggleSaveJob(job.id);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(saved
                                          ? 'Removed from saved.'
                                          : '${job.title} saved! ❤️'),
                                      duration:
                                          const Duration(seconds: 2),
                                      behavior:
                                          SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      action: saved
                                          ? null
                                          : SnackBarAction(
                                              label: 'Undo',
                                              onPressed: () => appState
                                                  .toggleSaveJob(job.id),
                                            ),
                                    ),
                                  );
                                },
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 220),
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: saved
                                        ? AppTheme.primaryBlue
                                            .withValues(alpha: 0.10)
                                        : _cardC(isDark),
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border.all(
                                        color: saved
                                            ? AppTheme.primaryBlue
                                            : _borderC(isDark),
                                        width: 1.5),
                                  ),
                                  child: Icon(
                                    saved
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_outline_rounded,
                                    color: saved
                                        ? AppTheme.primaryBlue
                                        : _subC(isDark),
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ApplyButton(
                                job: job, profile: widget.profile),
                          ),
                        ],
                      ),
                    ],
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

// ─── Circular Match Score Gauge ────────────────────────────────────────────

class _CircularMatchScore extends StatelessWidget {
  final double pct;
  final Color color;
  final bool isDark;

  const _CircularMatchScore({
    required this.pct,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (pct / 100).clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, val, __) => SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(56, 56),
              painter: _ArcPainter(
                progress: val,
                color: color,
                trackColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${pct.round()}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: color,
                        height: 1)),
                Text('%',
                    style: TextStyle(
                        fontSize: 8,
                        color: color.withValues(alpha: 0.70),
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Matching Skills Row ───────────────────────────────────────────────────

class _SkillsRow extends StatelessWidget {
  final List<String> skills;
  final bool isDark;

  const _SkillsRow({required this.skills, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 12, color: Color(0xFF10B981)),
            SizedBox(width: 5),
            Text('Matching Skills',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981))),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 5,
          children: [
            ...skills.take(4).map((s) => _skillTagW(s, isDark)),
            if (skills.length > 4)
              _pillChip(
                '+${skills.length - 4} more',
                isDark
                    ? const Color(0xFF1A2840)
                    : const Color(0xFFF1F5F9),
                _subC(isDark),
              ),
          ],
        ),
      ],
    );
  }
}

// ─── Missing Skills Row ────────────────────────────────────────────────────

class _MissingSkillsRow extends StatelessWidget {
  final List<String> skills;
  final bool isDark;

  const _MissingSkillsRow({required this.skills, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const redColor = Color(0xFFEF4444);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.add_circle_outline_rounded,
                size: 12, color: redColor.withValues(alpha: 0.80)),
            const SizedBox(width: 5),
            Text('Skills to Develop',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: redColor.withValues(alpha: 0.85))),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 5,
          children: [
            ...skills.take(3).map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2D1515)
                          : const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: redColor.withValues(alpha: 0.25)),
                    ),
                    child: Text(s,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: redColor.withValues(alpha: 0.85))),
                  ),
                ),
            if (skills.length > 3)
              _pillChip(
                '+${skills.length - 3}',
                isDark
                    ? const Color(0xFF2D1515)
                    : const Color(0xFFFFF5F5),
                redColor,
              ),
          ],
        ),
      ],
    );
  }
}

// ─── Apply Button ──────────────────────────────────────────────────────────

class _ApplyButton extends StatelessWidget {
  final JobRecommendation job;
  final CareerProfile profile;

  const _ApplyButton({required this.job, required this.profile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => SkillGapScreen(
              job: job,
              userSkills: profile.skills,
            ),
          ),
        );
      },
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.32),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('View Details',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2)),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Automation Risk Chip ──────────────────────────────────────────────────

class _AutomationRiskChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _AutomationRiskChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Automation risk based on occupational group analysis',
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text('${label.capitalize()} Automation Risk',
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }
}

// ─── Cross-Domain Transfer Badge ───────────────────────────────────────────

class _CrossDomainBadge extends StatelessWidget {
  final Map<String, String> transfers;
  final bool isDark;

  const _CrossDomainBadge({
    required this.transfers,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final firstEntry = transfers.entries.first;
    final tooltipMsg =
        'Your "${firstEntry.key}" skill transfers to "${firstEntry.value}"'
        '${transfers.length > 1 ? ' and ${transfers.length - 1} more' : ''}';

    return Tooltip(
      message: tooltipMsg,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accentTeal
                  .withValues(alpha: isDark ? 0.20 : 0.10),
              AppTheme.primaryBlue
                  .withValues(alpha: isDark ? 0.15 : 0.07),
            ],
          ),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
              color: AppTheme.accentTeal.withValues(alpha: 0.38)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔄', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            const Text('Cross-Domain Match',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.accentTeal,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Icon(Icons.info_outline_rounded,
                size: 13,
                color: AppTheme.accentTeal.withValues(alpha: 0.65)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.08, end: 0);
  }
}

// ─── "Why Matched" Expandable Section ─────────────────────────────────────

class _WhyMatchedSection extends StatelessWidget {
  final JobRecommendation job;
  final CareerProfile profile;
  final bool isDark;
  final bool expanded;
  final VoidCallback onToggle;

  const _WhyMatchedSection({
    required this.job,
    required this.profile,
    required this.isDark,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // FIX 7: Replaced the removed _buildYouBringBars wrapper with a direct
    // inline call to _buildContributions(max: 3). The `contributions` list
    // (max: 5) and `youBringBars` (max: 3) now clearly express different
    // truncation levels side-by-side without a confusing wrapper function.
    final contributions = _buildContributions(job.matching, max: 5);
    final youBringBars = _buildContributions(job.matching, max: 3);
    final attractedBars = _buildAttractedBars(job, profile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                  : AppTheme.primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.psychology_outlined,
                      size: 15, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text('Why did we match you?',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w700)),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: AppTheme.primaryBlue),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 280),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (contributions.isEmpty)
                  _WhyEmptyState(
                      isDark: isDark,
                      message: 'No matched skills to analyse.')
                else ...[
                  _ChartSectionLabel(
                    icon: Icons.key_rounded,
                    label: 'Top Keyword Contributions',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _HorizontalBarChart(
                    bars: contributions,
                    isDark: isDark,
                    barColor: AppTheme.primaryBlue,
                    showPct: true,
                    maxHeight: 14,
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _AttentionChart(
                        title: 'What you bring',
                        bars: youBringBars,
                        color: AppTheme.accentGreen,
                        isDark: isDark,
                        emptyMessage: 'No matched skills.',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AttentionChart(
                        title: 'What attracted you',
                        bars: attractedBars,
                        color: AppTheme.accentTeal,
                        isDark: isDark,
                        emptyMessage: 'No preference data.',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Horizontal Bar Chart ──────────────────────────────────────────────────

class _HorizontalBarChart extends StatelessWidget {
  final List<_SkillWeight> bars;
  final bool isDark;
  final Color barColor;
  final bool showPct;
  final double maxHeight;

  const _HorizontalBarChart({
    required this.bars,
    required this.isDark,
    required this.barColor,
    this.showPct = true,
    this.maxHeight = 22,
  });

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return _WhyEmptyState(isDark: isDark, message: 'No data available.');
    }
    final maxPct = bars.map((b) => b.pct).reduce(math.max);

    return Column(
      children: bars.asMap().entries.map((entry) {
        final i = entry.key;
        final bar = entry.value;
        final rel = maxPct > 0 ? bar.pct / maxPct : 0.0;
        final opacity = (1.0 - i * 0.15).clamp(0.45, 1.0);
        final color = barColor.withValues(alpha: opacity);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      bar.skill,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  if (showPct)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        '${bar.pct.round()}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: barColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: rel.clamp(0.0, 1.0)),
                duration: Duration(milliseconds: 550 + i * 80),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => Stack(
                  children: [
                    Container(
                      height: maxHeight,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: val,
                      child: Container(
                        height: maxHeight,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Attention Mini-Chart Panel ────────────────────────────────────────────

class _AttentionChart extends StatelessWidget {
  final String title;
  final List<_SkillWeight> bars;
  final Color color;
  final bool isDark;
  final String emptyMessage;

  const _AttentionChart({
    required this.title,
    required this.bars,
    required this.color,
    required this.isDark,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.06)
            : color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 10),
          bars.isEmpty
              ? _WhyEmptyState(isDark: isDark, message: emptyMessage)
              : _HorizontalBarChart(
                  bars: bars,
                  isDark: isDark,
                  barColor: color,
                  showPct: true,
                  maxHeight: 10,
                ),
        ],
      ),
    );
  }
}

// ─── Chart Section Label ───────────────────────────────────────────────────

class _ChartSectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _ChartSectionLabel({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 12,
            color: isDark ? Colors.white38 : Colors.black38),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white54 : Colors.black54)),
      ],
    );
  }
}

// ─── Empty State for Charts ────────────────────────────────────────────────

class _WhyEmptyState extends StatelessWidget {
  final bool isDark;
  final String message;

  const _WhyEmptyState({required this.isDark, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.bar_chart_outlined,
              size: 16,
              color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(width: 6),
          Text(message,
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38)),
        ],
      ),
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onClearFilters;
  final bool isDark;

  const _EmptyState({
    required this.onClearFilters,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF1A2840), Color(0xFF141E2E)]
                      : const [Color(0xFFEFF6FF), Color(0xFFF1F5F9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _borderC(isDark)),
                boxShadow: isDark
                    ? const []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        )
                      ],
              ),
              child: Icon(Icons.work_off_outlined,
                  size: 46,
                  color: isDark
                      ? Colors.white24
                      : Colors.grey.shade400),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.04, 1.04),
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 24),
            Text('No jobs found',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _textC(isDark),
                    letterSpacing: -0.4)),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or\nrefining your search query.',
              style: TextStyle(
                  fontSize: 14, color: _subC(isDark), height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 220,
              height: 48,
              child: ElevatedButton.icon(
                icon:
                    const Icon(Icons.filter_alt_off_rounded, size: 18),
                label: const Text('Reset All Filters'),
                onPressed: onClearFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 450.ms).scale(
          begin: const Offset(0.94, 0.94),
          end: const Offset(1.0, 1.0),
          curve: Curves.easeOutCubic,
        );
  }
}

// ─── String Extension ──────────────────────────────────────────────────────

extension _StringCapitalize on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}