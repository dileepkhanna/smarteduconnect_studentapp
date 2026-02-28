// lib/features/birthdays/data/birthdays_repository_impl.dart
import '../data/birthdays_api.dart';
import '../domain/birthdays_repository.dart';

class BirthdaysRepositoryImpl implements BirthdaysRepository {
  BirthdaysRepositoryImpl(this._api);

  final BirthdaysApi _api;

  @override
  Future<List<dynamic>> getTodayClassmateBirthdays() {
    return _api.getTodayClassmateBirthdays();
  }
}
