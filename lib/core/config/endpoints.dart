// // lib/core/config/endpoints.dart
// //
// // IMPORTANT:
// // - Backend has global prefix: /api
// // - AppConfig.apiBaseUrl already appends "/api"
// // So ALL endpoints here MUST NOT include "/api".

// class Endpoints {
//   Endpoints._();

//   // ------------------------------------------------------------
//   // AUTH (Email OTP = auth_otps + Nodemailer SMTP in backend)
//   // ------------------------------------------------------------
//   static const String login = '/auth/login';
//   static const String refresh = '/auth/refresh';
//   static const String logout = '/auth/logout';

//   static const String forgotPassword = '/auth/forgot-password';
//   static const String verifyOtp = '/auth/verify-otp';
//   static const String resetPassword = '/auth/reset-password';

//   /// Register deviceId + FCM token (Firebase only for Push / FCM)
//   static const String registerDevice = '/auth/register-device';

//   // ------------------------------------------------------------
//   // USERS / PROFILE
//   // ------------------------------------------------------------
//   static const String userMe = '/users/me';

//   /// Preferred real endpoint from backend:
//   /// POST /users/me/change-password
//   static const String changePassword = '/users/me/change-password';

//   /// Backward-compat alias used by some feature code
//   static const String userChangePassword = changePassword;

//   // NOTE: backend also has POST /users/change-password (alias).
//   // Keep it if you want to call it explicitly somewhere.
//   static const String changePasswordAlias = '/users/change-password';

//   // ------------------------------------------------------------
//   // SCHOOLS / CMS
//   // ------------------------------------------------------------

//   /// Backend: GET /schools/me  (returns school details/config under scope)
//   static const String schoolMe = '/schools/me';

//   /// CMS:
//   /// - GET /cms/static?key=PRIVACY_POLICY|TERMS|FAQ|ABOUT_ASE
//   /// - GET /cms/school?key=ABOUT_SCHOOL
//   static const String cmsStatic = '/cms/static';
//   static const String cmsSchool = '/cms/school';

//   // ------------------------------------------------------------
//   // CIRCULARS
//   // ------------------------------------------------------------

//   /// GET /circulars?type=EXAM|EVENT|PTM|HOLIDAY|TRANSPORT|GENERAL
//   static String circulars(String type) {
//     final t = type.trim().toUpperCase();
//     return '/circulars?type=${Uri.encodeQueryComponent(t)}';
//   }

//   /// GET /circulars/:id
//   static String circularDetail(String id) => '/circulars/$id';

//   /// POST /circulars/mark-seen   body: { type: "EVENT" }
//   ///
//   /// We keep the method signature (type param) for compatibility with existing
//   /// feature code, but backend does NOT accept type in querystring.
//   static String circularMarkSeen(String type) => '/circulars/mark-seen';

//   /// GET /circulars/unseen/all
//   /// Returns counts for all types (teacher/student/principal scoped).
//   static const String circularUnseenCounts = '/circulars/unseen/all';

//   /// GET /circulars/unseen/count?type=EVENT
//   static String circularUnseenCount(String type) {
//     final t = type.trim().toUpperCase();
//     return '/circulars/unseen/count?type=${Uri.encodeQueryComponent(t)}';
//   }

//   // ------------------------------------------------------------
//   // ATTENDANCE (Student/Parent)
//   // ------------------------------------------------------------

//   /// GET /attendance/students/my   (supports query fromDate/toDate etc)
//   static const String studentMyAttendance = '/attendance/students/my';

//   // ------------------------------------------------------------
//   // TIMETABLE (Student/Parent)
//   // ------------------------------------------------------------

//   /// GET /timetables/student/me  (student’s own class timetable)
//   static const String studentMyTimetable = '/timetables/student/me';

//   // ------------------------------------------------------------
//   // BIRTHDAYS (Student/Parent)
//   // ------------------------------------------------------------

//   /// GET /birthdays/students/today
//   static const String studentTodayBirthdays = '/birthdays/students/today';

