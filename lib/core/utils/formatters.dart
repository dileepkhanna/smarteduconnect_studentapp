// lib/core/utils/formatters.dart
import 'package:intl/intl.dart';

class Formatters {
  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateShort = DateFormat('dd MMM');
  static final DateFormat _time = DateFormat('hh:mm a');
  static final DateFormat _dayName = DateFormat('EEEE');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');

  static String date(DateTime? d) {
    if (d == null) return '-';
    return _date.format(d);
  }

  static String dateShort(DateTime? d) {
    if (d == null) return '-';
    return _dateShort.format(d);
  }

  static String time(DateTime? d) {
    if (d == null) return '-';
    return _time.format(d);
  }

  static String dayName(DateTime? d) {
    if (d == null) return '-';
    return _dayName.format(d);
  }

  static String monthYear(DateTime? d) {
    if (d == null) return '-';
    return _monthYear.format(d);
  }

  static String compactNumber(num? n) {
    if (n == null) return '-';
    final f = NumberFormat.compact();
    return f.format(n);
  }

  static double percent(num part, num total) {
    if (total == 0) return 0;
    return (part / total) * 100.0;
  }

  static String percentText(num part, num total, {int decimals = 0}) {
    final p = percent(part, total);
    return '${p.toStringAsFixed(decimals)}%';
  }
}
