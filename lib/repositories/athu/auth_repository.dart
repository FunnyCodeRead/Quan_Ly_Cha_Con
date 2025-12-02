import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:quan_ly_cha_con/models/user.dart';

abstract class AuthRepository {
  Future<User> register(String email, String password, String role);
  Future<User> login(String email, String password);
  Future<User?> loadUserById(String uid);
  Future<User> createChildAccount({
    required String name,
    required String email,
    required String password,
    required String parentId,
  });

  Future<void> deleteChild(String childId);

  Future<List<User>> loadChildrenForParent(String parentId);
  Future<User?> loadCurrentUser(String uid);
  Future<void> logout();

  /// ✅ nâng cấp premium cho CHA
  Future<void> upgradeToPremium(String parentUid);

  /// Quên mật khẩu: gửi email chứa mã OTP đặt lại mật khẩu
  Future<void> sendPasswordResetOtp(String email);

  /// Xác nhận mã OTP và đặt lại mật khẩu mới
  Future<void> confirmPasswordReset({
    required String otpCode,
    required String newPassword,
  });
}


class AuthRepositoryImpl implements AuthRepository {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  auth.FirebaseAuth? _secondaryAuth;

  Future<auth.FirebaseAuth> _getSecondaryAuth() async {
    if (_secondaryAuth != null) return _secondaryAuth!;

    final defaultApp = Firebase.app();
    FirebaseApp secondaryApp;

    try {
      secondaryApp = Firebase.app('secondary');
    } catch (_) {
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary',
        options: defaultApp.options,
      );
    }

    _secondaryAuth = auth.FirebaseAuth.instanceFor(app: secondaryApp);
    return _secondaryAuth!;
  }

  // ---------- PARSE USER SAFE ----------
  User? _parseUser(DataSnapshot snap) {
    if (!snap.exists || snap.value == null) return null;

    final raw = snap.value;

    Map<String, dynamic>? json;

    if (raw is Map) {
      json = Map<String, dynamic>.from(raw as Map);
    } else if (raw is String) {
      // phòng trường hợp data bị lưu stringify
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        json = Map<String, dynamic>.from(decoded as Map);
      }
    }

    if (json == null) {
      throw Exception('Dữ liệu user không hợp lệ: ${raw.runtimeType}');
    }

    // DB realtime thường không có field uid => lấy từ key
    json['uid'] ??= snap.key ?? '';

    return User.fromJson(json);
  }

  // ---------- AUTH ----------
  @override
  Future<User> register(String email, String password, String role) async {
    try {
      final userCredential =
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;
      if (uid == null) throw Exception('UID không hợp lệ');

      final user = User(
        uid: uid,
        email: email,
        role: role,
        name: '',
        isPremium: false,
      );

      await _database.ref('users/$uid').set(user.toJson());
      return user;
    } catch (e) {
      throw Exception('Đăng ký thất bại: $e');
    }
  }

  @override
  Future<User> login(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;
      if (uid == null) throw Exception('UID không hợp lệ');

      final snap = await _database.ref('users/$uid').get();
      final user = _parseUser(snap);

      if (user == null) {
        throw Exception("User chưa có dữ liệu trong database");
      }
      return user;
    } catch (e) {
      throw Exception('Đăng nhập thất bại: $e');
    }
  }

  @override
  Future<User?> loadUserById(String uid) async {
    try {
      final snap = await _database.ref('users/$uid').get();
      return _parseUser(snap);
    } catch (e) {
      throw Exception('Lỗi load user theo id: $e');
    }
  }

  @override
  Future<User?> loadCurrentUser(String uid) async {
    try {
      final snap = await _database.ref('users/$uid').get();
      return _parseUser(snap);
    } catch (e) {
      throw Exception('Lỗi tải user: $e');
    }
  }

  // ---------- CHILDREN ----------
  @override
  Future<User> createChildAccount({
    required String name,
    required String email,
    required String password,
    required String parentId,
  }) async {
    try {
      final secondaryAuth = await _getSecondaryAuth();

      final userCredential =
      await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final childId = userCredential.user?.uid;
      if (childId == null) throw Exception('Không tạo được tài khoản con');

      final child = User(
        uid: childId,
        email: email,
        role: 'con',
        name: name,
        parentId: parentId,
        isPremium: false,
      );

      await _database.ref('users/$childId').set(child.toJson());

      await secondaryAuth.signOut();
      return child;
    } catch (e) {
      throw Exception('Tạo tài khoản con thất bại: $e');
    }
  }

  @override
  Future<void> deleteChild(String childId) async {
    try {
      await _database.ref('users/$childId').remove();
      await _database.ref('locations/$childId').remove();
    } catch (e) {
      throw Exception('Xóa tài khoản con thất bại: $e');
    }
  }

  @override
  Future<List<User>> loadChildrenForParent(String parentId) async {
    try {
      final snapshot = await _database
          .ref('users')
          .orderByChild('parentId')
          .equalTo(parentId)
          .get();

      if (!snapshot.exists) return [];

      final list = <User>[];
      for (final childSnap in snapshot.children) {
        final child = _parseUser(childSnap);
        if (child != null) list.add(child);
      }
      return list;
    } catch (e) {
      throw Exception('Lỗi tải con: $e');
    }
  }

  // ---------- PREMIUM / RESET / LOGOUT ----------
  @override
  Future<void> upgradeToPremium(String parentUid) async {
    try {
      await _database.ref('users/$parentUid').update({'isPremium': true});
    } catch (e) {
      throw Exception("Nâng cấp premium thất bại: $e");
    }
  }

  @override
  Future<void> sendPasswordResetOtp(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Gửi mã OTP thất bại: $e');
    }
  }

  @override
  Future<void> confirmPasswordReset({
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      await _firebaseAuth.verifyPasswordResetCode(otpCode);
      await _firebaseAuth.confirmPasswordReset(
        code: otpCode,
        newPassword: newPassword,
      );
    } catch (e) {
      throw Exception('Đặt lại mật khẩu thất bại: $e');
    }
  }

  @override
  Future<void> logout() async => _firebaseAuth.signOut();
}

