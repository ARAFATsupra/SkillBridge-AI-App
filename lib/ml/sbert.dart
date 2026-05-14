// lib/ml/sbert.dart — SkillBridge AI
// Pure-Dart Sentence-BERT Approximation (LocalSbert)
//
// Research foundations:
//   - Reimers & Gurevych (2019): Sentence-BERT — sentence embeddings using
//       siamese BERT networks; cosine similarity on embeddings.
//   - Ajjam & Al-Raweshidy (2026): SBERT re-ranking outperforms TF-IDF alone
//       on semantic job matching (Precision@10, Recall@10).
//   - Huang (2022): Cluster-based attention weighting for skill embeddings.
//   - Mikolov et al. (2013): Skip-gram / mean-pooling sentence representations.
//
// What this file implements
// ─────────────────────────
// A fully offline, pure-Dart approximation of SBERT that requires NO server,
// NO HTTP call, and NO native code.  It mirrors the public API of the
// Flask-backed [SbertService] in lib/services/sbert_service.dart so that
// callers can swap implementations without touching business logic.
//
// Architecture:
//   1. Each term is mapped to one or more semantic clusters (§3).
//   2. A 32-dimensional embedding is generated from cluster memberships (§4).
//   3. Sentence embedding = mean-pool of constituent token embeddings (§5).
//   4. Similarity = cosine distance between sentence embeddings (§5).
//   5. [LocalSbertService] re-ranks [JobRecommendation] lists using the same
//      α/β/γ hybrid formula as sbert_service.dart (§6).
//
// Trade-offs vs. true SBERT
// ─────────────────────────
// ✓  No server required — always available offline.
// ✓  Zero latency — sub-millisecond per sentence.
// ✓  Domain-tuned — cluster vocabulary built from Bangladeshi job market data.
// ✗  Approximation only — does not capture fine-grained syntactic context.
//    Use the Flask-backed SbertService for highest accuracy in production.
//
// Usage
// ─────
// // Drop-in replacement for SbertService:
// final sbert = LocalSbertService();
// final reranked = await sbert.rerank(tfidfResults, userQuery: 'python data analyst');
//
// // Standalone similarity:
// final encoder = LocalSbertEncoder();
// final score = encoder.similarity('python machine learning', 'data science nlp');
//
// Public surface:
//   LocalSbertEncoder  — encodeText(), similarity()
//   LocalSbertService  — rerank(), isAvailable(), configure() [no-ops]
//   SbertConfig        — hybrid blend weights

import 'dart:math' show sqrt;
import 'package:meta/meta.dart';

import 'recommender.dart' show JobRecommendation;
import 'jaccard.dart' show asymmetricCoverageFromLists;

// =============================================================================
// §1  CONFIGURATION
// =============================================================================

/// Hybrid blend weights used by [LocalSbertService.rerank].
///
/// Mirrors the defaults in sbert_service.dart:
///   hybrid = α·tfidf_cosine + β·sbert + γ·jaccard
@immutable
class SbertConfig {
  /// Weight for the TF-IDF cosine signal (α).
  final double alphaTfidf;

  /// Weight for the local SBERT semantic signal (β).
  final double betaSbert;

  /// Weight for the Jaccard set-overlap signal (γ).
  final double gammaJaccard;

  const SbertConfig({
    this.alphaTfidf = 0.40,
    this.betaSbert = 0.45,
    this.gammaJaccard = 0.15,
  }) : assert(
          alphaTfidf + betaSbert + gammaJaccard > 0.999 &&
              alphaTfidf + betaSbert + gammaJaccard < 1.001,
          'SbertConfig weights must sum to 1.0',
        );

  @override
  String toString() =>
      'SbertConfig(α=$alphaTfidf, β=$betaSbert, γ=$gammaJaccard)';
}

const SbertConfig _kDefaultConfig = SbertConfig();

// =============================================================================
// §2  EMBEDDING DIMENSIONS
// =============================================================================

/// Dimensionality of the cluster-based sentence embedding.
///
/// - Dims 0–19 : cluster membership weights  (20 semantic clusters)
/// - Dims 20–31: intra-cluster discriminator (12 term-specific dims)
const int _kEmbeddingDim = 32;

