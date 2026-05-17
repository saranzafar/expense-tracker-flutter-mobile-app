import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/currency.dart';
import 'data/settings_repo.dart';
import 'features/backup/data/backup_prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsRepo = SettingsRepo();
  final backupRepo = BackupPrefsRepo();
  final themeMode = await settingsRepo.readThemeMode();
  final currency = await settingsRepo.readCurrency();
  final displayName = await settingsRepo.readDisplayName();
  final backupPrefs = await backupRepo.read();

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(() => _PrefilledThemeMode(themeMode)),
        currencyProvider.overrideWith(() => _PrefilledCurrency(currency)),
        displayNameProvider
            .overrideWith(() => _PrefilledDisplayName(displayName)),
        backupPrefsProvider
            .overrideWith(() => _PrefilledBackupPrefs(backupPrefs)),
      ],
      child: const XpenseApp(),
    ),
  );
}

class _PrefilledDisplayName extends DisplayNameNotifier {
  _PrefilledDisplayName(this.initial);
  final String initial;
  @override
  String build() => initial;
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

class _PrefilledBackupPrefs extends BackupPrefsNotifier {
  _PrefilledBackupPrefs(this.initial);
  final BackupPrefs initial;
  @override
  BackupPrefs build() => initial;
}