//   /// Teacher upcoming birthdays (used in Teacher/Principal apps, kept for reuse)
//   /// GET /birthdays/teachers/upcoming?days=3
//   static const String teacherUpcomingBirthdays = '/birthdays/teachers/upcoming';

//   // ------------------------------------------------------------
//   // EXAMS (Student/Parent)
//   // ------------------------------------------------------------

//   /// GET /exams/student/my-schedule
//   static const String studentMyExamSchedule = '/exams/student/my-schedule';

//   /// GET /exams/student/my-result
//   static const String studentMyExamResult = '/exams/student/my-result';

//   // ------------------------------------------------------------
//   // NOTIFICATIONS FEED (Student/Parent)
//   // ------------------------------------------------------------

//   /// GET /notifications
//   static const String notifications = '/notifications';

//   /// POST /notifications/mark-read  body: { notificationId } OR { all:true }
//   static const String notificationsMarkRead = '/notifications/mark-read';
// }


















// lib/core/config/endpoints.dart
//
// IMPORTANT:
// - Backend has global prefix: /api
// - AppConfig.apiBaseUrl already appends "/api"
// So ALL endpoints here MUST NOT include "/api".

class Endpoints {
  Endpoints._();

  // ------------------------------------------------------------
  // AUTH (Email OTP = auth_otps + Nodemailer SMTP in backend)
  // ------------------------------------------------------------
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';

  /// Register deviceId + FCM token (Firebase only for Push / FCM)
  static const String registerDevice = '/auth/register-device';

  // ------------------------------------------------------------
  // USERS / PROFILE
  // ------------------------------------------------------------
  static const String userMe = '/users/me';

  /// Preferred real endpoint from backend:
  /// POST /users/me/change-password
  static const String changePassword = '/users/me/change-password';

  /// Backward-compat alias used by some feature code
  static const String userChangePassword = changePassword;

  static const String changePasswordAlias = '/users/change-password';

  // ------------------------------------------------------------
  // SCHOOLS / CMS
  // ------------------------------------------------------------
  static const String schoolMe = '/schools/me';

  static const String cmsStatic = '/cms/static';
  static const String cmsSchool = '/cms/school';

  // ------------------------------------------------------------
  // ✅ CIRCULARS (FIXED)
  // ------------------------------------------------------------

  /// ✅ FIX:
  /// DO NOT embed query params in endpoint string.
  /// We will pass `type` through Dio queryParameters.
static String circulars(String type) => '/circulars';

  /// GET /circulars/:id
  static String circularDetail(String id) => '/circulars/$id';

  /// POST /circulars/mark-seen   body: { type: "EVENT" }
  static String circularMarkSeen(String type) => '/circulars/mark-seen';

  /// GET /circulars/unseen/all
  static const String circularUnseenCounts = '/circulars/unseen/all';

  /// GET /circulars/unseen/count?type=EVENT
  /// (Optional endpoint if you use it somewhere)
  static String circularUnseenCount(String type) {
    final t = type.trim().toUpperCase();
    return '/circulars/unseen/count?type=${Uri.encodeQueryComponent(t)}';
  }

  // ------------------------------------------------------------
  // ATTENDANCE (Student/Parent)
  // ------------------------------------------------------------
  static const String studentMyAttendance = '/attendance/students/my';

  // ------------------------------------------------------------
  // TIMETABLE (Student/Parent)
  // ------------------------------------------------------------
  static const String studentMyTimetable = '/timetables/student/me';

  // ------------------------------------------------------------
  // BIRTHDAYS (Student/Parent)
  // ------------------------------------------------------------
  static const String studentTodayBirthdays = '/birthdays/students/today';
  static const String teacherUpcomingBirthdays = '/birthdays/teachers';

  // ------------------------------------------------------------
  // EXAMS (Student/Parent)
  // ------------------------------------------------------------
  static const String studentMyExamSchedule = '/exams/student/my-schedule';
  static const String studentMyExamResult = '/exams/student/my-result';

  // ------------------------------------------------------------
  // NOTIFICATIONS FEED (Student/Parent)
  // ------------------------------------------------------------
  static const String notifications = '/notifications';
  static const String notificationsMarkRead = '/notifications/mark-read';
}
