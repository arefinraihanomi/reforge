import 'package:flutter/foundation.dart';

@immutable
class ProjectTask {
  final String id;
  final String projectId;
  final String userId;
  final String title;
  final String status; // 'pending', 'completed'
  final String priority; // 'low', 'medium', 'high'
  final int position;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProjectTask({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.title,
    this.status = 'pending',
    this.priority = 'medium',
    this.position = 0,
    this.createdAt,
    this.updatedAt,
  });

  bool get isCompleted => status == 'completed';

  ProjectTask copyWith({
    String? id,
    String? projectId,
    String? userId,
    String? title,
    String? status,
    String? priority,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectTask(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProjectTask.fromJson(Map<String, dynamic> json) {
    return ProjectTask(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      priority: json['priority'] as String? ?? 'medium',
      position: (json['position'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'user_id': userId,
      'title': title,
      'status': status,
      'priority': priority,
      'position': position,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectTask &&
        other.id == id &&
        other.projectId == projectId &&
        other.userId == userId &&
        other.title == title &&
        other.status == status &&
        other.priority == priority &&
        other.position == position;
  }

  @override
  int get hashCode => Object.hash(
        id,
        projectId,
        userId,
        title,
        status,
        priority,
        position,
      );
}
