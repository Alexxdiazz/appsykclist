// lib/alertas_page.dart
// Historial de alertas de caída del usuario (RF09), con su estado.
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'ciclista_page.dart' show AppColors;
import 'models.dart';

class AlertasPage extends StatefulWidget {
  const AlertasPage({super.key});

  @override
  State<AlertasPage> createState() => _AlertasPageState();
}

class _AlertasPageState extends State<AlertasPage> {
  List<Alerta>? _alertas;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final lista = await ApiService.instance.listarAlertas(limite: 50);
      if (!mounted) return;
      setState(() {
        _alertas = lista;
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
        title: const Text('Mis alertas', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(child: _cuerpo()),
    );
  }

  Widget _cuerpo() {
    final lista = _alertas;
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

    return RefreshIndicator(
      onRefresh: _cargar,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (lista.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Text(
                'Todavía no tenés alertas.\nSe crean cuando la app detecta una posible caída durante un recorrido.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textOnLight.withOpacity(0.7)),
              ),
            )
          else
            ...lista.map(_tarjeta),
        ],
      ),
    );
  }

  Widget _tarjeta(Alerta alerta) {
    final (icono, color) = switch (alerta.estado) {
      'confirmada' => (Icons.warning_amber_rounded, AppColors.error),
      'falsa_alarma' => (Icons.check_circle_outline, const Color(0xFF2E9E5B)),
      _ => (Icons.hourglass_top, AppColors.accent),
    };
    final ubicacion = (alerta.lat != null && alerta.lng != null)
        ? 'Lat ${alerta.lat!.toStringAsFixed(4)}, Lng ${alerta.lng!.toStringAsFixed(4)}'
        : 'Sin ubicación';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD5DDF2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icono, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alerta.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textOnLight),
                ),
                const SizedBox(height: 2),
                Text(
                  alerta.fecha,
                  style: TextStyle(fontSize: 12, color: AppColors.textOnLight.withOpacity(0.6)),
                ),
                Text(
                  ubicacion,
                  style: TextStyle(fontSize: 12, color: AppColors.textOnLight.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}