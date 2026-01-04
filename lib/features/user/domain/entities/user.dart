import 'package:flutter/foundation.dart';

@immutable
class User {
  final String uid;
  final String email;
  final String role; // 'cha' | 'con'
  final String name;
  final String? parentId;
  final bool isPremium;

  const User({
    this.uid = '',
    this.email = '',
    this.role = '',
    this.name = '',
    this.parentId,
    this.isPremium = false,
  });

  User copyWith({
    String? uid,
    String? email,
    String? role,
    String? name,
    String? parentId,
    bool? isPremium,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  @override
  String toString() =>
      'User(uid: $uid, email: $email, role: $role, name: $name, parentId: $parentId, isPremium: $isPremium)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is User &&
              runtimeType == other.runtimeType &&
              uid == other.uid &&
              email == other.email &&
              role == other.role &&
              name == other.name &&
              parentId == other.parentId &&
              isPremium == other.isPremium;

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      role.hashCode ^
      name.hashCode ^
      parentId.hashCode ^
      isPremium.hashCode;
}
