import 'package:flutter/material.dart';
import 'package:quan_ly_cha_con/models/user.dart';
import 'package:quan_ly_cha_con/repositories/athu/auth_repository.dart';
import 'package:quan_ly_cha_con/services/auth/session_manager.dart';

enum AuthStatus { initial, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SessionManager _sessionManager;

  AuthStatus _status = AuthStatus.initial;
  User? _currentUser;
  List<User> _children = [];
  User? _parentUser;

  String _errorMessage = '';
  String _resetMessage = '';
  String _resetErrorMessage = '';
  AuthStatus _resetStatus = AuthStatus.initial;

  String _lastResetEmail = '';

  AuthViewModel({
    required AuthRepository authRepository,
    required SessionManager sessionManager,
  })  : _authRepository = authRepository,
        _sessionManager = sessionManager;

  // ================= GETTERS =================
  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  List<User> get children => _children;
  User? get parentUser => _parentUser;

  String get errorMessage => _errorMessage;
  String get resetMessage => _resetMessage;
  String get resetErrorMessage => _resetErrorMessage;

  bool get isLoggedIn => _currentUser != null;
  bool get isParent => _currentUser?.role == 'cha';

  /// ✅ CHA premium thì true, CON luôn false
  bool get isPremiumParent =>
      _currentUser?.role == 'cha' && (_currentUser?.isPremium ?? false);

  /// Quyền premium chia sẻ cho cả cha và con (nếu cha đã nâng cấp)
  bool get hasSharedPremium =>
      (_currentUser?.isPremium ?? false) || (_parentUser?.isPremium ?? false);

  AuthStatus get resetStatus => _resetStatus;
  String get lastResetEmail => _lastResetEmail;

  // ================= AUTH =================
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


      _currentUser = user.copyWith(isPremium: user.isPremium);

      await _sessionManager.saveSession(
        userId: user.uid,
        email: user.email,
        role: user.role,
        userName: user.name,
      );

      if (isParent) {
        await _loadChildren();
      } else {
        await loadParentForChild();
      }

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
      _currentUser = user.copyWith(isPremium: user.isPremium);

      await _sessionManager.saveSession(
        userId: user.uid,
        email: user.email,
        role: user.role,
        userName: user.name,
      );

      if (isParent) {
        await _loadChildren();
      } else {
        await loadParentForChild();
      }

      _setStatus(AuthStatus.success);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> loadUserFromStorage() async {
    if (!_sessionManager.isLoggedIn) return;

    _setStatus(AuthStatus.loading);
    _errorMessage = '';

    try {
      final userId = _sessionManager.userId;
      if (userId == null) throw Exception('Không tìm thấy user');

      final user = await _authRepository.loadCurrentUser(userId);
      if (user == null) {
        _setStatus(AuthStatus.initial);
        return;
      }

      _currentUser = user.copyWith(isPremium: user.isPremium);

      if (isParent) {
        await _loadChildren();
      } else {
        await loadParentForChild();
      }

      _setStatus(AuthStatus.success);
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
      _parentUser = null;

      _setStatus(AuthStatus.initial);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ================= RESET PASSWORD =================
  Future<void> sendResetOtp(String email) async {
    _setResetStatus(AuthStatus.loading);
    _resetErrorMessage = '';
    _resetMessage = '';

    try {
      if (email.isEmpty) {
        throw Exception('Vui lòng nhập email');
      }

      await _authRepository.sendPasswordResetOtp(email);
      _lastResetEmail = email;
      _resetMessage =
          'Đã gửi mã OTP đặt lại mật khẩu tới email. Vui lòng kiểm tra hộp thư.';
      _setResetStatus(AuthStatus.success);
    } catch (e) {
      _setResetError(e.toString());
    }
  }

  Future<void> confirmPasswordReset({
    required String otpCode,
    required String newPassword,
    String? email,
  }) async {
    _setResetStatus(AuthStatus.loading);
    _resetErrorMessage = '';
    _resetMessage = '';

    try {
      if (otpCode.isEmpty || newPassword.isEmpty) {
        throw Exception('Vui lòng nhập đầy đủ mã OTP và mật khẩu mới');
      }
      if (newPassword.length < 6) {
        throw Exception('Mật khẩu mới phải ít nhất 6 ký tự');
      }

      await _authRepository.confirmPasswordReset(
        otpCode: otpCode,
        newPassword: newPassword,
      );

      _resetMessage =
          'Đặt lại mật khẩu thành công. Bạn có thể đăng nhập với mật khẩu mới.';
      _setResetStatus(AuthStatus.success);
    } catch (e) {
      _setResetError(e.toString());
    }
  }

  // ================= CHILDREN =================
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

  Future<void> deleteChild(String childId) async {
    _setStatus(AuthStatus.loading);

    try {
      await _authRepository.deleteChild(childId);
      _children.removeWhere((c) => c.uid == childId);
      _setStatus(AuthStatus.success);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> _loadChildren() async {
    final parentId = _currentUser?.uid;
    if (parentId == null) return;

    try {
      _children = await _authRepository.loadChildrenForParent(parentId);
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi tải con: $e');
    }
  }

  // ================= PARENT FOR CHILD =================
  Future<void> loadParentForChild() async {
    if (_currentUser == null || _currentUser!.role != 'con') return;

    final parentId = _currentUser!.parentId;
    if (parentId == null || parentId.isEmpty) return;

    _errorMessage = '';
    _setStatus(AuthStatus.loading);

    try {
      final parent = await _authRepository.loadUserById(parentId);
      if (parent == null) {
        throw Exception('Không tìm thấy tài khoản cha/mẹ');
      }

      _parentUser = parent;
      _setStatus(AuthStatus.success);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ================= PREMIUM =================
  Future<void> upgradePremium() async {
    final me = _currentUser;
    if (me == null || me.role != 'cha') return;

    _setStatus(AuthStatus.loading);

    try {
      await _authRepository.upgradeToPremium(me.uid);

      _currentUser = me.copyWith(isPremium: true);
      _setStatus(AuthStatus.success);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ================= HELPERS =================
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void clearResetState() {
    _resetMessage = '';
    _resetErrorMessage = '';
    _resetStatus = AuthStatus.initial;
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

  void _setResetStatus(AuthStatus status) {
    _resetStatus = status;
    notifyListeners();
  }

  void _setResetError(String message) {
    _resetErrorMessage = message;
    _resetStatus = AuthStatus.error;
    notifyListeners();
  }
}
