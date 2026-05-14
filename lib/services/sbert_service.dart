// lib/services/sbert_service.dart — SkillBridge AI
//
// SBERT Re-ranking Service
// ────────────────────────────────────────────────────────────────────────────
// Integrates Python-side SBERT semantic scores with the on-device TF-IDF
// engine.  The pipeline is:
//
//   1. [recommender.dart] runs TF-IDF + Jaccard → returns List<JobRecommendation>
//   2. SbertService.rerank()  sends the top-K candidates to the Flask API
//   3. Flask API encodes the user query with SBERT; scores it against the
//      candidate embeddings; returns SBERT scores sorted descending
//   4. SbertService blends the returned SBERT scores into the final hybrid score
//
// Hybrid score formula (mirrors the Colab notebook §8):
//
//   hybrid = α·tfidf_cosine + β·sbert + γ·jaccard
//   default weights: α=0.40, β=0.45, γ=0.15
//
// Graceful degradation:
//   If the Flask API is unreachable (offline / no server running), the service
//   logs a warning and falls back to LocalSbertService (lib/ml/sbert.dart) for
//   offline re-ranking.  The app never crashes due to SBERT unavailability.
//
// Usage
// ─────
// // 1. Get TF-IDF results as usual
// final tfidfResults = recommendJobs(userSkills, config: config);
//
// // 2. Re-rank asynchronously with SBERT
// final sbertService = SbertService();
// final hybridResults = await sbertService.rerank(
//   tfidfResults,
//   userQuery: 'data analyst python sql london',
// );
//
// // 3. Use hybridResults exactly like the original List<JobRecommendation>
// ────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

import '../ml/recommender.dart';
import '../ml/sbert.dart';

// =============================================================================
// §1  CONFIGURATION
// =============================================================================

/// Base URL of the Flask SBERT microservice.
///
/// - Development: `http://localhost:5001`  (sbert_api.py running on your machine)
/// - Production / hosted: replace with your server's public URL, e.g.
///   `https://api.skillbridge.example.com`
///
/// Can be overridden at runtime by calling [SbertService.configure].
String _baseUrl = 'http://localhost:5001';

/// Maximum number of TF-IDF candidates forwarded to the SBERT API for
/// re-ranking.  Larger → better recall; smaller → faster API response.
const int _defaultCandidatePool = 50;

/// HTTP timeout for the /rerank call.
const Duration _kTimeout = Duration(seconds: 8);

/// Hybrid score weights (must sum to 1.0).
const double _wTfidf   = 0.40; // keyword-exact signal
const double _wSbert   = 0.45; // semantic signal
const double _wJaccard = 0.15; // set-overlap signal

// =============================================================================
// §2  SBERT SCORE RESULT (from the Flask API)
// =============================================================================

/// Parsed entry from the `/rerank` response `rankings` array.
class _SbertRanking {
  final int id;
  final double sbertScore;
  const _SbertRanking({required this.id, required this.sbertScore});

  factory _SbertRanking.fromJson(Map<String, dynamic> json) => _SbertRanking(
        id: (json['id'] as num).toInt(),
        sbertScore: (json['sbert_score'] as num).toDouble(),
      );
}

// =============================================================================
// §3  SERVICE CLASS
// =============================================================================

/// Provides SBERT-based semantic re-ranking for [JobRecommendation] lists.
///
/// Stateless — safe to instantiate once and reuse.
class SbertService {
  // ── Singleton (optional; callers can also use plain instances) ─────────
  SbertService._internal();
  static final SbertService _instance = SbertService._internal();
  factory SbertService() => _instance;

  // ── Runtime configuration ─────────────────────────────────────────────

  /// Override the Flask API base URL at runtime.
  ///
  /// Call before the first [rerank] call if your server is not at
  /// `http://localhost:5001`.
  static void configure({String? baseUrl}) {
    if (baseUrl != null) _baseUrl = baseUrl.trimRight().replaceAll(RegExp(r'/$'), '');
  }

  // ── Public API ────────────────────────────────────────────────────────

