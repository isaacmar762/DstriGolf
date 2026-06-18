import '../models/user.dart';
import '../services/supabase_service.dart';
import '../services/local_db_service.dart';

class AuthRepository {
  final SupabaseService _supabase;
  final LocalDbService _localDb;

  AuthRepository(this._supabase, this._localDb);

  Future<UserModel> register(String email, String password, String nombre,
      String tipoVendedor) async {
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
  }

  Future<UserModel> login(String email, String password) async {
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