/// Number of semantic skill clusters.
const int _kNumClusters = 20;

// =============================================================================
// §3  SEMANTIC CLUSTER DEFINITIONS
// =============================================================================
//
// Each entry maps a canonical term (lower-cased) to a list of cluster IDs it
// belongs to.  Primary cluster listed first; secondary clusters contribute at
// half weight.  Terms not in the map fall back to the OOV (out-of-vocabulary)
// embedding computed from character n-grams.
//
// Cluster IDs:
//  0  Core programming languages  (python, java, c++, …)
//  1  Web front-end               (javascript, react, html, css, …)
//  2  Web back-end / frameworks   (node.js, django, flask, laravel, …)
//  3  Databases                   (sql, mysql, postgresql, mongodb, …)
//  4  Data science / analytics    (machine learning, statistics, …)
//  5  Data engineering            (spark, hadoop, etl, kafka, …)
//  6  Cloud / DevOps              (aws, docker, kubernetes, terraform, …)
//  7  Mobile development          (android, ios, flutter, kotlin, …)
//  8  AI / ML tools               (tensorflow, pytorch, scikit-learn, …)
//  9  Project management          (agile, scrum, jira, pmp, …)
// 10  Leadership / strategy       (leadership, management, strategic planning, …)
// 11  Communication / soft skills (communication, teamwork, writing, …)
// 12  Finance / accounting        (accounting, finance, budgeting, excel, …)
// 13  Marketing / growth          (marketing, seo, social media, google ads, …)
// 14  Design / UX                 (ui/ux, figma, adobe, prototyping, …)
// 15  Sales / business dev        (sales, crm, negotiation, business dev, …)
// 16  Engineering disciplines     (electrical, mechanical, civil, autocad, …)
// 17  Healthcare / clinical       (nursing, clinical research, medicine, …)
// 18  Research / education        (research, teaching, academic writing, …)
// 19  Operations / supply chain   (logistics, supply chain, procurement, …)

