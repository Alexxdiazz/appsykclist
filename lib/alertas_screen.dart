import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Añade intl a tu pubspec.yaml

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _alertas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlertas();
  }

  Future<void> _fetchAlertas() async {
    try {
      // Consulta con JOIN a perfiles y recorridos
      final response = await supabase
          .from('alertas_caida')
          .select('*, perfiles(nombre, plan), recorridos(titulo)')
          .order('detectada_en', ascending: false);

      setState(() {
        _alertas = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar alertas: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Alertas de Caída')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alertas.isEmpty
              ? const Center(child: Text('No hay alertas registradas'))
              : ListView.builder(
                  itemCount: _alertas.length,
                  itemBuilder: (context, index) {
                    final alerta = _alertas[index];
                    final fecha = DateTime.parse(alerta['detectada_en']);
                    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm').format(fecha);
                    final estado = alerta['estado'] ?? 'pendiente';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          Icons.warning_amber_rounded,
                          color: estado == 'pendiente' ? Colors.orange : Colors.green,
                        ),
                        title: Text(
                          'Usuario: ${alerta['perfiles']?['nombre'] ?? 'Desconocido'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Recorrido: ${alerta['recorridos']?['titulo'] ?? 'N/A'}'),
                            Text('Fecha: $formatoFecha'),
                            Text('Ubicación: Lat ${alerta['lat']}, Lng ${alerta['lng']}'),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: estado == 'pendiente' ? Colors.orange.shade100 : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            estado.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: estado == 'pendiente' ? Colors.orange.shade900 : Colors.green.shade900,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}