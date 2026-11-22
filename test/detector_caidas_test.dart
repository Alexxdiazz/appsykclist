import 'dart:math' as math;
import 'package:appsykclist/detector_caidas.dart';
import 'package:flutter_test/flutter_test.dart';

const int paso = 20; // ms entre lecturas (≈ 50 Hz)
final DateTime base = DateTime(2026, 11, 15, 10);

double pedaleo(int i) => 1.0 + 0.35 * math.sin(i * 0.9); // vibración de pedalear
double quieto(int i) => 1.0 + 0.02 * math.sin(i * 1.7); // teléfono inmóvil
double tumbo(int i) => i % 2 == 0 ? 0.4 : 2.0; // rodando tras el golpe

class Tramo {
  final int hasta;
  final double Function(int) f;
  const Tramo(this.hasta, this.f);
}

Tramo golpe(int desde, double g) => Tramo(desde + paso, (_) => g);

/// Devuelve los instantes (en ms) en que se detectó una caída.
List<int> correr(List<Tramo> tramos, [DetectorCaidas? detector]) {
  final d = detector ?? DetectorCaidas();
  final detecciones = <int>[];
  var t = 0;
  for (final tramo in tramos) {
    var i = 0;
    while (t < tramo.hasta) {
      if (d.procesar(tramo.f(i), base.add(Duration(milliseconds: t)))) detecciones.add(t);
      t += paso;
      i++;
    }
  }
  return detecciones;
}

void main() {
  test('pedalear 60 s no genera alertas', () {
    expect(correr([Tramo(60000, pedaleo)]), isEmpty);
  });

  test('caída real: golpe, tumbo y quietud → se detecta una sola vez, ~1,5 s después de quedar quieto', () {
    final d = correr([Tramo(10000, pedaleo), golpe(10000, 4.0), Tramo(10400, tumbo), Tramo(16000, quieto)]);
    expect(d.length, 1);
    expect(d.first, inInclusiveRange(11800, 12100));
  });

  test('bache: golpe de 3,5 g y se sigue pedaleando → no hay alerta', () {
    expect(correr([Tramo(10000, pedaleo), golpe(10000, 3.5), Tramo(40000, pedaleo)]), isEmpty);
  });

  test('frenada fuerte (1,8 g) no cuenta como golpe, aunque después quede quieto', () {
    expect(correr([Tramo(5000, pedaleo), Tramo(5200, (_) => 1.8), Tramo(8000, quieto)]), isEmpty);
  });

  test('golpe y solo 1 s de quietud, luego vuelve a moverse → no hay alerta', () {
    expect(
      correr([Tramo(10000, pedaleo), golpe(10000, 3.2), Tramo(11000, quieto), Tramo(30000, pedaleo)]),
      isEmpty,
    );
  });

  test('quietud recién 7 s después del golpe (fuera de la ventana) → no hay alerta', () {
    expect(
      correr([Tramo(10000, pedaleo), golpe(10000, 3.2), Tramo(17000, pedaleo), Tramo(25000, quieto)]),
      isEmpty,
    );
  });

  test('si sigue quieto no vuelve a disparar sin un nuevo golpe', () {
    final d = correr([Tramo(10000, pedaleo), golpe(10000, 4.0), Tramo(10400, tumbo), Tramo(60000, quieto)]);
    expect(d.length, 1);
  });

  test('dos golpes seguidos → una sola caída', () {
    final d = correr([
      Tramo(10000, pedaleo),
      golpe(10000, 4.0),
      Tramo(11000, quieto),
      golpe(11000, 3.9),
      Tramo(20000, quieto),
    ]);
    expect(d.length, 1);
  });

  test('el umbral exacto (2,8 g) cuenta; 2,79 g no', () {
    expect(correr([Tramo(1000, quieto), golpe(1000, 2.8), Tramo(6000, quieto)]).length, 1);
    expect(correr([Tramo(1000, quieto), golpe(1000, 2.79), Tramo(6000, quieto)]), isEmpty);
  });

  test('reiniciar() cancela una espera en curso', () {
    final d = DetectorCaidas();
    d.procesar(4.0, base);
    d.reiniciar();
    expect(d.esperandoQuietud, isFalse);
    var disparo = false;
    for (var t = paso; t < 5000; t += paso) {
      disparo = disparo || d.procesar(quieto(t ~/ paso), base.add(Duration(milliseconds: t)));
    }
    expect(disparo, isFalse);
  });
}