class SelfTrackingAttendance {
  const SelfTrackingAttendance({
    required this.fromLogicalDate,
    required this.toLogicalDate,
    required this.attendanceDates,
  });

  final String fromLogicalDate;
  final String toLogicalDate;
  final Set<String> attendanceDates;

  bool isAttended(DateTime date) {
    return attendanceDates.contains(_formatLogicalDate(date));
  }

  static String formatLogicalDate(DateTime date) {
    return _formatLogicalDate(date);
  }

  static String _formatLogicalDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class SelfTrackingAttendanceRange {
  const SelfTrackingAttendanceRange({
    required this.fromLogicalDate,
    required this.toLogicalDate,
  });

  final String fromLogicalDate;
  final String toLogicalDate;

  @override
  bool operator ==(Object other) {
    return other is SelfTrackingAttendanceRange &&
        other.fromLogicalDate == fromLogicalDate &&
        other.toLogicalDate == toLogicalDate;
  }

  @override
  int get hashCode => Object.hash(fromLogicalDate, toLogicalDate);
}
