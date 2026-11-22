class DetectorCaidas {
  DetectorCaidas({
    this.umbralImpactoG = 2.8,
    this.toleranciaQuietudG = 0.2,
    this.ventanaQuietud = const Duration(milliseconds: 1500),
    this.ventanaEvaluacion = const Duration(seconds: 6),
  });

  /// Aceleración total (en g) a partir de la cual una lectura cuenta como golpe.
  final double umbralImpactoG;

  /// Cuánto puede alejarse de 1 g una lectura para considerarse "quieto".
  final double toleranciaQuietudG;

  /// Tiempo seguido de quietud, después del golpe, para confirmar la posible caída.
  final Duration ventanaQuietud;

  /// Tiempo máximo, desde el golpe, para que aparezca esa quietud.
  final Duration ventanaEvaluacion;

  DateTime? _momentoImpacto;
  DateTime? _quietoDesde;

  /// true si hubo un golpe y se está esperando ver si la persona queda quieta.
  bool get esperandoQuietud => _momentoImpacto != null;

  /// Descarta cualquier espera en curso (por ejemplo, después de resolver una alerta).
  void reiniciar() {
    _momentoImpacto = null;
    _quietoDesde = null;
  }

  /// Procesa una lectura: [magnitudG] es la aceleración total en g (1,0 = teléfono quieto).
  /// Devuelve true cuando se detecta una posible caída.
  bool procesar(double magnitudG, DateTime ahora) {
    if (magnitudG >= umbralImpactoG) {
      _momentoImpacto = ahora; // un golpe nuevo reinicia la espera
      _quietoDesde = null;
      return false;
    }

    final impacto = _momentoImpacto;
    if (impacto == null) return false;

    if (ahora.difference(impacto) > ventanaEvaluacion) {
      reiniciar(); // hubo un golpe, pero la persona siguió moviéndose: no fue una caída
      return false;
    }

    if ((magnitudG - 1.0).abs() <= toleranciaQuietudG) {
      _quietoDesde ??= ahora;
      if (ahora.difference(_quietoDesde!) >= ventanaQuietud) {
        reiniciar();
        return true;
      }
    } else {
      _quietoDesde = null; // volvió a moverse: la quietud tiene que ser continua
    }
    return false;
  }
}