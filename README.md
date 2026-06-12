# Xpense Tracker

A clean, offline-first personal finance app for Android. Track expenses, income, loans, and projects — with optional, private Google Drive backup.

<p align="center">
  <img src="assets/app-images/xpense-tracker-saranzafar-home.jpeg" width="240" />
  <img src="assets/app-images/xpense-tracker-saranzafar-5.jpeg" width="240" />
  <img src="assets/app-images/xpense-tracker-saranzafar-7.jpeg" width="240" />
</p>

## Download

**[⬇ Download v1.0.1 — latest release](https://github.com/saranzafar/expense-tracker-flutter-mobile-app/releases/tag/v1.0.1)**

| APK | Architecture | Size |
|-----|-------------|------|
| [`app-arm64-v8a-release.apk`](https://github.com/saranzafar/expense-tracker-flutter-mobile-app/releases/download/v1.0.1/app-arm64-v8a-release.apk) | 64-bit · recommended (~95 % of devices) | 21.6 MB |
| [`app-armeabi-v7a-release.apk`](https://github.com/saranzafar/expense-tracker-flutter-mobile-app/releases/download/v1.0.1/app-armeabi-v7a-release.apk) | 32-bit legacy | 19.1 MB |
| [`app-x86_64-release.apk`](https://github.com/saranzafar/expense-tracker-flutter-mobile-app/releases/download/v1.0.1/app-x86_64-release.apk) | x86 / emulators | 23.1 MB |

Enable **"Install from unknown sources"** on your device, then open the APK. The app works fully offline — Google Sign-In is optional and only needed for Drive backup.

---

## Features

### Records
- Four record types: **expense**, **income**, **loan given**, **loan taken**
- Swipe to delete with confirmation dialog
- Infinite-scroll pagination (50 records per page)
- Category badges on each record tile

### Categories
- Shared category pool across income and expense records
- Create, rename, and delete categories from Settings → Categories
- Category-based filtering on the Records page

### Home Dashboard
- Balance card with hide/show toggle (persisted across restarts)
- Monthly income and expense mini-stats
- **Overview chart** — income vs expense line chart with 1W / 1M / 1Y and **custom date range** picker
- Income, expense and net totals for the active chart period
- Outstanding loans and borrowed-money summary card

### Loans
- Track money lent to others and money borrowed from others
- Mark as returned / repaid; history preserved in Returned tab
- Filter by date range

### Projects
- Create projects with name, description, start/end dates, total budget, advance payment, and category
- Vertical payment timeline — tap to add further payments at any time
- Filter by category and date range

### Finance Summary
- Records page shows income / expense / net totals for the current filter — updates live as filters change

### Design
- Material 3, fully light and dark-mode aware
- Frosted glass floating nav bar with smooth decoupled pill animation
- Smooth motion throughout (fade, size, cross-fade transitions)
- 10 currencies, system / light / dark theme toggle

### Backup
- Optional Google Drive backup to a **private app-data folder** (invisible in Drive UI)
- Auto-backup on reconnect; manual backup from Settings

---

## Tech Stack

Flutter · Riverpod 2 · Drift (SQLite) · fl_chart · `google_sign_in` · `googleapis` · Material 3

---

## Build from Source

```bash
git clone https://github.com/saranzafar/expense-tracker-flutter-mobile-app.git
cd expense-tracker-flutter-mobile-app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

For Google Drive backup and release-signing setup, see [SETUP.md](SETUP.md).

---

## Changelog

### [v1.0.1](https://github.com/saranzafar/expense-tracker-flutter-mobile-app/releases/tag/v1.0.1)
- Custom date range picker on the home chart (daily/monthly buckets auto-selected)
- Income / expense / net totals strip on both the home chart card and the Records page
- Projects — budget tracking with vertical payment timeline and category + date filters
- Loan taken record type with its own section in the Loans tab
- Shared categories across all record types with Settings → Categories management
- Infinite-scroll pagination on the Records page (50 records per page)
- Dark mode: chip text, category badge, and card surface colour fixes
- Balance card: dark-gray surface in dark mode (no longer inverts to white)
- Floating nav bar: frosted glass in light mode (white bg, black border, soft shadow); smooth white border in dark mode; green active pill
- Nav bar animation: pill travels directly from source to target tab (400 ms easeInOutCubic) — no intermediate tabs light up; swipe tracks the finger frame-perfectly

### [v1.0.0](https://github.com/saranzafar/expense-tracker-flutter-mobile-app/releases/tag/v1.0.0)
- Initial release: expense, income, loan-given records
- Google Drive backup, 10 currencies, light/dark themes

---

## License

MIT — see [LICENSE](LICENSE).

**Author:** Saran Zafar — [saranzafar.com](https://saranzafar.com) · [GitHub](https://github.com/saranzafar) · [LinkedIn](https://www.linkedin.com/in/saranzafar)
