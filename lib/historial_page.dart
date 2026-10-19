// lib/historial_page.dart
// Lista completa de recorridos del usuario (RF11).
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'ciclista_page.dart' show AppColors;
import 'models.dart';
import 'recorrido_card.dart';

class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  List<RecorridoReciente>? _recorridos;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final lista = await ApiService.instance.listarRecorridos(limite: 100);
      if (!mounted) return;
      setState(() {
        _recorridos = lista;
        _error = null;
      });
    } on SesionExpirada {
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    }
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
                : '${lista.length} recorridos · ${totalKm.toStringAsFixed(1)} km en total',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textOnLight),
          ),
          const SizedBox(height: 12),
          ...lista.map((r) => RecorridoCard(recorrido: r)),
        ],
      ),
    );
  }
}