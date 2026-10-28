# Futuer — Remote Device Management Platform

A secure Android-to-Android device management platform named **Futuer**, built using **Flutter**, **Dart**, and **InsForge** backend cloud infrastructure.

The platform provides two completely separate user workflows:
1. **Futuer Controller** (`com.futuer.controller` / Controller role) — installed on the primary Android phone for managing and monitoring enrolled devices.
2. **Futuer Agent** (`com.futuer.agent` / Managed Device role) — installed on the secondary Android phone that the owner explicitly authorizes and enrolls.

Both applications communicate through the configured InsForge project (`futuer123` / `8b68b972-f8f5-4f51-a96d-cac5b84afaa6`).

---

## 🚀 Phase 2: Role-Based Onboarding & Secure Atomic Pairing

### 1. Unified Entry Point: Choose Your Role
When the app launches for the first time without a configured role:
* **Welcome Screen:** "Welcome to Futuer — Choose how you want to use Futuer."
* **Option A: Controller:**
  * Description: *Manage your own enrolled device.*
  * Action: `Continue as Controller` -> Navigates to Controller Auth Screen.
* **Option B: Managed Device:**
  * Description: *Register this phone to an authorized Futuer Controller.*
  * Action: `Connect This Device` -> Navigates to Managed Device Enrollment Introduction.
* **Dynamic Persistence:** The selected role is saved in `FlutterSecureStorage` (`futuer_configured_role`). On subsequent launches, the app automatically opens the designated flow without silent role hopping.
* **Safe Role Reset:** Both flows provide explicit "Change Role" / "Disconnect Device" dialogs that revoke local sessions and return to the role picker.

---

### 2. Controller Flow
1. **Authentication (`controller_auth_screen.dart`):**
   * Sign In, Register Account, and Forgot Password using InsForge Auth.
   * Session persistence via `InsforgeClient(sessionStorage: SecureSessionStorage())`.
2. **Controller Dashboard (`controller_dashboard_screen.dart`):**
   * Enrolled device cards displaying live status indicators: `ONLINE`, `OFFLINE`, `CONNECTING`, `PERMISSION REQUIRED`, `LAST SEEN`.
   * Real-time 5-second polling for verified telemetry.
   * If no devices: displays **No devices connected yet.** with an **Add Your Device** button.
3. **Pairing Code Generation (`controller_pairing_screen.dart`):**
   * Generates a cryptographically secure, single-use, 10-minute expiring pairing code (e.g. `FUT-821`).
   * Stored in `pairing_requests` with `controller_user_id = auth.uid()`.
   * Live countdown timer (10:00 -> 00:00).
   * Real-time polling detects when the secondary device consumes the code and confirms enrollment automatically.
   * "Cancel Pairing" button updates status to `CANCELLED`.
4. **8-Tab Device Details (`controller_device_details_screen.dart`):**
   * Overview, Location (Google Maps), Notifications, Call Activity, Camera Sessions, Microphone Sessions, Connection History, and Permissions.

---

### 3. Managed Device Flow
1. **Enrollment Introduction (`agent_intro_screen.dart`):**
   * Explains the controller relationship, device owner authorization, expiring pairing codes, and Android permission requirements.
   * Highlights Android visual privacy indicators (status bar dots for camera and mic sessions).
2. **Managed Device Authentication (`agent_auth_screen.dart`):**
   * Authenticates the device enrollee with InsForge Auth.
   * Strictly isolated from the Controller dashboard.
3. **Enter Pairing Code & Atomic Consumption (`agent_pairing_screen.dart`):**
   * Code input validation (`FUT-XXX`) and rate limiting (lockout after 5 failed attempts).
   * Pre-verifies pending code from `pairing_requests` and presents a confirmation dialog with device details.
   * Calls PostgreSQL stored procedure `verify_and_consume_pairing_code(p_code, p_device_model)` to atomically lock, validate expiration, register device, mark code `CONSUMED`, and log audit trail.
4. **Permissions Checklist (`agent_permissions_screen.dart`):**
   * Displays 4 permission items separately: Location, Notifications, Camera, and Microphone.
   * For each permission: shows current status (Granted / Not Granted), why needed, "Enable / Configure" button, and "Recheck" button.
   * Denying a permission does not block enrollment; the device registers and marks the feature unavailable.
5. **Agent Status Screen (`agent_status_screen.dart`):**
   * Status indicator: `ONLINE & SYNCING`.
   * Heartbeat worker (transmits every 30s to `device_heartbeats`).
   * GPS location worker (uploads coordinates to `device_locations`).
   * Remote session listener for incoming camera/mic streaming requests.
   * "Disconnect Device" button to unpair and reset role.

---

## 🗄️ Database Architecture (InsForge PostgreSQL)

### Tables
1. `devices`: Enrolled phones, platform, battery, permissions, last seen.
2. `pairing_requests`: Short-lived single-use pairing codes (`PENDING`, `CONSUMED`, `EXPIRED`, `CANCELLED`).
3. `device_locations`: GPS coordinates, accuracy, timestamps.
4. `device_notifications`: Monitored notifications.
5. `call_activity`: Telephony call records (Incoming, Outgoing, Missed).
6. `device_sessions`: Live camera and microphone session requests.
7. `device_heartbeats`: Authenticated background heartbeats.
8. `device_audit_logs`: Security audit log.

### Stored Procedures
* `public.verify_and_consume_pairing_code(p_code TEXT, p_device_model TEXT DEFAULT 'Android Phone') RETURNS JSONB`:
  * Atomically locks matching `PENDING` pairing request (`FOR UPDATE`).
  * Checks expiration against `now()`.
  * Inserts the newly authorized device into `devices` under the Controller's user ID.
  * Sets request status to `CONSUMED`.
  * Records `PAIRING_CODE_CONSUMED` in `device_audit_logs`.
  * Returns JSON status with `device_id` and `controller_user_id`.

Migration files:
* [`schema/01_init_futuer.sql`](file:///d:/project/futuer/schema/01_init_futuer.sql)
* [`schema/02_pairing_and_roles.sql`](file:///d:/project/futuer/schema/02_pairing_and_roles.sql)

---

## 🧪 Verification & Build Status

* **Flutter Analysis (`root`):** Passed with 0 errors/warnings (`flutter analyze`).
* **Unit & Widget Tests (`root`):** Passed (`flutter test`).
* **Sub-projects (`controller/`, `agent/`):** Passed analysis and tests.
* **Android Debug Build:** Successfully built APK:
  `build/app/outputs/flutter-apk/app-debug.apk` (152.3 MB).
