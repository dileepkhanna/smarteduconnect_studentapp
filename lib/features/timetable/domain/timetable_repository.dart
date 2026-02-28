// lib/features/timetable/domain/timetable_repository.dart

abstract class TimetableRepository {
  /// Full timetable (week) for current logged-in user.
  /// - STUDENT: GET /timetables/student/me
  /// - TEACHER: GET /timetables/teacher/my (fallback)
  Future<Map<String, dynamic>> getMyTimetable();

  /// Timetable filtered by date (day).
  /// Implemented client-side by filtering the weekly timetable.
  Future<Map<String, dynamic>> getTimetableByDate(String date);
}
