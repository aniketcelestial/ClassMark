# ClassMark 📚

A smart Flutter attendance marking app with OTP-based, proximity-verified attendance.

## Features
- 🎓 **Dual-role system** — Separate flows for Teachers and Students
- 🔐 **Firebase Auth** — Email/password login & registration
- 📍 **Proximity Check** — OTP only accepted within 20m of teacher (GPS-based)
- ⏱️ **Auto-expiry** — OTPs expire after 10 minutes
- 📊 **Monthly Analytics** — Calendar view + percentage tracker for students
- 👥 **Live Attendance** — Real-time list of present students for teachers
- 🎨 **Glassy UI** — Dark glassmorphism theme with animated mesh backgrounds

---

## Project Structure

```
lib/
├── main.dart                          # App entry & routing
├── firebase_options.dart              # Firebase config (replace with yours)
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart         # App-wide constants (radius, OTP length)
│   │   └── app_routes.dart            # Named route constants
│   ├── theme/
│   │   └── app_theme.dart             # Dark glassy theme & color palette
│   └── utils/
│       └── logger.dart                # Pretty logger utility
│
├── shared/
│   ├── models/
│   │   ├── user_model.dart            # User data model
│   │   ├── otp_session_model.dart     # OTP session model
│   │   └── attendance_model.dart      # Attendance record model
│   ├── services/
│   │   ├── auth_service.dart          # Firebase Auth wrapper
│   │   ├── otp_service.dart           # Firestore OTP CRUD
│   │   └── ble_service.dart           # Bluetooth BLE proximity
│   └── widgets/
│       ├── glass_card.dart            # Reusable glassmorphism card
│       ├── gradient_button.dart       # Animated gradient button
│       ├── text_field.dart            # Styled text input
│       └── animated_bg.dart           # Animated mesh background
│
└── features/
    ├── auth/
    │   ├── controllers/
    │   │   └── auth_controller.dart   # Riverpod auth state
    │   └── screens/
    │       ├── splash_screen.dart
    │       ├── role_select_screen.dart
    │       ├── teacher_login_screen.dart
    │       └── student_login_screen.dart
    │
    ├── teacher/
    │   ├── controllers/
    │   │   └── teacher_controller.dart # OTP session state
    │   └── screens/
    │       ├── teacher_dashboard_screen.dart
    │       ├── generate_otp_screen.dart
    │       └── present_students_screen.dart
    │
    └── student/
        ├── controllers/
        │   └── student_controller.dart  # OTP submit + proximity logic
        └── screens/
            ├── student_dashboard_screen.dart
            ├── enter_otp_screen.dart
            └── monthly_attendance_screen.dart
```

---

## Setup Instructions

### 1. Firebase Project Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project → **ClassMark**
3. Enable **Authentication** → Email/Password
4. Enable **Firestore Database** → Start in Production mode
5. Register Android app with package: `com.classmark.app`
6. Download `google-services.json` → place in `android/app/`

### 2. Configure Firebase Options

**Option A (Recommended): Use FlutterFire CLI**
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
This auto-generates `lib/firebase_options.dart` for you.

**Option B: Manual**
Edit `lib/firebase_options.dart` and fill in your Firebase project values from:
Firebase Console → Project Settings → Your Apps → SDK config

### 3. Deploy Firestore Rules & Indexes
```bash
firebase deploy --only firestore:rules,firestore:indexes
```

### 4. Install Dependencies & Run
```bash
flutter pub get
flutter run
```

---

## How the Proximity Check Works

1. **Teacher generates OTP** → App captures teacher's GPS coordinates (lat/lng) and stores them in Firestore alongside the OTP
2. **Student enters OTP** → App fetches OTP session, retrieves teacher's stored coordinates, gets student's current GPS position
3. **Distance check** → Uses Geolocator's Haversine formula to calculate distance between the two coordinates
4. **Threshold** → If distance ≤ 20 meters: attendance is marked. If > 20m: rejected with an informative message

> The 20m threshold is configurable in `lib/core/constants/app_constants.dart`

---

## Firestore Collections

| Collection | Purpose |
|-----------|---------|
| `users` | User profiles (teachers & students) |
| `otp_sessions` | Active OTP sessions with teacher coordinates |
| `attendance` | Individual attendance records |

---

## Permissions Required (Android)

- `ACCESS_FINE_LOCATION` — High-accuracy GPS for proximity check
- `ACCESS_COARSE_LOCATION` — Fallback location
- `ACCESS_BACKGROUND_LOCATION` — Optional background access
- `INTERNET` — Firebase communication

---

## Tech Stack

| Technology | Usage |
|-----------|-------|
| Flutter 3.x | Cross-platform UI |
| Firebase Auth | Authentication |
| Cloud Firestore | Real-time database |
| Riverpod 2.x | State management |
| Geolocator | GPS & distance calculation |
| flutter_animate | Smooth animations |
| pin_code_fields | OTP input widget |
| Google Fonts (Space Grotesk) | Typography |