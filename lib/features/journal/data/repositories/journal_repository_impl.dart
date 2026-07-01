import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';
import '../datasources/journal_remote_datasource.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepositoryImpl(ref.watch(journalRemoteDataSourceProvider));
});

class JournalRepositoryImpl implements JournalRepository {
  JournalRepositoryImpl(this._remoteDataSource);

  final JournalRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<JournalEntry>>> getJournals({
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final result = await _remoteDataSource.getJournals(
        limit: limit,
        offset: offset,
      );
      return Right(result);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  @override
  Future<Either<Failure, JournalEntry>> createJournal({
    required String content,
    required List<File> images,
  }) async {
    try {
      final result = await _remoteDataSource.createJournal(
        content: content,
        images: images,
      );
      return Right(result);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  @override
  Future<Either<Failure, JournalEntry>> updateJournal({
    required JournalEntry entry,
    required String content,
    required List<String> keptImagePaths,
    required List<File> newImages,
  }) async {
    try {
      final result = await _remoteDataSource.updateJournal(
        entry: entry,
        content: content,
        keptImagePaths: keptImagePaths,
        newImages: newImages,
      );
      return Right(result);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteJournal(JournalEntry entry) async {
    try {
      await _remoteDataSource.deleteJournal(entry);
      return const Right(null);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  Failure _mapFailure(Object error) {
    if (error is Failure) {
      return error;
    }

    if (error is DioException) {
      final message = _extractMessage(error);
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return NetworkFailure(message);
        default:
          return ServerFailure(message);
      }
    }

    if (error is FirebaseException) {
      return ServerFailure(error.message ?? '사진을 처리하지 못했어요.');
    }

    return const ServerFailure('일기 데이터를 처리하지 못했어요.');
  }

  String _extractMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return '일기 데이터를 처리하지 못했어요.';
  }
}
