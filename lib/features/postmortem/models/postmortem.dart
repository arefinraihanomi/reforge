import 'package:flutter/foundation.dart';

@immutable
class ProjectPostmortem {
  final String id;
  final String projectId;
  final String userId;
  final String primaryReason; // 'scope_creep', 'technical_blocker', 'shifted_interest', 'time_constraint', 'other'
  final String whatWentWrong;
  final String? whatWentWell;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProjectPostmortem({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.primaryReason,
    required this.whatWentWrong,
    this.whatWentWell,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  String get reasonDisplayName {
    switch (primaryReason) {
      case 'scope_creep':
        return 'Scope Creep';
      case 'technical_blocker':
        return 'Technical Blocker';
      case 'shifted_interest':
        return 'Shifted Focus / Interest';
      case 'time_constraint':
        return 'Time Constraints';
      default:
        return 'Other';
    }
  }

  ProjectPostmortem copyWith({
    String? id,
    String? projectId,
    String? userId,
    String? primaryReason,
    String? whatWentWrong,
    String? whatWentWell,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectPostmortem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      primaryReason: primaryReason ?? this.primaryReason,
      whatWentWrong: whatWentWrong ?? this.whatWentWrong,
      whatWentWell: whatWentWell ?? this.whatWentWell,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProjectPostmortem.fromJson(Map<String, dynamic> json) {
    return ProjectPostmortem(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      userId: json['user_id'] as String,
      primaryReason: json['primary_reason'] as String? ?? 'other',
      whatWentWrong: json['what_went_wrong'] as String? ?? '',
      whatWentWell: json['what_went_well'] as String?,
      notes: json['notes'] as String?,
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
      'primary_reason': primaryReason,
      'what_went_wrong': whatWentWrong,
      if (whatWentWell != null) 'what_went_well': whatWentWell,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
