import 'package:flutter/material.dart';
import 'ciclista_page.dart' show AppColors, CiclistaPage;

class ResumenSemanal {
  final double distanciaKm;
  final int tiempoMin;
  final int recorridos;

  const ResumenSemanal({
    required this.distanciaKm,
    required this.tiempoMin,
    required this.recorridos,
  });
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
}

const _usuarioMock = 'Alexis';

const _resumenMock = ResumenSemanal(
  distanciaKm: 42.6,
  tiempoMin: 168,
  recorridos: 6,
);

const _recorridosMock = [
  RecorridoReciente(titulo: 'Vuelta por el parque', fecha: 'Hoy, 07:40', distanciaKm: 8.2, tiempoMin: 28),
  RecorridoReciente(titulo: 'Ida al trabajo', fecha: 'Ayer, 08:15', distanciaKm: 6.4, tiempoMin: 22),
  RecorridoReciente(titulo: 'Ruta de la costa', fecha: 'Lun, 18:30', distanciaKm: 15.1, tiempoMin: 51),
  RecorridoReciente(titulo: 'Vuelta corta', fecha: 'Dom, 10:05', distanciaKm: 4.3, tiempoMin: 15),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0; 

  void _irARuta() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CiclistaPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.pedal_bike, color: AppColors.accent),
            const SizedBox(width: 8),
            const Text('Syklist', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent,
              child: Text('A', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildSaludo(),
            const SizedBox(height: 16),
            _buildResumenSemanal(_resumenMock),
            const SizedBox(height: 16),
            _buildBotonIniciarRecorrido(),
            const SizedBox(height: 24),
            _buildEncabezadoHistorial(),
            const SizedBox(height: 8),
            ..._recorridosMock.map(_buildRecorridoCard),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSaludo() {
    return Text(
      'Hola, $_usuarioMock 👋',
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textOnLight),
    );
  }

  Widget _buildResumenSemanal(ResumenSemanal resumen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Esta semana',
            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statResumen('${resumen.distanciaKm.toStringAsFixed(1)} km', 'Distancia'),
              _statResumen('${resumen.tiempoMin} min', 'Tiempo'),
              _statResumen('${resumen.recorridos}', 'Recorridos'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statResumen(String valor, String etiqueta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: const TextStyle(color: AppColors.textOnDark, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          etiqueta,
          style: TextStyle(color: AppColors.textOnDark.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBotonIniciarRecorrido() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _irARuta,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        icon: const Icon(Icons.navigation),
        label: const Text(
          'Iniciar recorrido',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEncabezadoHistorial() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recorridos recientes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textOnLight),
        ),
        TextButton(
          onPressed: () => setState(() => _navIndex = 3), // "Historial"
          style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
          child: const Text('Ver todos'),
        ),
      ],
    );
  }

  Widget _buildRecorridoCard(RecorridoReciente recorrido) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.pedal_bike, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recorrido.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textOnDark),
                ),
                const SizedBox(height: 2),
                Text(
                  recorrido.fecha,
                  style: TextStyle(fontSize: 12, color: AppColors.textOnDark.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${recorrido.distanciaKm.toStringAsFixed(1)} km',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textOnDark),
              ),
              Text(
                '${recorrido.tiempoMin} min',
                style: TextStyle(fontSize: 12, color: AppColors.textOnDark.withOpacity(0.6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      (Icons.home, 'Inicio'),
      (Icons.location_on_outlined, 'Ruta'),
      (Icons.bar_chart, 'Actividad'),
      (Icons.history, 'Historial'),
      (Icons.person_outline, 'Perfil'),
    ];

    return BottomNavigationBar(
      currentIndex: _navIndex,
      onTap: (i) {
        setState(() => _navIndex = i);
        if (i == 1) _irARuta(); 
      },
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.primary,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      items: items
          .map((item) => BottomNavigationBarItem(icon: Icon(item.$1), label: item.$2))
          .toList(),
    );
  }
}