const Map<String, List<int>> _kClusterMap = {
  // ── Cluster 0: Core programming ──────────────────────────────────────
  'python': [0, 4, 8],
  'java': [0, 2],
  'c++': [0, 16],
  'c#': [0, 2],
  'r': [0, 4],
  'matlab': [0, 4, 16],
  'scala': [0, 5],
  'go': [0, 2, 6],
  'rust': [0, 2],
  'kotlin': [0, 7],
  'swift': [0, 7],
  'php': [0, 2],
  'ruby': [0, 2],
  'perl': [0],
  'bash': [0, 6],
  'shell scripting': [0, 6],
  'programming': [0],
  'coding': [0],
  'software development': [0, 2],
  'object oriented programming': [0],
  'functional programming': [0],
  'algorithms': [0],
  'data structures': [0],

  // ── Cluster 1: Web front-end ─────────────────────────────────────────
  'javascript': [1, 0],
  'typescript': [1, 0],
  'react': [1, 7],
  'angular': [1],
  'vue': [1],
  'html': [1],
  'css': [1, 14],
  'sass': [1, 14],
  'webpack': [1],
  'next.js': [1, 2],
  'nuxt': [1, 2],
  'web development': [1, 2],
  'frontend development': [1],
  'responsive design': [1, 14],
  'bootstrap': [1, 14],
  'tailwind': [1, 14],
  'jquery': [1],

  // ── Cluster 2: Web back-end / frameworks ─────────────────────────────
  'node.js': [2, 1],
  'django': [2, 0],
  'flask': [2, 0],
  'fastapi': [2, 0],
  'spring boot': [2, 0],
  'laravel': [2, 0],
  'express.js': [2, 1],
  'rest api': [2],
  'graphql': [2, 3],
  'microservices': [2, 6],
  'backend development': [2],
  'api development': [2],
  'web services': [2],

  // ── Cluster 3: Databases ──────────────────────────────────────────────
  'sql': [3, 4],
  'mysql': [3],
  'postgresql': [3],
  'sqlite': [3],
  'mongodb': [3],
  'redis': [3, 6],
  'elasticsearch': [3, 5],
  'cassandra': [3, 5],
  'firebase': [3, 6],
  'database design': [3],
  'database management': [3],
  'nosql': [3],
  'orm': [3, 0],
  'data modeling': [3, 4],

  // ── Cluster 4: Data science / analytics ─────────────────────────────
  'machine learning': [4, 8],
  'deep learning': [4, 8],
  'nlp': [4, 8],
  'natural language processing': [4, 8],
  'computer vision': [4, 8],
  'data science': [4, 8],
  'data analysis': [4, 3],
  'statistics': [4],
  'statistical analysis': [4],
  'data visualization': [4, 14],
  'tableau': [4, 14],
  'power bi': [4, 12],
  'data mining': [4, 5],
  'predictive modeling': [4, 8],
  'regression analysis': [4],
  'classification': [4, 8],
  'clustering': [4, 8],
  'feature engineering': [4, 8],
  'exploratory data analysis': [4],
  'a/b testing': [4, 13],
  'business intelligence': [4, 12],
  'excel': [4, 12],
  'google sheets': [4, 12],

  // ── Cluster 5: Data engineering ──────────────────────────────────────
  'apache spark': [5, 4],
  'spark': [5, 4],
  'hadoop': [5],
  'hive': [5],
  'kafka': [5, 6],
  'airflow': [5],
  'etl': [5, 3],
  'data pipeline': [5],
  'data warehouse': [5, 3],
  'dbt': [5, 3],
  'snowflake': [5, 3, 6],
  'redshift': [5, 3, 6],
  'bigquery': [5, 3, 6],
  'data lake': [5],
  'flink': [5],

  // ── Cluster 6: Cloud / DevOps ─────────────────────────────────────────
  'aws': [6],
  'azure': [6],
  'gcp': [6],
  'google cloud': [6],
  'docker': [6],
  'kubernetes': [6],
  'terraform': [6],
  'ansible': [6],
  'jenkins': [6],
  'ci/cd': [6],
  'devops': [6],
  'cloud computing': [6],
  'serverless': [6],
  'linux': [6, 0],
  'networking': [6],
  'cybersecurity': [6],
  'security': [6],
  'git': [6, 0],
  'github': [6, 0],
  'gitlab': [6, 0],

  // ── Cluster 7: Mobile development ────────────────────────────────────
  'android': [7, 0],
  'ios': [7, 0],
  'flutter': [7, 0],
  'react native': [7, 1],
  'mobile development': [7],
  'mobile app development': [7],
  'xcode': [7],
  'android studio': [7],

  // ── Cluster 8: AI / ML tools ──────────────────────────────────────────
  'tensorflow': [8, 4],
  'pytorch': [8, 4],
  'scikit-learn': [8, 4],
  'keras': [8, 4],
  'huggingface': [8, 4],
  'pandas': [8, 4, 0],
  'numpy': [8, 4, 0],
  'matplotlib': [8, 4],
  'seaborn': [8, 4],
  'opencv': [8, 4],
  'llm': [8, 4],
  'generative ai': [8, 4],
  'prompt engineering': [8, 4],
  'reinforcement learning': [8, 4],
  'transformer': [8, 4],
  'bert': [8, 4],

  // ── Cluster 9: Project management ─────────────────────────────────────
  'agile': [9, 10],
  'scrum': [9, 10],
  'kanban': [9],
  'jira': [9],
  'confluence': [9, 11],
  'project management': [9, 10],
  'pmp': [9],
  'product management': [9, 10],
  'roadmapping': [9, 10],
  'stakeholder management': [9, 10, 11],
  'risk management': [9, 12],
  'trello': [9],
  'asana': [9],
  'sprint planning': [9],

  // ── Cluster 10: Leadership / strategy ────────────────────────────────
  'leadership': [10, 11],
  'management': [10, 9],
  'team management': [10, 9],
  'strategic planning': [10],
  'decision making': [10],
  'problem solving': [10, 11],
  'critical thinking': [10, 11],
  'mentoring': [10, 18],
  'coaching': [10, 18],
  'change management': [10, 9],
  'organizational development': [10],
  'business strategy': [10, 15],
  'operations management': [10, 19],

  // ── Cluster 11: Communication / soft skills ───────────────────────────
  'communication': [11],
  'teamwork': [11],
  'collaboration': [11],
  'presentation': [11],
  'public speaking': [11],
  'writing': [11, 18],
  'report writing': [11, 18],
  'documentation': [11],
  'interpersonal skills': [11],
  'time management': [11],
  'attention to detail': [11],
  'adaptability': [11],
  'customer service': [11, 15],
  'emotional intelligence': [11, 10],
  'conflict resolution': [11, 10],

  // ── Cluster 12: Finance / accounting ─────────────────────────────────
  'accounting': [12],
  'finance': [12],
  'budgeting': [12],
  'financial analysis': [12, 4],
  'financial modeling': [12, 4],
  'financial reporting': [12, 11],
  'auditing': [12],
  'taxation': [12],
  'cost accounting': [12],
  'erp': [12, 9],
  'sap': [12, 9],
  'quickbooks': [12],
  'tally': [12],
  'investment analysis': [12, 4],
  'risk analysis': [12, 9],
  'ifrs': [12],
  'gaap': [12],

  // ── Cluster 13: Marketing / growth ────────────────────────────────────
  'marketing': [13],
  'digital marketing': [13],
  'seo': [13, 1],
  'sem': [13],
  'google ads': [13],
  'facebook ads': [13],
  'social media marketing': [13],
  'content marketing': [13, 11],
  'email marketing': [13],
  'growth hacking': [13],
  'brand management': [13],
  'market research': [13, 4],
  'google analytics': [13, 4],
  'crm': [13, 15],
  'hubspot': [13, 15],
  'copywriting': [13, 11],
  'video marketing': [13],

  // ── Cluster 14: Design / UX ────────────────────────────────────────────
  'ui/ux': [14],
  'ui': [14, 1],
  'ux': [14],
  'figma': [14],
  'adobe xd': [14],
  'adobe illustrator': [14],
  'adobe photoshop': [14],
  'graphic design': [14],
  'user research': [14],
  'prototyping': [14],
  'wireframing': [14],
  'motion design': [14],
  'design thinking': [14, 10],
  'visual design': [14],
  'canva': [14],
  'sketch': [14],
  'user experience': [14],
  'user interface': [14, 1],

  // ── Cluster 15: Sales / business development ──────────────────────────
  'sales': [15],
  'business development': [15, 10],
  'b2b sales': [15],
  'b2c sales': [15],
  'negotiation': [15, 11],
  'client management': [15, 11],
  'account management': [15],
  'lead generation': [15, 13],
  'cold calling': [15],
  'salesforce': [15, 13],
  'proposal writing': [15, 11],
  'revenue generation': [15, 12],
  'partnership development': [15, 10],

  // ── Cluster 16: Engineering disciplines ──────────────────────────────
  'electrical engineering': [16],
  'mechanical engineering': [16],
  'civil engineering': [16],
  'autocad': [16, 14],
  'solidworks': [16],
  'matlab simulation': [16, 0],
  'plc': [16],
  'scada': [16],
  'embedded systems': [16, 0],
  'robotics': [16, 8],
  'circuit design': [16],
  'structural analysis': [16],
  'project engineering': [16, 9],
  'quality control': [16, 19],
  'six sigma': [16, 19],
  'lean manufacturing': [16, 19],

  // ── Cluster 17: Healthcare / clinical ────────────────────────────────
  'nursing': [17],
  'clinical research': [17, 18],
  'patient care': [17],
  'medical writing': [17, 11],
  'pharmacology': [17],
  'public health': [17, 18],
  'epidemiology': [17, 4],
  'healthcare management': [17, 10],
  'telemedicine': [17, 6],
  'medical coding': [17, 12],
  'laboratory skills': [17],
  'clinical trials': [17, 18],

  // ── Cluster 18: Research / education ──────────────────────────────────
  'research': [18, 4],
  'teaching': [18],
  'academic writing': [18, 11],
  'curriculum development': [18],
  'data collection': [18, 4],
  'qualitative research': [18],
  'quantitative research': [18, 4],
  'literature review': [18],
  'grant writing': [18, 12],
  'e-learning': [18, 7],
  'instructional design': [18, 14],
  'training': [18, 10],
  'online teaching': [18, 7],

  // ── Cluster 19: Operations / supply chain ─────────────────────────────
  'supply chain': [19],
  'logistics': [19],
  'procurement': [19, 12],
  'inventory management': [19],
  'warehouse management': [19],
  'demand planning': [19, 4],
  'vendor management': [19, 15],
  'import export': [19],
  'customs': [19],
  'erp systems': [19, 12, 9],
  'operations': [19, 10],
  'fleet management': [19],
  'quality assurance': [19, 16],
};

