# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# Drift / sqlite3
-keep class com.simolus3.** { *; }
-keep class org.sqlite.** { *; }

# Google Sign-In + Drive API
-keep class com.google.api.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.api.client.** { *; }
-keep class com.google.api.services.** { *; }
-dontwarn com.google.api.client.**
-dontwarn com.google.api.services.**

# OkHttp / okio (used by googleapis_auth http client)
-dontwarn okhttp3.**
-dontwarn okio.**

# Tink (Google crypto, used transitively)
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# Keep generic signatures (needed for Gson / JSON reflection)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
