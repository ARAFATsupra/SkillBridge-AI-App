// lib/services/gemini_chat_service.dart  —  SkillBridge AI

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

/// One turn in the multi-turn chat history sent to Gemini.
class GeminiTurn {
  final String role; // "user" or "model"
  final String text;
  const GeminiTurn({required this.role, required this.text});
}

/// Thrown when the Gemini API returns a non-200 response or an unexpected payload.
class GeminiApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isRateLimited;
  final bool isSafetyBlocked;

  GeminiApiException(
    this.message, {
    this.statusCode,
    this.isRateLimited = false,
    this.isSafetyBlocked = false,
  });

  @override
  String toString() => statusCode == null
      ? 'GeminiApiException: $message'
      : 'GeminiApiException($statusCode): $message';
}

/// Cancellation token to abort an in-flight request.
class CancelToken {
  bool _isCancelled = false;
  final Completer<void> _completer = Completer<void>();

  void cancel() {
    if (!_isCancelled) {
      _isCancelled = true;
      if (!_completer.isCompleted) {
        _completer.completeError(CancellationException());
      }
    }
  }

  bool get isCancelled => _isCancelled;
  Future<void> get whenCancelled => _completer.future;
}

class CancellationException implements Exception {
  @override
  String toString() => 'Request was cancelled.';
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class GeminiChatService {
  final String apiKey;
  final String model;
  final http.Client _client;
  final bool enableLogging;

  /// ~175 k tokens — safely below the 1 M context limit of Gemini 2.5 Flash.
  static const int _maxTotalChars = 700000;
  static const Duration _timeout = Duration(seconds: 45);
  static const int _maxRetries = 3;

  GeminiChatService({
    required this.apiKey,
    this.model = 'gemini-2.5-flash',
    http.Client? client,
    this.enableLogging = false,
  }) : _client = client ?? http.Client();

  void dispose() => _client.close();

  Uri _endpoint() => Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC: Chat reply  (unchanged signature)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sends [history] to Gemini and returns the assistant reply text.
  Future<String> generateReply({
    required List<GeminiTurn> history,
    required String systemInstruction,
    double temperature = 0.4,
    int maxOutputTokens = 800,
    CancelToken? cancelToken,
  }) async {
    _log(' generateReply — ${history.length} turns');
    _assertApiKey();

    final payload = _buildPayload(
      history: history,
      systemInstruction: systemInstruction,
      temperature: temperature,
      maxOutputTokens: maxOutputTokens,
    );

    return _executeWithRetry(payload, cancelToken: cancelToken);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC: Dedicated CV analysis  (NEW)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Optimised single-turn call for deep CV analysis.
  ///
  /// Uses a lower temperature (0.28) for more consistent analysis output
  /// and a generous token budget (up to 1800) to cover full structured reports.
  ///
  /// [analysisPrompt] — the complete, already-built analysis prompt.
  /// [systemInstruction] — the system context (user profile, rules, etc.).
  Future<String> generateCvAnalysis({
    required String analysisPrompt,
    required String systemInstruction,
    int maxOutputTokens = 1800,
    CancelToken? cancelToken,
  }) async {
    _log(' generateCvAnalysis');
    _assertApiKey();

    final payload = _buildPayload(
      history: [GeminiTurn(role: 'user', text: analysisPrompt)],
      systemInstruction: systemInstruction,
      temperature: 0.28,
      maxOutputTokens: maxOutputTokens,
    );

    return _executeWithRetry(payload, cancelToken: cancelToken);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE: Retry loop
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String> _executeWithRetry(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    // Set up a completer that resolves when the cancel token fires.
    final cancelCompleter = Completer<void>();
    cancelToken?.whenCancelled.then((_) {
      if (!cancelCompleter.isCompleted) cancelCompleter.complete();
    });

    int attempt = 0;
    while (attempt < _maxRetries) {
      if (cancelToken?.isCancelled == true) throw CancellationException();
      attempt++;

      try {
        _log('📡 Attempt $attempt/$_maxRetries');

        final request = _client.post(
          _endpoint(),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode(payload),
        );

        final response = await _runWithTimeout(request, cancelCompleter);

        if (response.statusCode == 200) {
          return _parseSuccessResponse(response.body);
        }

        final errorMsg = _parseErrorBody(response.body, response.statusCode);
        final isRateLimit = response.statusCode == 429;
        final isServerErr = response.statusCode >= 500;

        if ((isRateLimit || isServerErr) && attempt < _maxRetries) {
          final delay = _backoff(attempt);
          _log(
              ' ${isRateLimit ? "Rate limited" : "Server error ${response.statusCode}"} — retry in ${delay.inMilliseconds} ms');
          await Future.delayed(delay);
          continue;
        }

        throw GeminiApiException(
          errorMsg,
          statusCode: response.statusCode,
          isRateLimited: isRateLimit,
        );
      } on CancellationException {
        rethrow;
      } on TimeoutException {
        if (attempt < _maxRetries) {
          await Future.delayed(_backoff(attempt));
          continue;
        }
        throw GeminiApiException(
            'Request timed out after ${_timeout.inSeconds} s. '
            'Check your internet connection and try again.');
      } catch (e) {
        if (e is GeminiApiException) rethrow;
        if (attempt >= _maxRetries) rethrow;
        _log('  Unexpected error: $e — retrying…');
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }

    throw GeminiApiException(
        'Failed after $_maxRetries attempts. Please try again shortly.');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE: Payload builder
  // ═══════════════════════════════════════════════════════════════════════════

  Map<String, dynamic> _buildPayload({
    required List<GeminiTurn> history,
    required String systemInstruction,
    required double temperature,
    required int maxOutputTokens,
  }) {
    final windowed = _applySlidingWindow(history);
    final contents = windowed
        .where((t) => t.text.trim().isNotEmpty)
        .map((t) => {
              'role': t.role,
              'parts': [
                {'text': t.text}
              ],
            })
        .toList();

    // Safety settings — block medium-and-above for all harm categories.
    final safetySettings = [
      {
        'category': 'HARM_CATEGORY_HARASSMENT',
        'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
      },
      {
        'category': 'HARM_CATEGORY_HATE_SPEECH',
        'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
      },
      {
        'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
        'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
      },
      {
        'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
        'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
      },
    ];

    return {
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction}
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxOutputTokens,
        'topP': 0.95,
        'topK': 40,
      },
      'safetySettings': safetySettings,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE: Sliding window token management
  // ═══════════════════════════════════════════════════════════════════════════

  /// Truncates history when total character count exceeds [_maxTotalChars].
  ///
  /// Strategy:
  ///  1. Always keep the first turn (user's initial goal/context message).
  ///  2. Always keep the most-recent [N] turns that fit within the budget.
  ///  3. Drop middle turns if necessary.
  List<GeminiTurn> _applySlidingWindow(List<GeminiTurn> history) {
    if (history.isEmpty) return [];

    int total = history.fold(0, (sum, t) => sum + t.text.length);
    if (total <= _maxTotalChars) return history;

    _log('⚠️ History too long ($total chars) — truncating');

    // Build from newest → oldest, then reverse.
    final kept = <GeminiTurn>[];
    int running = 0;

    // Always keep the very first turn if it exists and fits.
    final first = history.first;
    if (first.text.length <= _maxTotalChars ~/ 4) {
      kept.add(first);
      running += first.text.length;
    }

    for (int i = history.length - 1; i >= 1; i--) {
      final t = history[i];
      if (running + t.text.length <= _maxTotalChars) {
        kept.add(t);
        running += t.text.length;
      } else {
        _log(
            '  Dropped turn (${t.role}): ${t.text.substring(0, t.text.length.clamp(0, 50))}…');
      }
    }

    // first was inserted at index 0 of kept; remaining are newest-first → reverse.
    // Re-sort: first item stays first; the rest need reversing.
    final tail = kept.sublist(1).reversed.toList();
    return [kept.first, ...tail];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE: HTTP helpers
  // ═══════════════════════════════════════════════════════════════════════════

  Future<http.Response> _runWithTimeout(
    Future<http.Response> request,
    Completer<void> cancelCompleter,
  ) =>
      Future.any([
        request.timeout(_timeout),
        cancelCompleter.future.then((_) => throw CancellationException()),
      ]);

  String _parseSuccessResponse(String body) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final candidates = decoded['candidates'];

    if (candidates is! List || candidates.isEmpty) {
      final feedback = decoded['promptFeedback'];
      if (feedback?['blockReason'] != null) {
        throw GeminiApiException(
          'Response blocked by safety filter. Reason: ${feedback!['blockReason']}. '
          'Try rephrasing your message.',
          isSafetyBlocked: true,
        );
      }
      throw GeminiApiException(
          'No candidates returned. promptFeedback=$feedback');
    }

    final cand = candidates.first as Map<String, dynamic>;
    if (cand['finishReason'] == 'SAFETY') {
      throw GeminiApiException(
        'Gemini refused this request due to safety policies. '
        'Please rephrase your message.',
        isSafetyBlocked: true,
      );
    }

    final parts = (cand['content'] as Map<String, dynamic>?)?['parts'] as List?;
    if (parts == null || parts.isEmpty) return '';

    final buffer = StringBuffer();
    for (final p in parts) {
      if (p is Map<String, dynamic> && p['text'] is String) {
        buffer.write(p['text'] as String);
      }
    }
    final reply = buffer.toString().trim();
    _log(' Reply: ${reply.length} chars');
    return reply;
  }

  String _parseErrorBody(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        final err = decoded['error'] as Map<String, dynamic>;
        String msg = (err['message'] as String?) ?? body;

        // Actionable hints for common failures
        if (msg.contains('API key not valid') ||
            msg.contains('API_KEY_INVALID')) {
          msg += '\n\nFix: Run with --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE '
              'or check your key at https://aistudio.google.com/app/apikey';
        } else if (msg.contains('quota') ||
            msg.contains('rate limit') ||
            statusCode == 429) {
          msg += '\n\nFix: You have hit the free-tier rate limit. '
              'Wait ~60 seconds or upgrade your Google AI plan.';
        } else if (statusCode == 403) {
          msg +=
              '\n\nFix: The API key does not have permission to use model "$model". '
              'Check your Google AI project settings.';
        } else if (statusCode >= 500) {
          msg +=
              '\n\nGemini service is temporarily unavailable. Try again shortly.';
        }
        return msg;
      }
      return body;
    } catch (_) {
      return 'HTTP $statusCode — $body';
    }
  }

  /// Exponential back-off: 1 s → 2 s → 4 s.
  Duration _backoff(int attempt) =>
      Duration(milliseconds: 1000 * (1 << (attempt - 1)));

  void _log(String msg) {
    if (enableLogging) debugPrint('[GeminiService] $msg');
  }

  void _assertApiKey() {
    if (apiKey.isEmpty) {
      throw StateError(
        'Missing Gemini API key.\n'
        'Run: flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE',
      );
    }
  }
}
