import 'package:flutter_riverpod/flutter_riverpod.dart'
    show Ref, StreamProvider;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../di/auth_di.dart';
import '../../domain/entities/user.dart';
import 'auth_provider.dart';

part 'user_profile_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<User?> userProfile(Ref ref) {
  final authState = ref.watch(authStateProvider);
  final userProfileRepository = ref.watch(appUserProfileRepositoryProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return userProfileRepository.watchUserProfile(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (error, stackTrace) => const Stream.empty(),
  );
}

final duplicateLoginDeviceIdProvider = StreamProvider.autoDispose<String?>((
  ref,
) {
  final authState = ref.watch(authStateProvider);
  final userProfileRepository = ref.watch(appUserProfileRepositoryProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return userProfileRepository.watchLoginDeviceId(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (error, stackTrace) => const Stream.empty(),
  );
});
