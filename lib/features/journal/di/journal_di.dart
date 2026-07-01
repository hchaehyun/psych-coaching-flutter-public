import 'package:riverpod/riverpod.dart';

import '../data/repositories/journal_repository_impl.dart' as data_journal;
import '../domain/repositories/journal_repository.dart';

final appJournalRepositoryProvider = Provider<JournalRepository>((ref) {
  return ref.watch(data_journal.journalRepositoryProvider);
});
