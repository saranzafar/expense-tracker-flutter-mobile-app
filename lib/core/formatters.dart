import 'package:intl/intl.dart';

import 'currency.dart';

final _date = DateFormat('d MMM yyyy');
final _dayHeader = DateFormat('EEE, d MMM');
final _shortDate = DateFormat('d MMM');

String formatMoneyWith(int minor, CurrencyOption c) => formatMoney(minor, c);

String formatMoneySignedWith(int minor, CurrencyOption c,
        {required bool negative}) =>
    formatMoneySigned(minor, c, negative: negative);

String formatDate(DateTime d) => _date.format(d);
String formatDayHeader(DateTime d) => _dayHeader.format(d);
String formatShortDate(DateTime d) => _shortDate.format(d);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
