# InsForge Flutter App (`futuer`)

A complete Flutter application setup integrated with **InsForge** backend cloud infrastructure for:
1. **Authentication:** User registration (`signUp`), login (`signIn`), secure token persistence (`flutter_secure_storage`), session state listener, and sign out.
2. **Database:** PostgREST database CRUD operations (Select, Insert, Update, Delete) against your PostgreSQL database in InsForge.
3. **Flexible Backend Connection:** Configured so that **no dummy ID is pre-connected**. You can supply your InsForge credentials either in the configuration file or directly via the UI on startup.

---

## 🚀 How to Provide Your InsForge Credentials

You have two simple ways to provide your InsForge credentials:

### Option 1: In the Configuration File (Recommended for development)
Open [`lib/config/insforge_config.dart`](file:///d:/project/futuer/lib/config/insforge_config.dart) and paste your credentials:

```dart
class InsforgeConfig {
  static const String defaultUrl = 'https://<your-project-id>.us-east.insforge.app';
  static const String defaultAnonKey = 'your-insforge-anon-key';
  ...
}
```

### Option 2: Directly inside the App UI
Run the app. Because no ID is hardcoded, the app will show the **InsForge Backend Setup** screen:
1. Enter your **Project URL** (e.g., `https://xyz.us-east.insforge.app`).
2. Enter your **Public Anon Key**.
3. Tap **Connect to InsForge**.
4. The credentials are encrypted and stored in your device's secure keychain / storage so you don't have to enter them again.

---

## 📁 Project Architecture

```
lib/
├── config/
│   └── insforge_config.dart      # Central configuration for backend URL and Anon key
├── services/
│   ├── insforge_service.dart     # Initializes and manages the InsForge client & secure storage
│   ├── auth_service.dart         # Authentication operations (Sign In, Sign Up, Sign Out, Session)
│   └── database_service.dart     # PostgREST database CRUD operations (fetch, insert, update, delete)
├── screens/
│   ├── connection_screen.dart    # Setup screen when no credentials are provided yet
│   ├── auth_screen.dart          # Sign In / Sign Up tabbed authentication UI
│   ├── home_screen.dart          # Authenticated dashboard with PostgreSQL table explorer & CRUD
│   └── splash_gate.dart          # Dynamic router (Connection -> Auth -> Home)
└── main.dart                     # App entry point with Material 3 styling
```

---

## 🛠️ Running the Application

To run the Flutter app on your target platform (Chrome / Windows / Android / iOS):

```bash
flutter run
```

Or to run specifically on Chrome / Windows:
```bash
flutter run -d chrome
# or
flutter run -d windows
```

To run analysis or tests:
```bash
flutter analyze
flutter test
```
