import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  // Singleton
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  // Cliente de Supabase
  SupabaseClient get client => Supabase.instance.client;

  // Indica si hay sesión activa
  bool get haySesion => client.auth.currentSession != null;

  // Recupera la sesión guardada (Supabase la persiste automáticamente)
  Future<void> cargarSesion() async {
    // Supabase Flutter ya restaura la sesión al inicializar.
    // Este método queda por compatibilidad con tu main.dart.
    // Si necesitas forzar la recuperación:
  }

  // Cerrar sesión
  Future<void> cerrarSesion() async {
    await client.auth.signOut();
  }
}