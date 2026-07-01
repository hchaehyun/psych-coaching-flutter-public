import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'journal_password_provider.g.dart';

const _journalPasswordKey = 'journal_password';

@riverpod
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage();
}

@riverpod
class JournalPassword extends _$JournalPassword {
  @override
  Future<String?> build() async {
    final storage = ref.watch(secureStorageProvider);
    return await storage.read(key: _journalPasswordKey);
  }

  Future<void> setPassword(String password) async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: _journalPasswordKey, value: password);
    state = AsyncValue.data(password);
  }

  Future<void> removePassword() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: _journalPasswordKey);
    state = const AsyncValue.data(null);
  }

  bool verifyPassword(String input) {
    return state.valueOrNull == input;
  }

  bool get hasPassword => state.valueOrNull != null;
}
