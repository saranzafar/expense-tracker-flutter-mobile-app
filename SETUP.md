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

---

## 3. Release builds

Debug-signed APKs from `flutter run` are fine for development, but to publish or sideload to other devices you need a release keystore + a separate OAuth client.

### a) Generate a release keystore (one-time, NEVER lose this)

```bash
mkdir -p ~/keystores
keytool -genkey -v -keystore ~/keystores/xpense-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias xpense
```

⚠ **Back up the `.jks` file and its passwords to a password manager + encrypted cloud storage.** Lose this file = can never update the app on the same install path.

### b) Wire it into the build

Create `android/key.properties` (gitignored):

```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=xpense
storeFile=/absolute/path/to/xpense-release.jks
```

The `android/app/build.gradle.kts` in this repo already loads `key.properties` if present, enables R8 + resource shrinking, and signs the `release` build type with it. If the file is missing, it falls back to debug signing so CI / fresh clones still build.

### c) Register the release SHA-1 with Google Cloud

```bash
cd android && ./gradlew signingReport   # copy the "Variant: release" SHA-1
```

In Google Cloud Console → **APIs & Services → Credentials** → **+ Create credentials → OAuth client ID**:
- Type: **Android**
- Name: `Xpense Tracker Android (release)`
- Package name: `com.example.xpense_traker`
- SHA-1: the release fingerprint you just copied

You'll end up with **two** OAuth clients (debug + release) sharing the same package name. That's correct — Google Sign-In matches by `(package + SHA-1)` at runtime and routes each build to the right client.

Wait ~5 minutes after saving for propagation.

### d) Build

```bash
flutter clean && flutter pub get
flutter build apk --release --split-per-abi \
  --obfuscate --split-debug-info=build/symbols/v1.0.1
```

Outputs three APKs in `build/app/outputs/flutter-apk/`. Ship `app-arm64-v8a-release.apk` to ~95 % of users.

For Play Store, use `flutter build appbundle --release ...` instead. Play re-signs the bundle with its own "App Signing" key — you'll need to register **that** SHA-1 (visible in Play Console → App integrity, after the first upload) as a **third** OAuth client.

### e) Always archive

Each release: keep the matching `build/symbols/<version>` folder, the APK files, and a note of the git commit hash. Without the symbols, obfuscated crash reports from that build can never be decoded.
