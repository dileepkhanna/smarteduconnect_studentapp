// lib/features/school/data/school_api.dart
import '../../../core/network/api_client.dart';
import '../../../core/network/response_unwrap.dart';

/// School APIs for Teacher/Parent apps
///
/// ✅ REAL BACKEND (Backend_Final_Code.zip)
/// - GET /schools/me
/// - GET /cms/school?key=ABOUT_SCHOOL
class SchoolApi {
  SchoolApi(this._api);

  final ApiClient _api;

  /// ✅ GET /schools/me
  ///
  /// Returns (backend):
  /// {
  ///   id, schoolCode, name, logoUrl,
  ///   geofenceLat, geofenceLng, geofenceRadiusM,
  ///   examGradeScale, isActive, createdAt, updatedAt
  /// }
  Future<Map<String, dynamic>> getMySchool() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/schools/me');
      return unwrapAsMap(res.data);
    } catch (_) {
      return <String, dynamic>{
        'name': 'ASE School',
        'schoolCode': '',
      };
    }
  }

  /// ✅ GET /cms/school?key=ABOUT_SCHOOL
  ///
  /// Returns (backend):
  /// { key, title, content, updatedAt }
  Future<Map<String, dynamic>> getAboutSchool() async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/cms/school',
        queryParameters: const <String, dynamic>{'key': 'ABOUT_SCHOOL'},
      );
      return unwrapAsMap(res.data);
    } catch (_) {
      return <String, dynamic>{
        'title': 'About School',
        'content': '',
      };
    }
  }

  /// No dedicated endpoint exists in backend for "school config".
  /// We derive config from GET /schools/me (safe + production friendly).
  Future<Map<String, dynamic>> getSchoolConfig() async {
    final s = await getMySchool();
    return <String, dynamic>{
      'schoolCode': s['schoolCode'],
      'geofenceLat': s['geofenceLat'],
      'geofenceLng': s['geofenceLng'],
      'geofenceRadiusM': s['geofenceRadiusM'],
      'examGradeScale': s['examGradeScale'],
      'isActive': s['isActive'],
      'updatedAt': s['updatedAt'],
    };
  }
}
