// lib/features/homework/data/homework_repository_impl.dart

import '../data/homework_api.dart';
import '../domain/homework_repository.dart';

/// Homework Repository Implementation
///
/// ✅ Real backend: GET /homework
/// ✅ Student scoping is enforced by backend token
class HomeworkRepositoryImpl implements HomeworkRepository {
  final HomeworkApi _api;

  HomeworkRepositoryImpl(this._api);

  @override
  Future<List<dynamic>> getMyHomework({
    String? date,
    String? fromDate,
    String? toDate,
    String? subject,
    String? search,
    int? page,
    int? limit,
  }) {
    // If `date` provided, map to fromDate=toDate=date (backend supports date range only)
    final String? effectiveFrom =
        (date != null && date.trim().isNotEmpty) ? date.trim() : (fromDate?.trim());
    final String? effectiveTo =
        (date != null && date.trim().isNotEmpty) ? date.trim() : (toDate?.trim());

    return _api.getHomeworkItems(
      fromDate: (effectiveFrom != null && effectiveFrom.isNotEmpty) ? effectiveFrom : null,
      toDate: (effectiveTo != null && effectiveTo.isNotEmpty) ? effectiveTo : null,
      subject: subject,
      search: search,
      page: page ?? 1,
      limit: limit ?? 50, // better UX than backend default 20
    );
  }

  @override
  Future<List<dynamic>> getTodayHomework({
    String? subject,
    String? search,
    int? page,
    int? limit,
  }) {
    final today = HomeworkApi.formatYyyyMmDd(DateTime.now());

    return _api.getHomeworkItems(
      fromDate: today,
      toDate: today,
      subject: subject,
      search: search,
      page: page ?? 1,
      limit: limit ?? 50,
    );
  }

  @override
  Future<Map<String, dynamic>> getHomeworkDetail(String id) {
    return _api.getHomeworkDetail(id);
  }
}
