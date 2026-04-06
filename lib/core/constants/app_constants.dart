class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'ClassMark';

  // OTP
  static const int otpLength = 6;
  static const int otpExpiryMinutes = 10;

  // BLE
  static const double bleProximityThreshold = -70.0; // RSSI dBm ≈ 10m
  static const String bleServiceUUID = 'class-mark-ble-service';
  static const String bleCharUUID = 'class-mark-char-uuid';
  static const String bleDeviceName = 'ClassMark-Teacher';

  // UI
  static const double borderRadius = 20.0;
  static const double cardBlur = 20.0;
  static const double cardOpacity = 0.12;

  // Firestore collections
  static const String usersCollection = 'users';
  static const String otpSessionsCollection = 'otp_sessions';
  static const String attendanceCollection = 'attendance';

  // Roles
  static const String roleTeacher = 'teacher';
  static const String roleStudent = 'student';

  // Email validation
  static const List<String> blockedEmailDomains = ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com'];
}