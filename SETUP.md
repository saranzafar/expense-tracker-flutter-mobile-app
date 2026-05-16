# Setup — Xpense Tracker

The app runs **fully offline** out of the box. The only setup below is for the *optional* Google Drive backup feature. Skip it if you don't need backups.

## 1. Get the project running

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # only if drift schema changes
flutter run                                                # plug in an Android device
```

## 2. (Optional) Enable Google Drive backup

Backups land in a **hidden app-data folder** on the signed-in user's Drive — invisible in their Drive UI, scoped to this app only. To make sign-in work on your device, you need an OAuth 2.0 client ID in Google Cloud Console.

### a) Get your debug SHA-1

```bash
cd android
./gradlew signingReport
```

Look for the block under `Variant: debug`. Copy the **SHA-1** line.

(For release builds later, generate a release keystore and grab its SHA-1 the same way.)

### b) Create a Google Cloud project

1. <https://console.cloud.google.com> → top bar → **New project** (or reuse one).
2. **APIs & Services** → **Library** → search **Google Drive API** → **Enable**.
3. **APIs & Services** → **OAuth consent screen**:
   - User type: **External**
   - App name: `Xpense Tracker` (or your own)
   - Support email: yours
   - Scopes: add `.../auth/userinfo.email` and `.../auth/drive.appdata`
   - Test users: add your own Google account
4. **APIs & Services** → **Credentials** → **Create credentials** → **OAuth client ID**:
   - Type: **Android**
   - Package name: the `applicationId` from `android/app/build.gradle.kts` (default: `com.example.xpense_traker`)
   - SHA-1: paste from step (a)

No `google-services.json` is needed — that's for Firebase. `google_sign_in` 6.x matches via package name + SHA-1 at runtime.

### c) Try it out

1. `flutter run` → Settings → **Backup** → **Connect Google**
2. Sign in with the test-user account you added in step (b).3
3. Tap **Back up now** → "Backup uploaded ✓".
4. To see your backup file metadata, visit <https://myaccount.google.com/permissions> — this app should appear with "View and manage its own configuration data in your Google Drive". (You won't see the file in the normal Drive UI; that's by design.)

### Troubleshooting

- **"Sign in failed" / silent fail**: 90% of the time this is the SHA-1 mismatch. Re-run `./gradlew signingReport`, paste the *exact* SHA-1 (uppercase, with colons), wait a couple of minutes for Google to propagate.
- **"This app is blocked"**: your test account isn't in the consent-screen test-users list. Add it.
- **"403 storageQuotaExceeded"**: the user's Drive is full. We surface this in the Backup screen.