  /// Re-rank [tfidfResults] using SBERT semantic similarity.
  ///
  /// [userQuery] — the same text query that was fed into the TF-IDF engine
  ///   (build it with `buildUserQuery(...)` in the Colab notation, or
  ///   concatenate role + skills + industry + level + location).
  ///
  /// [candidatePool] — how many of the top TF-IDF candidates to send to the
  ///   API.  Defaults to [_defaultCandidatePool].
  ///
  /// [alphaTfidf], [betaSbert], [gammaJaccard] — hybrid blend weights.
  ///   Must sum to 1.0.
  ///
  /// Returns a new [List<JobRecommendation>] sorted by hybrid score.
  /// On API failure, falls back to [LocalSbertService] for offline re-ranking.
  Future<List<JobRecommendation>> rerank(
    List<JobRecommendation> tfidfResults, {
    required String userQuery,
    int? candidatePool,
    double alphaTfidf   = _wTfidf,
    double betaSbert    = _wSbert,
    double gammaJaccard = _wJaccard,
  }) async {
    if (tfidfResults.isEmpty) return tfidfResults;

    final pool = (candidatePool ?? _defaultCandidatePool)
        .clamp(1, tfidfResults.length);

    // ── Slice the pool ─────────────────────────────────────────────────
    final poolCandidates = tfidfResults.take(pool).toList();

    // ── Build the API payload ──────────────────────────────────────────
    //
    // We send each candidate's job ID and a concise text representation.
    // The API uses these texts to look up (or recompute) SBERT embeddings.
    // `id` here is JobRecommendation.id — the row index in the job dataset.
    final payload = jsonEncode({
      'query': userQuery,
      'candidates': poolCandidates
          .map((r) => {
                'id':   r.id,
                'text': _jobText(r),
              })
          .toList(),
    });

    // ── Call the Flask API ─────────────────────────────────────────────
    Map<String, dynamic>? apiResponse;
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/rerank'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(_kTimeout);

      if (response.statusCode == 200) {
        apiResponse = jsonDecode(response.body) as Map<String, dynamic>;
        dev.log(
          'SBERT /rerank OK  '
          '(${poolCandidates.length} candidates, '
          '${apiResponse["latency_ms"]}ms)',
          name: 'SbertService',
        );
      } else {
        dev.log(
          'SBERT /rerank HTTP ${response.statusCode}: ${response.body}',
          name: 'SbertService',
          level: 900,
        );
      }
    } catch (e) {
      dev.log(
        'SBERT API unreachable ($e) — falling back to LocalSbertService',
        name: 'SbertService',
        level: 900,
      );
      return await LocalSbertService().rerank(tfidfResults, userQuery: userQuery);
    }

    if (apiResponse == null) return tfidfResults;

    // ── Parse SBERT scores ─────────────────────────────────────────────
    final rankings = (apiResponse['rankings'] as List<dynamic>)
        .map((e) => _SbertRanking.fromJson(e as Map<String, dynamic>))
        .toList();

    // Build id → sbertScore lookup
    final sbertScores = <int, double>{
      for (final r in rankings) r.id: r.sbertScore,
    };

    // ── Blend TF-IDF + SBERT → hybrid score ────────────────────────────
    //
    // tfidfResults already carries:
    //   • score       ≈ TF-IDF cosine contribution (pre-normalised to [0,1])
    //   • matchRatio  ≈ Jaccard set-overlap
    //
    // We blend these with the freshly retrieved SBERT semantic score.
    final hybridPool = poolCandidates.map((rec) {
      final sbert = sbertScores[rec.id] ?? 0.0;
      final hybrid = alphaTfidf   * rec.score +
                     betaSbert    * sbert     +
                     gammaJaccard * rec.matchRatio;
      return _HybridResult(recommendation: rec, hybridScore: hybrid, sbertScore: sbert);
    }).toList()
      ..sort((a, b) => b.hybridScore.compareTo(a.hybridScore));

    // ── Append the rest of the list (outside the pool) unchanged ───────
    final remainder = tfidfResults.skip(pool).toList();

    // Return pool (now hybrid-sorted) + remainder (TF-IDF order)
    return [
      ...hybridPool.map((h) => h.recommendation),
      ...remainder,
    ];
  }

  // ── Health check ──────────────────────────────────────────────────────

  /// Returns `true` if the Flask API is reachable and reports status OK.
  Future<bool> isAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['status'] == 'ok';
      }
    } catch (_) {
      // server not running
    }
    return false;
  }

  // ── Private helpers ───────────────────────────────────────────────────

  /// Build a concise text representation of a job for the SBERT API.
  ///
  /// Mirrors the `combined_text` field constructed in the Colab notebook (§4):
  ///   title · industry · level · skills (×2) · location
  static String _jobText(JobRecommendation r) {
    final skills = r.matching + r.missing; // all required skills
    final skillStr = skills.join(', ');
    return '${r.title} ${r.industry} ${r.level} $skillStr $skillStr ${r.location}'
        .toLowerCase()
        .trim();
  }
}

// =============================================================================
// §4  INTERNAL VALUE TYPE
// =============================================================================

/// Temporary container used during score blending before the final sort.
class _HybridResult {
  final JobRecommendation recommendation;
  final double hybridScore;
  final double sbertScore;

  const _HybridResult({
    required this.recommendation,
    required this.hybridScore,
    required this.sbertScore,
  });
}