// lib/features/exams/data/exams_api.dart
import '../../../core/network/api_client.dart';
import '../../../core/network/response_unwrap.dart';

/// Exams API (Student / Parent)
///
/// ✅ Backend (authoritative):
/// - GET  /exams/student/my-schedule?examId=... (optional)
/// - GET  /exams/student/my-result?examId=...   (required; only if published)
///
/// Notes:
/// • Student/Parent is READ-ONLY
/// • Student scope (class/section) is resolved by backend from auth token
/// • Results are visible ONLY after teacher publishes (backend enforces)
class ExamsApi {
  ExamsApi(this._api);

  final ApiClient _api;

  // These are relative to the API base (your ApiClient base should already include /api)
  static const String _examsPath = '/exams';
  static const String _studentMySchedulePath = '/exams/student/my-schedule';
  static const String _studentMyResultPath = '/exams/student/my-result';

  /// Student-visible exams list (class/section filtered by backend token scope).
  Future<List<Map<String, dynamic>>> getMyClassExamsRaw() async {
    final res = await _api.get<dynamic>(
      _examsPath,
      queryParameters: const <String, dynamic>{
        'page': 1,
        'limit': 200,
      },
    );
    final data = unwrapAsList(res.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  }

  /// Raw schedule list from backend.
  ///
  /// Backend item shape:
  /// {
  ///   "id": "...",
  ///   "examId": "...",
  ///   "classNumber": 10,
  ///   "section": "B" | null,
  ///   "subject": "Math",
  ///   "examDate": "YYYY-MM-DD",
  ///   "timing": "09:30 AM - 12:30 PM"
  /// }
  Future<List<Map<String, dynamic>>> getMyExamScheduleRaw({
    String? examId,
  }) async {
    final qp = <String, dynamic>{
      if (examId != null && examId.trim().isNotEmpty) 'examId': examId.trim(),
    };

    final res = await _api.get<dynamic>(
      _studentMySchedulePath,
      queryParameters: qp.isEmpty ? null : qp,
    );

    final data = unwrapAsList(res.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  }

  /// Detailed result for a specific exam (published only).
  ///
  /// ✅ Backend:
  /// GET /exams/student/my-result?examId=UUID
  ///
  /// Response shape (backend):
  /// {
  ///   "examId": "...",
  ///   "studentProfileId": "...",
  ///   "classNumber": 10,
  ///   "section": "B",
  ///   "totalObtained": 420,
  ///   "totalMax": 500,
  ///   "percentage": 84,
  ///   "grade": "A",
  ///   "resultStatus": "PASS" | "FAIL",
  ///   "publishedAt": "...",
  ///   "subjects": [{"subject":"Math","obtained":90,"max":100}, ...]
  /// }
  Future<Map<String, dynamic>> getMyExamResultDetail(String examId) async {
    final res = await _api.get<Map<String, dynamic>>(
      _studentMyResultPath,
      queryParameters: <String, dynamic>{'examId': examId.trim()},
    );
    return unwrapAsMap(res.data);
  }
}
