// lib/features/cms_pages/data/cms_repository_impl.dart
import '../data/cms_api.dart';
import '../domain/cms_repository.dart';

class CmsRepositoryImpl implements CmsRepository {
  final CmsApi _api;

  CmsRepositoryImpl(this._api);

  @override
  Future<Map<String, dynamic>> getStaticPageByKey(String key) {
    return _api.getStaticPageByKey(key);
  }

  @override
  Future<Map<String, dynamic>> getSchoolPageByKey(
    String key, {
    bool includeInactive = false,
  }) {
    return _api.getSchoolPageByKey(key, includeInactive: includeInactive);
  }

  @override
  Future<Map<String, dynamic>> getCmsPage(String slug) {
    // Slug -> Static key mapping (backward compatibility)
    final key = CmsRepository.slugToStaticKey(slug);

    if (key != null) {
      return getStaticPageByKey(key);
    }

    // Support school-scoped key if passed directly
    if (slug.trim().toUpperCase() == 'ABOUT_SCHOOL') {
      return getSchoolPageByKey('ABOUT_SCHOOL');
    }

    // Fallback: treat slug as a key
    return getStaticPageByKey(slug.trim().toUpperCase());
  }

  /// ✅ IMPORTANT: Some projects keep `getPage()` abstract (no default implementation).
  /// So we implement it explicitly to avoid:
  /// "Missing concrete implementation of CmsRepository.getPage"
  @override
  Future<Map<String, dynamic>> getPage(String slug) => getCmsPage(slug);
}
