import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'api_service.dart';
import 'home_page.dart';
import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. INICIALIZAR SUPABASE AQUÍ
  await Supabase.initialize(
    url: 'https://edmpkuvrmxtedwezdzj.supabase.co',
    anonKey: 'sb_publishable_XZPLkx2zJ8d1_hyWZo_HUA_Uy-BJJ1o',
  );

  // 2. Ahora sí, recuperar la sesión
  await ApiService.instance.cargarSesion(); 
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Ciclistas',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF2C3E7A),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2C3E7A),
          secondary: Color(0xFF4A90D9),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: ApiService.instance.haySesion ? const HomePage() : const LoginPage(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}