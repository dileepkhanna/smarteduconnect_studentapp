// lib/features/exams/data/exams_repository_impl.dart

import 'package:dio/dio.dart';

import '../data/exams_api.dart';
import '../domain/exams_repository.dart';

/// Exams Repository Implementation (Student / Parent)
///
/// ✅ Uses real backend routes:
/// - /exams/student/my-schedule
/// - /exams/student/my-result
///
/// What this layer does:
/// • Normalizes schedule keys -> { examId, examName, subject, date, time }
/// • Builds a "results list" even though backend exposes result-by-examId only:
///   - derives unique examIds from schedule
///   - fetches result detail for each examId
///   - skips those not published (404 "Result not published")
class ExamsRepositoryImpl implements ExamsRepository {
  ExamsRepositoryImpl(this._api);

  final ExamsApi _api;

  @override
  Future<List<dynamic>> getMyClassExams() async {
    final raw = await _api.getMyClassExamsRaw();
    return raw.map((e) {
      final map = Map<String, dynamic>.from(e);
      return <String, dynamic>{
        'id': (map['id'] ?? '').toString(),
        'examName': (map['examName'] ?? 'Exam').toString(),
        'academicYear': (map['academicYear'] ?? '').toString(),
        'startDate': (map['startDate'] ?? '').toString(),
        'endDate': (map['endDate'] ?? '').toString(),
        'classSections': map['classSections'] ??
            map['applicableClassSections'] ??
            const <dynamic>[],
      };
    }).toList(growable: false);
  }

  @override
  Future<List<dynamic>> getMyExamSchedule() async {
    final raw = await _api.getMyExamScheduleRaw();

    // Build a friendly per-exam label using date range (backend doesn't expose examName to students).
    final labelByExamId = _buildExamLabels(raw);

    // Normalize to what your current UI expects.
    return raw.map((s) {
      final examId = (s['examId'] ?? '').toString();
      return <String, dynamic>{
        'examId': examId,
        'examName': labelByExamId[examId] ?? 'Exam',
        'subject': (s['subject'] ?? '').toString(),
        'date': (s['examDate'] ?? '').toString(),
        'time': (s['timing'] ?? '').toString(),
        // keep extra fields if later screens want them
        'classNumber': s['classNumber'],
        'section': s['section'],
      };
    }).toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> getMyExamResultDetail(String examId) async {
    final raw = await _api.getMyExamResultDetail(examId);
    if (raw.isEmpty) return raw;

    // Normalize + add compatibility fields used in some UIs
    final out = Map<String, dynamic>.from(raw);

    // Some UI code uses "overallGrade" instead of "grade"
    out['overallGrade'] = out['overallGrade'] ?? out['grade'];

    // Ensure numeric types are consistent
    out['totalObtained'] = _toNum(out['totalObtained']);
    out['totalMax'] = _toNum(out['totalMax']);
    out['percentage'] = _toNum(out['percentage']);

    return out;
  }

  @override
  Future<List<dynamic>> getMyExamResults() async {
    // Backend doesn't have "list my results".
    // So we:
    // 1) fetch schedule
    // 2) extract unique examIds
    // 3) fetch result for each examId (only published ones will succeed)
    final scheduleRaw = await _api.getMyExamScheduleRaw();
    if (scheduleRaw.isEmpty) return const <dynamic>[];

    final labelByExamId = _buildExamLabels(scheduleRaw);

    final examIds = <String>{};
    for (final s in scheduleRaw) {
      final id = (s['examId'] ?? '').toString();
      if (id.trim().isNotEmpty) examIds.add(id.trim());
    }

    final results = <Map<String, dynamic>>[];

    for (final examId in examIds) {
      try {
        final detail = await getMyExamResultDetail(examId);

        // If published, backend returns the object. Add list-friendly fields.
        results.add(<String, dynamic>{
          'examId': examId,
          'examName': labelByExamId[examId] ?? 'Exam',
          // backend doesn't provide academicYear for student result endpoint
          'academicYear': '',
          'percentage': detail['percentage'],
          'overallGrade': detail['overallGrade'] ?? detail['grade'],
          'publishedAt': detail['publishedAt'],
          // keep extra fields
          'grade': detail['grade'],
          'resultStatus': detail['resultStatus'],
          'totalObtained': detail['totalObtained'],
          'totalMax': detail['totalMax'],
        });
      } on DioException catch (e) {
        // Expected when result is not published yet
        if (e.response?.statusCode == 404) {
          continue;
        }
        // Non-404 failures for one exam should not break the whole screen.
        continue;
      } catch (_) {
        // Be safe: skip unexpected parsing issues for one examId
        continue;
      }
    }

    // Sort latest published first (if available)
    results.sort((a, b) {
      final da = _tryParseDateTime(a['publishedAt']?.toString());
      final db = _tryParseDateTime(b['publishedAt']?.toString());
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    return results;
  }

  // -----------------------
  // Helpers
  // -----------------------

  Map<String, String> _buildExamLabels(List<Map<String, dynamic>> scheduleRaw) {
    final datesByExam = <String, List<DateTime>>{};

    for (final s in scheduleRaw) {
      final examId = (s['examId'] ?? '').toString().trim();
      final d = _tryParseDate((s['examDate'] ?? '').toString());
      if (examId.isEmpty || d == null) continue;
      (datesByExam[examId] ??= <DateTime>[]).add(d);
    }

    final out = <String, String>{};
    for (final entry in datesByExam.entries) {
      final list = entry.value..sort();
      final start = list.first;
      final end = list.last;

      // Example label:
      // "Exam (Feb 10 - Feb 16)"
      out[entry.key] = start == end
          ? 'Exam (${_fmtShort(start)})'
          : 'Exam (${_fmtShort(start)} - ${_fmtShort(end)})';
    }
    return out;
  }

  DateTime? _tryParseDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    // backend sends "YYYY-MM-DD"
    return DateTime.tryParse(s);
  }

  DateTime? _tryParseDateTime(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  String _fmtShort(DateTime dt) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final m = months[(dt.month - 1).clamp(0, 11)];
    return '$m ${dt.day}';
  }

  num _toNum(dynamic v) {
    if (v is num) return v;
    if (v == null) return 0;
    return num.tryParse(v.toString()) ?? 0;
  }
}
