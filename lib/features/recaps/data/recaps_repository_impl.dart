// lib/features/recaps/data/recaps_repository_impl.dart

import '../data/recaps_api.dart';
import '../domain/recaps_repository.dart';

/// Recaps Repository Implementation (Student / Parent)
///
/// ✅ Uses REAL backend:
/// - GET /recaps (role scoped)
class RecapsRepositoryImpl implements RecapsRepository {
  final RecapsApi _api;

  RecapsRepositoryImpl(this._api);

  @override
  Future<List<dynamic>> getMyRecaps({
    String? date,
    String? fromDate,
    String? toDate,
    String? subject,
    String? search,
    int? page,
    int? limit,
  }) {
    return _api.getMyRecaps(
      date: date,
      fromDate: fromDate,
      toDate: toDate,
      subject: subject,
      search: search,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<List<dynamic>> getTodayRecaps() {
    return _api.getTodayRecaps();
  }
}
