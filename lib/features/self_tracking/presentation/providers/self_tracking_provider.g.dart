// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'self_tracking_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$selfTrackingTodayStatusHash() =>
    r'b188c1a4f4fc328fb572c16f184333eeda65041b';

/// See also [selfTrackingTodayStatus].
@ProviderFor(selfTrackingTodayStatus)
final selfTrackingTodayStatusProvider =
    FutureProvider<TodaySelfTrackingStatus>.internal(
      selfTrackingTodayStatus,
      name: r'selfTrackingTodayStatusProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selfTrackingTodayStatusHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SelfTrackingTodayStatusRef = FutureProviderRef<TodaySelfTrackingStatus>;
String _$todayRecordExistsHash() => r'305ccf5ac12023fd98f16e96f26b2c8a38856730';

/// See also [todayRecordExists].
@ProviderFor(todayRecordExists)
final todayRecordExistsProvider = AutoDisposeProvider<bool>.internal(
  todayRecordExists,
  name: r'todayRecordExistsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$todayRecordExistsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TodayRecordExistsRef = AutoDisposeProviderRef<bool>;
String _$saveSelfTrackingHash() => r'9f16f775171c842d62b4b0f68a0afad875846097';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [saveSelfTracking].
@ProviderFor(saveSelfTracking)
const saveSelfTrackingProvider = SaveSelfTrackingFamily();

/// See also [saveSelfTracking].
class SaveSelfTrackingFamily extends Family<AsyncValue<SelfTrackingRecord>> {
  /// See also [saveSelfTracking].
  const SaveSelfTrackingFamily();

  /// See also [saveSelfTracking].
  SaveSelfTrackingProvider call({
    required int emotionCode,
    required double sleepHours,
    required int sleepQuality,
  }) {
    return SaveSelfTrackingProvider(
      emotionCode: emotionCode,
      sleepHours: sleepHours,
      sleepQuality: sleepQuality,
    );
  }

  @override
  SaveSelfTrackingProvider getProviderOverride(
    covariant SaveSelfTrackingProvider provider,
  ) {
    return call(
      emotionCode: provider.emotionCode,
      sleepHours: provider.sleepHours,
      sleepQuality: provider.sleepQuality,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'saveSelfTrackingProvider';
}

/// See also [saveSelfTracking].
class SaveSelfTrackingProvider
    extends AutoDisposeFutureProvider<SelfTrackingRecord> {
  /// See also [saveSelfTracking].
  SaveSelfTrackingProvider({
    required int emotionCode,
    required double sleepHours,
    required int sleepQuality,
  }) : this._internal(
         (ref) => saveSelfTracking(
           ref as SaveSelfTrackingRef,
           emotionCode: emotionCode,
           sleepHours: sleepHours,
           sleepQuality: sleepQuality,
         ),
         from: saveSelfTrackingProvider,
         name: r'saveSelfTrackingProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$saveSelfTrackingHash,
         dependencies: SaveSelfTrackingFamily._dependencies,
         allTransitiveDependencies:
             SaveSelfTrackingFamily._allTransitiveDependencies,
         emotionCode: emotionCode,
         sleepHours: sleepHours,
         sleepQuality: sleepQuality,
       );

  SaveSelfTrackingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.emotionCode,
    required this.sleepHours,
    required this.sleepQuality,
  }) : super.internal();

  final int emotionCode;
  final double sleepHours;
  final int sleepQuality;

  @override
  Override overrideWith(
    FutureOr<SelfTrackingRecord> Function(SaveSelfTrackingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SaveSelfTrackingProvider._internal(
        (ref) => create(ref as SaveSelfTrackingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        emotionCode: emotionCode,
        sleepHours: sleepHours,
        sleepQuality: sleepQuality,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<SelfTrackingRecord> createElement() {
    return _SaveSelfTrackingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SaveSelfTrackingProvider &&
        other.emotionCode == emotionCode &&
        other.sleepHours == sleepHours &&
        other.sleepQuality == sleepQuality;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, emotionCode.hashCode);
    hash = _SystemHash.combine(hash, sleepHours.hashCode);
    hash = _SystemHash.combine(hash, sleepQuality.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SaveSelfTrackingRef on AutoDisposeFutureProviderRef<SelfTrackingRecord> {
  /// The parameter `emotionCode` of this provider.
  int get emotionCode;

  /// The parameter `sleepHours` of this provider.
  double get sleepHours;

  /// The parameter `sleepQuality` of this provider.
  int get sleepQuality;
}

class _SaveSelfTrackingProviderElement
    extends AutoDisposeFutureProviderElement<SelfTrackingRecord>
    with SaveSelfTrackingRef {
  _SaveSelfTrackingProviderElement(super.provider);

  @override
  int get emotionCode => (origin as SaveSelfTrackingProvider).emotionCode;
  @override
  double get sleepHours => (origin as SaveSelfTrackingProvider).sleepHours;
  @override
  int get sleepQuality => (origin as SaveSelfTrackingProvider).sleepQuality;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
