// lib/features/birthdays/domain/birthdays_repository.dart

/// Birthdays Repository (Student / Parent)
///
/// Read-only.
/// Returns today's birthdays for same-class classmates only (backend-scoped).
abstract class BirthdaysRepository {
  Future<List<dynamic>> getTodayClassmateBirthdays();
}
