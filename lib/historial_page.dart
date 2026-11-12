// lib/historial_page.dart
// Lista de recorridos del usuario (RF11).
// Monetización (RF14): el plan gratis ve solo los últimos 5; Premium tiene historial ilimitado.
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'ciclista_page.dart' show AppColors;
import 'models.dart';
import 'paywall_page.dart';
import 'recorrido_card.dart';

class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  List<RecorridoReciente>? _recorridos;
  bool _esPremium = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final r = await Future.wait<dynamic>([
        ApiService.instance.listarRecorridos(limite: 100),
        ApiService.instance.obtenerPerfil(),
      ]);
      if (!mounted) return;
      setState(() {
        _recorridos = r[0] as List<RecorridoReciente>;
        _esPremium = (r[1] as Perfil).esPremium;
        _error = null;
      });
    } on SesionExpirada {
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    }
  }

  Future<void> _verPremium() async {
    final cambio = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PaywallPage()),
    );
    if (cambio == true && mounted) _cargar(); // ahora el historial puede traer todo
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        title: const Text('Historial', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(child: _buildCuerpo()),
    );
  }

  Widget _buildCuerpo() {
    final lista = _recorridos;

    if (lista == null) {
      if (_error == null) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textOnLight)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _error = null);
                  _cargar();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnDark,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final totalKm = lista.fold<double>(0, (suma, r) => suma + r.distanciaKm);
    // El aviso solo aparece si el plan gratis llegó al tope de recorridos visibles.
    final mostrarBloqueo = !_esPremium && lista.length >= limiteHistorialGratis;

    return RefreshIndicator(
      onRefresh: _cargar,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            lista.isEmpty
                ? 'Todavía no tenés recorridos guardados.'
                : '${lista.length} recorridos · ${totalKm.toStringAsFixed(1)} km',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textOnLight),
          ),
          const SizedBox(height: 12),
          ...lista.map((r) => RecorridoCard(recorrido: r)),
          if (mostrarBloqueo) _buildBloqueoPremium(),
        ],
      ),
    );
  }

  Widget _buildBloqueoPremium() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Historial completo con Premium',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textOnLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'El plan gratis muestra hasta $limiteHistorialGratis recorridos. Con Premium el historial es ilimitado.',
            style: TextStyle(fontSize: 14, color: AppColors.textOnLight.withOpacity(0.7)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _verPremium,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.workspace_premium),
              label: const Text('Ver Premium', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}