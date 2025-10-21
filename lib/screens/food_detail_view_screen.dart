import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../models/user_log.dart';
import '../providers/food_log_provider.dart';
import 'emoji_selection_screen.dart';

class FoodDetailViewScreen extends StatefulWidget {
  final UserLog userLog;
  final VoidCallback? onBack;
  final VoidCallback? onSave;
  final VoidCallback? onDelete;

  const FoodDetailViewScreen({
    super.key,
    required this.userLog,
    this.onBack,
    this.onSave,
    this.onDelete,
  });

  @override
  State<FoodDetailViewScreen> createState() => _FoodDetailViewScreenState();
}

class _FoodDetailViewScreenState extends State<FoodDetailViewScreen> {
  DateTime _recommendedDisposalDate = DateTime.now().add(
    const Duration(days: 7),
  );

  String _selectedEmojiPath = '';
  bool _isEmojiSelectionMode = false; // 이모지 선택 모드 상태

  // 변경사항 추적을 위한 변수들
  late DateTime _originalExpiryDate;
  late String _originalEmojiPath;

  // 카테고리 목록
  final List<String> _categories = [
    '채소 · 과일',
    '육류 · 생선',
    '계란 · 두부',
    '김치 · 절임류',
    '유제품',
    '견과류 · 쌀',
    '디저트',
    '베이커리',
    '커피 · 술 · 음료',
    '소스 · 양념',
    '조리된 음식',
    '기타',
  ];

  // 보관 장소 목록
  final List<String> _locations = ['냉장', '냉동'];

  // 손질 상태 목록
  final List<String> _conditions = ['통째', '손질', '조리됨'];

