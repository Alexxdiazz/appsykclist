// lib/recorrido_page.dart
// Pantalla de recorrido en vivo (RF02, RF03, RF04, RF05, RF06):
//   1. "Comenzar"  → crea el recorrido en la base de datos (vía API) y empieza a leer el GPS
//   2. Mientras anda → dibuja la ruta en el mapa y cuenta tiempo, distancia y velocidad
//   3. "Finalizar" → guarda los puntos de GPS y cierra el recorrido (vía API)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'api_service.dart';
import 'ciclista_page.dart' show AppColors;
import 'models.dart';

/// Aviso para el usuario (GPS apagado, permiso denegado...).
class _Aviso implements Exception {
  final String mensaje;
  const _Aviso(this.mensaje);
}

class RecorridoPage extends StatefulWidget {
  const RecorridoPage({super.key});

  @override
  State<RecorridoPage> createState() => _RecorridoPageState();
}

class _RecorridoPageState extends State<RecorridoPage> {
  static const LatLng _centroPorDefecto = LatLng(-34.9011, -56.1645);

  final MapController _mapController = MapController();
  final Distance _calculadora = const Distance();

  final List<LatLng> _puntos = [];
  final List<DateTime> _momentos = [];

  StreamSubscription<Position>? _suscripcion;
  Timer? _timer;

  bool _mapaListo = false;
  bool _enCurso = false;
  bool _ocupado = false;
  bool _puntosEnviados = false;

