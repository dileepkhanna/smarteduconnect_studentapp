// lib/features/school/data/school_repository_impl.dart

import '../domain/school_repository.dart';
import 'school_api.dart';

class SchoolRepositoryImpl implements SchoolRepository {
  SchoolRepositoryImpl(this._api);

  final SchoolApi _api;

  @override
  Future<Map<String, dynamic>> getMySchool() {
    return _api.getMySchool();
  }

  @override
  Future<Map<String, dynamic>> getSchoolAbout() {
    return _api.getAboutSchool();
  }

  @override
  Future<Map<String, dynamic>> getAboutSchool() {
    // Alias for compatibility
    return _api.getAboutSchool();
  }

  @override
  Future<Map<String, dynamic>> getSchoolConfig() {
    return _api.getSchoolConfig();
  }
}
