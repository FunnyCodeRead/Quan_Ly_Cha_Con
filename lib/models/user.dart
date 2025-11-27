class User {
  final String uid;
  final String email;
  final String role;
  final String name;
  final String? parentId;

  User({
    this.uid = '',
    this.email = '',
    this.role = '',
    this.name = '',
    this.parentId,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'name': name,
      'parentId': parentId,
    };
  }

  // Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      name: json['name'] as String? ?? '',
      parentId: json['parentId'] as String?,
    );
  }

  // Copy with method
  User copyWith({
    String? uid,
    String? email,
    String? role,
    String? name,
    String? parentId,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
    );
  }

  @override
  String toString() => 'User(uid: $uid, email: $email, role: $role, name: $name, parentId: $parentId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is User &&
              runtimeType == other.runtimeType &&
              uid == other.uid &&
              email == other.email &&
              role == other.role &&
              name == other.name &&
              parentId == other.parentId;

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      role.hashCode ^
      name.hashCode ^
      parentId.hashCode;
}