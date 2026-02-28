class Validators {
  static String? required(String? v, {String message = 'This field is required'}) {
    if (v == null || v.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!re.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? schoolCode(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'School code is required';
    if (value.length < 3) return 'School code is too short';
    return null;
  }

  static String? password(String? v, {int min = 6}) {
    final value = (v ?? '');
    if (value.isEmpty) return 'Password is required';
    if (value.length < min) return 'Password must be at least $min characters';
    return null;
  }

  static String? otp(String? v, {int length = 6}) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'OTP is required';
    if (value.length != length) return 'OTP must be $length digits';
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'OTP must be numeric';
    return null;
  }

  static String? name(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Enter a valid name';
    return null;
  }

  static String? phone(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return null; // optional
    final re = RegExp(r'^\d{10}$');
    if (!re.hasMatch(value)) return 'Enter a valid 10-digit phone number';
    return null;
  }
}
