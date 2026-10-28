# Futuer — Remote Device Management Platform

A secure Android-to-Android device management platform named **Futuer**, built using **Flutter**, **Dart**, and **InsForge** backend cloud infrastructure.

The platform contains exactly two applications:
1. **Futuer Controller** (`com.futuer.controller`) — installed on the primary Android phone.
2. **Futuer Agent** (`com.futuer.agent`) — installed on the secondary Android phone that the owner explicitly enrolls and authorizes.

Both applications communicate through the configured InsForge project (`futuer123` / `8b68b972-f8f5-4f51-a96d-cac5b84afaa6`).

---

## 📱 Application Overview

### 1. Futuer Controller (`controller/`)
* **Package Name:** `com.futuer.controller`
* **Features:**
  * **Authentication:** Owner registration, login, session persistence, and session revocation using InsForge Auth.
  * **Main Dashboard:** Live overview of enrolled secondary devices showing:
    * Verified Online / Offline / Connecting / Permission Required / Last Seen status based on heartbeats.
    * Device model, battery level, charging indicator, last seen timestamp.
  * **8 Device Detail Sections:**
    1. **Overview:** Device metadata, heartbeat freshness, authorization revocation.
    2. **Location:** Google Maps integration with live coordinates vs. last-known location markers, accuracy, and timestamps.
    3. **Notifications:** Monitored notifications exposed by Android Notification Listener Service.
    4. **Call Activity:** Telephony call logs (Incoming, Outgoing, Missed, duration, phone number).
    5. **Camera Sessions:** Authorized live video session requests, stream status, and termination controls.
    6. **Microphone Sessions:** Authorized live audio session requests, stream status, and termination controls.
    7. **Connection History:** Verified heartbeat logs and device state transitions.
    8. **Permissions:** Live permission reporting (Location, Notifications, Calls, Camera, Microphone).

### 2. Futuer Agent (`agent/`)
* **Package Name:** `com.futuer.agent`
* **Features:**
  * Works alongside existing Android launcher without replacing it.
  * **Initial Enrollment:** Transparent onboarding explaining data collection and requesting permissions explicitly.
  * **Pairing:** Pairs with Futuer Controller using a 10-minute expiring 6-character pairing code (e.g. `FUT-821`).
  * **Background Heartbeat Worker:** Transmits authenticated heartbeats every 30 seconds to verify online status.
  * **Location Worker:** Captures GPS coordinates and accuracy and uploads updates to InsForge.
  * **Notification & Call Reporting:** Telemetry upload for authorized activities.
  * **Live Session Listener:** Listens for authorized Camera or Audio session requests, requiring explicit on-screen authorization before streaming and respecting Android privacy indicators.
  * **Revocation & Disconnect:** Allows secondary phone user to unpair at any time.

---

## 🗄️ Database Architecture (InsForge PostgreSQL)

The schema contains 7 tables with strict Row Level Security (RLS) policies:

| Table | Purpose | RLS Policy |
| :--- | :--- | :--- |
| `devices` | Enrolled devices, pairing codes, battery, permissions, last seen | Owner managed (`owner_user_id = auth.uid()`), Agent pairing lookup |
| `device_locations` | GPS coordinates, accuracy, timestamps | Owner read-only, Agent insert |
| `device_notifications` | App package, title, notification content, timestamp | Owner read-only, Agent insert |
| `call_activity` | Call type (Incoming/Outgoing/Missed), number, duration | Owner read-only, Agent insert |
| `device_sessions` | Authorized camera & microphone live sessions | Owner & Agent managed |
| `device_heartbeats` | Verified background heartbeats, battery, app version | Owner read-only, Agent insert |
| `device_audit_logs` | Audit trail of pairing, session requests, and revocations | Owner managed |

Migration script: [`schema/01_init_futuer.sql`](file:///d:/project/futuer/schema/01_init_futuer.sql)

---

## 📦 Built Android APKs

Both debug APKs have been compiled and verified:

1. **Futuer Controller APK:**
   * Path: `controller/build/app/outputs/flutter-apk/app-debug.apk`
   * Size: ~150 MB

2. **Futuer Agent APK:**
   * Path: `agent/build/app/outputs/flutter-apk/app-debug.apk`
   * Size: ~150 MB

---

## 🛠️ Commands

### Run Applications:
```bash
# Run Controller on connected Android phone 1
cd controller
flutter run

# Run Agent on connected Android phone 2
cd agent
flutter run
```

### Analysis & Tests:
```bash
# Controller
cd controller ; flutter analyze ; flutter test

# Agent
cd agent ; flutter analyze ; flutter test
```

### Build APKs:
```bash
# Build Controller APK
cd controller ; flutter build apk --debug

# Build Agent APK
cd agent ; flutter build apk --debug
```
