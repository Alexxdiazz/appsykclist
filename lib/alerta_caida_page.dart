// lib/alerta_caida_page.dart
// Pantalla de confirmación que aparece cuando se detecta una posible caída (RF09).
// Cuenta regresiva: si la persona no responde, la alerta se da por confirmada.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ciclista_page.dart' show AppColors;

enum ResultadoAlerta { estoyBien, necesitaAyuda, sinRespuesta }

class AlertaCaidaPage extends StatefulWidget {
  final int segundosDeEspera;

  const AlertaCaidaPage({super.key, this.segundosDeEspera = 15});

  @override
  State<AlertaCaidaPage> createState() => _AlertaCaidaPageState();
}

class _AlertaCaidaPageState extends State<AlertaCaidaPage> {
  late int _restantes;
  Timer? _timer;
  bool _cerrada = false;

  @override
  void initState() {
    super.initState();
    _restantes = widget.segundosDeEspera;
    _avisar();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _restantes--);
      if (_restantes <= 0) {
        _cerrar(ResultadoAlerta.sinRespuesta);
      } else {
        _avisar();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Vibración y sonido del sistema (en la web y en algunos equipos no hacen nada).
  void _avisar() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  void _cerrar(ResultadoAlerta resultado) {
    if (_cerrada) return;
    _cerrada = true;
    _timer?.cancel();
    if (mounted) Navigator.of(context).pop(resultado);
  }

  @override
  Widget build(BuildContext context) {
    final progreso = (_restantes.clamp(0, widget.segundosDeEspera) / widget.segundosDeEspera).toDouble();

    return Scaffold(
      backgroundColor: AppColors.error,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 88, color: Colors.white),
              const SizedBox(height: 12),
              const Text(
                '¿Te caíste?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Detectamos un golpe fuerte.\nSi no respondés, se registrará una alerta de caída.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, height: 1.4, color: Colors.white),
              ),
              const SizedBox(height: 28),
              Center(
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: CircularProgressIndicator(
                          value: progreso,
                          strokeWidth: 10,
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      Text(
                        '$_restantes',
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _cerrar(ResultadoAlerta.estoyBien),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF8E1B12),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('ESTOY BIEN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _cerrar(ResultadoAlerta.necesitaAyuda),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('NECESITO AYUDA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 20),
              const Text(
                'En una emergencia, llamá a los servicios de emergencia de tu zona.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}