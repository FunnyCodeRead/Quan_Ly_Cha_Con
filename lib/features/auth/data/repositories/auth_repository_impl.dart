import 'package:quan_ly_cha_con/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:quan_ly_cha_con/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:quan_ly_cha_con/features/auth/domain/repositories/auth_repository.dart';
import 'package:quan_ly_cha_con/features/user/domain/entities/user.dart';


class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;

  AuthRepositoryImpl({
    required this.remote,
    required this.local,
  });

  @override
  Future<User> register(String email, String password, String role) async {
    final user = await remote.register(email, password, role);
    return user;
  }

  @override
  Future<User> login(String email, String password) async {
    final user = await remote.login(email, password);
    return user;
  }

  @override
  Future<User?> loadUserById(String uid) => remote.loadUserById(uid);

  @override
  Future<User?> loadCurrentUser(String uid) => remote.loadCurrentUser(uid);

  @override
  Future<User> createChildAccount({
    required String name,
    required String email,
    required String password,
    required String parentId,
  }) {
    return remote.createChildAccount(
      name: name,
      email: email,
      password: password,
      parentId: parentId,
    );
  }

  @override
  Future<void> deleteChild(String childId) => remote.deleteChild(childId);

  @override
  Future<List<User>> loadChildrenForParent(String parentId) =>
      remote.loadChildrenForParent(parentId);

  @override
  Future<void> upgradeToPremium(String parentUid) =>
      remote.upgradeToPremium(parentUid);

  @override
  Future<void> sendPasswordResetOtp(String email) =>
      remote.sendPasswordResetOtp(email);

  @override
  Future<void> confirmPasswordReset({
    required String otpCode,
    required String newPassword,
  }) =>
      remote.confirmPasswordReset(otpCode: otpCode, newPassword: newPassword);

  @override
  Future<void> logout() => remote.logout();
}
