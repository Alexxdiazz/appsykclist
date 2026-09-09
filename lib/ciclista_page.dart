import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';


class AppColors {
  static const Color primary =Color(0xFF1A1B47);    // 60%
  static const Color secondary = Color(0xFF4A90D9);  // 30%
  static const Color accent = Color(0xFFF5A623) ;     // 10%
  static const Color background = Color(0xFFEAF0FB);
  static const Color error = Color(0xFFE74C3C);
  static const Color textOnDark = Colors.white;        // texto sobre fondos oscuros (primary)
  static const Color textOnLight = Color(0xFF1A1B47);  // texto sobre fondos claros (background)
}


class CiclistaViewModel extends ChangeNotifier {
  LatLng? _posicaoAtual;
  bool _loading = false;
  String? _mensagemErro;
  List<LatLng> _pontosRota = [];
  bool _rotaLoading = false;
  String? _rotaErro;

  LatLng? get posicaoAtual => _posicaoAtual;
  bool get loading => _loading;
  String? get mensagemErro => _mensagemErro;
  List<LatLng> get pontosRota => _pontosRota;
  bool get rotaLoading => _rotaLoading;
  String? get rotaErro => _rotaErro;

  Future<void> obtenerUbicacion() async {
    _loading = true;
    _mensagemErro = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _mensagemErro = 'Activa el GPS';
        _loading = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _mensagemErro = 'Permiso denegado permanentemente';
        _loading = false;
        notifyListeners();
        return;
      }
      if (permission == LocationPermission.denied) {
        _mensagemErro = 'Permiso denegado';
        _loading = false;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _posicaoAtual = LatLng(position.latitude, position.longitude);
    } catch (e) {
      _mensagemErro = 'Error: $e';
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> calcularRuta(LatLng origem, LatLng destino) async {
    _rotaLoading = true;
    _rotaErro = null;
    _pontosRota = [];
    notifyListeners();

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origem.longitude},${origem.latitude};'
        '${destino.longitude},${destino.latitude}?overview=full&geometries=geojson',
      );
      
      final response = await http.get(url);

      if (response.statusCode != 200) {
        _rotaErro = 'Error al calcular ruta';
        _rotaLoading = false;
        notifyListeners();
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      
      if (routes == null || routes.isEmpty) {
        _rotaErro = 'No se encontró ruta';
        _rotaLoading = false;
        notifyListeners();
        return;
      }

      final coords = routes[0]['geometry']['coordinates'] as List<dynamic>;
      _pontosRota = coords.map((c) {
        final list = c as List<dynamic>;
        return LatLng(list[1].toDouble(), list[0].toDouble());
      }).toList();

    } catch (e) {
      _rotaErro = 'Error: $e';
    }

    _rotaLoading = false;
    notifyListeners();
  }

  void limpiarRuta() {
    _pontosRota = [];
    _rotaErro = null;
    notifyListeners();
  }
}


class CiclistaPage extends StatefulWidget {
  const CiclistaPage({super.key});

  @override
  State<CiclistaPage> createState() => _CiclistaPageState();
}

class _CiclistaPageState extends State<CiclistaPage> {
  final _viewModel = CiclistaViewModel();
  final _mapController = MapController();
  final _destLatController = TextEditingController(text: '-23.5489');
  final _destLngController = TextEditingController(text: '-46.6388');

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _mapController.dispose();
    _destLatController.dispose();
    _destLngController.dispose();
    super.dispose();
  } 

  @override
  Widget build(BuildContext context) {
    final p = _viewModel.posicaoAtual;
    final loading = _viewModel.loading;
    final error = _viewModel.mensagemErro;
    final puntosRota = _viewModel.pontosRota;
    final rotaLoading = _viewModel.rotaLoading;
    final rotaError = _viewModel.rotaErro;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.pedal_bike, color: AppColors.accent),
            const SizedBox(width: 8),
            const Text('Syklist', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Color.fromARGB(255, 26, 27, 71),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-23.5505, -46.6333),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ciclista_app',
              ),
              if (p != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: p,
                      width: 40,
                      height: 40,
                      child: Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              // Ruta
              if (puntosRota.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: puntosRota,
                      color: Colors.blue,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              // Destino
              if (_destLatController.text.isNotEmpty && _destLngController.text.isNotEmpty)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        double.tryParse(_destLatController.text) ?? 0,
                        double.tryParse(_destLngController.text) ?? 0,
                      ),
                      width: 40,
                      height: 40,
                      child: Icon(Icons.location_pin, color: AppColors.accent, size: 40),
                    ),
                  ],
                ),
            ],
          ),
          
          // PANEL DE CONTROL (ARRIBA)
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: Card(
              elevation: 4,
              color: AppColors.background,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.route, color: Color.fromARGB(255, 26, 27, 71)),
                        const SizedBox(width: 8),
                        Text(
                          'Planificar ruta',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _destLatController,
                            decoration: const InputDecoration(
                              labelText: 'Latitud',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _destLngController,
                            decoration: const InputDecoration(
                              labelText: 'Longitud',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    if (rotaError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          rotaError,
                          style: TextStyle(color: AppColors.error, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: rotaLoading ? null : () {
                              final lat = double.tryParse(_destLatController.text);
                              final lng = double.tryParse(_destLngController.text);
                              if (lat != null && lng != null) {
                                final origem = p ?? const LatLng(-23.5505, -46.6333);
                                _viewModel.calcularRuta(origem, LatLng(lat, lng));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Color.fromARGB(255, 26, 27, 71),
                            ),
                            icon: rotaLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color.fromARGB(255, 26, 27, 71)),
                                  )
                                : const Icon(Icons.route),
                            label: Text(rotaLoading ? 'Calculando...' : 'Calcular'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _viewModel.limpiarRuta,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary),
                              backgroundColor: AppColors.secondary,
                        
                            ),
                            icon: const Icon(Icons.clear),
                            label: const Text('Limpiar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // BOTÓN DE UBICACIÓN (ABAJO)
          Positioned(
            right: 16,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  onPressed: loading ? null : () async {
                    await _viewModel.obtenerUbicacion();
                    final pos = _viewModel.posicaoAtual;
                    if (pos != null) _mapController.move(pos, 15);
                  },
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  icon: loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color.fromARGB(255, 26, 27, 71)),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(loading ? 'Obteniendo...' : 'Mi ubicación'),
                ),
                const SizedBox(height: 12),
                Card(
                  color: AppColors.background,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (error != null)
                          Text(error, style: TextStyle(color: AppColors.error, fontSize: 12))
                        else if (p != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ubicación actual',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Lat: ${p.latitude.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                'Lng: ${p.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Usa "Mi ubicación"',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary,),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}