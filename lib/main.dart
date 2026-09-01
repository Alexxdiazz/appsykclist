import 'package:flutter/material.dart';
import 'ciclista_page.dart';

void main() {
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
      home: const CiclistaPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}