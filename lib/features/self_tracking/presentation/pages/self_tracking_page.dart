import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/entities/user.dart' as app_user;
import '../../../auth/presentation/providers/user_profile_provider.dart';
import '../providers/self_tracking_provider.dart';

class SelfTrackingPage extends ConsumerStatefulWidget {
  const SelfTrackingPage({super.key});

  @override
  ConsumerState<SelfTrackingPage> createState() => _SelfTrackingPageState();
}

class _SelfTrackingPageState extends ConsumerState<SelfTrackingPage> {
  int _selectedEmotion = -1;
  int _selectedSleepQuality = -1;
  final TextEditingController _sleepHoursController = TextEditingController();

  static const List<_TrackingOption> _emotions = [
    _TrackingOption(assetPath: 'assets/images/smile.png', label: '평온함'),
    _TrackingOption(assetPath: 'assets/images/smile-2.png', label: '괜찮음'),
    _TrackingOption(assetPath: 'assets/images/meh.png', label: '무기력'),
    _TrackingOption(assetPath: 'assets/images/sad.png', label: '지침'),
    _TrackingOption(assetPath: 'assets/images/sad-2.png', label: '불안'),
  ];

  static const List<_TrackingOption> _sleepQualities = [
    _TrackingOption(assetPath: 'assets/images/sleep_1.png', label: '충분했어요'),
    _TrackingOption(assetPath: 'assets/images/sleep_2.png', label: '보통이예요'),
    _TrackingOption(assetPath: 'assets/images/sleep_3.png', label: '부족해요'),
    _TrackingOption(assetPath: 'assets/images/sleep_4.png', label: '거의 못 잤어요'),
  ];

  @override
  void dispose() {
    _sleepHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider).valueOrNull;
    final displayName = _resolveProfileName(user);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.black,
        systemNavigationBarColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 42, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$displayName님\n안녕하세요!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.22,
                  ),
                ),
                // const SizedBox(height: 10),
                const _MirrorPortrait(),
                // const SizedBox(height: 3),
                _buildTrackingPanel(),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSubmit() ? _handleSubmit : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      '완료하기',
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
        ),
      ),
    );
  }

  Widget _buildTrackingPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF020509),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.04),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSectionTitle('오늘 기분은 어떠세요?'),
          const SizedBox(height: 10),
          _buildOptionSelector(
            options: _emotions,
            selectedIndex: _selectedEmotion,
            onSelected: (index) => setState(() => _selectedEmotion = index),
            iconSize: 50,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('잠은 잘 잤나요?'),
          const SizedBox(height: 10),
          _buildOptionSelector(
            options: _sleepQualities,
            selectedIndex: _selectedSleepQuality,
            onSelected: (index) =>
                setState(() => _selectedSleepQuality = index),
            iconSize: 60,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('수면 시간'),
          const SizedBox(height: 14),
          _buildSleepTimeInput(),
        ],
      ),
    );
  }

  String _resolveProfileName(app_user.User? user) {
    if (user == null) return '회원';

    final nickname = user.nickname?.trim();
    if (nickname != null && nickname.isNotEmpty) {
      return nickname;
    }

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    return '회원';
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }

  Widget _buildOptionSelector({
    required List<_TrackingOption> options,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    required double iconSize,
  }) {
    return Row(
      children: List.generate(options.length, (index) {
        final option = options[index];
        final isSelected = selectedIndex == index;

        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelected(index),
            child: SizedBox(
              height: 84,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox.square(
                    dimension: iconSize,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AnimatedScale(
                          duration: const Duration(milliseconds: 180),
                          scale: isSelected ? 1.08 : 1,
                          child: Image.asset(
                            option.assetPath,
                            fit: BoxFit.contain,
                          ),
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: isSelected ? 1 : 0,
                          child: Icon(
                            Icons.check_rounded,
                            size: iconSize * 0.8,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.94),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSleepTimeInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _sleepHoursController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '0.0',
              suffixText: '시간',
              prefixIcon: const Icon(Icons.bedtime_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 16),
        ...[6, 7, 8].map(
          (hours) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: OutlinedButton(
              onPressed: () {
                _sleepHoursController.text = hours.toString();
                setState(() {});
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('$hours시간'),
            ),
          ),
        ),
      ],
    );
  }

  bool _canSubmit() {
    return _selectedEmotion >= 0 &&
        _selectedSleepQuality >= 0 &&
        _validateSleepHours(_sleepHoursController.text) == null;
  }

  String? _validateSleepHours(String input) {
    final text = input.trim();
    if (text.isEmpty) return '수면 시간을 입력해주세요.';

    final validFormat = RegExp(r'^\d+(\.\d)?$');
    if (!validFormat.hasMatch(text)) {
      return '수면 시간은 소수점 한 자리까지만 입력할 수 있어요.';
    }

    final sleepHours = double.tryParse(text);
    if (sleepHours == null || sleepHours <= 0 || sleepHours > 24) {
      return '수면 시간은 0보다 크고 24 이하여야 해요.';
    }

    return null;
  }

  void _handleSubmit() async {
    if (_selectedEmotion < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('기분을 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedSleepQuality < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('수면의 질을 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final validationMessage = _validateSleepHours(_sleepHoursController.text);
    if (validationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationMessage), backgroundColor: Colors.red),
      );
      return;
    }

    final emotionCode = _emotions.length - _selectedEmotion;
    final sleepQuality = _sleepQualities.length - _selectedSleepQuality;
    final sleepHours = double.parse(_sleepHoursController.text.trim());

    try {
      await ref.read(
        saveSelfTrackingProvider(
          emotionCode: emotionCode,
          sleepHours: sleepHours,
          sleepQuality: sleepQuality,
        ).future,
      );

      if (mounted) {
        context.go('/self-tracking/streak');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('기록 저장 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _TrackingOption {
  const _TrackingOption({required this.assetPath, required this.label});

  final String assetPath;
  final String label;
}

class _MirrorPortrait extends StatelessWidget {
  const _MirrorPortrait();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final portraitSize = width.clamp(240.0, 290.0).toDouble();

    return SizedBox.square(
      dimension: portraitSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/mirror_image.png',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: portraitSize * 0.23,
            top: portraitSize * 0.14,
            right: portraitSize * 0.22,
            bottom: portraitSize * 0.15,
            child: ClipRect(
              child: Image.asset(
                'assets/images/alien_hand.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
