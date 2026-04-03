class AppConstants {
  // Geofencing
  static const double proximityRadiusMeters = 20.0; // 20 meters

  // OTP
  static const int otpLength = 6;
  static const int otpExpiryMinutes = 10;

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String sessionsCollection = 'sessions';
  static const String attendanceCollection = 'attendance';
  static const String otpCollection = 'otp_sessions';

  // User Roles
  static const String roleTeacher = 'teacher';
  static const String roleStudent = 'student';

  // Storage Keys
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';
}
