import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _userId = 'user_id';
  static const String _email = 'email';
  static const String _role = 'role';
  static const String _userName = 'user_name';
  static const String _isLoggedIn = 'is_logged_in';

  final SharedPreferences _prefs;

  SessionManager(this._prefs);

  static Future<SessionManager> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SessionManager(prefs);
  }

  Future<void> saveSession({
    required String userId,
    required String email,
    required String role,
    required String userName,
  }) async {
    await Future.wait([
      _prefs.setString(_userId, userId),
      _prefs.setString(_email, email),
      _prefs.setString(_role, role),
      _prefs.setString(_userName, userName),
      _prefs.setBool(_isLoggedIn, true),
    ]);
  }

  String? get userId => _prefs.getString(_userId);
  String? get email => _prefs.getString(_email);
  String? get role => _prefs.getString(_role);
  String? get userName => _prefs.getString(_userName);
  bool get isLoggedIn => _prefs.getBool(_isLoggedIn) ?? false;

  Future<void> clearSession() async {
    await Future.wait([
      _prefs.remove(_userId),
      _prefs.remove(_email),
      _prefs.remove(_role),
      _prefs.remove(_userName),
      _prefs.setBool(_isLoggedIn, false),
    ]);
  }
}