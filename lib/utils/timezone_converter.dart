/// Timezone conversion utilities for PowerLog.
/// All conversions are based on UTC offsets (no external packages needed).
class TimezoneConverter {
  static const zones = [
    TzInfo('WIB', 'Western Indonesia', 7),   // UTC+7
    TzInfo('WITA', 'Central Indonesia', 8),  // UTC+8
    TzInfo('WIT', 'Eastern Indonesia', 9),   // UTC+9
    TzInfo('London', 'United Kingdom', 0),   // UTC+0/+1 (DST-aware)
  ];

  static DateTime toZone(TzInfo tz, [DateTime? utcNow]) {
    final base = (utcNow ?? DateTime.now()).toUtc();
    if (tz.code == 'London') {
      return base.add(Duration(hours: _londonOffset(base)));
    }
    return base.add(Duration(hours: tz.utcOffset));
  }

  /// UK BST: last Sunday of March 01:00 UTC → last Sunday of October 01:00 UTC
  static int _londonOffset(DateTime utc) {
    if (utc.month > 3 && utc.month < 10) return 1;
    if (utc.month < 3 || utc.month > 10) return 0;
    final lastSun = _lastSundayOf(utc.year, utc.month);
    if (utc.month == 3) {
      return (utc.day > lastSun || (utc.day == lastSun && utc.hour >= 1))
          ? 1
          : 0;
    }
    // October
    return (utc.day < lastSun || (utc.day == lastSun && utc.hour < 1))
        ? 1
        : 0;
  }

  static int _lastSundayOf(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0);
    return lastDay.day - (lastDay.weekday % 7);
  }
}

class TzInfo {
  final String code;
  final String label;
  final int utcOffset;
  const TzInfo(this.code, this.label, this.utcOffset);
}
