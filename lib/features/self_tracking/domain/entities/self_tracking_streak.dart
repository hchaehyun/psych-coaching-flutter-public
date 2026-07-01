enum SelfTrackingStreakState {
  checkedIn,
  restarted;

  static SelfTrackingStreakState fromJson(String value) {
    return switch (value) {
      'checked_in' => SelfTrackingStreakState.checkedIn,
      'restarted' => SelfTrackingStreakState.restarted,
      _ => SelfTrackingStreakState.restarted,
    };
  }
}

class SelfTrackingStreak {
  const SelfTrackingStreak({
    required this.logicalDate,
    required this.checkedInToday,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.totalAttendanceDays,
    required this.lastAttendedLogicalDate,
    required this.streakState,
  });

  final String logicalDate;
  final bool checkedInToday;
  final int currentStreakDays;
  final int longestStreakDays;
  final int totalAttendanceDays;
  final String lastAttendedLogicalDate;
  final SelfTrackingStreakState streakState;

  DateTime get logicalDateValue => DateTime.parse(logicalDate);
}
