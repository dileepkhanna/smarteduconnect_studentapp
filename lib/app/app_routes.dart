// lib/app/app_routes.dart

class AppRoutes {
  // Auth
  static const splash = '/';
  static const schoolCode = '/school-code';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const verifyOtp = '/verify-otp';
  static const resetPassword = '/reset-password';
  static const firstTimeSetup = '/first-time-setup';

  // Biometrics
  static const biometricSetup = '/biometric-setup';
  static const biometricsSetup = biometricSetup; // alias

  // App
  static const home = '/home';

  // Profile
  static const profile = '/profile';
  static const myProfile = profile; // ✅ alias (some files use myProfile)
  static const editProfile = '/profile/edit';

  // CMS pages
  static const privacyPolicy = '/privacy-policy';
  static const terms = '/terms';
  static const faq = '/faq';
  static const aboutAse = '/about-ase';
  static const helpSupport = '/help-support';

  // School
  static const aboutSchool = '/about-school';

  // Timetable
  static const timetable = '/timetable';

  // Attendance
  static const attendance = '/attendance';

  // Recaps
  static const recaps = '/recaps';
  static const recapDetail = '/recaps/detail';

  // Homework
  static const homework = '/homework';
  static const homeworkDetail = '/homework/detail';

  // Circulars
  static const circularTypes = '/circulars/types';
  static const circularList = '/circulars/list';
  static const circularDetail = '/circulars/detail';

  // Notifications
  static const notifications = '/notifications';
  static const generalNotifications = notifications; // ✅ FIX: alias for older code

  // Exams
  static const exams = '/exams';
  static const examSchedule = '/exams/schedule';
  static const examResult = '/exams/result';

  // Birthdays
  static const birthdaysToday = '/birthdays/today';

  /// Helper to build "/path?x=1&y=2"
  static String withQuery(String path, Map<String, String> query) {
    final uri = Uri(path: path, queryParameters: query.isEmpty ? null : query);
    return uri.toString();
  }
}
