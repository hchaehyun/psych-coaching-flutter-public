// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_actions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileActionsHash() => r'c8937d844ae2d64bd904ba37e011807803d03e3e';

/// 유저 프로필 관련 write-side 액션을 관리하는 Provider
/// Presentation Layer에서 Repository를 직접 호출하지 않도록 중간 계층 역할
///
/// Copied from [ProfileActions].
@ProviderFor(ProfileActions)
final profileActionsProvider =
    AutoDisposeNotifierProvider<ProfileActions, AsyncValue<void>>.internal(
      ProfileActions.new,
      name: r'profileActionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$profileActionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ProfileActions = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
