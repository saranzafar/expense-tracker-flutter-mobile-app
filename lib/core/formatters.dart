import 'package:intl/intl.dart';

final _pkr = NumberFormat.currency(
  locale: 'en_PK',
  symbol: 'Rs ',
  decimalDigits: 0,
);
final _date = DateFormat('d MMM yyyy');
final _dayHeader = DateFormat('EEE, d MMM');
final _shortDate = DateFormat('d MMM');

String formatPkr(int minor) => _pkr.format(minor / 100);

String formatPkrSigned(int minor, {required bool negative}) {
  final s = formatPkr(minor.abs());
  return negative ? '− $s' : '+ $s';
}

String formatDate(DateTime d) => _date.format(d);
String formatDayHeader(DateTime d) => _dayHeader.format(d);
String formatShortDate(DateTime d) => _shortDate.format(d);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
