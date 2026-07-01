import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/device_id_service.dart';
import '../../di/auth_di.dart';
import '../../domain/entities/user.dart';

part 'auth_provider.g.dart';

@riverpod
Stream<User?> authState(Ref ref) {
  return ref.watch(appAuthRepositoryProvider).authStateChanges;
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<User?> build() async {
    return null;
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      final result = await ref
          .read(appAuthRepositoryProvider)
          .signInWithGoogle();
      result.fold(
        (failure) {
          state = AsyncValue.error(failure.message, StackTrace.current);
        },
        (user) {
          state = AsyncValue.data(user);
        },
      );

      // 로그인 성공 시 Firestore에 유저 정보 저장
      final user = state.valueOrNull;
      if (user != null) {
        final deviceId = await ref
            .read(deviceIdServiceProvider)
            .getPersistentDeviceId();
        debugPrint('[Auth] Firestore에 deviceId 저장: $deviceId');
        await ref
            .read(appUserProfileRepositoryProvider)
            .syncUserOnSignIn(
              uid: user.uid,
              email: user.email,
              displayName: user.displayName,
              photoUrl: user.photoUrl,
              deviceId: deviceId,
            );
        ref.invalidate(appUserProfileRepositoryProvider);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      final result = await ref.read(appAuthRepositoryProvider).signOut();
      final failure = result.fold<Failure?>((value) => value, (_) => null);

      if (failure != null) {
        state = AsyncValue.error(failure, StackTrace.current);
        throw failure;
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      final result = await ref.read(appAuthRepositoryProvider).deleteAccount();
      final failure = result.fold<Failure?>((value) => value, (_) => null);

      if (failure != null) {
        state = AsyncValue.error(failure, StackTrace.current);
        throw failure;
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
