import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod/riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'device_id_service.g.dart';

const _deviceIdKey = 'persistent_device_id';

abstract class DeviceIdService {
  Future<String> getPersistentDeviceId();
}

@riverpod
DeviceIdService deviceIdService(Ref ref) {
  return DeviceIdServiceImpl(
    deviceInfoPlugin: DeviceInfoPlugin(),
    storage: const FlutterSecureStorage(),
    uuid: const Uuid(),
  );
}

@riverpod
Future<String> currentDeviceId(Ref ref) {
  return ref.watch(deviceIdServiceProvider).getPersistentDeviceId();
}

class DeviceIdServiceImpl implements DeviceIdService {
  DeviceIdServiceImpl({
    required DeviceInfoPlugin deviceInfoPlugin,
    required FlutterSecureStorage storage,
    required Uuid uuid,
  }) : _deviceInfoPlugin = deviceInfoPlugin,
       _storage = storage,
       _uuid = uuid;

  final DeviceInfoPlugin _deviceInfoPlugin;
  final FlutterSecureStorage _storage;
  final Uuid _uuid;

  @override
  Future<String> getPersistentDeviceId() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      return androidInfo.id;
    }

    if (Platform.isIOS) {
      final existingId = await _storage.read(key: _deviceIdKey);
      if (existingId != null) {
        return existingId;
      }

      final newId = _uuid.v4();
      await _storage.write(key: _deviceIdKey, value: newId);
      return newId;
    }

    return 'unknown-device';
  }
}
