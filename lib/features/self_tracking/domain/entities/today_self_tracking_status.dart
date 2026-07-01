import 'self_tracking_record.dart';

class TodaySelfTrackingStatus {
  const TodaySelfTrackingStatus({
    required this.exists,
    required this.logicalDate,
    required this.record,
  });

  final bool exists;
  final String logicalDate;
  final SelfTrackingRecord? record;
}
