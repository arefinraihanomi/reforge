import 'package:flutter/foundation.dart';

import 'tag.dart';

/// Lifecycle statuses an idea can hold.
enum IdeaStatus {
  draft('draft', 'Draft'),
  active('active', 'New'),
  exploring('exploring', 'Exploring'),
  building('building', 'Building'),
  converted('converted', 'Converted'),
  archived('archived', 'Archived');

  const IdeaStatus(this.value, this.label);

  /// Database column value.
  final String value;

  /// Human-readable label for UI display.
  final String label;

  static IdeaStatus fromValue(String value) {
    return IdeaStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => IdeaStatus.active,
    );
  }
}

/// Reforge Evolution stages (shown in stepper UI).
enum IdeaStage {
  captured('captured', 'Captured'),
  explored('explored', 'Explored'),
  forge('forge', 'Forge'),
  building('building', 'Building'),
  rebuild('rebuild', 'Rebuild');

  const IdeaStage(this.value, this.label);
  final String value;
  final String label;

  /// 1-based stage number for display (e.g. "Stage 2 of 5").
  int get number => index + 1;

  static IdeaStage fromValue(String value) {
    return IdeaStage.values.firstWhere(
      (s) => s.value == value,
      orElse: () => IdeaStage.captured,
    );
  }
}

/// A single workshop note or scratch entry stored as JSON inside `workshop_notes`.
@immutable
class WorkshopNote {
  final String text;
  final DateTime createdAt;

  const WorkshopNote({required this.text, required this.createdAt});

  factory WorkshopNote.fromJson(Map<String, dynamic> json) {
    return WorkshopNote(
      text: json['text'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}

/// Core domain model representing a captured idea in the Idea Vault.
@immutable
class Idea {
  final String id;
  final int ideaNumber;
  final String userId;
  final String title;
  final String? description;
  final String? problem;
  final String? targetUsers;
  final String? potentialDirection;
  final String? hypothesis;
  final List<WorkshopNote> workshopNotes;
  final IdeaStatus status;
  final IdeaStage stage;
  final int revisionsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Tag> tags;

  const Idea({
    required this.id,
    this.ideaNumber = 0,
    required this.userId,
    required this.title,
    this.description,
    this.problem,
    this.targetUsers,
    this.potentialDirection,
    this.hypothesis,
    this.workshopNotes = const [],
    this.status = IdeaStatus.active,
    this.stage = IdeaStage.captured,
    this.revisionsCount = 1,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });

  /// Creates an [Idea] from a Supabase JSON row.
  ///
  /// Expects the query to join `tags` via `idea_tags` as:
  /// `.select('*, idea_tags(tag_id, tags(*))')`.
  factory Idea.fromJson(Map<String, dynamic> json) {
    // Parse tags from the joined relation
    final List<Tag> parsedTags = [];
    final ideaTagsRaw = json['idea_tags'];
    if (ideaTagsRaw is List) {
      for (final entry in ideaTagsRaw) {
        if (entry is Map<String, dynamic>) {
          final tagData = entry['tags'];
          if (tagData is Map<String, dynamic>) {
            parsedTags.add(Tag.fromJson(tagData));
          }
        }
      }
    }

    // Parse workshop notes from JSONB
    final List<WorkshopNote> notes = [];
    final notesRaw = json['workshop_notes'];
    if (notesRaw is List) {
      for (final entry in notesRaw) {
        if (entry is Map<String, dynamic>) {
          notes.add(WorkshopNote.fromJson(entry));
        }
      }
    }

    return Idea(
      id: json['id'] as String,
      ideaNumber: (json['idea_number'] as num?)?.toInt() ?? 0,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      problem: json['problem'] as String?,
      targetUsers: json['target_users'] as String?,
      potentialDirection: json['potential_direction'] as String?,
      hypothesis: json['hypothesis'] as String?,
      workshopNotes: notes,
      status: IdeaStatus.fromValue(json['status'] as String? ?? 'active'),
      stage: IdeaStage.fromValue(json['stage'] as String? ?? 'captured'),
      revisionsCount: (json['revisions_count'] as num?)?.toInt() ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      tags: parsedTags,
    );
  }

  /// Converts this [Idea] to a JSON map suitable for Supabase insert/update.
  ///
  /// Does NOT include `id`, `idea_number`, `created_at`, or relational fields
  /// like `tags` / `idea_tags` — those are managed via separate operations.
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'title': title.trim(),
      if (description != null) 'description': description,
      if (problem != null) 'problem': problem,
      if (targetUsers != null) 'target_users': targetUsers,
      if (potentialDirection != null) 'potential_direction': potentialDirection,
      if (hypothesis != null) 'hypothesis': hypothesis,
      'workshop_notes':
          workshopNotes.map((n) => n.toJson()).toList(),
      'status': status.value,
      'stage': stage.value,
      'revisions_count': revisionsCount,
    };
  }

  /// Converts mutable fields to a JSON map suitable for Supabase update.
  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title.trim(),
      'description': description,
      'problem': problem,
      'target_users': targetUsers,
      'potential_direction': potentialDirection,
      'hypothesis': hypothesis,
      'workshop_notes':
          workshopNotes.map((n) => n.toJson()).toList(),
      'status': status.value,
      'stage': stage.value,
      'revisions_count': revisionsCount,
    };
  }

  Idea copyWith({
    String? id,
    int? ideaNumber,
    String? userId,
    String? title,
    String? description,
    String? problem,
    String? targetUsers,
    String? potentialDirection,
    String? hypothesis,
    List<WorkshopNote>? workshopNotes,
    IdeaStatus? status,
    IdeaStage? stage,
    int? revisionsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Tag>? tags,
  }) {
    return Idea(
      id: id ?? this.id,
      ideaNumber: ideaNumber ?? this.ideaNumber,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      problem: problem ?? this.problem,
      targetUsers: targetUsers ?? this.targetUsers,
      potentialDirection: potentialDirection ?? this.potentialDirection,
      hypothesis: hypothesis ?? this.hypothesis,
      workshopNotes: workshopNotes ?? this.workshopNotes,
      status: status ?? this.status,
      stage: stage ?? this.stage,
      revisionsCount: revisionsCount ?? this.revisionsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Idea &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ideaNumber == other.ideaNumber &&
          title == other.title &&
          status == other.status &&
          stage == other.stage &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, ideaNumber, title, status, stage, updatedAt);

  @override
  String toString() => 'Idea(#$ideaNumber "$title" [$status] [$stage])';
}