  @override
  void initState() {
    super.initState();
    _recommendedDisposalDate =
        widget.userLog.expiryDate ??
        DateTime.now().add(const Duration(days: 7));
    _selectedEmojiPath = widget.userLog.emojiPath;

    // 원본 값 저장 (변경사항 추적용)
    _originalExpiryDate = _recommendedDisposalDate;
    _originalEmojiPath = _selectedEmojiPath;

    // 디버깅을 위해 UserLog 정보 출력
    print('=== Food Detail View Debug ===');
    print('Food Name: ${widget.userLog.foodName}');
    print('Category: "${widget.userLog.category}"');
    print('Storage Type: ${widget.userLog.storageType}');
    print('Condition: ${widget.userLog.condition}');
    print('Is Sealed: ${widget.userLog.isSealed}');
    print('=============================');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _isEmojiSelectionMode
              ? EmojiSelectionScreen(
                  currentEmojiPath: _selectedEmojiPath,
                  onEmojiSelected: _onEmojiSelected,
                  onBack: _onEmojiSelectionBack,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      _buildFoodInfoBox(),
                      const SizedBox(height: 24),
                      _buildDateSection(),
                      const SizedBox(height: 24),
                      _buildCategorySection(),
                      const SizedBox(height: 24),
                      _buildLocationSection(),
                      const SizedBox(height: 24),
                      _buildConditionSection(),
                      const SizedBox(height: 24),
                      _buildSealedSection(),
                      const SizedBox(height: 24),
                      _buildRecommendedDisposalSection(),
                      const SizedBox(height: 40),
                      _buildDeleteButton(),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    if (_isEmojiSelectionMode) {
      // 이모지 선택 모드일 때의 헤더
      return Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 28, bottom: 6),
        child: Row(
          children: [
            // 뒤로가기 버튼
            GestureDetector(
              onTap: _onEmojiSelectionBack,
              child: Container(
                width: 24,
                height: 24,
                child: Transform.scale(
                  scaleX: -1, // 좌우 반전
                  child: SvgPicture.asset(
                    'assets/images/ic_ic_arrowsmall_right.svg',
                    width: 24,
                    height: 24,
                    color: const Color(0xFF676C74),
                  ),
                ),
              ),
            ),
            const Spacer(),
            // 제목
            const Text(
              '이모지 선택',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF363A48),
                letterSpacing: -0.3,
                height: 22 / 16,
              ),
            ),
            const Spacer(),
            // 빈 공간 (대칭을 위해)
            const SizedBox(width: 26),
          ],
        ),
      );
    } else {
      // 일반 모드일 때의 헤더
      return Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 28, bottom: 6),
        child: Row(
          children: [
            // 취소 버튼
            GestureDetector(
              onTap: widget.onBack,
              child: const Text(
                '취소',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF676C74),
                  letterSpacing: -0.3,
                  height: 22 / 14,
                ),
              ),
            ),
            const Spacer(),
            // 제목
            const Text(
              '음식 상세',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF363A48),
                letterSpacing: -0.3,
                height: 22 / 16,
              ),
            ),
            const Spacer(),
            // 저장 버튼
            GestureDetector(
              onTap: _hasChanges() ? _saveChanges : null,
              child: Text(
                '저장',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _hasChanges()
                      ? const Color(0xFF363A48) // 활성화 상태
                      : const Color(0xFFBDBDBD), // 비활성화 상태
                  letterSpacing: -0.3,
                  height: 22 / 14,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFoodInfoBox() {
    return GestureDetector(
      onTap: _navigateToEmojiSelection,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 음식 아이콘
            _selectedEmojiPath.isNotEmpty
                ? Container(
                    width: 40,
                    height: 40,
                    child: Image.asset(
                      _selectedEmojiPath,
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: const ShapeDecoration(
                            color: Color(0xFFEAECF0),
                            shape: CircleBorder(),
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    decoration: const ShapeDecoration(
                      color: Color(0xFFEAECF0),
                      shape: CircleBorder(),
                    ),
                  ),

            const SizedBox(height: 8),

            // 음식명
            Text(
              widget.userLog.foodName,
              style: const TextStyle(
                color: Color(0xFF363A48),
                fontSize: 22,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                height: 32 / 22,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '보관 시작일',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF676C74),
            letterSpacing: -0.3,
            height: 22 / 14,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              // 이전 날짜 버튼 (비활성화)
              Container(
                width: 50,
                height: 40,
                decoration: ShapeDecoration(
                  color: const Color(0xFFF5F5F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child: Center(
                  child: Transform.scale(
                    scaleX: -1, // 좌우 반전으로 이전 방향
                    child: SvgPicture.asset(
                      'assets/images/chevron-back.svg',
                      width: 24,
                      height: 24,
                      color: const Color(0xFFBDBDBD),
                    ),
                  ),
                ),
              ),

              // 날짜 표시
              Expanded(
                child: Text(
                  '${widget.userLog.startDate.year}.${widget.userLog.startDate.month.toString().padLeft(2, '0')}.${widget.userLog.startDate.day.toString().padLeft(2, '0')} ${_getDayOfWeek(widget.userLog.startDate)}',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF363A48),
                    letterSpacing: -0.4,
                    height: 24 / 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // 다음 날짜 버튼 (비활성화)
              Container(
                width: 50,
                height: 40,
                decoration: ShapeDecoration(
                  color: const Color(0xFFF5F5F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/chevron-back.svg',
                    width: 24,
                    height: 24,
                    color: const Color(0xFFBDBDBD),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '카테고리',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF676C74),
            letterSpacing: -0.3,
            height: 22 / 14,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 34,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _isCategorySelected(category);

              return Container(
                margin: EdgeInsets.only(
                  right: index < _categories.length - 1 ? 8 : 0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF363A48)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFFBDBDBD),
                      height: 22 / 14,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '보관 장소',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF676C74),
            letterSpacing: -0.3,
            height: 22 / 14,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 34,
          child: Row(
            children: _locations.map((location) {
              final isSelected = location == widget.userLog.storageType;

              return Container(
                margin: EdgeInsets.only(
                  right: location == _locations.last ? 0 : 8,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF363A48)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  location,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFFBDBDBD),
                    height: 22 / 14,
                    letterSpacing: -0.3,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '손질 상태',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF676C74),
            letterSpacing: -0.3,
            height: 22 / 14,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 34,
          child: Row(
            children: _conditions.map((condition) {
              final isSelected = _isConditionSelected(condition);

              return Container(
                margin: EdgeInsets.only(
                  right: condition == _conditions.last ? 0 : 8,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF363A48)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  condition,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFFBDBDBD),
                    height: 22 / 14,
                    letterSpacing: -0.3,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSealedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '밀폐 여부',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF676C74),
            letterSpacing: -0.3,
            height: 22 / 14,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 34,
          child: Row(
            children: ['밀폐안함', '밀폐함'].map((sealedOption) {
              final isSelected =
                  (sealedOption == '밀폐함') == widget.userLog.isSealed;

              return Container(
                margin: EdgeInsets.only(right: sealedOption == '밀폐함' ? 0 : 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF363A48)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sealedOption,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFFBDBDBD),
                    height: 22 / 14,
                    letterSpacing: -0.3,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedDisposalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '권장 폐기일',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF676C74),
            letterSpacing: -0.3,
            height: 22 / 14,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showDatePicker,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // 이전 날짜 버튼
                GestureDetector(
                  onTap: () => setState(
                    () => _recommendedDisposalDate = _recommendedDisposalDate
                        .subtract(const Duration(days: 1)),
                  ),
                  child: Container(
                    width: 50,
                    height: 40,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF353948),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: Center(
                      child: Transform.scale(
                        scaleX: -1, // 좌우 반전으로 이전 방향
                        child: SvgPicture.asset(
                          'assets/images/chevron-back.svg',
                          width: 24,
                          height: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // 날짜 표시
                Expanded(
                  child: Text(
                    '${_recommendedDisposalDate.year}.${_recommendedDisposalDate.month.toString().padLeft(2, '0')}.${_recommendedDisposalDate.day.toString().padLeft(2, '0')} ${_getDayOfWeek(_recommendedDisposalDate)}',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF363A48),
                      letterSpacing: -0.4,
                      height: 24 / 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // 다음 날짜 버튼
                GestureDetector(
                  onTap: () => setState(
                    () => _recommendedDisposalDate = _recommendedDisposalDate
                        .add(const Duration(days: 1)),
                  ),
                  child: Container(
                    width: 50,
                    height: 40,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF353948),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/chevron-back.svg',
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showDeleteConfirmation,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF363A48), // 남색 배경
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: const Text(
          '버리기',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            height: 24 / 16,
          ),
        ),
      ),
    );
  }

  // 삭제 확인 다이얼로그 표시
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '음식을 버리시겠습니까?',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF363A48),
            ),
          ),
          content: Text(
            '${widget.userLog.foodName}을(를) 버리시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF676C74),
              height: 20 / 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF676C74),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteFood();
              },
              child: const Text(
                '버리기',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD04466),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 음식 삭제 처리
  Future<void> _deleteFood() async {
    try {
      final success = await Provider.of<FoodLogProvider>(
        context,
        listen: false,
      ).deleteFoodLog(widget.userLog.id, widget.userLog.storageType);

      if (success) {
        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.userLog.foodName}이(가) 삭제되었습니다'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF525866),
          ),
        );

        // 삭제 완료 후 콜백 호출
        if (widget.onDelete != null) {
          widget.onDelete!();
        }
      } else {
        // 실패 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('삭제에 실패했습니다'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFFD04466),
          ),
        );
      }
    } catch (e) {
      print('삭제 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('삭제 중 오류가 발생했습니다: $e'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFFD04466),
        ),
      );
    }
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
    return days[date.weekday % 7];
  }

  // 변경사항이 있는지 확인
  bool _hasChanges() {
    return _recommendedDisposalDate != _originalExpiryDate ||
        _selectedEmojiPath != _originalEmojiPath;
  }

  // 카테고리 선택 여부 확인 (기존 카테고리와 새로운 카테고리 매핑)
  bool _isCategorySelected(String newCategory) {
    final oldCategory = widget.userLog.category;

    // 디버깅을 위해 콘솔에 출력
    print('UserLog category: "$oldCategory", checking against: "$newCategory"');
    print(
      'Category length: ${oldCategory.length}, newCategory length: ${newCategory.length}',
    );
    print(
      'Category bytes: ${oldCategory.codeUnits}, newCategory bytes: ${newCategory.codeUnits}',
    );

    // 기존 카테고리와 새로운 카테고리 매핑
    switch (oldCategory) {
      case '과일':
      case '채소':
      case '채소 · 과일':
      case '채소·과일': // 중간점 없는 버전도 추가
        return newCategory == '채소 · 과일';
      case '육류':
      case '해산물':
      case '육류 · 생선':
      case '육류·생선': // 중간점 없는 버전도 추가
        return newCategory == '육류 · 생선';
      case '계란':
      case '두부':
      case '계란 · 두부':
      case '계란·두부': // 중간점 없는 버전도 추가
        return newCategory == '계란 · 두부';
      case '김치':
      case '절임류':
      case '김치 · 절임류':
      case '김치·절임류': // 중간점 없는 버전도 추가
        return newCategory == '김치 · 절임류';
      case '유제품':
        return newCategory == '유제품';
      case '견과류':
      case '쌀':
      case '견과류 · 쌀':
      case '견과류·쌀': // 중간점 없는 버전도 추가
        return newCategory == '견과류 · 쌀';
      case '디저트':
        return newCategory == '디저트';
      case '베이커리':
        return newCategory == '베이커리';
      case '커피':
      case '술':
      case '음료':
      case '커피 · 술 · 음료':
      case '커피·술·음료': // 중간점 없는 버전도 추가
        return newCategory == '커피 · 술 · 음료';
      case '소스':
      case '양념':
      case '소스 · 양념':
      case '소스·양념': // 중간점 없는 버전도 추가
        return newCategory == '소스 · 양념';
      case '조리된 음식':
        return newCategory == '조리된 음식';
      case '샌드위치':
      case '빵':
      case '도시락':
      case '기타':
        return newCategory == '기타';
      default:
        // 정확히 일치하는 경우
        final isExactMatch = newCategory == oldCategory;
        print('Exact match: $isExactMatch');
        return isExactMatch;
    }
  }

  // 손질 상태 선택 여부 확인 (기존 상태와 새로운 상태 매핑)
  bool _isConditionSelected(String newCondition) {
    final oldCondition = widget.userLog.condition;

    // 기존 상태와 새로운 상태 매핑
    switch (oldCondition) {
      case '통째':
        return newCondition == '통째';
      case '썰어둠':
        return newCondition == '손질';
      case '다져둠':
        return newCondition == '조리됨';
      default:
        // 정확히 일치하는 경우
        return newCondition == oldCondition;
    }
  }

  // 권장 폐기일을 위한 DatePicker 표시
  void _showDatePicker() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _recommendedDisposalDate.isBefore(now)
          ? now
          : _recommendedDisposalDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)), // 1년 후까지 선택 가능
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF814083), // 헤더 색상
              onPrimary: Colors.white, // 헤더 텍스트 색상
              onSurface: Color(0xFF363A48), // 날짜 텍스트 색상
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _recommendedDisposalDate) {
      setState(() {
        _recommendedDisposalDate = picked;
      });
    }
  }

  // 이모지 선택 완료
  void _onEmojiSelected(String emojiPath) {
    setState(() {
      _selectedEmojiPath = emojiPath;
      _isEmojiSelectionMode = false;
    });
  }

  // 이모지 선택 모드에서 뒤로가기
  void _onEmojiSelectionBack() {
    setState(() {
      _isEmojiSelectionMode = false;
    });
  }

  // 변경사항 저장
  Future<void> _saveChanges() async {
    try {
      // 권장폐기일과 이모지 경로가 변경되었는지 확인
      final originalExpiryDate =
          widget.userLog.expiryDate ??
          DateTime.now().add(const Duration(days: 7));
      final hasExpiryDateChanged =
          _recommendedDisposalDate != originalExpiryDate;
      final hasEmojiPathChanged =
          _selectedEmojiPath != widget.userLog.emojiPath;

      if (hasExpiryDateChanged || hasEmojiPathChanged) {
        // Provider를 통해 권장폐기일 업데이트
        final success =
            await Provider.of<FoodLogProvider>(
              context,
              listen: false,
            ).updateExpiryDate(
              widget.userLog.id,
              widget.userLog.storageType,
              _recommendedDisposalDate,
            );

        if (success) {
          // 이모지 경로도 업데이트
          if (hasEmojiPathChanged) {
            await Provider.of<FoodLogProvider>(
              context,
              listen: false,
            ).updateEmojiPath(
              widget.userLog.id,
              widget.userLog.storageType,
              _selectedEmojiPath,
            );
          }

          // 원본 값 업데이트 (변경사항 추적용)
          _originalExpiryDate = _recommendedDisposalDate;
          _originalEmojiPath = _selectedEmojiPath;

          // 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                hasExpiryDateChanged && hasEmojiPathChanged
                    ? '권장폐기일과 이모지가 업데이트되었습니다'
                    : hasExpiryDateChanged
                    ? '권장폐기일이 업데이트되었습니다'
                    : '이모지가 업데이트되었습니다',
              ),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF525866),
            ),
          );

          // 상세 화면 닫기
          if (widget.onSave != null) {
            widget.onSave!();
          }
        } else {
          // 실패 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('저장에 실패했습니다'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFFD04466),
            ),
          );
        }
      } else {
        // 변경사항이 없으면 그냥 닫기
        if (widget.onSave != null) {
          widget.onSave!();
        }
      }
    } catch (e) {
      print('저장 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 중 오류가 발생했습니다: $e'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFFD04466),
        ),
      );
    }
  }

  // 이모지 선택 모드로 전환
  void _navigateToEmojiSelection() {
    setState(() {
      _isEmojiSelectionMode = true;
    });
  }
}
