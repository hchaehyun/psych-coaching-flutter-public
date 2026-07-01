import 'package:riverpod/riverpod.dart';

import '../data/repositories/auth_repository_impl.dart' as data_auth;
import '../data/repositories/user_profile_repository_impl.dart'
    as data_user_profile;
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/user_profile_repository.dart';

final appAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  return ref.watch(data_auth.authRepositoryProvider);
});

final appUserProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return ref.watch(data_user_profile.userProfileRepositoryProvider);
});