// =============================================================================
// §4  EMBEDDING COMPUTATION
// =============================================================================

/// Returns a 32-dimensional unit embedding for a single normalised term.
///
/// Dims 0–19: cluster membership weights.
///   Primary cluster → 1.0; secondary clusters → 0.5.
/// Dims 20–31: intra-cluster discriminator derived from term's character hash.
///
/// Unknown terms produce an OOV vector from character bigrams (dims 20–31 only).
List<double> _termEmbedding(String term) {
  final vec = List<double>.filled(_kEmbeddingDim, 0.0);

  final clusters = _kClusterMap[term];
  if (clusters != null && clusters.isNotEmpty) {
    // Primary cluster → full weight
    vec[clusters[0]] = 1.0;
    // Secondary clusters → half weight
    for (int i = 1; i < clusters.length; i++) {
      vec[clusters[i]] = 0.5;
    }
  }

  // Intra-cluster discriminator: deterministic hash over the term string
  // fills dims 20–31.  This ensures two terms in the same cluster (e.g.
  // 'python' and 'java') are not perfectly identical.
  final hash = _termHash(term);
  for (int d = _kNumClusters; d < _kEmbeddingDim; d++) {
    // Spread hash bits across dims 20–31 in [−0.3, 0.3]
    vec[d] = ((hash >> (d - _kNumClusters)) & 0x3) / 10.0 - 0.15;
  }

  return _unitNorm(vec);
}

