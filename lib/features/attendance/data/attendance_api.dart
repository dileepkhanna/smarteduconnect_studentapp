// lib/features/attendance/data/attendance_api.dart
import '../../../core/config/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/response_unwrap.dart';

/// Attendance API (Student / Parent)
///
/// ✅ Backend (authoritative):
/// GET /api/attendance/students/my
///
/// Query supported by backend AttendanceFilterQueryDto:
/// - month: int (1..12)
/// - year: int (2000..2100)
/// - fromDate: YYYY-MM-DD
/// - toDate: YYYY-MM-DD
///
/// Response shape (backend):
/// {
///   student: { studentProfileId, fullName, rollNumber, classNumber, section },
///   range: { from, to },
///   percentage,
///   presentDays,
///   halfDays,
///   absentDays,
///   totalDays,
///   items: [ { date, morningStatus, afternoonStatus, finalStatus } ]
/// }
///
/// UI expects a normalized structure:
/// {
///   summary: { totalDays, present, absent, halfDay, percentage },
///   records: [ { date, morning, afternoon, final } ],
///   student?: ...,
///   range?: ...
/// }
class AttendanceApi {
  AttendanceApi(this._api);

  final ApiClient _api;

  /// Fetch my attendance with flexible filters.
  ///
  /// Notes:
  /// - You can pass month as:
  ///   - "YYYY-MM" (e.g., "2025-12") OR
  ///   - "12" (with year="2025")
  /// - For day/week/custom ranges, use fromDate/toDate (YYYY-MM-DD).
  Future<Map<String, dynamic>> getMyAttendance({
    String? month, // "YYYY-MM" or "1..12"
    String? year, // "YYYY"
    String? fromDate, // "YYYY-MM-DD"
    String? toDate, // "YYYY-MM-DD"
  }) async {
    final parsed = _parseMonthYear(month: month, year: year);

    final qp = <String, dynamic>{
      if (parsed.month != null) 'month': parsed.month,
      if (parsed.year != null) 'year': parsed.year,
      if (_isNonEmpty(fromDate)) 'fromDate': fromDate!.trim(),
      if (_isNonEmpty(toDate)) 'toDate': toDate!.trim(),
    };

    final res = await _api.get<Map<String, dynamic>>(
      Endpoints.studentMyAttendance,
      queryParameters: qp.isEmpty ? null : qp,
    );

    final raw = unwrapAsMap(res.data);
    return _normalizeAttendance(raw);
  }

  /// Day-wise view:
  /// Backend uses the same endpoint; we set fromDate=toDate=date.
  Future<Map<String, dynamic>> getMyAttendanceByDate(String date) {
    return getMyAttendance(fromDate: date, toDate: date);
  }

  Map<String, dynamic> _normalizeAttendance(Map<String, dynamic> raw) {
    // Backend authoritative keys:
    final totalDays = _toInt(raw['totalDays'] ?? raw['total']);
    final presentDays = _toInt(raw['presentDays'] ?? raw['present']);
    final absentDays = _toInt(raw['absentDays'] ?? raw['absent']);
    final halfDays =
        _toInt(raw['halfDays'] ?? raw['halfDay'] ?? raw['halfday']);
    final percentage = _toNum(raw['percentage']);

    final items = (raw['items'] is List)
        ? List<dynamic>.from(raw['items'] as List)
        : const <dynamic>[];

    final records = <Map<String, dynamic>>[];
    for (final it in items) {
      if (it is! Map) continue;
      final m = Map<String, dynamic>.from(it as Map);

      records.add({
        'date': (m['date'] ?? '').toString(),
        'morning': (m['morningStatus'] ?? m['morning'] ?? '').toString(),
        'afternoon': (m['afternoonStatus'] ?? m['afternoon'] ?? '').toString(),
        'final': (m['finalStatus'] ?? m['final'] ?? '').toString(),
      });
    }

    return <String, dynamic>{
      if (raw['student'] != null) 'student': raw['student'],
      if (raw['range'] != null) 'range': raw['range'],
      'summary': <String, dynamic>{
        'totalDays': totalDays,
        'present': presentDays,
        'absent': absentDays,
        'halfDay': halfDays,
        'percentage': percentage,
      },
      'records': records,
    };
  }

  _MonthYear _parseMonthYear({String? month, String? year}) {
    final m = month?.trim();
    final y = year?.trim();

    int? monthInt;
    int? yearInt;

    // Accept "YYYY-MM" (common from UI)
    if (_isNonEmpty(m) && m!.contains('-')) {
      final parts = m.split('-');
      if (parts.length >= 2) {
        final yParsed = int.tryParse(parts[0]);
        final mParsed = int.tryParse(parts[1]);
        if (yParsed != null) yearInt = yParsed;
        if (mParsed != null) monthInt = mParsed;
      }
    } else if (_isNonEmpty(m)) {
      monthInt = int.tryParse(m!);
    }

    if (yearInt == null && _isNonEmpty(y)) {
      yearInt = int.tryParse(y!);
    }

    // Backend validation guards (keep client clean)
    if (monthInt != null && (monthInt < 1 || monthInt > 12)) monthInt = null;
    if (yearInt != null && (yearInt < 2000 || yearInt > 2100)) yearInt = null;

    return _MonthYear(month: monthInt, year: yearInt);
  }

  bool _isNonEmpty(String? s) => s != null && s.trim().isNotEmpty;

  int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  num _toNum(dynamic v) {
    if (v is num) return v;
    return num.tryParse(v?.toString() ?? '') ?? 0;
  }
}

class _MonthYear {
  final int? month;
  final int? year;
  const _MonthYear({this.month, this.year});
}
