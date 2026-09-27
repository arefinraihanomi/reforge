import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

/// Result object for AI Idea Review advisory function.
class AiIdeaReviewResult {
  final String summary;
  final List<String> risks;
  final String recommendedMvpCut;

  const AiIdeaReviewResult({
    required this.summary,
    required this.risks,
    required this.recommendedMvpCut,
  });

  factory AiIdeaReviewResult.fromJson(Map<String, dynamic> json) {
    return AiIdeaReviewResult(
      summary: json['summary'] as String? ?? 'Idea complexity analyzed.',
      risks: (json['risks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      recommendedMvpCut: json['recommendedMvpCut'] as String? ??
          'Focus strictly on core feature.',
    );
  }
}

/// Result object for AI Post-Mortem advisory function.
class AiPostmortemResult {
  final String whatWentWrong;
  final String whatWentWell;
  final List<Map<String, String>> suggestedLessons;

  const AiPostmortemResult({
    required this.whatWentWrong,
    required this.whatWentWell,
    required this.suggestedLessons,
  });

  factory AiPostmortemResult.fromJson(Map<String, dynamic> json) {
    final rawLessons = json['suggestedLessons'] as List<dynamic>? ?? [];
    final lessons = rawLessons.map((item) {
      if (item is Map<String, dynamic>) {
        return {
          'lesson': item['lesson'] as String? ?? '',
          'category': item['category'] as String? ?? 'architecture',
        };
      }
      return {
        'lesson': item.toString(),
        'category': 'architecture',
      };
    }).toList();

    return AiPostmortemResult(
      whatWentWrong: json['whatWentWrong'] as String? ?? '',
      whatWentWell: json['whatWentWell'] as String? ?? '',
      suggestedLessons: lessons,
    );
  }
}

/// Result object for AI Reforge V2 advisory function.
class AiReforgeResult {
  final String suggestedV2Title;
  final String tighterMvpScope;
  final List<String> simplifications;
  final List<String> recommendedTasks;

  const AiReforgeResult({
    required this.suggestedV2Title,
    required this.tighterMvpScope,
    required this.simplifications,
    required this.recommendedTasks,
  });

  factory AiReforgeResult.fromJson(Map<String, dynamic> json) {
    return AiReforgeResult(
      suggestedV2Title: json['suggestedV2Title'] as String? ?? '',
      tighterMvpScope: json['tighterMvpScope'] as String? ?? '',
      simplifications: (json['simplifications'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      recommendedTasks: (json['recommendedTasks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

/// Service handling non-blocking AI advisory calls to Supabase Edge Functions.
class AiGatewayService {
  final SupabaseClient _client;

  AiGatewayService(this._client);

  /// Invoke `ai_idea_review` function with 15s timeout and non-blocking error recovery.
  Future<AiIdeaReviewResult?> reviewIdea({
    required String title,
    String? description,
    List<String>? tags,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'ai_idea_review',
        body: {
          'title': title,
          'description': description,
          'tags': tags,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.data is Map<String, dynamic>) {
        return AiIdeaReviewResult.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      // Non-blocking failure: return null and allow manual entry in client
      return null;
    }
  }

  /// Invoke `ai_postmortem` function with 15s timeout and non-blocking error recovery.
  Future<AiPostmortemResult?> generatePostmortemDraft({
    required String title,
    String? mvpScope,
    String? abandonReason,
    String? abandonNote,
    List<Map<String, String>>? decisions,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'ai_postmortem',
        body: {
          'title': title,
          'mvpScope': mvpScope,
          'abandonReason': abandonReason,
          'abandonNote': abandonNote,
          'decisions': decisions,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.data is Map<String, dynamic>) {
        return AiPostmortemResult.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Invoke `ai_reforge` function with 15s timeout and non-blocking error recovery.
  Future<AiReforgeResult?> suggestReforgeStrategy({
    required String ancestorTitle,
    String? abandonReason,
    List<String>? selectedLessons,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'ai_reforge',
        body: {
          'ancestorTitle': ancestorTitle,
          'abandonReason': abandonReason,
          'selectedLessons': selectedLessons,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.data is Map<String, dynamic>) {
        return AiReforgeResult.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// Riverpod provider for [AiGatewayService].
final aiGatewayServiceProvider = Provider<AiGatewayService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AiGatewayService(client);
});