  String? _recorridoId;
  DateTime? _inicio;
  int _segundos = 0;
  double _distanciaM = 0;
  LatLng? _actual;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ubicarme();
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // GPS
  // --------------------------------------------------------------------------
  Future<void> _verificarPermiso() async {
    final servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      throw const _Aviso('Activá la ubicación (GPS) del dispositivo.');
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
      throw const _Aviso('Necesitamos el permiso de ubicación para registrar el recorrido.');
    }
  }

  /// Muestra dónde estás apenas se abre la pantalla (si el permiso lo permite).
  Future<void> _ubicarme() async {
    try {
      await _verificarPermiso();
      final posicion = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final p = LatLng(posicion.latitude, posicion.longitude);
      setState(() => _actual = p);
      _moverMapa(p);
    } catch (_) {
      // Si falla, el botón "Comenzar" vuelve a pedir el permiso y muestra el motivo.
    }
  }

  void _moverMapa(LatLng p) {
    if (_mapaListo) _mapController.move(p, 16);
  }

  void _alNuevaPosicion(Position posicion) {
    if (!mounted) return;
    final p = LatLng(posicion.latitude, posicion.longitude);
    setState(() {
      if (_puntos.isNotEmpty) {
        _distanciaM += _calculadora.as(LengthUnit.Meter, _puntos.last, p);
      }
      _puntos.add(p);
      _momentos.add(DateTime.now());
      _actual = p;
    });
    _moverMapa(p);
  }

  // --------------------------------------------------------------------------
  // Comenzar / Finalizar
  // --------------------------------------------------------------------------
  String _tituloSegunHora() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Recorrido de la mañana';
    if (hora < 19) return 'Recorrido de la tarde';
    return 'Recorrido de la noche';
  }

  Future<void> _comenzar() async {
    setState(() {
      _ocupado = true;
      _error = null;
    });

    try {
      await _verificarPermiso();
      final id = await ApiService.instance.iniciarRecorrido(_tituloSegunHora());
      if (!mounted) return;

      _recorridoId = id;
      _inicio = DateTime.now();
      _puntos.clear();
      _momentos.clear();
      _distanciaM = 0;
      _segundos = 0;
      _puntosEnviados = false;

      _suscripcion = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3, // solo avisa si se movió al menos 3 metros
        ),
      ).listen(
        _alNuevaPosicion,
        onError: (_) {
          if (mounted) setState(() => _error = 'No se pudo leer el GPS.');
        },
      );

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final inicio = _inicio;
        if (!mounted || inicio == null) return;
        setState(() => _segundos = DateTime.now().difference(inicio).inSeconds);
      });

      setState(() {
        _enCurso = true;
        _ocupado = false;
      });
    } on SesionExpirada {
      _irALogin();
    } on ApiException catch (e) {
      _mostrarError(e.mensaje);
    } on _Aviso catch (e) {
      _mostrarError(e.mensaje);
    } catch (_) {
      _mostrarError('No se pudo iniciar el recorrido.');
    }
  }

  Future<void> _finalizar() async {
    final id = _recorridoId;
    if (id == null) return;

    setState(() {
      _ocupado = true;
      _error = null;
    });

    _suscripcion?.cancel();
    _suscripcion = null;
    _timer?.cancel();
    _timer = null;

    final inicio = _inicio;
    if (inicio != null) _segundos = DateTime.now().difference(inicio).inSeconds;

    try {
      if (!_puntosEnviados && _puntos.isNotEmpty) {
        final List<Map<String, dynamic>> lista = [
          for (var i = 0; i < _puntos.length; i++)
            {
              'lat': _puntos[i].latitude,
              'lng': _puntos[i].longitude,
              'registrado_en': _momentos[i].toUtc().toIso8601String(),
            },
        ];
        await ApiService.instance.enviarPuntos(id, lista);
        _puntosEnviados = true;
      }

      await ApiService.instance.finalizarRecorrido(
        id,
        distanciaM: _distanciaM,
        duracionS: _segundos,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recorrido guardado')),
      );
      Navigator.of(context).pop(true); // la Home se actualiza al recibir "true"
    } on SesionExpirada {
      _irALogin();
    } on ApiException catch (e) {
      _mostrarError(e.mensaje); // se puede volver a tocar "Finalizar" para reintentar
    } catch (_) {
      _mostrarError('No se pudo guardar el recorrido.');
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    setState(() {
      _error = mensaje;
      _ocupado = false;
    });
  }

  void _irALogin() {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
  }

  // --------------------------------------------------------------------------
  // Pantalla
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        // Mientras graba no se muestra la flecha de volver, para no perder el recorrido sin querer.
        automaticallyImplyLeading: !_enCurso,
        title: const Text('Recorrido', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMapa()),
          _buildPanel(),
        ],
      ),
    );
  }

  Widget _buildMapa() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _actual ?? _centroPorDefecto,
        initialZoom: 15,
        onMapReady: () {
          _mapaListo = true;
          final p = _actual;
          if (p != null) _mapController.move(p, 16);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ciclista_app',
        ),
        if (_puntos.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: List<LatLng>.of(_puntos),
                color: AppColors.secondary,
                strokeWidth: 5,
              ),
            ],
          ),
        if (_actual != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _actual!,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPanel() {
    final km = _distanciaM / 1000;
    final velocidadMedia = _segundos > 0 ? km / (_segundos / 3600) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: _stat(formatearDuracion(_segundos), 'Tiempo')),
                Expanded(child: _stat('${km.toStringAsFixed(2)} km', 'Distancia')),
                Expanded(child: _stat('${velocidadMedia.toStringAsFixed(1)} km/h', 'Vel. media')),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.accent, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _enCurso ? _botonFinalizar() : _botonComenzar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String valor, String etiqueta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            valor,
            style: const TextStyle(color: AppColors.textOnDark, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          etiqueta,
          style: TextStyle(color: AppColors.textOnDark.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }

  Widget _botonComenzar() {
    return ElevatedButton.icon(
      onPressed: _ocupado ? null : _comenzar,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      icon: _ocupado
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          : const Icon(Icons.play_arrow),
      label: Text(
        _ocupado ? 'Iniciando...' : 'Comenzar recorrido',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _botonFinalizar() {
    return ElevatedButton.icon(
      onPressed: _ocupado ? null : _finalizar,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      icon: _ocupado
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.stop),
      label: Text(
        _ocupado ? 'Guardando...' : 'Finalizar y guardar',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}