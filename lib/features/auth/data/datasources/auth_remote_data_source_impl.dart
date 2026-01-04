import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:quan_ly_cha_con/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:quan_ly_cha_con/features/user/data/models/user_model.dart';
import 'package:quan_ly_cha_con/features/user/domain/entities/user.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final auth.FirebaseAuth firebaseAuth;
  final FirebaseDatabase database;

  auth.FirebaseAuth? _secondaryAuth;

  AuthRemoteDataSourceImpl({
    auth.FirebaseAuth? firebaseAuth,
    FirebaseDatabase? database,
  })  : firebaseAuth = firebaseAuth ?? auth.FirebaseAuth.instance,
        database = database ?? FirebaseDatabase.instance;

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

  User? _parseUser(DataSnapshot snap) {
    return UserModel.fromSnapshot(snap);
  }

  @override
  Future<User> register(String email, String password, String role) async {
    final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
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

    final model = UserModel.fromEntity(user);
    await database.ref('users/$uid').set(model.toJson(includeUid: true));
    return user;
  }

  @override
  Future<User> login(String email, String password) async {
    final userCredential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user?.uid;
    if (uid == null) throw Exception('UID không hợp lệ');

    final snap = await database.ref('users/$uid').get();
    final user = _parseUser(snap);
    if (user == null) throw Exception('User chưa có dữ liệu trong database');
    return user;
  }

  @override
  Future<User?> loadUserById(String uid) async {
    final snap = await database.ref('users/$uid').get();
    return _parseUser(snap);
  }

  @override
  Future<User?> loadCurrentUser(String uid) async {
    final snap = await database.ref('users/$uid').get();
    return _parseUser(snap);
  }

  @override
  Future<User> createChildAccount({
    required String name,
    required String email,
    required String password,
    required String parentId,
  }) async {
    final secondaryAuth = await _getSecondaryAuth();

    final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
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

    final model = UserModel.fromEntity(child);
    await database.ref('users/$childId').set(model.toJson(includeUid: true));

    await secondaryAuth.signOut();
    return child;
  }

  @override
  Future<void> deleteChild(String childId) async {
    await database.ref('users/$childId').remove();
    await database.ref('locations/$childId').remove();
  }

  @override
  Future<List<User>> loadChildrenForParent(String parentId) async {
    final snapshot = await database
        .ref('users')
        .orderByChild('parentId')
        .equalTo(parentId)
        .get();

    if (!snapshot.exists) return [];

    final list = <User>[];
    for (final childSnap in snapshot.children) {
      final u = _parseUser(childSnap);
      if (u != null) list.add(u);
    }
    return list;
  }

  @override
  Future<void> upgradeToPremium(String parentUid) async {
    await database.ref('users/$parentUid').update({'isPremium': true});
  }

  @override
  Future<void> sendPasswordResetOtp(String email) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> confirmPasswordReset({
    required String otpCode,
    required String newPassword,
  }) async {
    await firebaseAuth.verifyPasswordResetCode(otpCode);
    await firebaseAuth.confirmPasswordReset(
      code: otpCode,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> logout() async => firebaseAuth.signOut();
}
