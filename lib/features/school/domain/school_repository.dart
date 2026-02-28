// lib/features/school/domain/school_repository.dart

abstract class SchoolRepository {
  /// ✅ Backend: GET /schools/me
  Future<Map<String, dynamic>> getMySchool();

  /// ✅ Backend: GET /cms/school?key=ABOUT_SCHOOL
  ///
  /// Some parts of your project use this name:
  Future<Map<String, dynamic>> getSchoolAbout();

  /// Some parts of your project use this name:
  Future<Map<String, dynamic>> getAboutSchool();

  /// ✅ Backend doesn't have a separate config endpoint; derived from /schools/me
  Future<Map<String, dynamic>> getSchoolConfig();
}
