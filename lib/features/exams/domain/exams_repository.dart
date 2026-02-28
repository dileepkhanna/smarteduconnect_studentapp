// lib/features/exams/domain/exams_repository.dart

/// Exams Repository (Student / Parent)
///
/// Kept compatible with your current UI calls:
/// - getMyExamSchedule()
/// - getMyExamResults()
/// - getMyExamResultDetail(examId)
///
/// Internally, we normalize backend keys so UI stays stable.
abstract class ExamsRepository {
  Future<List<dynamic>> getMyClassExams();
  Future<List<dynamic>> getMyExamSchedule();
  Future<List<dynamic>> getMyExamResults();
  Future<Map<String, dynamic>> getMyExamResultDetail(String examId);
}
