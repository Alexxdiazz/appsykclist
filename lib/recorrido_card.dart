// lib/recorrido_card.dart
// Tarjeta de un recorrido. La usan la Home y el Historial.
import 'package:flutter/material.dart';

import 'ciclista_page.dart' show AppColors;
import 'models.dart';

class RecorridoCard extends StatelessWidget {
  final RecorridoReciente recorrido;

  const RecorridoCard({super.key, required this.recorrido});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.pedal_bike, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recorrido.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
}