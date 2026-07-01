// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_password_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$secureStorageHash() => r'273dc403a965c1f24962aaf4d40776611a26f8b8';

/// See also [secureStorage].
@ProviderFor(secureStorage)
final secureStorageProvider =
    AutoDisposeProvider<FlutterSecureStorage>.internal(
      secureStorage,
      name: r'secureStorageProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$secureStorageHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SecureStorageRef = AutoDisposeProviderRef<FlutterSecureStorage>;
String _$journalPasswordHash() => r'209f7c8fff24cd1908708d6466052da69028158e';

/// See also [JournalPassword].
@ProviderFor(JournalPassword)
final journalPasswordProvider =
    AutoDisposeAsyncNotifierProvider<JournalPassword, String?>.internal(
      JournalPassword.new,
      name: r'journalPasswordProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$journalPasswordHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$JournalPassword = AutoDisposeAsyncNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
