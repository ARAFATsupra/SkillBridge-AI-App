// lib/ml/jaccard.dart — SkillBridge AI
// Jaccard Similarity Engine
//
// Research foundations:
//   - Alsaif et al. (2022): Jaccard Coefficient (JC) vs Cosine Similarity (CS)
//       → JC(A, B) = |A ∩ B| / |A ∪ B|  [Alsaif et al. §3.2, Eq. 8]
//       → Cosine accuracy 0.86 vs Jaccard 0.61 across 159 resumes
//       → Jaccard best used as a complementary set-overlap signal alongside cosine.
//   - Dawson et al. (2021): Asymmetric skill coverage for transition difficulty.
//   - Levandowsky & Winter (1971): Jaccard distance / similarity formulation.
//   - Huang (2022): Term-weight attention applied to set-overlap metrics.
//
// This file is the canonical standalone Jaccard module for SkillBridge AI.
// All other ML files (cosine.dart, recommender.dart, sbert.dart) import from here.
//
// Public surface:
//   - jaccardSimilarity(Set, Set)                → double
//   - jaccardSimilarityFromLists(List, List)     → double
//   - weightedJaccard(Map, Map)                  → double
//   - asymmetricCoverage(Set, Set)               → double
//   - jaccardDistance(Set, Set)                  → double
//   - jaccardBatch(Set, List)                    → List<JaccardResult>
//   - topKByJaccard(Set, List, {int k})          → List<JaccardResult>
//   - JaccardResult                              (immutable result bundle)
//   - JaccardBatchEntry                          (candidate container)

import 'package:meta/meta.dart';

// =============================================================================
// §1  CONSTANTS
// =============================================================================

/// Minimum Jaccard score to be considered a "partial" match.
/// Below this threshold the overlap is considered negligible.
///
/// [Alsaif et al. §4.3] — corresponds to "weak" tier in their 3-tier system.
const double kJaccardWeakThreshold = 0.15;

/// Minimum Jaccard score for a "moderate" match.
/// [Alsaif et al. §4.3]
const double kJaccardModerateThreshold = 0.40;

/// Minimum Jaccard score for a "strong" match.
/// [Alsaif et al. §4.3]
const double kJaccardStrongThreshold = 0.65;

// =============================================================================
// §2  PUBLIC VALUE OBJECTS
// =============================================================================

/// Immutable result returned by [jaccardBatch] and [topKByJaccard].
@immutable
class JaccardResult {
  /// Key identifying the candidate (e.g. job ID or title).
  final String key;

  /// Jaccard similarity in [0.0, 1.0].
  final double similarity;

  /// Jaccard distance = 1 − similarity.
  double get distance => 1.0 - similarity;

  /// Number of skills in the intersection |A ∩ B|.
  final int intersectionSize;

  /// Number of skills in the union |A ∪ B|.
  final int unionSize;

  /// Human-readable match tier label.
  String get tierLabel {
    if (similarity >= kJaccardStrongThreshold) return 'Strong Match';
    if (similarity >= kJaccardModerateThreshold) return 'Moderate Match';
    if (similarity >= kJaccardWeakThreshold) return 'Weak Match';
    return 'No Match';
  }

  const JaccardResult({
    required this.key,
    required this.similarity,
    required this.intersectionSize,
    required this.unionSize,
  });

  @override
  String toString() =>
      'JaccardResult(key: "$key", similarity: ${similarity.toStringAsFixed(4)}, '
      'intersection: $intersectionSize, union: $unionSize, tier: $tierLabel)';
}

/// Input container for [jaccardBatch] and [topKByJaccard].
@immutable
class JaccardBatchEntry {
  /// Unique identifier for this candidate (e.g. job ID or title).
  final String key;

  /// The set of skills for this candidate. Already normalised (lower-cased).
  final Set<String> skills;

  const JaccardBatchEntry({required this.key, required this.skills});

  /// Convenience constructor from a raw list; normalises each entry.
  factory JaccardBatchEntry.fromList(String key, List<String> skills) =>
      JaccardBatchEntry(key: key, skills: _normalise(skills));
}

// =============================================================================
// §3  CORE SIMILARITY FUNCTIONS
// =============================================================================

