import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../providers/month_provider.dart';

/// Navegador de mes (◀ Mes Año ▶ + Hoy) equivalente al topbar de la web.
class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(selectedMonthProvider);
    final notifier = ref.read(selectedMonthProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: notifier.prev,
          icon: const Icon(Icons.chevron_left),
          visualDensity: VisualDensity.compact,
        ),
        Text(
          Fmt.mesLabel(m.month, m.year),
          style: const TextStyle(
              color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 13),
        ),
        IconButton(
          onPressed: notifier.next,
          icon: const Icon(Icons.chevron_right),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: notifier.today,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: AppColors.darkBg,
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            textStyle:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          child: const Text('Hoy'),
        ),
      ],
    );
  }
}
