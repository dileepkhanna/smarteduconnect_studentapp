// lib/features/birthdays/data/birthdays_api.dart
import '../../../core/config/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/response_unwrap.dart';

/// Birthdays API (Student / Parent)
///
/// ✅ Backend (authoritative):
/// GET /api/birthdays/students/today
///
/// RULES (as per prompts):
/// • Student sees ONLY same-class classmates’ birthdays
/// • Student gets birthdays ONLY on the actual birthday day (T-0)
/// • Read-only
/// • Backend resolves class/section from auth token (no params needed)
///
/// Expected response (backend):
/// [
///   {
///     "studentId": "uuid",
///     "name": "Rahul",
///     "profilePhoto": "https://r2-url/photo.jpg",
///     "class": "10",
///     "section": "B",
///     "dob": "2010-09-12"
///   }
/// ]
class BirthdaysApi {
  BirthdaysApi(this._api);

  final ApiClient _api;

  /// Fetch ONLY today's birthdays for the logged-in student's class.
  Future<List<dynamic>> getTodayClassmateBirthdays() async {
    final res = await _api.get<dynamic>(
      Endpoints.studentTodayBirthdays,
    );

    final data = unwrapAsList(res.data);

    // Normalize to ensure list contains maps (defensive)
    final out = <dynamic>[];
    for (final it in data) {
      if (it is Map) {
        out.add(Map<String, dynamic>.from(it));
      }
    }
    return out;
  }
}
