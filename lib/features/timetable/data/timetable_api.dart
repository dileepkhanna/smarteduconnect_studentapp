// lib/features/timetable/data/timetable_api.dart

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/response_unwrap.dart';

/// Timetable API (works for both Parent/Student App and Teacher App)
///
/// Backend routes (NestJS):
/// STUDENT:
///   - GET /timetables/student/me   (preferred)
///   - GET /timetables/student/my   (kept in backend)
/// TEACHER:
///   - GET /timetables/teacher/my
///
/// Backend student timetable response:
/// {
///   id, classNumber, section, isActive, createdBy, createdAt, updatedAt,
///   slots: [{ id, dayOfWeek, timing, subject, sortOrder }]
/// }
///
/// Backend teacher timetable response:
/// {
///   id, teacherUserId, isActive, createdBy, createdAt, updatedAt,
///   slots: [{ id, dayOfWeek, timing, classNumber, section, subject, assignedTeacherUserId, sortOrder }]
/// }
///
/// This API normalizes into a UI-friendly shape:
/// {
///   type: "STUDENT" | "TEACHER",
///   id, classNumber?, section?, teacherUserId?,
///   isActive, updatedAt,
///   days: [ { dayOfWeek, dayLabel, slots:[...] } ],
///   slots: [ ...flat normalized slots... ] // optional convenience
/// }
class TimetableApi {
  TimetableApi(this._api);

  final ApiClient _api;

  // -----------------------
  // Public (used by repository)
  // -----------------------

  Future<Map<String, dynamic>> getMyTimetable() async {
    // Parent/Student app must use student endpoints only.
    try {
      final raw = await _getMap('/timetables/student/me');
      return _normalizeTimetable(raw, fallbackType: 'STUDENT');
    } on DioException catch (e) {
      // Some backends may expose student/my alias.
      final status = e.response?.statusCode;
      if (status == 404) {
        try {
          final raw2 = await _getMap('/timetables/student/my');
          return _normalizeTimetable(raw2, fallbackType: 'STUDENT');
        } on DioException catch (aliasErr) {
          if (aliasErr.response?.statusCode == 404) {
            // No timetable assigned for this student/class.
            return _emptyStudentTimetable();
          }
          rethrow;
        }
      }
      // For non-404 (401/403/5xx), bubble up so UI shows real error.
      rethrow;
    }
  }

  /// Day-wise view:
  /// Backend doesn't provide a separate "by date" endpoint for students/teachers,
  /// so we filter the weekly timetable.
  ///
  /// [date] must be ISO like "2025-12-31".
  Future<Map<String, dynamic>> getMyTimetableByDate(String date) async {
    final weekly = await getMyTimetable();

    final dt = _parseDate(date);
    final dow = dt.weekday; // Mon=1..Sun=7 (matches backend convention)

    final days = (weekly['days'] is List)
        ? List<Map<String, dynamic>>.from(
            (weekly['days'] as List).whereType<Map>())
        : <Map<String, dynamic>>[];

    final day = days.firstWhere(
      (d) => _toInt(d['dayOfWeek']) == dow,
      orElse: () => <String, dynamic>{
        'dayOfWeek': dow,
        'dayLabel': _dayLabel(dow),
        'slots': <Map<String, dynamic>>[],
      },
    );

    return <String, dynamic>{
      'date': date,
      'dayOfWeek': dow,
      'dayLabel': _dayLabel(dow),
      'type': weekly['type'],
      'meta': <String, dynamic>{
        'id': weekly['id'],
        'classNumber': weekly['classNumber'],
        'section': weekly['section'],
        'teacherUserId': weekly['teacherUserId'],
        'isActive': weekly['isActive'],
        'updatedAt': weekly['updatedAt'],
      },
      'slots': (day['slots'] is List)
          ? List<Map<String, dynamic>>.from(
              (day['slots'] as List).whereType<Map>())
          : <Map<String, dynamic>>[],
    };
  }

  // -----------------------
  // Optional extra endpoints (useful for Principal CRUD later)
  // -----------------------

  Future<List<Map<String, dynamic>>> listStudentTimetables() async {
    final raw = await _getAny('/timetables/student');
    final list = _asList(raw);
    return list
        .map(_asMap)
        .map((m) => _normalizeTimetable(m, fallbackType: 'STUDENT'))
        .toList();
  }

  Future<List<Map<String, dynamic>>> listTeacherTimetables() async {
    final raw = await _getAny('/timetables/teacher');
    final list = _asList(raw);
    return list
        .map(_asMap)
        .map((m) => _normalizeTimetable(m, fallbackType: 'TEACHER'))
        .toList();
  }

  // -----------------------
  // Core helpers
  // -----------------------

  Future<dynamic> _getAny(String path, {Map<String, dynamic>? query}) async {
    final res = await _api.get<dynamic>(path, query: query);
    return unwrapEnvelope(res.data);
  }

  Future<Map<String, dynamic>> _getMap(String path,
      {Map<String, dynamic>? query}) async {
    final data = await _getAny(path, query: query);
    return _asMap(data);
  }

