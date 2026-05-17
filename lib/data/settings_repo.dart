import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/currency.dart';

const _kThemeMode = 'theme_mode';
const _kCurrencyCode = 'currency_code';
const _kDisplayName = 'display_name';

class SettingsRepo {
  Future<ThemeMode> readThemeMode() async {
    final p = await SharedPreferences.getInstance();
    return _parseThemeMode(p.getString(_kThemeMode));
  }

  Future<void> writeThemeMode(ThemeMode mode) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kThemeMode, _encodeThemeMode(mode));
  }

  Future<CurrencyOption> readCurrency() async {
    final p = await SharedPreferences.getInstance();
    return currencyByCode(p.getString(_kCurrencyCode) ?? 'PKR');
  }

  Future<void> writeCurrency(String code) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCurrencyCode, code);
  }

  Future<String> readDisplayName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kDisplayName) ?? '';
  }

  Future<void> writeDisplayName(String name) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kDisplayName, name);
  }
}

ThemeMode _parseThemeMode(String? v) {
  switch (v) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

String _encodeThemeMode(ThemeMode m) {
  switch (m) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

final settingsRepoProvider = Provider<SettingsRepo>((_) => SettingsRepo());

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system; // overridden in main()

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsRepoProvider).writeThemeMode(mode);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class CurrencyNotifier extends Notifier<CurrencyOption> {
  @override
  CurrencyOption build() => kCurrencies[0]; // PKR — overridden in main()

  Future<void> set(String code) async {
    state = currencyByCode(code);
    await ref.read(settingsRepoProvider).writeCurrency(code);
  }
}

final currencyProvider =
    NotifierProvider<CurrencyNotifier, CurrencyOption>(CurrencyNotifier.new);

class DisplayNameNotifier extends Notifier<String> {
  @override
  String build() => ''; // overridden in main()

  Future<void> set(String name) async {
    state = name;
    await ref.read(settingsRepoProvider).writeDisplayName(name);
  }

  /// Only fills the name if it's currently empty. Used after Google sign-in.
  Future<void> setFromGoogle(String? googleName) async {
    if (state.isNotEmpty) return;
    final n = (googleName ?? '').trim();
    if (n.isEmpty) return;
    await set(n);
  }
}

final displayNameProvider =
    NotifierProvider<DisplayNameNotifier, String>(DisplayNameNotifier.new);
