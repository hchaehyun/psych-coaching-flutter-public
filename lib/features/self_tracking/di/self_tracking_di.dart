import 'package:riverpod/riverpod.dart';

import '../data/repositories/self_tracking_repository_impl.dart'
    as data_self_tracking;
import '../domain/repositories/self_tracking_repository.dart';

final appSelfTrackingRepositoryProvider = Provider<SelfTrackingRepository>((
  ref,
) {
  return ref.watch(data_self_tracking.selfTrackingRepositoryProvider);
});
