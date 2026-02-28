// lib/features/cms_pages/data/cms_api.dart
import '../../../core/network/api_client.dart';
import '../../../core/network/response_unwrap.dart';

/// CMS API
///
/// ✅ Backend (authoritative):
/// - GET /api/cms/static?key=PRIVACY_POLICY|TERMS|FAQ|ABOUT_ASE   (PUBLIC)
/// - GET /api/cms/school?key=ABOUT_SCHOOL                       (AUTH + school scope)
///
/// Response shape:
/// {
///   "key": "ABOUT_ASE",
///   "title": "About ASE Technologies",
///   "content": "....",
///   "updatedAt": "2025-01-01T00:00:00.000Z"
/// }
class CmsApi {
  CmsApi(this._api);

  final ApiClient _api;

  /// Static CMS page (PUBLIC)
  Future<Map<String, dynamic>> getStaticPageByKey(String key) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/cms/static',
        queryParameters: <String, dynamic>{'key': key.trim()},
      );
      return unwrapAsMap(res.data);
    } catch (_) {
      return <String, dynamic>{
        'key': key.trim().toUpperCase(),
        'title': key.trim(),
        'content': '',
      };
    }
  }

  /// School-scoped CMS page (AUTH)
  ///
  /// includeInactive is supported by backend for principal usage.
  Future<Map<String, dynamic>> getSchoolPageByKey(
    String key, {
    bool includeInactive = false,
  }) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/cms/school',
        queryParameters: <String, dynamic>{
          'key': key.trim(),
          'includeInactive': includeInactive,
        },
      );
      return unwrapAsMap(res.data);
    } catch (_) {
      return <String, dynamic>{
        'key': key.trim().toUpperCase(),
        'title': key.trim(),
        'content': '',
      };
    }
  }
}