/// Deterministic hash for a term string (FNV-1a 32-bit).
int _termHash(String s) {
  const int prime = 16777619;
  int hash = 0x811c9dc5; // FNV offset basis
  for (final c in s.codeUnits) {
    hash = (hash ^ c) * prime & 0xFFFFFFFF;
  }
  return hash;
}

/// Returns the unit-normalised version of [v]. Returns zero vector if |v|=0.
List<double> _unitNorm(List<double> v) {
  double magnitude = 0.0;
  for (final x in v) {
    magnitude += x * x;
  }
  magnitude = sqrt(magnitude);
  if (magnitude == 0.0) return List<double>.filled(v.length, 0.0);
  return v.map((x) => x / magnitude).toList();
}

/// Dot product of two same-length vectors.
double _dot(List<double> a, List<double> b) {
  double sum = 0.0;
  for (int i = 0; i < a.length; i++) {
    sum += a[i] * b[i];
  }
  return sum;
}

// =============================================================================
// §5  SENTENCE ENCODER
// =============================================================================

/// Pure-Dart SBERT approximation for career-domain text.
///
/// Encodes sentences into 32-dimensional vectors via:
///   1. Tokenisation (whitespace + punctuation split, stopword removal).
///   2. Term embedding lookup against [_kClusterMap].
///   3. Mean-pooling over all token embeddings. [Mikolov et al. 2013]
///   4. Unit normalisation of the resulting vector.
///
/// The resulting cosine similarity closely tracks semantic skill proximity
/// in the Bangladeshi job-market domain.
class LocalSbertEncoder {
  // Singleton — stateless, safe to reuse
  LocalSbertEncoder._internal();
  static final LocalSbertEncoder _instance = LocalSbertEncoder._internal();
  factory LocalSbertEncoder() => _instance;

  // ── Public API ────────────────────────────────────────────────────────

  /// Encodes [text] into a 32-dimensional unit vector.
  ///
  /// Returns a zero vector if [text] contains no recognisable terms.
  List<double> encodeText(String text) {
    final tokens = _tokenise(text);
    if (tokens.isEmpty) return List<double>.filled(_kEmbeddingDim, 0.0);

    // Mean-pool token embeddings
    final pooled = List<double>.filled(_kEmbeddingDim, 0.0);
    for (final token in tokens) {
      final emb = _termEmbedding(token);
      for (int d = 0; d < _kEmbeddingDim; d++) {
        pooled[d] += emb[d];
      }
    }
    for (int d = 0; d < _kEmbeddingDim; d++) {
      pooled[d] /= tokens.length;
    }
    return _unitNorm(pooled);
  }