  Map<String, dynamic> _normalizeTimetable(
    Map<String, dynamic> raw, {
    required String fallbackType,
  }) {
    // If already normalized, just return
    if (raw['days'] is List && raw['type'] is String) return raw;

    final slotsRaw = (raw['slots'] is List)
        ? List<dynamic>.from(raw['slots'] as List)
        : <dynamic>[];

    final bool isTeacher = raw.containsKey('teacherUserId') ||
        slotsRaw.any(
            (e) => e is Map && (e as Map).containsKey('assignedTeacherUserId'));

    final type = isTeacher ? 'TEACHER' : fallbackType;

    final normalizedSlots = <Map<String, dynamic>>[];
    for (final s in slotsRaw) {
      if (s is! Map) continue;
      final m = Map<String, dynamic>.from(s as Map);

      final timing = (m['timing'] ?? '').toString().trim();
      final timingParsed = _parseTiming(timing);

      normalizedSlots.add(<String, dynamic>{
        'id': m['id'],
        'dayOfWeek': _toInt(m['dayOfWeek']),
        'dayLabel': _dayLabel(_toInt(m['dayOfWeek'])),
        'timing': timingParsed['label'],
        'startTime': timingParsed['startTime'], // best-effort
        'endTime': timingParsed['endTime'], // best-effort
        'subject': (m['subject'] ?? '').toString(),
        'sortOrder': _toInt(m['sortOrder']),
        if (isTeacher) 'classNumber': _toInt(m['classNumber']),
        if (isTeacher)
          'section': (m['section'] == null) ? null : m['section'].toString(),
        if (isTeacher) 'assignedTeacherUserId': m['assignedTeacherUserId'],
      });
    }

    // Sort stable: dayOfWeek -> sortOrder -> startTime
    normalizedSlots.sort((a, b) {
      final d = _toInt(a['dayOfWeek']).compareTo(_toInt(b['dayOfWeek']));
      if (d != 0) return d;

      final so = _toInt(a['sortOrder']).compareTo(_toInt(b['sortOrder']));
      if (so != 0) return so;

      final stA = (a['startTime'] ?? '') as String;
      final stB = (b['startTime'] ?? '') as String;
      return stA.compareTo(stB);
    });

    final Map<int, List<Map<String, dynamic>>> byDay =
        <int, List<Map<String, dynamic>>>{};
    for (final s in normalizedSlots) {
      final dow = _toInt(s['dayOfWeek']);
      final arr = byDay[dow] ?? <Map<String, dynamic>>[];
      arr.add(s);
      byDay[dow] = arr;
    }

    final days = <Map<String, dynamic>>[];
    for (int dow = 1; dow <= 7; dow++) {
      days.add(<String, dynamic>{
        'dayOfWeek': dow,
        'dayLabel': _dayLabel(dow),
        'slots': byDay[dow] ?? <Map<String, dynamic>>[],
      });
    }

    return <String, dynamic>{
      'type': type,
      'id': raw['id'],
      'isActive': raw['isActive'] ?? true,
      'updatedAt': raw['updatedAt'],
      // Student meta
      'classNumber': raw['classNumber'],
      'section': raw['section'],
      // Teacher meta
      'teacherUserId': raw['teacherUserId'],
      // Normalized
      'days': days,
      'slots': normalizedSlots,
    };
  }

  Map<String, dynamic> _parseTiming(String timing) {
    final t = timing.trim();
    if (t.isEmpty) {
      return <String, dynamic>{'label': '', 'startTime': '', 'endTime': ''};
    }

    // Try to extract times like "09:00 - 09:45", "9:00 AM - 9:45 AM", "09:00 to 09:45"
    final cleaned = t.replaceAll('–', '-').replaceAll('—', '-');
    final parts =
        cleaned.split(RegExp(r'\s*(?:-|\bto\b)\s*', caseSensitive: false));

    String start = '';
    String end = '';

    if (parts.length >= 2) {
      start = _normalizeClock(parts[0]);
      end = _normalizeClock(parts[1]);
    } else {
      // fallback: find two time-like tokens
      final matches = RegExp(r'(\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)?)')
          .allMatches(cleaned)
          .toList();
      if (matches.length >= 2) {
        start = _normalizeClock(matches[0].group(1) ?? '');
        end = _normalizeClock(matches[1].group(1) ?? '');
      }
    }

    final label = (start.isNotEmpty && end.isNotEmpty) ? '$start - $end' : t;
    return <String, dynamic>{
      'label': label,
      'startTime': start,
      'endTime': end,
    };
  }

  String _normalizeClock(String s) {
    final v = s.trim();
    if (v.isEmpty) return '';
    // Keep AM/PM if present, else keep HH:mm as-is
    // Also trim seconds if any
    final noSeconds = v.replaceAll(RegExp(r'(\d{1,2}:\d{2}):\d{2}'), r'$1');
    return noSeconds;
  }

  DateTime _parseDate(String date) {
    // Expect "YYYY-MM-DD"
    try {
      return DateTime.parse(date);
    } catch (_) {
      // Very defensive fallback: now
      return DateTime.now();
    }
  }

  String _dayLabel(int weekday) {
    switch (weekday) {
      case 1:
        return 'MONDAY';
      case 2:
        return 'TUESDAY';
      case 3:
        return 'WEDNESDAY';
      case 4:
        return 'THURSDAY';
      case 5:
        return 'FRIDAY';
      case 6:
        return 'SATURDAY';
      case 7:
        return 'SUNDAY';
      default:
        return 'MONDAY';
    }
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic v) {
    if (v is List) return List<dynamic>.from(v);
    if (v is Map && v['data'] is List)
      return List<dynamic>.from(v['data'] as List);
    if (v is Map && v['items'] is List)
      return List<dynamic>.from(v['items'] as List);
    return <dynamic>[];
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> _emptyStudentTimetable() {
    return <String, dynamic>{
      'type': 'STUDENT',
      'id': null,
      'isActive': true,
      'updatedAt': null,
      'classNumber': null,
      'section': null,
      'teacherUserId': null,
      'days': List<Map<String, dynamic>>.generate(
        7,
        (i) => <String, dynamic>{
          'dayOfWeek': i + 1,
          'dayLabel': _dayLabel(i + 1),
          'slots': <Map<String, dynamic>>[],
        },
      ),
      'slots': <Map<String, dynamic>>[],
    };
  }
}
