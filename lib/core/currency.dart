import 'package:intl/intl.dart';

class CurrencyOption {
  final String code;
  final String symbol;
  final String name;
  final String flag;
  final int decimals;
  final String locale;

  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
    required this.decimals,
    required this.locale,
  });
}

const kCurrencies = <CurrencyOption>[
  CurrencyOption(
      code: 'PKR',
      symbol: 'Rs',
      name: 'Pakistani Rupee',
      flag: '🇵🇰',
      decimals: 0,
      locale: 'en_PK'),
  CurrencyOption(
      code: 'USD',
      symbol: '\$',
      name: 'US Dollar',
      flag: '🇺🇸',
      decimals: 2,
      locale: 'en_US'),
  CurrencyOption(
      code: 'EUR',
      symbol: '€',
      name: 'Euro',
      flag: '🇪🇺',
      decimals: 2,
      locale: 'en_IE'),
  CurrencyOption(
      code: 'GBP',
      symbol: '£',
      name: 'British Pound',
      flag: '🇬🇧',
      decimals: 2,
      locale: 'en_GB'),
  CurrencyOption(
      code: 'INR',
      symbol: '₹',
      name: 'Indian Rupee',
      flag: '🇮🇳',
      decimals: 0,
      locale: 'en_IN'),
  CurrencyOption(
      code: 'AED',
      symbol: 'AED',
      name: 'UAE Dirham',
      flag: '🇦🇪',
      decimals: 2,
      locale: 'en_AE'),
  CurrencyOption(
      code: 'SAR',
      symbol: 'SAR',
      name: 'Saudi Riyal',
      flag: '🇸🇦',
      decimals: 2,
      locale: 'en_SA'),
  CurrencyOption(
      code: 'CAD',
      symbol: 'CA\$',
      name: 'Canadian Dollar',
      flag: '🇨🇦',
      decimals: 2,
      locale: 'en_CA'),
  CurrencyOption(
      code: 'AUD',
      symbol: 'A\$',
      name: 'Australian Dollar',
      flag: '🇦🇺',
      decimals: 2,
      locale: 'en_AU'),
  CurrencyOption(
      code: 'JPY',
      symbol: '¥',
      name: 'Japanese Yen',
      flag: '🇯🇵',
      decimals: 0,
      locale: 'ja_JP'),
];

CurrencyOption currencyByCode(String code) =>
    kCurrencies.firstWhere((c) => c.code == code, orElse: () => kCurrencies[0]);

String formatMoney(int minor, CurrencyOption c) {
  final value = minor / (c.decimals == 0 ? 100 : 100);
  final f = NumberFormat.currency(
    locale: c.locale,
    symbol: '${c.symbol} ',
    decimalDigits: c.decimals,
  );
  return f.format(value);
}

String formatMoneySigned(int minor, CurrencyOption c,
    {required bool negative}) {
  final s = formatMoney(minor.abs(), c);
  return negative ? '− $s' : '+ $s';
}
