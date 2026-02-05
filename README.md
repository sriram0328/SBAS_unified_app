# SBAS Attendance - Smart Building Attendance System

A comprehensive Flutter-based attendance management system designed for educational institutions with dual-role dashboards for students and faculty.

**Version**: 1.0.0+1  
**Platform**: Flutter (Cross-platform Mobile Application)  
**SDK**: Dart 3.10.4+

---

## 📋 Project Overview

SBAS Attendance streamlines attendance tracking and management through:

### Features
- ✅ **Role-based Authentication**: Secure student/faculty login
- ✅ **Dual Dashboards**: Separate interfaces for students and faculty
- ✅ **Barcode Scanning**: Real-time attendance marking via camera
- ✅ **Attendance Tracking**: Daily, weekly, and monthly views
- ✅ **ID Card Generation**: Digital student ID cards with barcodes
- ✅ **Comprehensive Reporting**: Attendance reports with multiple filters
- ✅ **Timetable Management**: Faculty timetable viewing and scheduling
- ✅ **Real-time Synchronization**: Cloud Firestore integration

---

## 🛠️ Tech Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| **Framework** | Flutter | Latest |
| **Language** | Dart | 3.10.4+ |
| **Backend** | Firebase | Multi-service |
| **Authentication** | Firebase Auth | 5.3.4 |
| **Database** | Cloud Firestore | 5.5.1 |
| **Barcode Scanner** | mobile_scanner | 5.2.3 |
| **Barcode Generator** | barcode_widget | 2.0.4 |
| **State Management** | Provider | 6.1.0 |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.10.4+)
- Dart (3.10.4+)
- Firebase project setup
- Mobile device or emulator

### Installation & Setup

1. **Clone and setup dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run the development server:**
   ```bash
   flutter run
   ```

3. **Build for production:**
   ```bash
   flutter build apk      # Android
   flutter build ios      # iOS
   ```

---

## 📁 Project Structure

```
lib/
├── main.dart              # App entry point
├── app.dart               # App configuration
├── firebase_options.dart  # Firebase config
├── splashscreen.dart      # Splash screen
├── auth/                  # Authentication module
├── student/               # Student dashboard & features
│   ├── attendance/        # Attendance views (daily, weekly, monthly)
│   ├── idcard/           # ID card generation
│   └── reports/          # Student reports
├── faculty/               # Faculty dashboard & features
│   ├── scanning/         # Barcode scanning
│   ├── timetable/        # Timetable management
│   └── reports/          # Attendance reports
├── core/                  # Core utilities & services
├── models/                # Data models
└── services/              # API & Firebase services

auth_server/               # Development authentication server (Port 9002)
```

---

## 🔐 Development: Auth Server & Firestore Rules

### Auth Server
- Located at `auth_server/` directory
- Verifies credentials server-side
- Issues Firebase custom tokens for development
- Runs on local port 9002
- Follow `auth_server/README.md` for setup instructions

### Development Security Rules
- A permissive `firestore.rules.dev` file is included for testing
- **⚠️ Important**: Never deploy dev rules to production

### Production Recommended Flow
1. Verify credentials on a trusted backend using Firebase Admin SDK
2. Issue a custom token with role claims
3. Client receives token and calls `FirebaseAuth.signInWithCustomToken(token)`
4. Use strict Firestore security rules restricting access based on authentication and role claims

---

## 📚 Resources

For Flutter development help:
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/)
- [Firebase for Flutter](https://firebase.flutter.dev/)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)

---

## 📝 License

This project is private and not intended for public distribution.