/// Computes the Jaccard Coefficient between two pre-normalised skill sets.
///
/// Formula: JC(A, B) = |A ∩ B| / |A ∪ B|
///
/// [Alsaif et al. 2022, §3.2] used Jaccard as a fallback metric for sparse
/// vectors where cosine similarity may be unreliable due to low term overlap.
/// Their evaluation on 159 resumes found:
///   - Cosine accuracy: **0.86**
///   - Jaccard accuracy: **0.61**
///
/// Edge cases:
///   - Both empty → returns **1.0** (vacuously identical).
///   - Exactly one empty → returns **0.0**.
///
/// ### Parameters
/// - [setA], [setB]: pre-normalised (lower-cased, trimmed) skill sets.
///   Call [jaccardSimilarityFromLists] if you have raw lists.
double jaccardSimilarity(Set<String> setA, Set<String> setB) {
  if (setA.isEmpty && setB.isEmpty) return 1.0;
  if (setA.isEmpty || setB.isEmpty) return 0.0;

  final int intersectionSize = setA.intersection(setB).length;
  final int unionSize = setA.union(setB).length;
  return unionSize == 0 ? 0.0 : intersectionSize / unionSize;
}

/// Convenience overload: accepts raw lists (lowercased and trimmed internally).
///
/// [Alsaif et al. §3.2]
double jaccardSimilarityFromLists(List<String> a, List<String> b) =>
    jaccardSimilarity(_normalise(a), _normalise(b));

/// Jaccard distance: 1 − JC(A, B).
///
/// Satisfies the metric axioms (symmetry, triangle inequality) when used on
/// binary feature sets. Use this for clustering or distance-based algorithms
/// rather than similarity-based ranking. [Levandowsky & Winter, 1971]
double jaccardDistance(Set<String> setA, Set<String> setB) =>
    1.0 - jaccardSimilarity(setA, setB);

/// Jaccard distance from raw lists.
double jaccardDistanceFromLists(List<String> a, List<String> b) =>
    1.0 - jaccardSimilarityFromLists(a, b);

// =============================================================================
// §4  WEIGHTED JACCARD
// =============================================================================

/// Weighted Jaccard similarity for term-importance maps.
///
/// Extends the binary Jaccard formula to handle continuous weights:
///
///   WJ(A, B) = Σ min(w_A(t), w_B(t)) / Σ max(w_A(t), w_B(t))
///
/// where w_A(t) is the weight (e.g. TF-IDF score) of term t in document A,
/// and 0 is used for missing terms.
///
/// Reduces to standard Jaccard when all weights are 0 or 1.
///
/// Useful when you already have TF-IDF vectors and want a Jaccard-family score
/// that accounts for term importance, not just presence/absence.
///
/// ### Parameters
/// - [a], [b]: term → weight maps. Keys should be pre-normalised.
/// - Returns **1.0** when both maps are empty; **0.0** when one is empty.
double weightedJaccard(Map<String, double> a, Map<String, double> b) {
  if (a.isEmpty && b.isEmpty) return 1.0;
  if (a.isEmpty || b.isEmpty) return 0.0;

  final allKeys = {...a.keys, ...b.keys};

  double numerator = 0.0;
  double denominator = 0.0;

  for (final key in allKeys) {
    final wA = a[key] ?? 0.0;
    final wB = b[key] ?? 0.0;
    numerator += wA < wB ? wA : wB; // min
    denominator += wA > wB ? wA : wB; // max
  }

  return denominator == 0.0 ? 0.0 : numerator / denominator;
}

// =============================================================================
// §5  ASYMMETRIC SKILL COVERAGE
// =============================================================================

