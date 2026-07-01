import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as image_lib;
import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/journal_entry.dart';

final journalRemoteDataSourceProvider = Provider<JournalRemoteDataSource>((
  ref,
) {
  return JournalRemoteDataSourceImpl(
    dio: ref.watch(dioProvider),
    storage: FirebaseStorage.instance,
    auth: firebase_auth.FirebaseAuth.instance,
    uuid: const Uuid(),
  );
});

abstract class JournalRemoteDataSource {
  Future<List<JournalEntry>> getJournals({int limit = 100, int offset = 0});

  Future<JournalEntry> createJournal({
    required String content,
    required List<File> images,
  });

  Future<JournalEntry> updateJournal({
    required JournalEntry entry,
    required String content,
    required List<String> keptImagePaths,
    required List<File> newImages,
  });

  Future<void> deleteJournal(JournalEntry entry);
}

class JournalRemoteDataSourceImpl implements JournalRemoteDataSource {
  JournalRemoteDataSourceImpl({
    required Dio dio,
    required FirebaseStorage storage,
    required firebase_auth.FirebaseAuth auth,
    required Uuid uuid,
  }) : _dio = dio,
       _storage = storage,
       _auth = auth,
       _uuid = uuid;

  static const _maxImageBytes = 2 * 1024 * 1024;
  static const _maxImageCount = 5;
  static const _maxImageDimension = 1080;
  static const _jpegQuality = 85;
  static const _jpegFallbackQuality = 80;

  final Dio _dio;
  final FirebaseStorage _storage;
  final firebase_auth.FirebaseAuth _auth;
  final Uuid _uuid;

  @override
  Future<List<JournalEntry>> getJournals({
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      '/journals',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final data = _extractResponseData(response.data);
    if (data is! List) {
      throw Exception('Journal API response is missing list data');
    }

    return data.map((raw) => _parseJournal(_asMap(raw))).toList();
  }

  @override
  Future<JournalEntry> createJournal({
    required String content,
    required List<File> images,
  }) async {
    _validateImageCount(images.length);

    final draftId = _uuid.v4();
    final uploadedPaths = await _uploadImages(images, journalKey: draftId);

    try {
      final response = await _dio.post(
        '/journals',
        data: {'content': content, 'images': uploadedPaths},
      );
      return _parseJournal(_asMap(_extractResponseData(response.data)));
    } catch (_) {
      await _deleteImagePaths(uploadedPaths);
      rethrow;
    }
  }

  @override
  Future<JournalEntry> updateJournal({
    required JournalEntry entry,
    required String content,
    required List<String> keptImagePaths,
    required List<File> newImages,
  }) async {
    _validateImageCount(keptImagePaths.length + newImages.length);

    final uploadedPaths = await _uploadImages(
      newImages,
      journalKey: _uuid.v4(),
    );
    final nextImagePaths = [...keptImagePaths, ...uploadedPaths];

    try {
      final response = await _dio.put(
        '/journals/${entry.id}',
        data: {'content': content, 'images': nextImagePaths},
      );
      return _parseJournal(_asMap(_extractResponseData(response.data)));
    } catch (_) {
      await _deleteImagePaths(uploadedPaths);
      rethrow;
    }
  }

  @override
  Future<void> deleteJournal(JournalEntry entry) async {
    await _dio.delete('/journals/${entry.id}');
  }

  void _validateImageCount(int imageCount) {
    if (imageCount > _maxImageCount) {
      throw const ServerFailure('사진은 최대 5장까지 첨부할 수 있어요.');
    }
  }

  Future<List<String>> _uploadImages(
    List<File> images, {
    required String journalKey,
  }) async {
    if (images.isEmpty) return [];

    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure('로그인이 필요해요.');
    }

    final paths = <String>[];
    try {
      for (final image in images) {
        final jpegBytes = await _normalizeImageAsJpeg(image);

        final imageId = _uuid.v4();
        final ref = _storage.ref().child(
          'users/${user.uid}/journals/$journalKey/$imageId.jpg',
        );
        await ref.putData(
          jpegBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        paths.add(ref.fullPath);
      }
    } catch (_) {
      await _deleteImagePaths(paths);
      rethrow;
    }

    return paths;
  }

  Future<Uint8List> _normalizeImageAsJpeg(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final decodedImage = image_lib.decodeImage(bytes);
      if (decodedImage == null) {
        throw const ServerFailure('사진 파일을 처리하지 못했어요.');
      }

      final resizedImage = _resizeImage(
        image_lib.bakeOrientation(decodedImage),
      );
      final jpegBytes = Uint8List.fromList(
        image_lib.encodeJpg(resizedImage, quality: _jpegQuality),
      );
      if (jpegBytes.length < _maxImageBytes) {
        return jpegBytes;
      }

      final fallbackJpegBytes = Uint8List.fromList(
        image_lib.encodeJpg(resizedImage, quality: _jpegFallbackQuality),
      );
      if (fallbackJpegBytes.length < _maxImageBytes) {
        return fallbackJpegBytes;
      }

      throw const ServerFailure('사진은 2MB보다 작아야 해요.');
    } on Failure {
      rethrow;
    } catch (_) {
      throw const ServerFailure('사진 파일을 처리하지 못했어요.');
    }
  }

  image_lib.Image _resizeImage(image_lib.Image image) {
    final maxDimension = image.width > image.height
        ? image.width
        : image.height;
    if (maxDimension <= _maxImageDimension) {
      return image;
    }

    if (image.width >= image.height) {
      return image_lib.copyResize(
        image,
        width: _maxImageDimension,
        interpolation: image_lib.Interpolation.average,
      );
    }

    return image_lib.copyResize(
      image,
      height: _maxImageDimension,
      interpolation: image_lib.Interpolation.average,
    );
  }

  Future<void> _deleteImagePaths(List<String> paths) async {
    for (final path in paths) {
      try {
        await _storage.ref(path).delete();
      } catch (_) {
        // Storage cleanup is best-effort; the journal API result is authoritative.
      }
    }
  }

  dynamic _extractResponseData(dynamic rawResponse) {
    final root = _asMap(rawResponse);
    if (root['success'] != true) {
      throw Exception('Journal API request failed');
    }
    return root['data'];
  }

  JournalEntry _parseJournal(Map<String, dynamic> raw) {
    return JournalEntry(
      id: raw['id'] as String? ?? '',
      userId: raw['user_id'] as String? ?? '',
      content: raw['content'] as String? ?? '',
      imagePaths: _toStringList(raw['images']),
      isDeleted: raw['is_deleted'] as bool? ?? false,
      deletedAt: _toDateTimeOrNull(raw['deleted_at']),
      createdAt: _toDateTime(raw['created_at']),
      updatedAt: _toDateTime(raw['updated_at']),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw Exception('Expected a JSON object response');
  }

  List<String> _toStringList(dynamic value) {
    if (value is! List) return [];
    return value.map((item) => '$item').toList();
  }

  DateTime _toDateTime(dynamic value) {
    final milliseconds = value is int ? value : int.tryParse('$value');
    if (milliseconds == null) {
      throw Exception('Expected epoch milliseconds for date field');
    }
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  DateTime? _toDateTimeOrNull(dynamic value) {
    if (value == null) return null;
    return _toDateTime(value);
  }
}
