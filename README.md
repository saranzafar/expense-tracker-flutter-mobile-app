# Xpense Tracker

A clean, offline-first personal finance app for Android. Track expenses, income, and money you've lent — with optional, private Google Drive backup.
Built with Flutter, Riverpod, and Drift. Designed around a strict black-and-white interface with sparing lime-green accents.

---

## Features

- **Three record types** — expense, income, and loan-given (with expected return date, mark-as-returned flow).
- **Available balance** computed live as `income − expense − outstanding loans`. Numbers tween smoothly between changes.
- **Records list** grouped by day with swipe-to-delete and filters (All / Income / Expense).
- **Date-range filtering** — 1D / 1W / 1M / 1Y chips plus a year-picker dropdown that walks from the current year back to your earliest record. Applies to both Records and Loans.
- **Loans tab** with Outstanding / Returned sections, overdue indicators, and one-tap "Mark returned".
- **10 currencies** — PKR, USD, EUR, GBP, INR, AED, SAR, CAD, AUD, JPY. Display-only switch; data stays intact.
- **Light, dark, and system themes** with crossfade transitions.
- **Personalized greeting** — set a display name (auto-picked from your Google account when you connect Drive backup, editable from the Backup page).
- **Onboarding** with line-art illustrations on first launch.
- **Google Drive backup (optional)** — backs up the SQLite database to a private app-data folder only this app can see. Wi-Fi-only toggle. Auto-restore prompt after sign-in on a fresh install.
- **Polished motion** — gentle crossfades on tab switches and async loaders, fade-up staggered cards, animated money values, AnimatedSize on conditional form fields. No bouncy springs, no distractions.
- **Traditional Android back-button** — walks back through tab history; press back again on Home to exit.
- **Offline-first**: the app makes no network calls until the user explicitly opts in to backup.

---

## Tech stack

| Layer | Tool |
|---|---|
| Framework | Flutter (Dart 3.11+) |
| State | `flutter_riverpod` |
| Local DB | `drift` (SQLite) |
| Preferences | `shared_preferences` |
| Theming | Material 3 + `google_fonts` (Plus Jakarta Sans) |
| Currency / dates | `intl` |
| Illustrations | `flutter_svg` |
| External links | `url_launcher` |
| Backup auth | `google_sign_in` |
| Drive API | `googleapis`, `googleapis_auth` |
| Connectivity | `connectivity_plus` |
| Codegen | `build_runner`, `drift_dev`, `riverpod_generator` |

---

## Download

Pre-built APKs are attached to each [GitHub release](https://github.com/saranzafar/expense-tracker-flutter-mobile-app/releases). Grab `xpense-tracker-<version>-arm64-v8a.apk` for any modern Android phone (~21 MB).

To install: enable **Install from unknown sources** for your browser / file manager, open the APK, install. Google Drive backup is opt-in — the app works fully offline.

## Getting started (from source)

### Prerequisites
- Flutter SDK 3.11+
- An Android device or emulator

### Run it

```bash
git clone https://github.com/saranzafar/expense-tracker-flutter-mobile-app.git
cd expense-tracker-flutter-mobile-app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

That's it — the app is fully usable offline.

### (Optional) Enable Google Drive backup

The backup feature requires a one-time OAuth client setup in Google Cloud Console. See [SETUP.md](SETUP.md) for the step-by-step.

### Building a release APK

See [SETUP.md → Release builds](SETUP.md#3-release-builds) for keystore + signing setup. TL;DR once configured:

```bash
flutter build apk --release --split-per-abi \
  --obfuscate --split-debug-info=build/symbols/<version>
```

---

## Project structure

```
lib/
  app.dart                    MaterialApp + root gate
  main.dart                   Boot: hydrate prefs, ProviderScope overrides
  core/                       theme, currency, formatters
  data/                       Drift DB, providers, repo classes
  shell/home_shell.dart       Bottom nav + center FAB
  features/
    onboarding/               First-launch slides
    home/                     Dashboard (balance card, recent activity)
    records/                  List + type-aware form
    loans/                    Outstanding / Returned tabs
    backup/                   Google Drive sync (data + UI)
    settings/                 Theme, currency, backup, about, dev tools
    about/                    Author + repo info
assets/illustrations/         SVGs for onboarding & empty states
```

---

## Design system

- **Surface / Ink** — pure white (`#FFFFFF`) and pure black (`#000000`), with one tonal flip for dark mode.
- **Accent** — lime green `#A4F133`, kept to roughly 5–10 % of any screen (primary CTAs, balance amount, active tab indicator).
- **Typography** — Plus Jakarta Sans, five weights.
- **Components** — 20 px rounded cards with 1 px hairline borders, no shadows. 200 ms `easeOutCubic` transitions.

---

## Roadmap

- [x] Date-range filter on Records & Loans
- [x] Display name & personalized greeting
- [x] Traditional Android back-button behavior
- [x] Motion polish across the app
- [ ] Charts (monthly trend, type breakdown)
- [ ] CSV export / share
- [ ] Text search on Records
- [ ] Recurring records
- [ ] Multiple wallets / accounts
- [ ] iOS support

PRs and issues welcome.

---

## License

MIT — see [LICENSE](LICENSE).

## Author

**Saran Zafar** — Software Engineer
[saranzafar.com](https://saranzafar.com) · [GitHub](https://github.com/saranzafar) · [LinkedIn](https://www.linkedin.com/in/saranzafar)
