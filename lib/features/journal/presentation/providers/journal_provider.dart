import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../di/journal_di.dart';
import '../../domain/entities/journal_entry.dart';

final journalEntriesProvider =
    AsyncNotifierProvider<JournalEntriesNotifier, List<JournalEntry>>(
      JournalEntriesNotifier.new,
    );

class JournalEntriesNotifier extends AsyncNotifier<List<JournalEntry>> {
  @override
  Future<List<JournalEntry>> build() async {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) return [];

    return _fetch();
  }

  Future<List<JournalEntry>> _fetch() async {
    final result = await ref.read(appJournalRepositoryProvider).getJournals();
    return result.fold((failure) => throw failure, (entries) => entries);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<JournalEntry> create({
    required String content,
    required List<File> images,
  }) async {
    final result = await ref
        .read(appJournalRepositoryProvider)
        .createJournal(content: content, images: images);
    final entry = result.fold((failure) => throw failure, (value) => value);
    final previous = state.valueOrNull ?? [];
    state = AsyncData([entry, ...previous]);
    return entry;
  }

  Future<JournalEntry> updateEntry({
    required JournalEntry entry,
    required String content,
    required List<String> keptImagePaths,
    required List<File> newImages,
  }) async {
    final result = await ref
        .read(appJournalRepositoryProvider)
        .updateJournal(
          entry: entry,
          content: content,
          keptImagePaths: keptImagePaths,
          newImages: newImages,
        );
    final updated = result.fold((failure) => throw failure, (value) => value);
    final previous = state.valueOrNull ?? [];
    state = AsyncData([
      for (final item in previous)
        if (item.id == updated.id) updated else item,
    ]);
    return updated;
  }

  Future<void> delete(JournalEntry entry) async {
    final result = await ref
        .read(appJournalRepositoryProvider)
        .deleteJournal(entry);
    result.fold((failure) => throw failure, (_) {});
    final previous = state.valueOrNull ?? [];
    state = AsyncData([
      for (final item in previous)
        if (item.id != entry.id) item,
    ]);
  }
}

String journalErrorMessage(Object error) {
  if (error is Failure) {
    return error.message;
  }
  return '일기 데이터를 처리하지 못했어요.';
}
