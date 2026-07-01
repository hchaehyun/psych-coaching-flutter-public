class SelfTrackingRecord {
  const SelfTrackingRecord({
    required this.userId,
    required this.logicalDate,
    required this.emotionCode,
    required this.emotionLabel,
    required this.sleepHours,
    required this.sleepQuality,
    required this.recordedAt,
    required this.updatedAt,
  });

  final String userId;
  final String logicalDate;
  final int emotionCode;
  final String emotionLabel;
  final double sleepHours;
  final int sleepQuality;
  final DateTime recordedAt;
  final DateTime updatedAt;
}
