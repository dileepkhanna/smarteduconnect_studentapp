// lib/features/homework/domain/homework_repository.dart

/// Homework Repository (Parent/Student now, but backend supports roles)
///
/// Existing UI calls:
/// - getMyHomework()
/// - getTodayHomework()
///
/// ✅ Implemented using real backend GET /homework with fromDate/toDate logic.
abstract class HomeworkRepository {
  /// All homework for logged-in student (scoped by backend token).
  ///
  /// Optional filters:
  /// - date: convenience (mapped to fromDate=toDate)
  /// - fromDate/toDate: YYYY-MM-DD
  /// - subject/search: backend-supported
  /// - page/limit: backend pagination (PaginationDto)
  Future<List<dynamic>> getMyHomework({
    String? date,
    String? fromDate,
    String? toDate,
    String? subject,
    String? search,
    int? page,
    int? limit,
  });

  /// Today homework for logged-in student:
  /// backend has no /today route, so we use fromDate=toDate=today on /homework.
  Future<List<dynamic>> getTodayHomework({
    String? subject,
    String? search,
    int? page,
    int? limit,
  });

  /// Used by homework detail screen (if/when needed).
  Future<Map<String, dynamic>> getHomeworkDetail(String id);
}
