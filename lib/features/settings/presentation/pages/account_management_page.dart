import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as image_lib;
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_app_bar.dart';
import '../../../../core/widgets/common_button.dart';
import '../../../../core/widgets/common_dialog.dart';
import '../../../../core/widgets/github_grass_loading_indicator.dart';
import '../../../auth/presentation/providers/user_profile_provider.dart';
import '../../../auth/presentation/providers/profile_actions_provider.dart';

class AccountManagementPage extends ConsumerStatefulWidget {
  const AccountManagementPage({super.key});

  @override
  ConsumerState<AccountManagementPage> createState() =>
      _AccountManagementPageState();
}

class _AccountManagementPageState extends ConsumerState<AccountManagementPage> {
  final _nicknameController = TextEditingController();
  final _imagePicker = ImagePicker();

  Uint8List? _selectedImageBytes;
  bool _isLoading = false;
  bool _isPickingImage = false;
  bool _didHydrate = false;

  @override
  void initState() {
    super.initState();
    // 초기 데이터 로드
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user != null) {
      _nicknameController.text = user.nickname ?? '';
      _didHydrate = true;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    if (_isPickingImage || _isLoading) return;

    setState(() => _isPickingImage = true);
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedImage == null) return;

      final bytes = await pickedImage.readAsBytes();
      final normalizedBytes = _normalizeProfileImage(bytes);

      if (!mounted) return;
      setState(() {
        _selectedImageBytes = normalizedBytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지를 불러오지 못했어요: $e')));
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Uint8List _normalizeProfileImage(Uint8List bytes) {
    final decodedImage = image_lib.decodeImage(bytes);
    if (decodedImage == null) {
      return bytes;
    }

    const maxImageSize = 512;
    final orientedImage = image_lib.bakeOrientation(decodedImage);
    final longestSide = orientedImage.width > orientedImage.height
        ? orientedImage.width
        : orientedImage.height;

    final resizedImage = longestSide > maxImageSize
        ? image_lib.copyResize(
            orientedImage,
            width: orientedImage.width >= orientedImage.height
                ? maxImageSize
                : null,
            height: orientedImage.height > orientedImage.width
                ? maxImageSize
                : null,
          )
        : orientedImage;

    return Uint8List.fromList(image_lib.encodeJpg(resizedImage, quality: 85));
  }

  Future<String?> _uploadSelectedProfileImage(String uid) async {
    final imageBytes = _selectedImageBytes;
    if (imageBytes == null) return null;

    final storageRef = FirebaseStorage.instance.ref(
      'users/$uid/profile/profile.jpg',
    );
    await storageRef.putData(
      imageBytes,
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public,max-age=3600',
      ),
    );
    return storageRef.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final profileImageUrl = await _uploadSelectedProfileImage(user.uid);

      await ref
          .read(profileActionsProvider.notifier)
          .updateProfile(
            uid: user.uid,
            nickname: _nicknameController.text.trim(),
            profileImageUrl: profileImageUrl,
          );

      if (mounted) {
        // 성공 다이얼로그 (선택사항) 혹은 스낵바
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('프로필이 저장되었습니다.')));
        context.pop(); // 뒤로가기
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => CommonDialog(
            title: '오류 발생',
            description: '저장 중 문제가 발생했습니다.\n다시 시도해주세요.',
            primaryButtonText: '확인',
            onPrimaryPressed: () => Navigator.pop(context),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteNickname(String uid) async {
    showDialog(
      context: context,
      builder: (context) => CommonDialog(
        icon: Icons.delete_forever,
        title: '닉네임 삭제',
        description: '닉네임을 삭제하면\n기본 이름(구글 계정 이름)이 표시됩니다.',
        primaryButtonText: '삭제',
        onPrimaryPressed: () async {
          Navigator.pop(context); // Dialog 닫기
          await _deleteNickname(uid);
        },
        secondaryButtonText: '취소',
        onSecondaryPressed: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _deleteNickname(String uid) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(profileActionsProvider.notifier).deleteNickname(uid);
      _nicknameController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('닉네임이 삭제되었습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('삭제 중 오류가 발생했습니다.')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider).valueOrNull;

    // 로딩 중이거나 유저 정보가 없으면 로딩 표시
    if (user == null) {
      return const Scaffold(body: Center(child: GitHubGrassLoadingIndicator()));
    }

    if (!_didHydrate) {
      _nicknameController.text = user.nickname ?? '';
      _didHydrate = true;
    }

    return Scaffold(
      appBar: CommonAppBar(
        title: '프로필 관리',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 프로필 이미지
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.35,
                                  ),
                                  width: 2,
                                ),
                                color: const Color(0xFFE8EEF8),
                              ),
                              child: ClipOval(
                                child: _buildProfileImage(user.photoUrl),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 2,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.surfaceColor,
                                    width: 3,
                                  ),
                                ),
                                child: _isPickingImage
                                    ? const Padding(
                                        padding: EdgeInsets.all(7),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 17,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 이름 (수정 불가)
                _buildLabel('이름'),
                const SizedBox(height: 8),
                _buildReadOnlyField(user.displayName ?? '이름 없음'),
                const SizedBox(height: 24),

                // 이메일 (수정 불가)
                _buildLabel('이메일'),
                const SizedBox(height: 8),
                _buildReadOnlyField(user.email ?? '-'),
                const SizedBox(height: 24),

                // 닉네임 (수정 가능)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel('닉네임'),
                    if (user.nickname != null && user.nickname!.isNotEmpty)
                      TextButton(
                        onPressed: () => _confirmDeleteNickname(user.uid),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '닉네임 삭제',
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nicknameController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(hintText: '닉네임을 입력해주세요'),
                ),

                const SizedBox(height: 48),

                // 저장 버튼
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: CommonButton(
                    label: '저장하기',
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            '저장하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? photoUrl) {
    final selectedImageBytes = _selectedImageBytes;
    if (selectedImageBytes != null) {
      return Image.memory(selectedImageBytes, fit: BoxFit.cover);
    }

    final resolvedPhotoUrl = photoUrl?.trim();
    if (resolvedPhotoUrl != null && resolvedPhotoUrl.isNotEmpty) {
      return Image.network(
        resolvedPhotoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.person_outline_rounded,
            size: 54,
            color: AppTheme.primaryColor,
          );
        },
      );
    }

    return const Icon(
      Icons.person_outline_rounded,
      size: 54,
      color: AppTheme.primaryColor,
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF5A6B7D),
      ),
    );
  }

  Widget _buildReadOnlyField(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black54, fontSize: 16),
      ),
    );
  }
}