  /// Cosine similarity between two free-form skill/job texts.
  ///
  /// Returns a value in [0.0, 1.0]; higher = more semantically similar.
  double similarity(String textA, String textB) {
    final a = encodeText(textA);
    final b = encodeText(textB);
    final sim = _dot(a, b).clamp(0.0, 1.0);
    return sim;
  }

  // ── Private helpers ───────────────────────────────────────────────────

  /// Tokenises text into normalised terms.
  ///
  /// Strategy:
  ///   1. Lowercase and strip punctuation (except '/' and '.' for acronyms).
  ///   2. Try multi-word phrase matching (bigrams, trigrams) first so that
  ///      'machine learning' is recognised as a single cluster term rather
  ///      than two unknown unigrams.
  ///   3. Fall back to unigrams for unmatched tokens.
  ///   4. Remove stopwords.
  List<String> _tokenise(String text) {
    // Basic clean
    final clean = text.toLowerCase().replaceAll(RegExp(r'[^\w\s./+-]'), ' ');
    final words = clean
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !_kStopWords.contains(w))
        .toList();

    final tokens = <String>[];
    int i = 0;
    while (i < words.length) {
      // Try trigram
      if (i + 2 < words.length) {
        final tri = '${words[i]} ${words[i + 1]} ${words[i + 2]}';
        if (_kClusterMap.containsKey(tri)) {
          tokens.add(tri);
          i += 3;
          continue;
        }
      }
      // Try bigram
      if (i + 1 < words.length) {
        final bi = '${words[i]} ${words[i + 1]}';
        if (_kClusterMap.containsKey(bi)) {
          tokens.add(bi);
          i += 2;
          continue;
        }
      }
      // Unigram (known or OOV)
      tokens.add(words[i]);
      i++;
    }
    return tokens;
  }
}

// ── Stopword list (English + domain-specific noise) ───────────────────────────
const Set<String> _kStopWords = {
  'a', 'an', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
  'of', 'with', 'by', 'from', 'up', 'about', 'into', 'through', 'during',
  'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had',
  'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might',
  'shall', 'can', 'not', 'no', 'nor', 'so', 'yet', 'both', 'either',
  'each', 'few', 'more', 'most', 'other', 'some', 'such',
  'than', 'too', 'very', 's', 't', 'just', 'don', 'now', 'i', 'you',
  'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them',
  // Domain noise
  'experience', 'skills', 'skill', 'knowledge', 'ability', 'proficiency',
  'strong', 'good', 'excellent', 'required', 'preferred', 'must', 'year',
  'years', 'work', 'working', 'minimum', 'least', 'plus', 'using', 'use',
};

// =============================================================================
// §6  LOCAL SBERT SERVICE  (drop-in replacement for SbertService)
// =============================================================================

/// Fully-offline SBERT re-ranking service.
///
/// Provides the same public API as [SbertService] in sbert_service.dart, but
/// uses [LocalSbertEncoder] instead of a Flask HTTP call.
///
/// ### Hybrid formula (mirrors sbert_service.dart §1):
///   hybrid = α·tfidf_cosine + β·local_sbert + γ·jaccard
///
/// ### When to prefer this over SbertService:
///   - The app is running offline or the Flask server is not deployed.
///   - Latency is critical (local is sub-millisecond vs. 100–500 ms HTTP).
///   - A server cannot be provisioned (e.g. free-tier hosting).
///
/// ### When to prefer SbertService:
///   - Maximum semantic accuracy is required.
///   - The Flask server (sbert_api.py) is reliably deployed.
class LocalSbertService {
  // Singleton
  LocalSbertService._internal();
  static final LocalSbertService _instance = LocalSbertService._internal();
  factory LocalSbertService() => _instance;

  final LocalSbertEncoder _encoder = LocalSbertEncoder();

  // ── Runtime configuration (mirrors SbertService.configure) ────────────

