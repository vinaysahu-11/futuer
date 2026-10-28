# InsForge Flutter App (`futuer`) — Android Edition

A Flutter Android application integrated with **InsForge** backend cloud infrastructure for:
1. **Authentication:** User registration (`signUp`), login (`signIn`), secure token persistence (`flutter_secure_storage`), session state listener, and sign out.
2. **Database:** PostgREST database CRUD operations (Select, Insert, Update, Delete) against your PostgreSQL database in InsForge.
3. **Dedicated Android Configuration:** Configured exclusively for Android with `INTERNET` and `ACCESS_NETWORK_STATE` permissions enabled in `AndroidManifest.xml` and unnecessary platforms removed.

---

## 📱 Android Configuration Details

* **Platform Target:** Android only (`android/`)
* **Package Name:** `com.example.futuer`
* **Permissions in `AndroidManifest.xml`:**
  * `android.permission.INTERNET` (enables InsForge API / backend calls)
  * `android.permission.ACCESS_NETWORK_STATE` (network state monitoring)
* **Secure Storage:** Uses Android Keystore and EncryptedSharedPreferences via `flutter_secure_storage`.

---

## 🔗 Linked InsForge Project

* **Project:** `futuer123` (`8b68b972-f8f5-4f51-a96d-cac5b84afaa6`)
* **Account:** `projecttest1437@gmail.com`
* **API Host:** `https://6krn5up4.us-east.insforge.app`
* **API Key:** `ik_3039eac4f5de85011d8a2ddf076aab68`
* **Config file:** [`lib/config/insforge_config.dart`](file:///d:/project/futuer/lib/config/insforge_config.dart)

---

## 📁 Project Architecture

```
futuer/
├── android/                      # Android native project files
│   └── app/src/main/
│       └── AndroidManifest.xml   # Configured with Internet permissions
├── lib/
│   ├── config/
│   │   └── insforge_config.dart  # InsForge backend URL & API key
│   ├── services/
│   │   ├── insforge_service.dart # Initializes InsForge client & secure storage
│   │   ├── auth_service.dart     # Authentication (Sign In, Sign Up, Sign Out)
│   │   └── database_service.dart # PostgREST database CRUD operations
│   ├── screens/
│   │   ├── connection_screen.dart# Setup screen to modify credentials if needed
│   │   ├── auth_screen.dart      # Sign In / Sign Up tabbed UI
│   │   ├── home_screen.dart      # Dashboard with PostgreSQL table explorer
│   │   └── splash_gate.dart      # Dynamic gatekeeper routing
│   └── main.dart                 # App entrypoint (Material 3)
└── pubspec.yaml                  # Dependencies (insforge_flutter, etc.)
```

---

## 🛠️ Running and Building for Android

### 1. Run on a connected Android phone or Emulator:
Make sure USB debugging is enabled on your Android device (or launch an emulator), then:

```bash
flutter run
```

### 2. Build Release Android APK:
```bash
flutter build apk --release
```
The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

### 3. Build Android App Bundle (for Google Play):
```bash
flutter build appbundle --release
```
The AAB will be generated at `build/app/outputs/bundle/release/app-release.aab`.
