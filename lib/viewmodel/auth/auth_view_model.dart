import 'package:flutter/material.dart';
import 'package:quan_ly_cha_con/models/User.dart';
import 'package:quan_ly_cha_con/repositories/athu/auth_repository.dart';
import 'package:quan_ly_cha_con/services/auth/session_manager.dart';

enum AuthStatus { initial, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SessionManager _sessionManager;

  AuthStatus _status = AuthStatus.initial;
  User? _currentUser;
  List<User> _children = [];
  String _errorMessage = '';

  AuthViewModel({
    required AuthRepository authRepository,
    required SessionManager sessionManager,
  })  : _authRepository = authRepository,
        _sessionManager = sessionManager;

  // Getters
  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  List<User> get children => _children;
  String get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isParent => _currentUser?.role == 'cha';

  // ============ AUTH ============
  Future<void> register({
    required String email,
    required String password,
    required String role,
  }) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = '';

    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email và mật khẩu không được trống');
      }
      if (password.length < 6) {
        throw Exception('Mật khẩu phải ít nhất 6 ký tự');
      }

      final user = await _authRepository.register(email, password, role);
      _currentUser = user;
      await _sessionManager.saveSession(
        userId: user.uid,
        email: user.email,
        role: user.role,
        userName: user.name,
      );

      if (isParent) await _loadChildren();
      _setStatus(AuthStatus.success);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = '';

    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email và mật khẩu không được trống');
      }

      final user = await _authRepository.login(email, password);
      _currentUser = user;
      await _sessionManager.saveSession(
        userId: user.uid,
        email: user.email,
        role: user.role,
        userName: user.name,
      );

      if (isParent) await _loadChildren();
      _setStatus(AuthStatus.success);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ============ CHILDREN ============
  Future<void> createChildAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    _setStatus(AuthStatus.loading);

    try {
      final parentId = _currentUser?.uid;
      if (parentId == null) {
        throw Exception('Không xác định được tài khoản cha');
      }

      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        throw Exception('Vui lòng nhập đầy đủ thông tin');
      }

      final child = await _authRepository.createChildAccount(
        name: name,
        email: email,
        password: password,
        parentId: parentId,
      );

      _children.add(child);
      _setStatus(AuthStatus.success);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> _loadChildren() async {
    try {
      final parentId = _currentUser?.uid;
      if (parentId == null) return;

      _children = await _authRepository.loadChildrenForParent(parentId);
      notifyListeners();
    } catch (e) {
      print('Lỗi tải con: $e');
    }
  }

  // ============ HELPERS ============
  Future<void> loadUserFromStorage() async {
    if (!_sessionManager.isLoggedIn) return;

    _setStatus(AuthStatus.loading);

    try {
      final userId = _sessionManager.userId;
      if (userId == null) throw Exception('Không tìm thấy user');

      final user = await _authRepository.loadCurrentUser(userId);
      if (user != null) {
        _currentUser = user;
        if (isParent) await _loadChildren();
        _setStatus(AuthStatus.success);
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
      await _sessionManager.clearSession();
      _currentUser = null;
      _children = [];
      _setStatus(AuthStatus.initial);
    } catch (e) {
      _setError(e.toString());
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = AuthStatus.error;
    notifyListeners();
  }
}