import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_button.dart';
import '../../domain/entities/self_tracking_attendance.dart';
import '../../domain/entities/self_tracking_streak.dart';
import '../providers/self_tracking_provider.dart';

class SelfTrackingStreakPage extends ConsumerWidget {
  const SelfTrackingStreakPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakState = ref.watch(selfTrackingStreakProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: streakState.when(
            data: (streak) => _StreakContent(streak: streak),
            loading: () => const _StreakLoadingView(),
            error: (error, stackTrace) => _StreakErrorView(error: error),
          ),
        ),
      ),
    );
  }
}

class _StreakContent extends ConsumerWidget {
  const _StreakContent({required this.streak});

  final SelfTrackingStreak streak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = streak.currentStreakDays;
    final isRestarted = streak.streakState == SelfTrackingStreakState.restarted;
    final displayCount = count <= 0 ? 1 : count;
    final attendanceState = ref.watch(
      selfTrackingAttendanceProvider(_weekRangeFor(streak.logicalDateValue)),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _LogoWithFire(showFire: true, muted: isRestarted),
          const SizedBox(height: 20),
          if (isRestarted)
            const Text(
              '오늘부터 다시 시작',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1F2328),
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            )
          else
            _StreakTitle(count: displayCount),
          const SizedBox(height: 8),
          Text(
            isRestarted
                ? '새로운 마음으로\n오늘의 출석을 시작했어요 ♥'
                : '오늘은 우리가 만난지\n$displayCount일째 되는 날이에요 ♥',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8B9098),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 30),
          _WeekAttendanceCard(
            today: streak.logicalDateValue,
            attendance: attendanceState.valueOrNull,
          ),
          const Spacer(flex: 5),
          CommonButton(
            label: '완료하기',
            width: double.infinity,
            height: 48,
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );
  }
}

class _LogoWithFire extends StatelessWidget {
  const _LogoWithFire({required this.showFire, required this.muted});

  final bool showFire;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 208,
      height: 194,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 184,
            height: 184,
            fit: BoxFit.contain,
          ),
          if (showFire)
            Positioned(
              right: 26,
              bottom: 6,
              child: Opacity(
                opacity: muted ? 0.72 : 1,
                child: const Text('🔥', style: TextStyle(fontSize: 78)),
              ),
            ),
        ],
      ),
    );
  }
}

class _StreakTitle extends StatelessWidget {
  const _StreakTitle({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: '연속 '),
          TextSpan(
            text: '$count번째',
            style: const TextStyle(color: AppTheme.primaryColor),
          ),
          const TextSpan(text: ' 출석 완료'),
        ],
      ),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xFF1F2328),
        fontSize: 26,
        fontWeight: FontWeight.w800,
        height: 1.25,
      ),
    );
  }
}

class _WeekAttendanceCard extends StatelessWidget {
  const _WeekAttendanceCard({required this.today, required this.attendance});

  static const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

  final DateTime today;
  final SelfTrackingAttendance? attendance;

  @override
  Widget build(BuildContext context) {
    final sunday = _weekStartFor(today);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var index = 0; index < _weekdayLabels.length; index++)
            _WeekdayCheckItem(
              label: _weekdayLabels[index],
              checked:
                  attendance?.isAttended(sunday.add(Duration(days: index))) ??
                  false,
            ),
        ],
      ),
    );
  }
}

SelfTrackingAttendanceRange _weekRangeFor(DateTime logicalDate) {
  final sunday = _weekStartFor(logicalDate);
  final saturday = sunday.add(const Duration(days: 6));

  return SelfTrackingAttendanceRange(
    fromLogicalDate: SelfTrackingAttendance.formatLogicalDate(sunday),
    toLogicalDate: SelfTrackingAttendance.formatLogicalDate(saturday),
  );
}

DateTime _weekStartFor(DateTime date) {
  return date.subtract(Duration(days: date.weekday % 7));
}

class _WeekdayCheckItem extends StatelessWidget {
  const _WeekdayCheckItem({required this.label, required this.checked});

  final String label;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF686D76),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 11),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: checked ? const Color(0xFF5AA7F2) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: checked
                ? null
                : Border.all(color: const Color(0xFFD9DCE2), width: 1.2),
          ),
          child: checked
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
      ],
    );
  }
}

class _StreakLoadingView extends StatelessWidget {
  const _StreakLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}

class _StreakErrorView extends ConsumerWidget {
  const _StreakErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
      child: Column(
        children: [
          const Spacer(),
          const _LogoWithFire(showFire: false, muted: true),
          const SizedBox(height: 22),
          const Text(
            '출석 정보를 불러오지 못했어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage(error),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () => ref.invalidate(selfTrackingStreakProvider),
              child: const Text('다시 시도'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('홈으로 가기'),
            ),
          ),
        ],
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error is Failure) {
      return error.message;
    }
    return '잠시 후 다시 시도해주세요.';
  }
}
