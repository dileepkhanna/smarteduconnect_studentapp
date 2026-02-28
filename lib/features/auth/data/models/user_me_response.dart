// lib/features/auth/data/models/user_me_response.dart

class UserMeResponse {
  const UserMeResponse({
    required this.id,
    required this.role,
    required this.email,
    required this.phone,
    required this.schoolId,
    required this.schoolCode,
    required this.mustChangePassword,
    required this.biometricsEnabled,
    required this.isActive,
    required this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,

    // OPTIONAL (not currently returned by /users/me in backend, but kept
    // for future-proofing + UI convenience):
    this.fullName,
    this.rollNumber,
    this.classNumber,
    this.section,
    this.profilePhotoUrl,
  });

  final String id;
  final String role;
  final String email;
  final String? phone;
  final String schoolId;
  final String schoolCode;

  final bool mustChangePassword;
  final bool biometricsEnabled;
  final bool isActive;

  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional student-facing fields (may be absent in backend /users/me response)
  final String? fullName;
  final String? rollNumber;
  final int? classNumber;
  final String? section;
  final String? profilePhotoUrl;

  /// Some screens call `updated.user` — make it work by returning self.
  UserMeResponse get user => this;

  /// Screens expect this getter.
  String? get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;

    final em = email.trim();
    if (em.isEmpty) return null;
    final at = em.indexOf('@');
    if (at > 0) return em.substring(0, at);
    return em;
  }

  /// Screens expect this getter.
  String? get classSectionLabel {
    final c = classNumber;
    final s = section?.trim();
    if (c == null && (s == null || s.isEmpty)) return null;
    if (c != null && s != null && s.isNotEmpty) return '$c${s.toUpperCase()}';
    if (c != null) return '$c';
    return s?.toUpperCase();
  }

  /// Screens expect this getter.
  String? get photoUrl => profilePhotoUrl;

  String get roleUpper => role.trim().toUpperCase();
  bool get isStudent => roleUpper == 'STUDENT';

  static DateTime? _parseDt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static DateTime _parseRequiredDt(dynamic v) {
    final dt = _parseDt(v);
    if (dt == null) return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return dt;
  }

  factory UserMeResponse.fromJson(Map<String, dynamic> json) {
    // Parse optional student fields if backend ever includes them
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return UserMeResponse(
      id: (json['id'] as String?)?.trim() ?? '',
      role: (json['role'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim(),
      schoolId: (json['schoolId'] as String?)?.trim() ?? '',
      schoolCode: (json['schoolCode'] as String?)?.trim() ?? '',
      mustChangePassword: json['mustChangePassword'] == true,
      biometricsEnabled: json['biometricsEnabled'] == true,
      isActive: json['isActive'] == true,
      lastLoginAt: _parseDt(json['lastLoginAt']),
      createdAt: _parseRequiredDt(json['createdAt']),
      updatedAt: _parseRequiredDt(json['updatedAt']),

      // Optional
      fullName: (json['fullName'] as String?)?.trim(),
      rollNumber: (json['rollNumber'] as String?)?.trim(),
      classNumber: toInt(json['classNumber']),
      section: (json['section'] as String?)?.trim(),
      profilePhotoUrl: (json['profilePhotoUrl'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'role': role,
      'email': email,
      'phone': phone,
      'schoolId': schoolId,
      'schoolCode': schoolCode,
      'mustChangePassword': mustChangePassword,
      'biometricsEnabled': biometricsEnabled,
      'isActive': isActive,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),

      // Optional
      if (fullName != null) 'fullName': fullName,
      if (rollNumber != null) 'rollNumber': rollNumber,
      if (classNumber != null) 'classNumber': classNumber,
      if (section != null) 'section': section,
      if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
    };
  }
}
