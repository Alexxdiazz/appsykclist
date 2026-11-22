// lib/api_service.dart
// Todo lo que Flutter le pide a la API de Vercel pasa por acá.
// Flutter NO habla directo con Supabase: habla con Vercel, y Vercel con Supabase.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Dirección de la API publicada en Vercel (sin barra al final).
const String apiBaseUrl = 'https://syklist-api.vercel.app';

/// Todas las direcciones completas (con https://) de la API, en un solo lugar.
/// Cada método de ApiService usa una de estas.
class Endpoints {
  static const String login = '$apiBaseUrl/api/auth/login'; //       https://syklist-api.vercel.app/api/auth/login
  static const String register = '$apiBaseUrl/api/auth/register'; // https://syklist-api.vercel.app/api/auth/register
  static const String perfil = '$apiBaseUrl/api/perfil'; //           https://syklist-api.vercel.app/api/perfil
  static const String resumen = '$apiBaseUrl/api/resumen'; //         https://syklist-api.vercel.app/api/resumen
  static const String recorridos = '$apiBaseUrl/api/recorridos'; //   https://syklist-api.vercel.app/api/recorridos
  static const String puntos = '$apiBaseUrl/api/puntos'; //           https://syklist-api.vercel.app/api/puntos
  static const String alertas = '$apiBaseUrl/api/alertas'; //         https://syklist-api.vercel.app/api/alertas
  static const String suscripcion = '$apiBaseUrl/api/suscripcion'; // https://syklist-api.vercel.app/api/suscripcion
  static const String estadisticas = '$apiBaseUrl/api/estadisticas'; // https://syklist-api.vercel.app/api/estadisticas

  /// https://syklist-api.vercel.app/api/recorridos/<id>
  static String recorrido(String id) => '$apiBaseUrl/api/recorridos/$id';
}

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

/// La función pedida es solo del plan Premium (la API respondió 403).
class PremiumRequerido extends ApiException {
  const PremiumRequerido(String mensaje) : super(mensaje);
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
  // Pedido HTTP genérico. Recibe la dirección COMPLETA (https://...).
  // --------------------------------------------------------------------------
  Future<dynamic> _enviar(
    String metodo,
    String url, {
    Object? cuerpo,
    Map<String, String>? query,
    bool conToken = true,
  }) async {
    final uri = Uri.parse(url).replace(queryParameters: query);

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
      throw ApiException('${uri.host} tardó demasiado en responder.');
    } catch (_) {
      throw ApiException(
        'No se pudo conectar con ${uri.host}. Revisá que la API esté publicada y que la URL sea correcta.',
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
      if (respuesta.statusCode == 403) throw PremiumRequerido(mensaje);
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
      Endpoints.login,
      cuerpo: {'email': email, 'password': password},
      conToken: false,
    ) as Map<String, dynamic>;
    await _guardarToken(datos['token'] as String);
    return Perfil.fromJson(datos['perfil'] as Map<String, dynamic>);
  }

  /// [aceptoTerminos] y [versionTerminos]: la API exige la aceptación y guarda qué versión se aceptó.
  Future<Perfil> registrarse({
    required String email,
    required String password,
    required String nombre,
    required bool aceptoTerminos,
    required String versionTerminos,
  }) async {
    final datos = await _enviar(
      'POST',
      Endpoints.register,
      cuerpo: {
        'email': email,
        'password': password,
        'nombre': nombre,
        'acepto_terminos': aceptoTerminos,
        'version_terminos': versionTerminos,
      },
      conToken: false,
    ) as Map<String, dynamic>;
    await _guardarToken(datos['token'] as String);
    return Perfil.fromJson(datos['perfil'] as Map<String, dynamic>);
  }

  // --------------------------------------------------------------------------
  // Datos de la Home
  // --------------------------------------------------------------------------
  Future<Perfil> obtenerPerfil() async {
    final datos = await _enviar('GET', Endpoints.perfil) as Map<String, dynamic>;
    return Perfil.fromJson(datos);
  }

  Future<ResumenSemanal> obtenerResumen() async {
    final datos = await _enviar('GET', Endpoints.resumen) as Map<String, dynamic>;
    return ResumenSemanal.fromJson(datos);
  }

  Future<List<RecorridoReciente>> listarRecorridos({int limite = 20}) async {
    final datos = await _enviar(
      'GET',
      Endpoints.recorridos,
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
      Endpoints.recorridos,
      cuerpo: {'titulo': titulo},
    ) as Map<String, dynamic>;
    return datos['id'] as String;
  }

  Future<void> enviarPuntos(String recorridoId, List<Map<String, dynamic>> puntos) async {
    await _enviar(
      'POST',
      Endpoints.puntos,
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
      Endpoints.recorrido(recorridoId),
      cuerpo: {'distancia_m': distanciaM, 'duracion_s': duracionS},
    );
  }

  // --------------------------------------------------------------------------
  // Alertas de caída (RF08 / RF09)
  // --------------------------------------------------------------------------
  /// Registra una posible caída en la base de datos (tabla alertas_caida) y devuelve su id.
  /// [lat] y [lng] son opcionales (puede no haber señal de GPS). [recorridoId] se manda si la
  /// caída ocurrió durante un recorrido. [estado]: pendiente, confirmada o falsa_alarma.
  Future<String?> registrarAlerta({
    double? lat,
    double? lng,
    String? recorridoId,
    String estado = 'pendiente',
  }) async {
    final datos = await _enviar(
      'POST',
      Endpoints.alertas,
      cuerpo: {
        'estado': estado,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (recorridoId != null) 'recorrido_id': recorridoId,
      },
    ) as Map<String, dynamic>;
    return datos['id']?.toString();
  }

  /// Cambia el estado de una alerta mía: 'confirmada' o 'falsa_alarma'.
  Future<void> actualizarAlerta(String id, String estado) async {
    await _enviar('PATCH', Endpoints.alertas, cuerpo: {'id': id, 'estado': estado});
  }

  Future<List<Alerta>> listarAlertas({int limite = 20}) async {
    final datos = await _enviar(
      'GET',
      Endpoints.alertas,
      query: {'limite': '$limite'},
    ) as List<dynamic>;
    return datos.map((e) => Alerta.fromJson(e as Map<String, dynamic>)).toList();
  }

  // --------------------------------------------------------------------------
  // Plan Premium (monetización)
  // --------------------------------------------------------------------------
  /// [periodo] es 'mensual' o 'anual'. El pago de esta entrega es simulado.
  Future<void> activarPremium(String periodo) async {
    await _enviar(
      'POST',
      Endpoints.suscripcion,
      cuerpo: {'accion': 'activar', 'periodo': periodo},
    );
  }

  Future<void> cancelarPremium() async {
    await _enviar('POST', Endpoints.suscripcion, cuerpo: {'accion': 'cancelar'});
  }

  /// Solo premium: en el plan gratis lanza [PremiumRequerido].
  Future<Estadisticas> obtenerEstadisticas() async {
    final datos = await _enviar('GET', Endpoints.estadisticas) as Map<String, dynamic>;
    return Estadisticas.fromJson(datos);
  }
}