/// Asymmetric skill coverage: fraction of *required* skills covered by candidate.
///
/// Unlike symmetric Jaccard, this metric is **directional** [Dawson et al. 2021]:
/// a candidate may cover all required skills while the job covers only half of
/// theirs — the asymmetry is critical for transition-difficulty estimation.
///
/// Formula: coverage(required, candidate) = |required ∩ candidate| / |required|
///
/// Edge cases:
///   - [requiredSkills] is empty → returns **1.0** (nothing to satisfy).
///   - [candidateSkills] is empty but requirements exist → returns **0.0**.
///   - Comparison is **case-insensitive** with leading/trailing whitespace stripped.
///
/// ### Parameters
/// - [requiredSkills]: skills the job demands (denominator).
/// - [candidateSkills]: skills the candidate offers (numerator contributor).
double asymmetricCoverage(
  Set<String> requiredSkills,
  Set<String> candidateSkills,
) {
  if (requiredSkills.isEmpty) return 1.0;
  if (candidateSkills.isEmpty) return 0.0;

  final matched = requiredSkills.intersection(candidateSkills).length;
  return matched / requiredSkills.length;
}

/// Convenience overload from raw lists (normalised internally).
double asymmetricCoverageFromLists(
  List<String> required,
  List<String> candidate,
) =>
    asymmetricCoverage(_normalise(required), _normalise(candidate));

// =============================================================================
// §6  BATCH SCORING
// =============================================================================

/// Scores [query] against every candidate in [candidates] and returns all
/// results sorted by similarity descending.
///
/// More efficient than repeated [jaccardSimilarity] calls when the query set
/// is constant, because the query is normalised only once.
///
/// ### Parameters
/// - [query]: the user's skill set (raw list; normalised internally).
/// - [candidates]: list of [JaccardBatchEntry] to score against.
List<JaccardResult> jaccardBatch(
  List<String> query,
  List<JaccardBatchEntry> candidates,
) {
  final querySet = _normalise(query);
  final results = <JaccardResult>[];

  for (final candidate in candidates) {
    final intersection = querySet.intersection(candidate.skills);
    final union = querySet.union(candidate.skills);
    final sim = union.isEmpty ? 0.0 : intersection.length / union.length;

    results.add(JaccardResult(
      key: candidate.key,
      similarity: sim,
      intersectionSize: intersection.length,
      unionSize: union.length,
    ));
  }

  results.sort((a, b) => b.similarity.compareTo(a.similarity));
  return results;
}

/// Returns the top-[k] Jaccard matches for [query] from [candidates],
/// sorted by similarity descending.
///
/// ### Parameters
/// - [k]: number of results to return (default 10). Clamped to
///   `candidates.length` automatically.
/// - [minSimilarity]: lower bound — results below this threshold are excluded
///   even if they'd otherwise be in the top K. Default 0.0 (no cutoff).
List<JaccardResult> topKByJaccard(
  List<String> query,
  List<JaccardBatchEntry> candidates, {
  int k = 10,
  double minSimilarity = 0.0,
}) {
  final all = jaccardBatch(query, candidates);
  return all
      .where((r) => r.similarity >= minSimilarity)
      .take(k.clamp(1, all.length))
      .toList();
}

// =============================================================================
// §7  EVALUATION HELPERS
// =============================================================================

/// Computes per-threshold precision, recall, and F1 across a labelled result set.
///
/// [results]: the ranked [JaccardResult] list from [jaccardBatch].
/// [relevant]: set of keys considered ground-truth relevant.
/// [threshold]: minimum similarity to count as "retrieved". Default 0.15.
///
/// Returns a map with keys: `precision`, `recall`, `f1`, `retrieved`, `relevant`.
Map<String, double> jaccardEvaluate({
  required List<JaccardResult> results,
  required Set<String> relevant,
  double threshold = kJaccardWeakThreshold,
}) {
  final retrieved = results.where((r) => r.similarity >= threshold).toList();
  final truePositives = retrieved.where((r) => relevant.contains(r.key)).length;

  final precision =
      retrieved.isEmpty ? 0.0 : truePositives / retrieved.length;
  final recall =
      relevant.isEmpty ? 0.0 : truePositives / relevant.length;
  final f1 = (precision + recall) == 0
      ? 0.0
      : 2 * precision * recall / (precision + recall);

  return {
    'precision': precision,
    'recall': recall,
    'f1': f1,
    'retrieved': retrieved.length.toDouble(),
    'relevant': relevant.length.toDouble(),
  };
}

// =============================================================================
// §8  PRIVATE HELPERS
// =============================================================================

/// Normalises a raw skill list: trims whitespace, lowercases, deduplicates.
Set<String> _normalise(List<String> skills) =>
    skills.map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty).toSet();
