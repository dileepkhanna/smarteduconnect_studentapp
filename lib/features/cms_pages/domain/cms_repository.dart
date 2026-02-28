// lib/features/cms_pages/domain/cms_repository.dart

abstract class CmsRepository {
  /// ✅ Static pages: PRIVACY_POLICY / TERMS / FAQ / ABOUT_ASE
  Future<Map<String, dynamic>> getStaticPageByKey(String key);

  /// ✅ School-scoped pages: ABOUT_SCHOOL
  Future<Map<String, dynamic>> getSchoolPageByKey(
    String key, {
    bool includeInactive = false,
  });

  /// Backward compatibility for older code that uses "slug"
  /// (e.g. "about-ase", "privacy-policy").
  Future<Map<String, dynamic>> getCmsPage(String slug);

  /// backward compatibility (some screens might call getPage)
  Future<Map<String, dynamic>> getPage(String slug) => getCmsPage(slug);

  /// Utility mapping for old slug-based screens.
  static String? slugToStaticKey(String slug) {
    final s = slug.trim().toLowerCase();
    switch (s) {
      case 'privacy-policy':
      case 'privacy_policy':
      case 'privacy':
        return 'PRIVACY_POLICY';
      case 'terms':
      case 'terms-and-conditions':
      case 'terms_conditions':
      case 'terms-conditions':
        return 'TERMS';
      case 'faq':
        return 'FAQ';
      case 'about-ase':
      case 'about_ase':
      case 'about-ase-technologies':
        return 'ABOUT_ASE';
      // If later backend adds a static help page key, this supports it:
      case 'help-support':
      case 'help_support':
      case 'help':
      case 'support':
        return 'HELP_SUPPORT';
      default:
        return null;
    }
  }
}
