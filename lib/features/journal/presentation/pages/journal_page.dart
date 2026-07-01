import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_app_bar.dart';
import '../../../../core/widgets/common_dialog.dart';
import '../../../../core/widgets/github_grass_loading_indicator.dart';
import '../../domain/entities/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../../../settings/presentation/pages/secondary_password_page.dart';
import '../../../settings/presentation/providers/journal_password_provider.dart';

// 일기장 잠금 해제 상태 (세션 내에서만 유지)
final journalUnlockedProvider = StateProvider<bool>((ref) => false);

class JournalPage extends ConsumerStatefulWidget {
  final bool isActive;

  const JournalPage({super.key, this.isActive = false});

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage>
    with WidgetsBindingObserver {
  static const _maxJournalImages = 5;

  final _journalController = TextEditingController();
  final _passwordController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _journalController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 백그라운드로 전환될 때 일기장 다시 잠금
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(journalUnlockedProvider.notifier).state = false;
    }
  }

  Future<bool> _addEntry() async {
    final text = _journalController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('일기 내용을 입력해주세요.');
      return false;
    }

    try {
      await ref
          .read(journalEntriesProvider.notifier)
          .create(content: text, images: List<File>.from(_selectedImages));
      if (!mounted) return true;
      setState(() {
        _selectedImages = [];
      });
      _journalController.clear();
      _showSnackBar('일기가 저장되었습니다');
      return true;
    } catch (e) {
      if (mounted) {
        _showSnackBar(journalErrorMessage(e));
      }
      return false;
    }
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxJournalImages) {
      _showMaxImageCountSnackBar();
      return;
    }

    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1080,
        imageQuality: 85,
      );
      final files = _imageFilesWithinLimit(
        images,
        currentCount: _selectedImages.length,
      );
      if (files.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진을 불러올 수 없습니다. 실제 기기에서 테스트해주세요.')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showMaxImageCountSnackBar() {
    _showSnackBar('사진은 최대 $_maxJournalImages장까지 첨부할 수 있어요.');
  }

  List<File> _imageFilesWithinLimit(
    List<XFile> images, {
    required int currentCount,
  }) {
    if (images.isEmpty) return const [];

    final remainingCount = _maxJournalImages - currentCount;
    if (remainingCount <= 0) {
      _showMaxImageCountSnackBar();
      return const [];
    }

    if (images.length > remainingCount) {
      _showMaxImageCountSnackBar();
    }

    return images
        .take(remainingCount)
        .map((image) => File(image.path))
        .toList();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _getWeekdayName(DateTime date) {
    const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return weekdays[date.weekday - 1];
  }

  bool _hasCheckedRecommendation = false;

  Future<void> _checkPasswordRecommendation() async {
    // 1. 비밀번호 설정 권유 확인
    final hasPassword = ref.read(journalPasswordProvider).valueOrNull != null;
    if (!hasPassword) {
      final prefs = await SharedPreferences.getInstance();
      final shown =
          prefs.getBool('journal_password_recommendation_shown') ?? false;

      if (!shown && mounted) {
        await prefs.setBool('journal_password_recommendation_shown', true);
        if (!mounted) return;

        final keepProcceding = await showDialog<bool>(
          context: context,
          builder: (context) => CommonDialog(
            icon: Icons.lock_outline, // 추후 이미지로 교체 예정
            title: '처음 일기를 쓰는 날이네요.',
            description:
                '작은결은 소중한 기록을 지키기\n위해 2차 비밀번호를 제공해요.\n\n잠금을 켜고 마음 편히 기록해보세요.',
            primaryButtonText: '2차 비밀번호 설정하기',
            onPrimaryPressed: () => Navigator.pop(context, true),
            secondaryButtonText: '나중에 하기',
            onSecondaryPressed: () => Navigator.pop(context, false),
          ),
        );

        if (keepProcceding == true && mounted) {
          if (mounted) {
            final success = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const SecondaryPasswordPage(mode: PasswordMode.setup),
                fullscreenDialog: true,
              ),
            );

            if (success == true && mounted) {
              await showDialog(
                context: context,
                builder: (context) => CommonDialog(
                  icon: Icons.lock_outline, // 추후 이미지로 교체
                  title: '2차 비밀번호 설정 완료',
                  description: '2차 비밀번호 설정이 완료됐어요.\n이제 일기를 작성하러 가볼까요?',
                  primaryButtonText: '확인',
                  onPrimaryPressed: () => Navigator.pop(context),
                ),
              );
            }
          }
          // 비밀번호 설정이 실패하거나 취소되었을 수 있지만,
          // 사용자가 일기를 작성할 수 있도록 계속 진행합니다.
          // 성공적으로 설정했다면, 다음 번에는 `hasPassword`가 업데이트되어 반영될 것입니다.
        }
      }
    }
  }

  Future<void> _showWriteBottomSheet() async {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildWriteBottomSheet(),
    );
  }

  List<JournalEntry> _getEntriesForDay(
    DateTime day,
    List<JournalEntry> entries,
  ) {
    final normalizedDay = _normalizeDate(day);
    return entries
        .where(
          (entry) => isSameDay(_normalizeDate(entry.createdAt), normalizedDay),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final passwordState = ref.watch(journalPasswordProvider);
    final isUnlocked = ref.watch(journalUnlockedProvider);

    return passwordState.when(
      loading: () => const Scaffold(
        appBar: CommonAppBar(title: '나의 일기장'),
        body: Center(child: GitHubGrassLoadingIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: const CommonAppBar(title: '나의 일기장'),
        body: Center(child: Text('오류: $e')),
      ),
      data: (password) {
        // 데이터가 로드되고 현재 탭이 활성화되어 있으면 비밀번호 권유 체크 (최초 1회)
        if (widget.isActive && !_hasCheckedRecommendation) {
          _hasCheckedRecommendation = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkPasswordRecommendation();
          });
        }

        final hasPassword = password != null;
        if (hasPassword && !isUnlocked) {
          return _buildLockScreen();
        }
        final journalEntriesState = ref.watch(journalEntriesProvider);
        return _buildJournalContent(journalEntriesState);
      },
    );
  }

  Widget _buildLockScreen() {
    return Scaffold(
      appBar: const CommonAppBar(title: '나의 일기장'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                '비밀번호를 입력해주세요',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _passwordController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: const InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: _verifyPassword,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _verifyPassword(_passwordController.text),
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyPassword(String input) {
    final notifier = ref.read(journalPasswordProvider.notifier);
    if (notifier.verifyPassword(input)) {
      ref.read(journalUnlockedProvider.notifier).state = true;
      _passwordController.clear();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호가 틀렸습니다')));
    }
  }

  Widget _buildJournalContent(
    AsyncValue<List<JournalEntry>> journalEntriesState,
  ) {
    final allEntries =
        journalEntriesState.valueOrNull ?? const <JournalEntry>[];
    final selectedDayEntries = _getEntriesForDay(_selectedDay, allEntries);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: const CommonAppBar(title: '나의 일기장'),
      body: Column(
        children: [
          // 달력 카드
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: TableCalendar<JournalEntry>(
                locale: 'ko_KR',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                availableCalendarFormats: const {
                  CalendarFormat.month: '월',
                  CalendarFormat.twoWeeks: '2주',
                  CalendarFormat.week: '주',
                },
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: (day) => _getEntriesForDay(day, allEntries),
                rowHeight: 42,
                daysOfWeekHeight: 32,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  cellMargin: const EdgeInsets.all(4),
                  todayDecoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  defaultTextStyle: const TextStyle(
                    color: AppTheme.textPrimary,
                  ),
                  weekendTextStyle: TextStyle(color: Colors.red[300]),
                  markerDecoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  markerSize: 5,
                  markersMaxCount: 1,
                  markerMargin: const EdgeInsets.only(top: 1),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  weekendStyle: TextStyle(
                    color: Colors.red[300],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: AppTheme.primaryColor,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: AppTheme.primaryColor,
                  ),
                  formatButtonDecoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  formatButtonPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  formatButtonTextStyle: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  titleTextStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  headerPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // 선택된 날짜 & 일기 개수 표시
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_calendar_outlined,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedDay.month}월 ${_selectedDay.day}일 ${_getWeekdayName(_selectedDay)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        selectedDayEntries.isEmpty
                            ? '작성된 일기가 없어요'
                            : '${selectedDayEntries.length}개의 기록',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showWriteBottomSheet,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 해당 날짜 일기 목록
          Expanded(
            child: _buildEntriesBody(journalEntriesState, selectedDayEntries),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesBody(
    AsyncValue<List<JournalEntry>> journalEntriesState,
    List<JournalEntry> selectedDayEntries,
  ) {
    if (journalEntriesState.isLoading && selectedDayEntries.isEmpty) {
      return const Center(child: GitHubGrassLoadingIndicator());
    }

    if (journalEntriesState.hasError && selectedDayEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 42,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                journalErrorMessage(journalEntriesState.error!),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    ref.read(journalEntriesProvider.notifier).refresh(),
                child: const Text('다시 불러오기'),
              ),
            ],
          ),
        ),
      );
    }

    if (selectedDayEntries.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: selectedDayEntries.length,
      itemBuilder: (context, index) {
        final entry = selectedDayEntries[index];
        return _buildEntryCard(entry);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                size: 48,
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '아직 기록이 없어요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '오늘 하루를 기록해보세요',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(JournalEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 (시간)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(entry.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // 더보기 버튼 (편집/삭제)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz,
                    size: 20,
                    color: Colors.grey[400],
                  ),
                  padding: EdgeInsets.zero,
                  color: AppTheme.surfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditBottomSheet(entry);
                    } else if (value == 'delete') {
                      _showDeleteDialog(entry);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text('수정'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outlined,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text('삭제', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 본문 텍스트
            if (entry.content.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                entry.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],

            // 첨부 이미지
            if (entry.imagePaths.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildImageGrid(entry.imagePaths),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(JournalEntry entry) {
    showDialog(
      context: context,
      builder: (context) => CommonDialog(
        icon: Icons.delete_outline,
        title: '일기 삭제',
        description: '이 일기를 삭제하시겠습니까?',
        primaryButtonText: '삭제',
        onPrimaryPressed: () async {
          Navigator.pop(context);
          await _deleteEntry(entry);
        },
        secondaryButtonText: '취소',
        onSecondaryPressed: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    try {
      await ref.read(journalEntriesProvider.notifier).delete(entry);
      if (mounted) {
        _showSnackBar('일기가 삭제되었습니다');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(journalErrorMessage(e));
      }
    }
  }

  void _showEditBottomSheet(JournalEntry entry) {
    var editedContent = entry.content;
    final keptImagePaths = List<String>.from(entry.imagePaths);
    final newImages = <File>[];
    var isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 핸들
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // 헤더
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '일기 수정',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_selectedDay.month}월 ${_selectedDay.day}일 ${_getWeekdayName(_selectedDay)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // 텍스트 입력
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextFormField(
                      initialValue: entry.content,
                      onChanged: (value) {
                        editedContent = value;
                      },
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: '오늘 하루는 어땠나요?',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                      ),
                      maxLines: 5,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),

                  // 선택된 이미지 미리보기
                  if (keptImagePaths.isNotEmpty || newImages.isNotEmpty) ...[
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: keptImagePaths.length + newImages.length,
                        itemBuilder: (context, imgIndex) {
                          final isRemote = imgIndex < keptImagePaths.length;
                          return Stack(
                            children: [
                              isRemote
                                  ? _buildStorageImageThumbnail(
                                      keptImagePaths[imgIndex],
                                    )
                                  : Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                          image: FileImage(
                                            newImages[imgIndex -
                                                keptImagePaths.length],
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                              Positioned(
                                top: 6,
                                right: 14,
                                child: GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      if (isRemote) {
                                        keptImagePaths.removeAt(imgIndex);
                                      } else {
                                        newImages.removeAt(
                                          imgIndex - keptImagePaths.length,
                                        );
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 하단 버튼들
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final currentImageCount =
                                      keptImagePaths.length + newImages.length;
                                  if (currentImageCount >= _maxJournalImages) {
                                    _showMaxImageCountSnackBar();
                                    return;
                                  }

                                  try {
                                    final images = await _imagePicker
                                        .pickMultiImage(
                                          maxWidth: 1080,
                                          imageQuality: 85,
                                        );
                                    final files = _imageFilesWithinLimit(
                                      images,
                                      currentCount: currentImageCount,
                                    );
                                    if (files.isNotEmpty) {
                                      setModalState(() {
                                        newImages.addAll(files);
                                      });
                                    }
                                  } catch (e) {
                                    // Handle error silently
                                  }
                                },
                          icon: Icon(
                            Icons.photo_library_outlined,
                            color: AppTheme.primaryColor,
                          ),
                          tooltip: '사진 추가',
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  Navigator.pop(context);
                                },
                          child: Text(
                            '취소',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final content = editedContent.trim();
                                  if (content.isEmpty) {
                                    _showSnackBar('일기 내용을 입력해주세요.');
                                    return;
                                  }

                                  setModalState(() {
                                    isSubmitting = true;
                                  });
                                  final updated = await _updateEntry(
                                    entry,
                                    content,
                                    keptImagePaths,
                                    newImages,
                                  );
                                  if (!context.mounted) return;
                                  if (updated) {
                                    Navigator.pop(context);
                                  } else {
                                    setModalState(() {
                                      isSubmitting = false;
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('저장'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _updateEntry(
    JournalEntry entry,
    String content,
    List<String> keptImagePaths,
    List<File> newImages,
  ) async {
    try {
      await ref
          .read(journalEntriesProvider.notifier)
          .updateEntry(
            entry: entry,
            content: content,
            keptImagePaths: List<String>.from(keptImagePaths),
            newImages: List<File>.from(newImages),
          );
      if (mounted) {
        _showSnackBar('일기가 수정되었습니다');
      }
      return true;
    } catch (e) {
      if (mounted) {
        _showSnackBar(journalErrorMessage(e));
      }
      return false;
    }
  }

  Widget _buildWriteBottomSheet() {
    var isSubmitting = false;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 핸들
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // 헤더
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '일기 작성',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_selectedDay.month}월 ${_selectedDay.day}일 ${_getWeekdayName(_selectedDay)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // 텍스트 입력
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    controller: _journalController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '오늘 하루는 어땠나요?',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                    ),
                    maxLines: 5,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),

                // 선택된 이미지 미리보기
                if (_selectedImages.isNotEmpty) ...[
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(_selectedImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 14,
                              child: GestureDetector(
                                onTap: () {
                                  _removeImage(index);
                                  setModalState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 하단 버튼들
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                await _pickImages();
                                setModalState(() {});
                              },
                        icon: Icon(
                          Icons.photo_library_outlined,
                          color: AppTheme.primaryColor,
                        ),
                        tooltip: '사진 추가',
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : () {
                                _journalController.clear();
                                setState(() => _selectedImages = []);
                                Navigator.pop(context);
                              },
                        child: Text(
                          '취소',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setModalState(() {
                                  isSubmitting = true;
                                });
                                final saved = await _addEntry();
                                if (!context.mounted) return;
                                if (saved) {
                                  Navigator.pop(context);
                                } else {
                                  setModalState(() {
                                    isSubmitting = false;
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('저장'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStorageImageThumbnail(String imagePath) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 90,
      height: 90,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildStorageImage(imagePath, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildStorageImage(
    String imagePath, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    return FutureBuilder<String>(
      future: FirebaseStorage.instance.ref(imagePath).getDownloadURL(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.network(
            snapshot.data!,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (context, error, stackTrace) =>
                _buildImagePlaceholder(),
          );
        }

        if (snapshot.hasError) {
          return _buildImagePlaceholder();
        }

        return _buildImagePlaceholder(showProgress: true);
      },
    );
  }

  Widget _buildImagePlaceholder({bool showProgress = false}) {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: showProgress
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.broken_image_outlined, color: Colors.grey[500]),
    );
  }

  Widget _buildImageGrid(List<String> imagePaths) {
    Widget storageImage(String path) {
      return _buildStorageImage(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    final images = imagePaths;
    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          height: 200,
          child: storageImage(images[0]),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: images.length == 2 ? 2 : 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: images.length > 6 ? 6 : images.length,
      itemBuilder: (context, index) {
        final isLastWithMore = index == 5 && images.length > 6;
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              storageImage(images[index]),
              if (isLastWithMore)
                Container(
                  color: Colors.black45,
                  child: Center(
                    child: Text(
                      '+${images.length - 6}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
