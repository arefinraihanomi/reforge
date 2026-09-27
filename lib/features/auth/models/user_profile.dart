import 'package:flutter/foundation.dart';

/// Represents a public profile linked to an authenticated user.
@immutable
class UserProfile {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.updatedAt,
  });

  /// Creates a [UserProfile] instance from a database JSON map.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Converts this [UserProfile] into a database JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Returns a copy of this [UserProfile] with the given fields replaced.
  UserProfile copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          avatarUrl == other.avatarUrl &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(id, displayName, avatarUrl, createdAt, updatedAt);

  @override
  String toString() =>
      'UserProfile(id: $id, displayName: $displayName, avatarUrl: $avatarUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
}
