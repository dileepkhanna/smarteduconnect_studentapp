// lib/features/recaps/domain/recaps_repository.dart

abstract class RecapsRepository {
  /// Student/Parent: backend automatically scopes to the logged-in student class/section.
  ///
  /// Filters supported by backend via GET /recaps:
  /// - fromDate, toDate (YYYY-MM-DD)
  /// - subject
  /// - search (free text on content)
  /// - page, limit (pagination)
  ///
  /// App convenience:
  /// - date: if provided, we internally map it to fromDate=toDate=date
  Future<List<dynamic>> getMyRecaps({
    String? date, // YYYY-MM-DD (client convenience)
    String? fromDate, // YYYY-MM-DD
    String? toDate, // YYYY-MM-DD
    String? subject,
    String? search,
    int? page,
    int? limit,
  });

  /// Convenience method: fetch recaps only for today (fromDate=toDate=today)
  Future<List<dynamic>> getTodayRecaps();
}
