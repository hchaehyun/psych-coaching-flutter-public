import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:riverpod/riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/user_remote_datasource.dart';

part 'auth_repository_impl.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(userRemoteDataSourceProvider),
  );
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final UserRemoteDataSource _userRemoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource, this._userRemoteDataSource);

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final user = await _remoteDataSource.signInWithGoogle();
      return Right(user);
    } on firebase.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseError(e.code)));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    // TODO: 회원 탈퇴시 30일 유예 도입 시 아래 즉시 삭제 로직을
    // Go API 호출(POST /users/{uid}/delete-request)로 교체.
    // 서버에서 deletionScheduledAt 설정 → Cloud Scheduler가 30일 후 실제 삭제 수행.
    try {
      // 재인증이 성공했을 때만 Firestore 데이터를 삭제하고, 이후 Auth 계정을 삭제한다.
      await _remoteDataSource.deleteAccount(
        onAfterReauthentication: (uid) async {
          await _userRemoteDataSource.deleteUserData(uid);
        },
      );
      return const Right(null);
    } on firebase.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseError(e.code)));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Stream<User?> get authStateChanges => _remoteDataSource.authStateChanges;

  @override
  User? get currentUser => _remoteDataSource.currentUser;

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return '다른 로그인 방식으로 가입된 계정입니다.';
      case 'invalid-credential':
        return '인증 정보가 올바르지 않습니다.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      default:
        return '인증 오류가 발생했습니다.';
    }
  }
}
