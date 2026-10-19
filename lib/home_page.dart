import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Cambiamos el nombre de la clase
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState(); // 2. Cambiamos el estado
}

// 3. Cambiamos el nombre del estado
class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _recorridos = [];
  List<Map<String, dynamic>> _alertas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final recorridosRes = await supabase
          .from('recorridos')
          .select()
          .eq('estado', 'activo')
          .limit(5);

      final alertasRes = await supabase
          .from('alertas_caida')
          .select('*, perfiles(nombre)')
          .order('detectada_en', ascending: false)
          .limit(3);

      setState(() {
        _recorridos = List<Map<String, dynamic>>.from(recorridosRes);
        _alertas = List<Map<String, dynamic>>.from(alertasRes);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Control')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Recorridos Activos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ..._recorridos.map((r) => ListTile(
            leading: const Icon(Icons.route),
            title: Text(r['titulo'] ?? 'Sin título'),
            subtitle: Text('Estado: ${r['estado']}'),
          )),
          const Divider(),
          const Text('Últimas Alertas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ..._alertas.map((a) => ListTile(
            leading: const Icon(Icons.warning, color: Colors.red),
            title: Text('Alerta de: ${a['perfiles']?['nombre'] ?? 'Desconocido'}'),
            subtitle: Text('Ubicación: ${a['lat']}, ${a['lng']}'),
          )),
        ],
      ),
    );
  }
}