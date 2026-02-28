// lib/features/homework/data/homework_api.dart
import '../../../core/network/api_client.dart';
import '../../../core/network/response_unwrap.dart';

/// Homework API
///
/// ✅ Real Backend (Backend_Final_Code.zip):
/// - GET    /homework
/// - GET    /homework/:id
///
/// Roles:
/// - STUDENT: backend auto-filters to student's class/section (token scope)
/// - TEACHER: backend auto-filters to teacher's own homework
/// - PRINCIPAL: can view all (optionally filter by teacherUserId/class/section/subject)
///
/// Filtering supported by backend query DTO:
/// - teacherUserId
/// - classNumber
/// - section (single alphabet)
/// - subject
/// - fromDate / toDate (YYYY-MM-DD)
/// - search
/// - page / limit (pagination)
class HomeworkApi {
  HomeworkApi(this._api);

  final ApiClient _api;

  static const String _basePath = '/homework';

  /// GET /homework (paged)
  Future<Map<String, dynamic>> getHomeworkPaged({
    String? teacherUserId,
    int? classNumber,
    String? section,
    String? subject,
    String? fromDate,
    String? toDate,
    String? search,
    int? page,
    int? limit,
  }) async {
    final qp = <String, dynamic>{
      if (teacherUserId != null && teacherUserId.trim().isNotEmpty)
        'teacherUserId': teacherUserId.trim(),
      if (classNumber != null) 'classNumber': classNumber,
      if (section != null && section.trim().isNotEmpty)
        'section': section.trim(),
      if (subject != null && subject.trim().isNotEmpty)
        'subject': subject.trim(),
      if (fromDate != null && fromDate.trim().isNotEmpty)
        'fromDate': fromDate.trim(),
      if (toDate != null && toDate.trim().isNotEmpty) 'toDate': toDate.trim(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
    };

    final res = await _api.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: qp.isEmpty ? null : qp,
    );

    return unwrapAsMap(res.data);
  }

  /// Convenience: returns only `items` from GET /homework
  Future<List<dynamic>> getHomeworkItems({
    String? teacherUserId,
    int? classNumber,
    String? section,
    String? subject,
    String? fromDate,
    String? toDate,
    String? search,
    int? page,
    int? limit,
  }) async {
    final raw = await getHomeworkPaged(
      teacherUserId: teacherUserId,
      classNumber: classNumber,
      section: section,
      subject: subject,
      fromDate: fromDate,
      toDate: toDate,
      search: search,
      page: page,
      limit: limit,
    );

    final items = raw['items'];
    if (items is List) return List<dynamic>.from(items);
    // fallback: allow server variations safely
    if (raw['data'] is List) return List<dynamic>.from(raw['data'] as List);
    return <dynamic>[];
  }

  /// GET /homework/:id
  Future<Map<String, dynamic>> getHomeworkDetail(String id) async {
    final safeId = id.trim();
    if (safeId.isEmpty) return <String, dynamic>{};

    final res = await _api.get<Map<String, dynamic>>(
      '$_basePath/$safeId',
      queryParameters: null,
    );
    return unwrapAsMap(res.data);
  }

  // -----------------------
  // Helpers
  // -----------------------

  static String formatYyyyMmDd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
