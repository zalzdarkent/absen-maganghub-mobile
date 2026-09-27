import 'package:flutter/foundation.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository authRepository;

  AuthViewModel({required this.authRepository});

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  UserModel? get currentUser => authRepository.currentUser;
  bool get isAuthenticated => authRepository.isAuthenticated;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<UserModel?> checkSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await authRepository.checkSession();
      return user;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      if (usernameOrEmail.trim().isEmpty || password.trim().isEmpty) {
        throw Exception('Harap masukkan username/email dan kata sandi.');
      }
      await authRepository.login(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );
      _successMessage = 'Berhasil masuk!';
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? name,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      if (username.trim().isEmpty || email.trim().isEmpty || password.trim().isEmpty) {
        throw Exception('Harap isi semua bidang pendaftaran.');
      }
      if (!email.contains('@') || !email.contains('.')) {
        throw Exception('Format email tidak valid.');
      }
      if (password.length < 6) {
        throw Exception('Kata sandi minimal 6 karakter.');
      }

      await authRepository.register(
        username: username,
        email: email,
        password: password,
        name: name,
      );
      _successMessage = 'Pendaftaran berhasil!';
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await authRepository.logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
