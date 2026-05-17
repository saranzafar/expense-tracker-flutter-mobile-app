# Xpense Tracker

A clean, offline-first personal finance app for Android. Track expenses, income, and money you've lent — with optional, private Google Drive backup.

<p align="center">
  <img src="assets/app-images/xpense-tracker-saranzafar-home.jpeg" width="240" />
  <img src="assets/app-images/xpense-tracker-saranzafar-5.jpeg" width="240" />
  <img src="assets/app-images/xpense-tracker-saranzafar-7.jpeg" width="240" />
</p>

## Features

- Three record types: **expense**, **income**, **loan-given** (with expected return date)
- Date-range filtering — 1D / 1W / 1M / 1Y / custom year
- 10 currencies, light / dark / system themes
- Optional Google Drive backup to a private app-data folder
- Fully offline — no network calls until you opt in

## Download

Get the APK from the [latest release](https://github.com/saranzafar/expense-tracker-flutter-mobile-app/releases/latest). Enable "Install from unknown sources" and open the file. The app works fully offline; Google Sign-In is optional.

## Tech stack

Flutter · Riverpod · Drift (SQLite) · `google_sign_in` · `googleapis` · Material 3

## Build from source

```bash
git clone https://github.com/saranzafar/expense-tracker-flutter-mobile-app.git
cd expense-tracker-flutter-mobile-app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

For Google Drive backup and release-signing setup, see [SETUP.md](SETUP.md).

## License

MIT — see [LICENSE](LICENSE).

**Author:** Saran Zafar — [saranzafar.com](https://saranzafar.com) · [GitHub](https://github.com/saranzafar) · [LinkedIn](https://www.linkedin.com/in/saranzafar)
