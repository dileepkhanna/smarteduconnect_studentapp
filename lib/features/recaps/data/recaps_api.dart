// lib/features/recaps/data/recaps_api.dart
import '../../../core/network/api_client.dart';
import '../../../core/network/response_unwrap.dart';

/// Recaps API (Student / Parent)
///
/// ✅ REAL BACKEND (Backend_Final_Code.zip):
/// - GET /recaps  (role scoped)
///
/// Student role behavior:
/// - backend automatically returns only their class/section recaps
/// - filters: fromDate, toDate, subject, search, page, limit
class RecapsApi {
  RecapsApi(this._api);

  final ApiClient _api;

  static const String _recapsPath = '/recaps';

  /// GET /recaps
  Future<List<dynamic>> getMyRecaps({
    String? date, // client convenience -> fromDate=toDate=date
    String? fromDate,
    String? toDate,
    String? subject,
    String? search,
    int? page,
    int? limit,
  }) async {
    final Map<String, dynamic> q = <String, dynamic>{};

    // If date passed, force exact day (backend supports range only)
    final String? trimmedDate = _trimOrNull(date);
    final String? trimmedFrom = _trimOrNull(fromDate);
    final String? trimmedTo = _trimOrNull(toDate);

    if (trimmedDate != null) {
      q['fromDate'] = trimmedDate;
      q['toDate'] = trimmedDate;
    } else {
      if (trimmedFrom != null) q['fromDate'] = trimmedFrom;
      if (trimmedTo != null) q['toDate'] = trimmedTo;
    }

    final String? trimmedSubject = _trimOrNull(subject);
    if (trimmedSubject != null) q['subject'] = trimmedSubject;

    final String? trimmedSearch = _trimOrNull(search);
    if (trimmedSearch != null) q['search'] = trimmedSearch;

    if (page != null) q['page'] = page;
    if (limit != null) q['limit'] = limit;

    final dynamic res = await _api.get<dynamic>(
      _recapsPath,
      query: q,
    );

    return _extractList(res);
  }

  /// Today recaps = GET /recaps?fromDate=today&toDate=today
  Future<List<dynamic>> getTodayRecaps() async {
    final String today = _yyyyMmDd(DateTime.now());

    final dynamic res = await _api.get<dynamic>(
      _recapsPath,
      query: <String, dynamic>{
        'fromDate': today,
        'toDate': today,
      },
    );

    return _extractList(res);
  }

  // ----------------- helpers -----------------

  String? _trimOrNull(String? v) {
    final s = (v ?? '').trim();
    return s.isEmpty ? null : s;
  }

  String _yyyyMmDd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<dynamic> _extractList(dynamic responseOrData) {
    final data = unwrapEnvelope(responseOrData);

    // Backend list shape: { items: [...], total, skip, take }
    if (data is Map && data['items'] is List) {
      return List<dynamic>.from(data['items'] as List);
    }

    // Some clients wrap arrays inside { data: [...] }
    if (data is Map && data['data'] is List) {
      return List<dynamic>.from(data['data'] as List);
    }

    // Direct list
    if (data is List) {
      return List<dynamic>.from(data);
    }

    return <dynamic>[];
  }
}
