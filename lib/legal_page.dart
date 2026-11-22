// lib/legal_page.dart
// Muestra un documento legal (Términos de uso o Política de Privacidad) en pantalla completa.
import 'package:flutter/material.dart';

import 'ciclista_page.dart' show AppColors;
import 'legal_content.dart';

class LegalPage extends StatelessWidget {
  final String titulo;
  final List<SeccionLegal> secciones;

  const LegalPage({super.key, required this.titulo, required this.secciones});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              'Versión $versionTerminos · Última actualización: $fechaTerminos',
              style: TextStyle(fontSize: 12, color: AppColors.textOnLight.withOpacity(0.6)),
            ),
            const SizedBox(height: 16),
            for (final seccion in secciones) ..._seccion(seccion),
          ],
        ),
      ),
    );
  }

  List<Widget> _seccion(SeccionLegal seccion) {
    return [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(
          seccion.titulo,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textOnLight),
        ),
      ),
      for (final parrafo in seccion.parrafos) _parrafo(parrafo),
    ];
  }

  Widget _parrafo(String texto) {
    final esItem = texto.startsWith('• ');
    return Padding(
      padding: EdgeInsets.only(bottom: 8, left: esItem ? 12 : 0),
      child: Text(
        texto,
        style: TextStyle(fontSize: 14.5, height: 1.5, color: AppColors.textOnLight.withOpacity(0.85)),
      ),
    );
  }
}