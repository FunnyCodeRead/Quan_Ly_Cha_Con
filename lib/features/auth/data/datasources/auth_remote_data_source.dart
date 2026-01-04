import 'package:quan_ly_cha_con/features/user/domain/entities/user.dart';

abstract class AuthRemoteDataSource {
  Future<User> register(String email, String password, String role);
  Future<User> login(String email, String password);

  Future<User?> loadUserById(String uid);
  Future<User?> loadCurrentUser(String uid);

  Future<User> createChildAccount({
    required String name,
    required String email,
    required String password,
    required String parentId,
  });

  Future<void> deleteChild(String childId);
  Future<List<User>> loadChildrenForParent(String parentId);

  Future<void> upgradeToPremium(String parentUid);
  Future<void> sendPasswordResetOtp(String email);

  Future<void> confirmPasswordReset({
    required String otpCode,
    required String newPassword,
  });

  Future<void> logout();
}
