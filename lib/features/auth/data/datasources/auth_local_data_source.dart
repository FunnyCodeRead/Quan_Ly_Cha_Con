
import 'package:quan_ly_cha_con/core/services/session_manager.dart';

abstract class AuthLocalDataSource {
  bool get isLoggedIn;
  String? get userId;

  Future<void> saveSession({
    required String userId,
    required String email,
    required String role,
    required String userName,
  });

  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SessionManager _session;

  AuthLocalDataSourceImpl(this._session);

  @override
  bool get isLoggedIn => _session.isLoggedIn;

  @override
  String? get userId => _session.userId;

  @override
  Future<void> saveSession({
    required String userId,
    required String email,
    required String role,
    required String userName,
  }) {
    return _session.saveSession(
      userId: userId,
      email: email,
      role: role,
      userName: userName,
    );
  }

  @override
  Future<void> clearSession() => _session.clearSession();
}