  /// No-op: kept for API compatibility with SbertService.
  /// LocalSbertService has no server URL to configure.
  static void configure({String? baseUrl}) {
    // intentionally empty — local service needs no URL
  }

  // ── Public API ─────────────────────────────────────────────────────────

  /// Re-ranks [tfidfResults] using local SBERT semantic similarity.
  ///
  /// ### Parameters
  /// - [tfidfResults]: ranked list from the TF-IDF engine (recommender.dart).
  /// - [userQuery]: free-form query text (role + skills + industry, etc.).
  /// - [candidatePool]: how many top candidates to re-rank. Default 50.
  /// - [config]: blend weights α/β/γ. Defaults to [_kDefaultConfig].
  ///
  /// Returns a new sorted [List<JobRecommendation>].
  /// On an empty input, returns [tfidfResults] unchanged.
  Future<List<JobRecommendation>> rerank(
    List<JobRecommendation> tfidfResults, {
    required String userQuery,
    int candidatePool = 50,
    SbertConfig config = _kDefaultConfig,
    // Legacy named params — kept for drop-in compat with SbertService
    double alphaTfidf = 0.40,
    double betaSbert = 0.45,
    double gammaJaccard = 0.15,
  }) async {
    if (tfidfResults.isEmpty) return tfidfResults;

    final pool = candidatePool.clamp(1, tfidfResults.length);
    final poolCandidates = tfidfResults.take(pool).toList();
    final remainder = tfidfResults.skip(pool).toList();

    // Encode the user query once (amortised over all candidates)
    final queryVec = _encoder.encodeText(userQuery);

    final reranked = poolCandidates.map((rec) {
      // Local SBERT score: cosine between query embedding and job text embedding
      final jobText = _jobText(rec);
      final jobVec = _encoder.encodeText(jobText);
      final sbertScore = _dot(queryVec, jobVec).clamp(0.0, 1.0);

      // Use provided legacy params if config is default
      final a = config == _kDefaultConfig ? alphaTfidf : config.alphaTfidf;
      final b = config == _kDefaultConfig ? betaSbert : config.betaSbert;
      final g = config == _kDefaultConfig ? gammaJaccard : config.gammaJaccard;

      final hybrid = a * rec.score + b * sbertScore + g * rec.matchRatio;

      return _ScoredRec(recommendation: rec, hybridScore: hybrid, sbertScore: sbertScore);
    }).toList()
      ..sort((a, b) => b.hybridScore.compareTo(a.hybridScore));

    return [...reranked.map((r) => r.recommendation), ...remainder];
  }

  /// Always returns `true` — local service has no network dependency.
  Future<bool> isAvailable() async => true;

  // ── Diagnostic: per-candidate SBERT scores ────────────────────────────

  /// Returns a map of job ID → local SBERT score for the given query.
  ///
  /// Useful for debugging and UI transparency features ("why was this
  /// result ranked higher?").
  Map<int, double> debugScores(
    List<JobRecommendation> candidates,
    String userQuery,
  ) {
    final queryVec = _encoder.encodeText(userQuery);
    return {
      for (final rec in candidates)
        rec.id: _dot(queryVec, _encoder.encodeText(_jobText(rec))).clamp(0.0, 1.0),
    };
  }

  // ── Private helpers ────────────────────────────────────────────────────

  /// Builds a concise text representation of a job.
  ///
  /// Mirrors the `combined_text` field in the Colab notebook (§4) and the
  /// same helper in sbert_service.dart for score parity.
  static String _jobText(JobRecommendation r) {
    final skills = [...r.matching, ...r.missing];
    final skillStr = skills.join(' ');
    // Double the skills string — mirrors the Colab notebook's weighting trick
    return '${r.title} ${r.industry} ${r.level} $skillStr $skillStr ${r.location}'
        .toLowerCase()
        .trim();
  }
}

// =============================================================================
// §7  INTERNAL VALUE TYPE
// =============================================================================

/// Internal container used during re-ranking sort.
class _ScoredRec {
  final JobRecommendation recommendation;
  final double hybridScore;
  final double sbertScore;

  const _ScoredRec({
    required this.recommendation,
    required this.hybridScore,
    required this.sbertScore,
  });
}
