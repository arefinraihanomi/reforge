import 'package:flutter/foundation.dart';

@immutable
class ProjectVersion {
  final String id;
  final String userId;
  final String sourceProjectId;
  final String newProjectId;
  final String versionLabel;
  final String? changesSummary;
  final List<String> lessonsApplied;
  final DateTime? createdAt;

  const ProjectVersion({
    required this.id,
    required this.userId,
    required this.sourceProjectId,
    required this.newProjectId,
    this.versionLabel = 'v2',
    this.changesSummary,
    this.lessonsApplied = const [],
    this.createdAt,
  });

  ProjectVersion copyWith({
    String? id,
    String? userId,
    String? sourceProjectId,
    String? newProjectId,
    String? versionLabel,
    String? changesSummary,
    List<String>? lessonsApplied,
    DateTime? createdAt,
  }) {
    return ProjectVersion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sourceProjectId: sourceProjectId ?? this.sourceProjectId,
      newProjectId: newProjectId ?? this.newProjectId,
      versionLabel: versionLabel ?? this.versionLabel,
      changesSummary: changesSummary ?? this.changesSummary,
      lessonsApplied: lessonsApplied ?? this.lessonsApplied,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ProjectVersion.fromJson(Map<String, dynamic> json) {
    return ProjectVersion(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sourceProjectId: json['source_project_id'] as String,
      newProjectId: json['new_project_id'] as String,
      versionLabel: json['version_label'] as String? ?? 'v2',
      changesSummary: json['changes_summary'] as String?,
      lessonsApplied: json['lessons_applied'] != null
          ? (json['lessons_applied'] as List).map((e) => e.toString()).toList()
          : const [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'source_project_id': sourceProjectId,
      'new_project_id': newProjectId,
      'version_label': versionLabel,
      if (changesSummary != null) 'changes_summary': changesSummary,
      'lessons_applied': lessonsApplied,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
