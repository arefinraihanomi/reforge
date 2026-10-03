import 'package:flutter/foundation.dart';

@immutable
class ProjectDecision {
  final String id;
  final String projectId;
  final String userId;
  final String title;
  final String decision;
  final String? rationale;
  final String entryType; // 'decision', 'blocker', 'note'
  final String category;  // 'Architecture', 'Database', 'UI/UX', 'Scope', 'DevOps', 'Other'
  final DateTime? createdAt;

  const ProjectDecision({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.title,
    required this.decision,
    this.rationale,
    this.entryType = 'decision',
    this.category = 'Other',
    this.createdAt,
  });

  bool get isBlocker => entryType == 'blocker';
  bool get isDecision => entryType == 'decision';
  bool get isNote => entryType == 'note';

  ProjectDecision copyWith({
    String? id,
    String? projectId,
    String? userId,
    String? title,
    String? decision,
    String? rationale,
    String? entryType,
    String? category,
    DateTime? createdAt,
  }) {
    return ProjectDecision(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      decision: decision ?? this.decision,
      rationale: rationale ?? this.rationale,
      entryType: entryType ?? this.entryType,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ProjectDecision.fromJson(Map<String, dynamic> json) {
    return ProjectDecision(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      decision: json['decision'] as String? ?? '',
      rationale: json['rationale'] as String?,
      entryType: json['entry_type'] as String? ?? 'decision',
      category: json['category'] as String? ?? 'Other',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'user_id': userId,
      'title': title,
      'decision': decision,
      if (rationale != null) 'rationale': rationale,
      'entry_type': entryType,
      'category': category,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
