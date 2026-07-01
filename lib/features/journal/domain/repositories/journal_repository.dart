import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/journal_entry.dart';

abstract class JournalRepository {
  Future<Either<Failure, List<JournalEntry>>> getJournals({
    int limit = 100,
    int offset = 0,
  });

  Future<Either<Failure, JournalEntry>> createJournal({
    required String content,
    required List<File> images,
  });

  Future<Either<Failure, JournalEntry>> updateJournal({
    required JournalEntry entry,
    required String content,
    required List<String> keptImagePaths,
    required List<File> newImages,
  });

  Future<Either<Failure, void>> deleteJournal(JournalEntry entry);
}
