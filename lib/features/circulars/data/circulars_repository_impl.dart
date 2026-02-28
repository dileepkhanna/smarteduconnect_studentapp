import 'circulars_api.dart';
import '../domain/circulars_repository.dart';

class CircularsRepositoryImpl implements CircularsRepository {
  final CircularsApi _api;

  CircularsRepositoryImpl(this._api);

  @override
  Future<List<dynamic>> getCircularsByType(
    String type, {
    String? search,
    bool? isActive,
    int? page,
    int? limit,
  }) {
    return _api.getCircularsByType(
      type,
      search: search,
      isActive: isActive,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<Map<String, dynamic>> getCircularDetail(String id) {
    return _api.getCircularDetail(id);
  }

  @override
  Future<void> markTypeAsSeen(String type) {
    return _api.markSeen(type);
  }

  @override
  Future<Map<String, dynamic>> getUnseenCounts() {
    return _api.getUnseenCounts();
  }
}
