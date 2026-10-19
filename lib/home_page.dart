// lib/home_page.dart
// Pantalla de inicio: datos reales traídos de la API (Vercel → Supabase).
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'ciclista_page.dart' show AppColors, CiclistaPage;
import 'historial_page.dart';
import 'models.dart';
import 'recorrido_card.dart';
import 'recorrido_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _api = ApiService.instance;

  Perfil? _perfil;
  ResumenSemanal? _resumen;
  List<RecorridoReciente> _recientes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // --------------------------------------------------------------------------
  // Datos
  // --------------------------------------------------------------------------
  Future<void> _cargar() async {
    try {
      final r = await Future.wait<dynamic>([
        _api.obtenerPerfil(),
        _api.obtenerResumen(),
        _api.listarRecorridos(limite: 4),
      ]);
      if (!mounted) return;
      setState(() {
        _perfil = r[0] as Perfil;
        _resumen = r[1] as ResumenSemanal;
        _recientes = r[2] as List<RecorridoReciente>;
        _error = null;
      });
    } on SesionExpirada {
      _irALogin();
    } on ApiException catch (e) {
      _mostrarError(e.mensaje);
    } catch (_) {
      _mostrarError('Respuesta inesperada del servidor.');
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    if (_perfil == null) {
      setState(() => _error = mensaje);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  void _irALogin() {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
  }

  Future<void> _cerrarSesion() async {
    await _api.cerrarSesion();
    _irALogin();
  }

  void _reintentar() {
    setState(() => _error = null);
    _cargar();
  }

  // --------------------------------------------------------------------------
  // Navegación
  // --------------------------------------------------------------------------
  Future<void> _iniciarRecorrido() async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RecorridoPage()),
    );
    if (guardado == true) _cargar(); // actualiza resumen y recientes
  }

  void _verHistorial() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistorialPage()));
  }

  void _alTocarNav(int indice) {
    if (indice == 1) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CiclistaPage()));
    } else if (indice == 3) {
      _verHistorial();
    } else if (indice != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Próximamente')),
      );
    }
  }

  // --------------------------------------------------------------------------
  // Pantalla
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.pedal_bike, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Ciclista App', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [_buildMenuUsuario()],
      ),
      body: SafeArea(child: _buildCuerpo()),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCuerpo() {
    final perfil = _perfil;
    if (perfil == null) {
      if (_error != null) return _buildError();
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildSaludo(perfil.nombre),
          const SizedBox(height: 16),
          _buildResumenSemanal(
            _resumen ?? const ResumenSemanal(distanciaKm: 0, tiempoMin: 0, recorridos: 0),
          ),
          const SizedBox(height: 16),
          _buildBotonIniciarRecorrido(),
          const SizedBox(height: 24),
          _buildEncabezadoHistorial(),
          const SizedBox(height: 8),
          if (_recientes.isEmpty)
            _buildSinRecorridos()
          else
            ..._recientes.map((r) => RecorridoCard(recorrido: r)),
        ],
      ),
    );
  }

  Widget _buildError() {
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
              onPressed: _reintentar,
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

  Widget _buildMenuUsuario() {
    final nombre = _perfil?.nombre ?? '';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    return PopupMenuButton<String>(
      onSelected: (valor) {
        if (valor == 'salir') _cerrarSesion();
      },
      itemBuilder: (_) => const [
        PopupMenuItem<String>(value: 'salir', child: Text('Cerrar sesión')),
      ],
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.accent,
          child: Text(
            inicial,
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSaludo(String nombre) {
    return Text(
      'Hola, $nombre 👋',
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
        onPressed: _iniciarRecorrido,
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
          onPressed: _verHistorial,
          style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
          child: const Text('Ver todos'),
        ),
      ],
    );
  }

  Widget _buildSinRecorridos() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Todavía no tenés recorridos.\nTocá "Iniciar recorrido" para registrar el primero.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textOnLight.withOpacity(0.7)),
      ),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      (Icons.home, 'Inicio'),
      (Icons.location_on_outlined, 'Ruta'),
      (Icons.bar_chart, 'Actividad'),
      (Icons.history, 'Historial'),
      (Icons.person_outline, 'Perfil'),
    ];

    return BottomNavigationBar(
      currentIndex: 0,
      onTap: _alTocarNav,
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