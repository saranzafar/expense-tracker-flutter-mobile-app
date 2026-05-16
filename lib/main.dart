import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/currency.dart';
import 'data/settings_repo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = SettingsRepo();
  final themeMode = await repo.readThemeMode();
  final currency = await repo.readCurrency();

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(() => _PrefilledThemeMode(themeMode)),
        currencyProvider.overrideWith(() => _PrefilledCurrency(currency)),
      ],
      child: const XpenseApp(),
    ),
  );
}

class _PrefilledThemeMode extends ThemeModeNotifier {
  _PrefilledThemeMode(this.initial);
  final ThemeMode initial;
  @override
  ThemeMode build() => initial;
}

class _PrefilledCurrency extends CurrencyNotifier {
  _PrefilledCurrency(this.initial);
  final CurrencyOption initial;
  @override
  CurrencyOption build() => initial;
}
