import 'package:flutter/material.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _user;
  String? _error;

  AuthProvider(this._authRepository);

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get esMayorista => _user?.esMayorista ?? false;
  bool get esTAT => _user?.esTAT ?? false;
  bool get esAdmin => _user?.esAdmin ?? false;

  Future<void> tryAutoLogin() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final user = await _authRepository.tryAutoLogin();
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _user = await _authRepository.login(email, password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      final msg = e.toString();
      _error = msg.startsWith('Exception: ') ? msg.substring(11) : msg;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
      String email, String password, String nombre, String tipoVendedor) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.register(email, password, nombre, tipoVendedor);
      _status = AuthStatus.unauthenticated;
      _error = 'Registro exitoso. Espera a que el administrador active tu cuenta.';
      notifyListeners();
      return true;
    } catch (e) {
      final msg = e.toString();
      _error = msg.startsWith('Exception: ') ? msg.substring(11) : msg;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
