enum ChartPeriod { week, month, year }

class ChartPoint {
  final DateTime date;
  final double income;
  final double expense;
  const ChartPoint({
    required this.date,
    required this.income,
    required this.expense,
  });
}
