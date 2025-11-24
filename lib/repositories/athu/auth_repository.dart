import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:quan_ly_cha_con/models/User.dart';

abstract class AuthRepository {
  Future<User> register(String email, String password, String role);
  Future<User> login(String email, String password);
  Future<User> createChildAccount({
    required String name,
    required String email,
    required String password,
    required String parentId,
  });
  Future<List<User>> loadChildrenForParent(String parentId);
  Future<User?> loadCurrentUser(String uid);
  Future<void> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  @override
  Future<User> register(String email, String password, String role) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
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

      final snapshot = await _database.ref('users/$uid').get();
      final json = Map<String, dynamic>.from(snapshot.value as Map);
      return User.fromJson(json);
    } catch (e) {
      throw Exception('Đăng nhập thất bại: $e');
    }
  }

  @override
  Future<User> createChildAccount({
    required String name,
    required String email,
    required String password,
    required String parentId,
  }) async {
    try {
      // Tạo tài khoản con mà không logout tài khoản cha
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
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
      );

      await _database.ref('users/$childId').set(child.toJson());

      // Logout con, giữ cha đăng nhập
      await _firebaseAuth.signOut();

      // Re-login với tài khoản cha
      // (nên gọi từ ViewModel để refresh)
      return child;
    } catch (e) {
      throw Exception('Tạo tài khoản con thất bại: $e');
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
      for (final child in snapshot.children) {
        final json = Map<String, dynamic>.from(child.value as Map);
        list.add(User.fromJson(json));
      }
      return list;
    } catch (e) {
      throw Exception('Lỗi tải con: $e');
    }
  }

  @override
  Future<User?> loadCurrentUser(String uid) async {
    try {
      final snapshot = await _database.ref('users/$uid').get();
      if (!snapshot.exists) return null;

      final json = Map<String, dynamic>.from(snapshot.value as Map);
      return User.fromJson(json);
    } catch (e) {
      throw Exception('Lỗi tải user: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
}