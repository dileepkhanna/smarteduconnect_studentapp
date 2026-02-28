// lib/features/circulars/domain/circulars_repository.dart

abstract class CircularsRepository {
  /// List circulars by type (EXAM/EVENT/PTM/HOLIDAY/TRANSPORT/GENERAL)
  ///
  /// Backend supports optional search and pagination.
  Future<List<dynamic>> getCircularsByType(
    String type, {
    String? search,
    bool? isActive,
    int? page,
    int? limit,
  });

  /// Detail screen
  Future<Map<String, dynamic>> getCircularDetail(String id);

  /// Mark category as seen (clears unseen badge for that type)
  Future<void> markTypeAsSeen(String type);

  /// Unseen counts for all types: { "EXAM": 2, "EVENT": 0, ... }
  Future<Map<String, dynamic>> getUnseenCounts();
}
