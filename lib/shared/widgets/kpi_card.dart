import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Tarjeta KPI con barra de acento inferior (.kpi-card de la web).
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
    this.sub,
  });

  final String label;
  final String value;
  final Color accent;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.darkMuted,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      height: 1,
                    ),
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 4),
                  Text(sub!,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.darkMuted)),
                ],
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(height: 3, color: accent),
          ),
        ],
      ),
    );
  }
}
