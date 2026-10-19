// lib/models.dart
// Modelos de datos que llegan desde la API (Vercel → Supabase).

double _aDouble(dynamic valor) {
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor.toString()) ?? 0;
}

class Perfil {
  final String id;
  final String nombre;
  final String plan;

  const Perfil({required this.id, required this.nombre, required this.plan});

  factory Perfil.fromJson(Map<String, dynamic> json) => Perfil(
        id: json['id'] as String,
        nombre: (json['nombre'] as String?) ?? 'Ciclista',
        plan: (json['plan'] as String?) ?? 'gratis',
      );
}

class ResumenSemanal {
  final double distanciaKm;
  final int tiempoMin;
  final int recorridos;

  const ResumenSemanal({
    required this.distanciaKm,
    required this.tiempoMin,
    required this.recorridos,
  });

  factory ResumenSemanal.fromJson(Map<String, dynamic> json) => ResumenSemanal(
        distanciaKm: _aDouble(json['distancia_km']),
        tiempoMin: _aDouble(json['tiempo_min']).round(),
        recorridos: _aDouble(json['recorridos']).round(),
      );
}

class RecorridoReciente {
  final String titulo;
  final String fecha;
  final double distanciaKm;
  final int tiempoMin;

  const RecorridoReciente({
    required this.titulo,
    required this.fecha,
    required this.distanciaKm,
    required this.tiempoMin,
  });

  factory RecorridoReciente.fromJson(Map<String, dynamic> json) {
    final inicio = DateTime.tryParse(json['iniciado_en'].toString());
    return RecorridoReciente(
      titulo: (json['titulo'] as String?) ?? 'Recorrido',
      fecha: inicio == null ? '' : formatearFecha(inicio),
      distanciaKm: _aDouble(json['distancia_m']) / 1000,
      tiempoMin: (_aDouble(json['duracion_s']) / 60).round(),
    );
  }
}

/// "Hoy, 07:40" / "Ayer, 08:15" / "Lun, 18:30" / "03/04, 10:05"
String formatearFecha(DateTime fecha) {
  final f = fecha.toLocal();
  final ahora = DateTime.now();
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final dia = DateTime(f.year, f.month, f.day);
  final diferencia = hoy.difference(dia).inDays;

  final hora = '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
  const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  if (diferencia == 0) return 'Hoy, $hora';
  if (diferencia == 1) return 'Ayer, $hora';
  if (diferencia > 1 && diferencia < 7) return '${dias[f.weekday - 1]}, $hora';
  return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}, $hora';
}

/// 125 segundos → "02:05"   |   3725 segundos → "1:02:05"
String formatearDuracion(int segundos) {
  final h = segundos ~/ 3600;
  final m = (segundos % 3600) ~/ 60;
  final s = segundos % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}