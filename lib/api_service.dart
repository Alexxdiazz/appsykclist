// lib/api_service.dart
// Todo lo que Flutter le pide a la API de Vercel pasa por acá.
// Flutter NO habla directo con Supabase: habla con Vercel, y Vercel con Supabase.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

const String apiBaseUrl = 'https://edrnpkuvrmxtedwezdzj.supabase.co';

class ApiException implements Exception {
  final String mensaje;
  const ApiException(this.mensaje);

  @override
  String toString() => mensaje;
}

/// El token venció o no es válido: hay que volver a iniciar sesión.
class SesionExpirada extends ApiException {
  const SesionExpirada() : super('Tu sesión venció. Volvé a iniciar sesión.');
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const _claveToken = 'token_sesion';
  String? _token;

  bool get haySesion => _token != null && _token!.isNotEmpty;

  /// Se llama una vez al arrancar la app: recupera el token guardado.
  Future<void> cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_claveToken);
  }

  Future<void> _guardarToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveToken, token);
  }

  Future<void> cerrarSesion() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveToken);
  }

  // --------------------------------------------------------------------------
  // Pedido HTTP genérico
  // --------------------------------------------------------------------------
  Future<dynamic> _enviar(
    String metodo,
    String ruta, {
    Object? cuerpo,
    Map<String, String>? query,
    bool conToken = true,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$ruta').replace(queryParameters: query);

    final peticion = http.Request(metodo, uri)
      ..headers['Content-Type'] = 'application/json';
    if (conToken && _token != null) {
      peticion.headers['Authorization'] = 'Bearer $_token';
    }
    if (cuerpo != null) {
      peticion.body = jsonEncode(cuerpo);
    }

    late final http.Response respuesta;
    try {
      final stream = await peticion.send().timeout(const Duration(seconds: 25));
      respuesta = await http.Response.fromStream(stream);
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder.');
    } catch (_) {
      throw const ApiException(
        'No se pudo conectar con el servidor. Revisá tu conexión y la URL de la API.',
      );
    }

    dynamic datos;
    if (respuesta.body.isNotEmpty) {
      try {
        datos = jsonDecode(respuesta.body);
      } catch (_) {
        datos = null;
      }
    }

    if (respuesta.statusCode == 401 && conToken) {
      await cerrarSesion();
      throw const SesionExpirada();
    }
    if (respuesta.statusCode >= 400) {
      final mensaje = (datos is Map && datos['error'] is String)
          ? datos['error'] as String
          : 'Error del servidor (${respuesta.statusCode})';
      throw ApiException(mensaje);
    }
    return datos;
  }

  // --------------------------------------------------------------------------
  // Sesión
  // --------------------------------------------------------------------------
  Future<Perfil> iniciarSesion(String email, String password) async {
    final datos = await _enviar(
      'POST',
      '/api/auth/login',
      cuerpo: {'email': email, 'password': password},
      conToken: false,
    ) as Map<String, dynamic>;
    await _guardarToken(datos['token'] as String);
    return Perfil.fromJson(datos['perfil'] as Map<String, dynamic>);
  }

  Future<Perfil> registrarse({
    required String email,
    required String password,
    required String nombre,
  }) async {
    final datos = await _enviar(
      'POST',
      '/api/auth/register',
      cuerpo: {'email': email, 'password': password, 'nombre': nombre},
      conToken: false,
    ) as Map<String, dynamic>;
    await _guardarToken(datos['token'] as String);
    return Perfil.fromJson(datos['perfil'] as Map<String, dynamic>);
  }

  // --------------------------------------------------------------------------
  // Datos de la Home
  // --------------------------------------------------------------------------
  Future<Perfil> obtenerPerfil() async {
    final datos = await _enviar('GET', '/api/perfil') as Map<String, dynamic>;
    return Perfil.fromJson(datos);
  }

  Future<ResumenSemanal> obtenerResumen() async {
    final datos = await _enviar('GET', '/api/resumen') as Map<String, dynamic>;
    return ResumenSemanal.fromJson(datos);
  }

  Future<List<RecorridoReciente>> listarRecorridos({int limite = 20}) async {
    final datos = await _enviar(
      'GET',
      '/api/recorridos',
      query: {'limite': '$limite'},
    ) as List<dynamic>;
    return datos
        .map((e) => RecorridoReciente.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // --------------------------------------------------------------------------
  // Recorrido en vivo
  // --------------------------------------------------------------------------
  /// Crea el recorrido en la base de datos y devuelve su id.
  Future<String> iniciarRecorrido(String titulo) async {
    final datos = await _enviar(
      'POST',
      '/api/recorridos',
      cuerpo: {'titulo': titulo},
    ) as Map<String, dynamic>;
    return datos['id'] as String;
  }

  Future<void> enviarPuntos(String recorridoId, List<Map<String, dynamic>> puntos) async {
    await _enviar(
      'POST',
      '/api/puntos',
      cuerpo: {'recorrido_id': recorridoId, 'puntos': puntos},
    );
  }

  Future<void> finalizarRecorrido(
    String recorridoId, {
    required double distanciaM,
    required int duracionS,
  }) async {
    await _enviar(
      'PATCH',
      '/api/recorridos/$recorridoId',
      cuerpo: {'distancia_m': distanciaM, 'duracion_s': duracionS},
    );
  }
}