# ClassMark 📚

A smart Flutter attendance marking app with OTP-based, proximity-verified attendance.

## Features
- 🎓 **Dual-role system** — Separate flows for Teachers and Students
- 🔐 **Firebase Auth** — Email/password login & registration
- 📍 **Proximity Check** — OTP only accepted within 20m of teacher
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


## Tech Stack

| Technology | Usage |
|-----------|-------|
| Flutter 3.x | Cross-platform UI |
| Firebase Auth | Authentication |
| Cloud Firestore | Real-time database |
| Riverpod 2.x | State management |
| Ble | Bluetooth Proximity and Scanning |
| flutter_animate | Smooth animations |
| pin_code_fields | OTP input widget |
| Google Fonts (Space Grotesk) | Typography |
