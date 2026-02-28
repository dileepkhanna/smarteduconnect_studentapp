// lib/core/utils/date_utils.dart

class DateUtilsX {
  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  static DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  static DateTime endOfMonth(DateTime d) {
    final next = (d.month == 12) ? DateTime(d.year + 1, 1, 1) : DateTime(d.year, d.month + 1, 1);
    return next.subtract(const Duration(milliseconds: 1));
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static int daysBetweenInclusive(DateTime start, DateTime end) {
    final s = startOfDay(start);
    final e = startOfDay(end);
    return e.difference(s).inDays.abs() + 1;
  }

  static List<DateTime> daysInRange(DateTime start, DateTime end) {
    final s = startOfDay(start);
    final e = startOfDay(end);
    final days = <DateTime>[];
    for (int i = 0; i <= e.difference(s).inDays; i++) {
      days.add(s.add(Duration(days: i)));
    }
    return days;
  }
}
