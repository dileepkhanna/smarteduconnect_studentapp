// lib/features/attendance/domain/attendance_repository.dart

abstract class AttendanceRepository {
  /// Fetch attendance for the logged-in student.
  ///
  /// - month can be "YYYY-MM" OR "1..12"
  /// - year is "YYYY"
  /// - fromDate/toDate are "YYYY-MM-DD" for day/week/custom ranges
  Future<Map<String, dynamic>> getMyAttendance({
    String? month,
    String? year,
    String? fromDate,
    String? toDate,
  });

  /// Convenience method for a single day (fromDate=toDate=date).
  Future<Map<String, dynamic>> getMyAttendanceByDate(String date);
}
