import 'package:shared_preferences/shared_preferences.dart';

/// 오전 9시 최초 접속 시 거울속 나 페이지로 리다이렉트하는 서비스
/// 
/// 사용법:
/// 1. main.dart나 home 페이지에서 앱 시작 시 호출
/// 2. shouldRedirectToSelfTracking()이 true면 /self-tracking으로 이동
/// 
/// 활성화 방법:
/// 주석 처리된 코드를 해제하고 사용
class MorningRedirectService {
  static const String _lastTrackingDateKey = 'last_self_tracking_date';
  
  final SharedPreferences _prefs;
  
  MorningRedirectService(this._prefs);
  
  /// 오전 9시 이후 첫 접속인지 확인
  /// 조건:
  /// 1. 현재 시간이 오전 9시 이후
  /// 2. 오늘 아직 거울속 나 기록을 하지 않음
  bool shouldRedirectToSelfTracking() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nineAM = DateTime(now.year, now.month, now.day, 9, 0);
    
    // 오전 9시 이전이면 리다이렉트 안 함
    if (now.isBefore(nineAM)) {
      return false;
    }
    
    // 오늘 이미 기록했는지 확인
    final lastTrackingDateString = _prefs.getString(_lastTrackingDateKey);
    if (lastTrackingDateString != null) {
      final lastTrackingDate = DateTime.tryParse(lastTrackingDateString);
      if (lastTrackingDate != null) {
        final lastDate = DateTime(
          lastTrackingDate.year,
          lastTrackingDate.month,
          lastTrackingDate.day,
        );
        // 오늘 이미 기록했으면 리다이렉트 안 함
        if (lastDate.isAtSameMomentAs(today)) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  /// 오늘 기록 완료 표시
  Future<void> markTodayAsTracked() async {
    await _prefs.setString(
      _lastTrackingDateKey,
      DateTime.now().toIso8601String(),
    );
  }
  
  /// 기록 날짜 초기화 (테스트용)
  Future<void> resetTrackingDate() async {
    await _prefs.remove(_lastTrackingDateKey);
  }
}

// ============================================================
// 아래 Provider는 현재 비활성화 상태입니다.
// 활성화하려면 주석을 해제하세요.
// ============================================================

/*
@riverpod
Future<MorningRedirectService> morningRedirectService(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return MorningRedirectService(prefs);
}

/// 리다이렉트 필요 여부 Provider
@riverpod
Future<bool> shouldRedirectToSelfTracking(Ref ref) async {
  final service = await ref.watch(morningRedirectServiceProvider.future);
  return service.shouldRedirectToSelfTracking();
}
*/

// ============================================================
// 사용 예시 (home_page.dart 또는 main_shell_page.dart에서)
// ============================================================
/*
@override
void initState() {
  super.initState();
  _checkMorningRedirect();
}

Future<void> _checkMorningRedirect() async {
  final shouldRedirect = await ref.read(shouldRedirectToSelfTrackingProvider.future);
  if (shouldRedirect && mounted) {
    context.go('/self-tracking');
  }
}
*/
