import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    super.uid = '',
    super.email = '',
    super.role = '',
    super.name = '',
    super.parentId,
    super.isPremium = false,
  });

  /// Parse từ Map JSON (ví dụ khi lấy từ RTDB)
  factory UserModel.fromJson(
      Map<String, dynamic> json, {
        String uidFallback = '',
      }) {
    return UserModel(
      uid: (json['uid'] as String?)?.trim().isNotEmpty == true
          ? (json['uid'] as String)
          : uidFallback,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      name: json['name'] as String? ?? '',
      parentId: json['parentId'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  /// Convert -> Map để set/update lên RTDB
  Map<String, dynamic> toJson({bool includeUid = true}) {
    final map = <String, dynamic>{
      'email': email,
      'role': role,
      'name': name,
      'parentId': parentId,
      'isPremium': isPremium,
    };
    if (includeUid) map['uid'] = uid;
    return map;
  }

  /// Convert từ Entity -> Model (khi muốn write)
  factory UserModel.fromEntity(User u) {
    return UserModel(
      uid: u.uid,
      email: u.email,
      role: u.role,
      name: u.name,
      parentId: u.parentId,
      isPremium: u.isPremium,
    );
  }

  /// Parse “chịu mọi loại dữ liệu” từ DataSnapshot (Map hoặc String JSON)
  static UserModel? fromSnapshot(DataSnapshot snap) {
    if (!snap.exists || snap.value == null) return null;

    final raw = snap.value;

    Map<String, dynamic>? json;

    try {
      if (raw is Map) {
        json = raw.map((k, v) => MapEntry(k.toString(), v));
      } else if (raw is String) {
        dynamic decoded;
        try {
          decoded = jsonDecode(raw);
        } catch (_) {
          decoded = null;
        }

        if (decoded is String) {
          try {
            decoded = jsonDecode(decoded);
          } catch (_) {
            decoded = null;
          }
        }

        if (decoded is Map) {
          json = decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      }
    } catch (_) {
      json = null;
    }

    if (json == null) return null;

    // RTDB thường không lưu uid trong data => lấy từ key
    final uidKey = snap.key ?? '';
    json['uid'] ??= uidKey;

    return UserModel.fromJson(json, uidFallback: uidKey);
  }
}
