import 'package:flutter/foundation.dart';
import 'project_task.dart';

@immutable
class Project {
  final String id;
  final int? projectNumber;
  final String userId;
  final String? ideaId;
  final String title;
  final String? summary;
  final String status; // 'active', 'in_progress', 'paused', 'abandoned', 'completed', 'reforged'
  final String? mvpScope;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final DateTime? completedAt;
  final DateTime? abandonedAt;
  final String? abandonReason;
  final String? abandonNote;
  final List<ProjectTask> tasks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Project({
    required this.id,
    this.projectNumber,
    required this.userId,
    this.ideaId,
    required this.title,
    this.summary,
    this.status = 'active',
    this.mvpScope,
    this.startedAt,
    this.pausedAt,
    this.completedAt,
    this.abandonedAt,
    this.abandonReason,
    this.abandonNote,
    this.tasks = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == 'active' || status == 'in_progress';
  bool get isAbandoned => status == 'abandoned';
  bool get isCompleted => status == 'completed';

  int get totalTasksCount => tasks.length;
  int get completedTasksCount => tasks.where((t) => t.isCompleted).length;
  
  double get taskProgress {
    if (tasks.isEmpty) return 0.0;
    return completedTasksCount / totalTasksCount;
  }

  Project copyWith({
    String? id,
    int? projectNumber,
    String? userId,
    String? ideaId,
    String? title,
    String? summary,
    String? status,
    String? mvpScope,
    DateTime? startedAt,
    DateTime? pausedAt,
    DateTime? completedAt,
    DateTime? abandonedAt,
    String? abandonReason,
    String? abandonNote,
    List<ProjectTask>? tasks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      projectNumber: projectNumber ?? this.projectNumber,
      userId: userId ?? this.userId,
      ideaId: ideaId ?? this.ideaId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      status: status ?? this.status,
      mvpScope: mvpScope ?? this.mvpScope,
      startedAt: startedAt ?? this.startedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      completedAt: completedAt ?? this.completedAt,
      abandonedAt: abandonedAt ?? this.abandonedAt,
      abandonReason: abandonReason ?? this.abandonReason,
      abandonNote: abandonNote ?? this.abandonNote,
      tasks: tasks ?? this.tasks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Project.fromJson(Map<String, dynamic> json, {List<ProjectTask>? tasks}) {
    return Project(
      id: json['id'] as String,
      projectNumber: (json['project_number'] as num?)?.toInt(),
      userId: json['user_id'] as String,
      ideaId: json['idea_id'] as String?,
      title: json['title'] as String? ?? 'Untitled Project',
      summary: json['summary'] as String?,
      status: json['status'] as String? ?? 'active',
      mvpScope: json['mvp_scope'] as String?,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      pausedAt: json['paused_at'] != null
          ? DateTime.tryParse(json['paused_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      abandonedAt: json['abandoned_at'] != null
          ? DateTime.tryParse(json['abandoned_at'] as String)
          : null,
      abandonReason: json['abandon_reason'] as String?,
      abandonNote: json['abandon_note'] as String?,
      tasks: tasks ??
          (json['project_tasks'] != null
              ? (json['project_tasks'] as List)
                  .map((t) => ProjectTask.fromJson(t as Map<String, dynamic>))
                  .toList()
              : const []),
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
      if (projectNumber != null) 'project_number': projectNumber,
      'user_id': userId,
      if (ideaId != null) 'idea_id': ideaId,
      'title': title,
      if (summary != null) 'summary': summary,
      'status': status,
      if (mvpScope != null) 'mvp_scope': mvpScope,
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (pausedAt != null) 'paused_at': pausedAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (abandonedAt != null) 'abandoned_at': abandonedAt!.toIso8601String(),
      if (abandonReason != null) 'abandon_reason': abandonReason,
      if (abandonNote != null) 'abandon_note': abandonNote,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
