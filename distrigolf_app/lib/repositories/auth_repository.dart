import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import '../services/local_db_service.dart';

class AuthRepository {
  final SupabaseService _supabase;
  final LocalDbService _localDb;

  AuthRepository(this._supabase, this._localDb);

  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'Credenciales inválidas. Verifica tu email y contraseña.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Demasiados intentos. Intenta de nuevo más tarde.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Email no confirmado. Revisa tu bandeja de entrada.';
    }
    return 'Error al iniciar sesión. Intenta de nuevo.';
  }

  Future<UserModel> register(String email, String password, String nombre,
      String tipoVendedor) async {
    try {
      final authRes = await _supabase.signUp(email, password);

      if (authRes.user == null) {
        throw Exception('Error al crear usuario');
      }

      final perfil = UserModel(
        id: authRes.user!.id,
        email: email,
        nombre: nombre,
        tipoVendedor: tipoVendedor,
        activo: false,
      );

      await _supabase.crearPerfil(perfil);
      return perfil;
    } on AuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Error al crear usuario')) rethrow;
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    }
  }

  Future<UserModel> login(String email, String password) async {
    try {
      final authRes = await _supabase.signIn(email, password);

      if (authRes.user == null) {
        throw Exception('Credenciales inválidas');
      }

      final perfil = await _supabase.obtenerPerfil(authRes.user!.id);
      if (perfil == null) {
        throw Exception('Perfil no encontrado');
      }
      if (!perfil.activo) {
        throw Exception('Cuenta pendiente de activación por el administrador');
      }

      return perfil;
    } on AuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Credenciales') ||
          msg.contains('Perfil') ||
          msg.contains('Cuenta')) {
        rethrow;
      }
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    }
  }

  Future<UserModel?> tryAutoLogin() async {
    final currentUser = _supabase.currentUser;
    if (currentUser == null) return null;

    final perfil = await _supabase.obtenerPerfil(currentUser.id);
    if (perfil == null || !perfil.activo) return null;

    return perfil;
  }

  Future<void> logout() async {
    await _supabase.signOut();
  }
}
