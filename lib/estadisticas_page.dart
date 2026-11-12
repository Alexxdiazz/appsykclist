// lib/estadisticas_page.dart
// Estadísticas avanzadas (RF15). Solo para el plan premium:
// en el plan gratis la API responde 403 y esta pantalla muestra el bloqueo con el acceso al paywall.
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'ciclista_page.dart' show AppColors;
import 'models.dart';
import 'paywall_page.dart';

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  Estadisticas? _datos;
  bool _bloqueado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final datos = await ApiService.instance.obtenerEstadisticas();
      if (!mounted) return;
      setState(() {
        _datos = datos;
        _bloqueado = false;
        _error = null;
      });
    } on SesionExpirada {
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    } on PremiumRequerido {
      if (mounted) {
        setState(() {
          _bloqueado = true;
          _datos = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    }
  }

  Future<void> _verPremium() async {
    final cambio = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PaywallPage()),
    );
    if (cambio == true && mounted) {
      setState(() {
        _bloqueado = false;
        _error = null;
      });
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        title: const Text('Actividad', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(child: _cuerpo()),
    );
  }

  Widget _cuerpo() {
    if (_bloqueado) return _vistaBloqueada();
    final datos = _datos;
    if (datos != null) return _vistaDatos(datos);
    if (_error != null) return _vistaError();
    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
  }

  // --------------------------------------------------------------------------
  // Plan gratis: función bloqueada
  // --------------------------------------------------------------------------
  Widget _vistaBloqueada() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.lock, color: AppColors.accent, size: 36),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Estadísticas avanzadas',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textOnLight),
        ),
        const SizedBox(height: 8),
        Text(
          'Conocé tu rendimiento en detalle. Esta función es parte del plan Premium.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textOnLight.withOpacity(0.7)),
        ),
        const SizedBox(height: 24),
        _adelanto(Icons.speed, 'Velocidad media', 'Tu ritmo promedio en km/h'),
        _adelanto(Icons.emoji_events_outlined, 'Tu recorrido más largo', 'Tu mejor marca de distancia'),
        _adelanto(Icons.bar_chart, 'Kilómetros por semana', 'Tu evolución de las últimas 4 semanas'),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _verPremium,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          icon: const Icon(Icons.workspace_premium),
          label: const Text(
            'Desbloquear con Premium',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _adelanto(IconData icono, String titulo, String texto) {
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
          Icon(icono, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textOnLight),
                ),
                const SizedBox(height: 2),
                Text(
                  texto,
                  style: TextStyle(fontSize: 12, color: AppColors.textOnLight.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline, size: 20, color: AppColors.textOnLight.withOpacity(0.4)),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Plan premium: datos
  // --------------------------------------------------------------------------
  Widget _vistaDatos(Estadisticas d) {
    return RefreshIndicator(
      onRefresh: _cargar,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Tu actividad total',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textOnLight),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard(Icons.route_outlined, 'Distancia total', '${d.totalKm.toStringAsFixed(1)} km')),
              const SizedBox(width: 12),
              Expanded(child: _statCard(Icons.access_time, 'Tiempo total', formatearMinutos(d.totalMin))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard(Icons.pedal_bike, 'Recorridos', '${d.recorridos}')),
              const SizedBox(width: 12),
              Expanded(child: _statCard(Icons.speed, 'Velocidad media', '${d.velocidadMedia.toStringAsFixed(1)} km/h')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard(Icons.timeline, 'Promedio por recorrido', '${d.promedioKm.toStringAsFixed(1)} km')),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  Icons.emoji_events_outlined,
                  'Más largo',
                  d.mejorTitulo == null ? '—' : '${d.mejorKm.toStringAsFixed(1)} km',
                  detalle: d.mejorTitulo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _grafico(d.semanas),
        ],
      ),
    );
  }

  Widget _statCard(IconData icono, String etiqueta, String valor, {String? detalle}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.textOnDark.withOpacity(0.7)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textOnDark),
            ),
          ),
          if (detalle != null)
            Text(
              detalle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AppColors.textOnDark.withOpacity(0.6)),
            ),
        ],
      ),
    );
  }

  Widget _grafico(List<SemanaKm> semanas) {
    const alturaMaxima = 110.0;
    final maximo = semanas.fold<double>(0, (m, s) => s.km > m ? s.km : m);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kilómetros por semana',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: alturaMaxima + 70,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final semana in semanas)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          semana.km.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, color: AppColors.textOnDark),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: maximo > 0 ? (semana.km / maximo * alturaMaxima).clamp(4.0, alturaMaxima).toDouble() : 4.0,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          semana.etiqueta,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: AppColors.textOnDark.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vistaError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textOnLight),
            ),
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
}