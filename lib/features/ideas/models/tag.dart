import 'package:flutter/foundation.dart';

/// Represents a user-created tag for categorizing ideas.
@immutable
class Tag {
  final String id;
  final String userId;
  final String name;
  final String? color;
  final DateTime createdAt;

  const Tag({
    required this.id,
    required this.userId,
    required this.name,
    this.color,
    required this.createdAt,
  });

  /// Creates a [Tag] from a Supabase JSON row.
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      color: json['color'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Converts this [Tag] to a JSON map suitable for Supabase insert.
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'name': name.trim(),
      if (color != null) 'color': color,
    };
  }

  Tag copyWith({
    String? id,
    String? userId,
    String? name,
    String? color,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'Tag(id: $id, name: $name)';
}
