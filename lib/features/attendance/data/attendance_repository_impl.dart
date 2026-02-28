// lib/features/attendance/data/attendance_repository_impl.dart
import '../data/attendance_api.dart';
import '../domain/attendance_repository.dart';

/// Attendance Repository Implementation (Student / Parent)
///
/// • Read-only access
/// • Strictly scoped to logged-in student (backend enforces scope)
class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceApi _api;

  AttendanceRepositoryImpl(this._api);

  @override
  Future<Map<String, dynamic>> getMyAttendance({
    String? month,
    String? year,
    String? fromDate,
    String? toDate,
  }) {
    return _api.getMyAttendance(
      month: month,
      year: year,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  @override
  Future<Map<String, dynamic>> getMyAttendanceByDate(String date) {
    return _api.getMyAttendanceByDate(date);
  }
}
