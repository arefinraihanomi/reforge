import 'package:flutter/foundation.dart';

@immutable
class ProjectLesson {
  final String id;
  final String? projectId;
  final String? postmortemId;
  final String userId;
  final String lesson;
  final String category; // 'architecture', 'scope', 'technical', 'process', 'other'
  final DateTime? createdAt;

  const ProjectLesson({
    required this.id,
    this.projectId,
    this.postmortemId,
    required this.userId,
    required this.lesson,
    this.category = 'architecture',
    this.createdAt,
  });

  ProjectLesson copyWith({
    String? id,
    String? projectId,
    String? postmortemId,
    String? userId,
    String? lesson,
    String? category,
    DateTime? createdAt,
  }) {
    return ProjectLesson(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      postmortemId: postmortemId ?? this.postmortemId,
      userId: userId ?? this.userId,
      lesson: lesson ?? this.lesson,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ProjectLesson.fromJson(Map<String, dynamic> json) {
    return ProjectLesson(
      id: json['id'] as String,
      projectId: json['project_id'] as String?,
      postmortemId: json['postmortem_id'] as String?,
      userId: json['user_id'] as String,
      lesson: json['lesson'] as String? ?? '',
      category: json['category'] as String? ?? 'architecture',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (projectId != null) 'project_id': projectId,
      if (postmortemId != null) 'postmortem_id': postmortemId,
      'user_id': userId,
      'lesson': lesson,
      'category': category,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
