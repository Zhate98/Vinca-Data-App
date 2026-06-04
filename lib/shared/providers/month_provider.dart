import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mes/año seleccionado en el navegador temporal (topbar de la web).
class SelectedMonth {
  final int month;
  final int year;
  const SelectedMonth(this.month, this.year);

  SelectedMonth get prev =>
      month == 1 ? SelectedMonth(12, year - 1) : SelectedMonth(month - 1, year);
  SelectedMonth get next =>
      month == 12 ? SelectedMonth(1, year + 1) : SelectedMonth(month + 1, year);
}

class MonthNotifier extends StateNotifier<SelectedMonth> {
  MonthNotifier()
      : super(SelectedMonth(DateTime.now().month, DateTime.now().year));

  void prev() => state = state.prev;
  void next() => state = state.next;
  void today() =>
      state = SelectedMonth(DateTime.now().month, DateTime.now().year);
}

final selectedMonthProvider =
    StateNotifierProvider<MonthNotifier, SelectedMonth>((ref) {
  return MonthNotifier();
});
