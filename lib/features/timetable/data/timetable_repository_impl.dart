// lib/features/timetable/data/timetable_repository_impl.dart

import '../domain/timetable_repository.dart';
import 'timetable_api.dart';

class TimetableRepositoryImpl implements TimetableRepository {
  TimetableRepositoryImpl(this._api);

  final TimetableApi _api;

  @override
  Future<Map<String, dynamic>> getMyTimetable() {
    return _api.getMyTimetable();
  }

  @override
  Future<Map<String, dynamic>> getTimetableByDate(String date) {
    return _api.getMyTimetableByDate(date);
  }
}
