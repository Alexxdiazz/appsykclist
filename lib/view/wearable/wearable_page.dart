import 'dart:async';
import 'package:flutter/material.dart';
import '../../ciclista_page.dart' show AppColors;

enum _Fase { listo, cuenta, enCurso, pausado, terminado }

class WearablePage extends StatefulWidget {
  const WearablePage({super.key});

  @override
  State<WearablePage> createState() => _WearablePageState();
}

class _WearablePageState extends State<WearablePage> {
  static const double _lado = 250; 
  static const double _kmPorSegundo = 0.005;
  static const Color _acento = AppColors.accent;

  Timer? _timer;
  _Fase _fase = _Fase.listo;
  int _cuenta = 3;
  int _segundos = 0;

  double get _km => _segundos * _kmPorSegundo;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciar() {
    _timer?.cancel();
    setState(() {
      _fase = _Fase.cuenta;
      _cuenta = 3;
      _segundos = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_fase == _Fase.cuenta) {
          _cuenta--;
          if (_cuenta <= 0) _fase = _Fase.enCurso;
        } else if (_fase == _Fase.enCurso) {
          _segundos++;
        }
      });
    });
  }

  void _pausar() => setState(() => _fase = _Fase.pausado);

  void _seguir() => setState(() => _fase = _Fase.enCurso);

  void _finalizar() {
    _timer?.cancel();
    setState(() => _fase = _Fase.terminado);
  }

  void _nuevo() => setState(() {
        _fase = _Fase.listo;
        _segundos = 0;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ClipOval(
                child: Container(
                  width: _lado,
                  height: _lado,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF3A3A3C), width: 3),
                  ),
                  child: _contenido(),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF8E8E93)),
                tooltip: 'Volver a la app',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contenido() {
    return switch (_fase) {
      _Fase.listo => _vistaListo(),
      _Fase.cuenta => _vistaCuenta(),
      _Fase.enCurso => _vistaResumen(
          etiqueta: 'EN RECORRIDO',
          colorEtiqueta: _acento,
          acciones: _botonPildora('PAUSAR', _pausar),
        ),
      _Fase.pausado => _vistaResumen(
          etiqueta: 'PAUSADO',
          colorEtiqueta: Colors.white,
          acciones: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _botonPildora('SEGUIR', _seguir, ancho: 76),
              const SizedBox(width: 8),
              _botonPildora('FIN', _finalizar, ancho: 76, relleno: false),
            ],
          ),
        ),
      _Fase.terminado => _vistaResumen(
          etiqueta: '¡LISTO!',
          colorEtiqueta: _acento,
          acciones: _botonPildora('NUEVO', _nuevo),
        ),
    };
  }

  Widget _vistaListo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _etiqueta('SYKLIST', _acento),
        const SizedBox(height: 10),
        SizedBox(
          width: 150,
          height: 150,
          child: ElevatedButton(
            onPressed: _iniciar,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: _acento,
              foregroundColor: Colors.black,
              padding: EdgeInsets.zero,
              elevation: 0,
            ),
            child: const Text(
              'INICIAR',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _vistaCuenta() {
    return Text(
      '$_cuenta',
      style: const TextStyle(color: Colors.white, fontSize: 130, fontWeight: FontWeight.w800),
    );
  }

  Widget _vistaResumen({
    required String etiqueta,
    required Color colorEtiqueta,
    required Widget acciones,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _etiqueta(etiqueta, colorEtiqueta),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _formatoTiempo(_segundos),
            style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          '${_km.toStringAsFixed(2)} km',
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        acciones,
      ],
    );
  }

  Widget _etiqueta(String texto, Color color) {
    return Text(
      texto,
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2),
    );
  }

  Widget _botonPildora(String texto, VoidCallback alTocar, {double ancho = 150, bool relleno = true}) {
    const estiloTexto = TextStyle(fontSize: 18, fontWeight: FontWeight.w800);
    return SizedBox(
      width: ancho,
      height: 46,
      child: relleno
          ? ElevatedButton(
              onPressed: alTocar,
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                backgroundColor: _acento,
                foregroundColor: Colors.black,
                padding: EdgeInsets.zero,
                elevation: 0,
              ),
              child: Text(texto, style: estiloTexto),
            )
          : OutlinedButton(
              onPressed: alTocar,
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                side: const BorderSide(color: Colors.white, width: 2),
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
              ),
              child: Text(texto, style: estiloTexto),
            ),
    );
  }

  String _formatoTiempo(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final seg = s % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = seg.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }
}