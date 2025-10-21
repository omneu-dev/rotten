import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../models/food.dart';
import '../models/user_log.dart';
import '../services/food_data_service.dart';
import '../providers/food_log_provider.dart';
import 'emoji_selection_screen.dart';

class FoodDetailScreen extends StatefulWidget {
  final Food selectedFood;
  final VoidCallback? onBack;

  const FoodDetailScreen({super.key, required this.selectedFood, this.onBack});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  final FoodDataService _foodDataService = FoodDataService();

  DateTime _selectedDate = DateTime.now();
  DateTime _recommendedDisposalDate = DateTime.now().add(
    const Duration(days: 7),
  ); // 권장 폐기일 (기본 7일 후)
  String _selectedCategory = '채소·과일';
  String _selectedLocation = '냉장';
  String _selectedCondition = '통째';
  bool _isSealed = false;
  String _selectedEmojiPath = '';
  bool _isEmojiSelectionMode = false; // 이모지 선택 모드 상태
  bool _isAIAutoPrediction = true; // AI 자동 예측 체크박스 상태

  final List<String> _categories = [
    '채소·과일',
    '육류·생선',
    '계란·두부',
    '김치·절임류',
    '유제품',
    '건과류·쌀',
    '베이커리',
    '디저트',
    '커피·술·음료',
    '조리된 음식',
    '기타',
  ];

  final List<String> _locations = ['냉장', '냉동'];
  final List<String> _conditions = ['통째', '손질', '조리됨'];

  @override
  void initState() {
    super.initState();
    // 선택된 음식의 카테고리로 초기화
    if (_categories.contains(widget.selectedFood.category)) {
      _selectedCategory = widget.selectedFood.category;
    }
    // 선택된 음식의 이모지 경로로 초기화
    _selectedEmojiPath = widget.selectedFood.emojiPath;
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
                  onEmojiSelected: (String newEmojiPath) {
                    setState(() {
                      _selectedEmojiPath = newEmojiPath;
                      _isEmojiSelectionMode = false;
                    });
                  },
                  onBack: () {
                    setState(() {
                      _isEmojiSelectionMode = false;
                    });
                  },
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
                      // 손질 상태와 밀폐 여부는 AI 자동 예측이 선택되었을 때 표시 (AI 예측에 필요한 정보)
                      if (_isAIAutoPrediction) ...[
                        const SizedBox(height: 24),
                        _buildConditionSection(),
                        const SizedBox(height: 24),
                        _buildSealedSection(),
                      ],
                      const SizedBox(height: 24),
                      _buildRecommendedDisposalSection(),
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
              onTap: () {
                setState(() {
                  _isEmojiSelectionMode = false;
                });
              },
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
            // 뒤로가기 버튼 (좌우 반전)
            GestureDetector(
              onTap: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.pop(context);
                }
              },
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
              '보관 상태',
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
              onTap: _saveFood,
              child: const Text(
                '저장',
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
        //height: 112,
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
                        // 에러 발생 시 빈 동그라미 표시
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
              widget.selectedFood.name,
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
              // 이전 날짜 버튼
              GestureDetector(
                onTap: () => setState(
                  () => _selectedDate = _selectedDate.subtract(
                    const Duration(days: 1),
                  ),
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
                  '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')} ${_getDayOfWeek(_selectedDate)}',
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
                  () => _selectedDate = _selectedDate.add(
                    const Duration(days: 1),
                  ),
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
      ],
    );
  }

  Widget _buildRecommendedDisposalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목과 AI 자동 예측 체크박스
        Row(
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
            const Spacer(),
            // AI 자동 예측 체크박스
            GestureDetector(
              onTap: () {
                setState(() {
                  _isAIAutoPrediction = !_isAIAutoPrediction;
                });
              },
              child: Row(
                children: [
                  const Text(
                    'AI 자동 예측',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF676C74),
                      letterSpacing: -0.3,
                      height: 22 / 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SvgPicture.asset(
                    'assets/images/checkbox.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      _isAIAutoPrediction
                          ? const Color(0xFFD04466)
                          : const Color(0xFFEAECF0),
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 날짜 선택 컴포넌트 (AI 예측이 꺼져있을 때만 표시)
        if (!_isAIAutoPrediction) ...[
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
              final isSelected = category == _selectedCategory;

              return Container(
                margin: EdgeInsets.only(
                  right: index < _categories.length - 1 ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF363A48)
                          : const Color(0xFFEAECF0),
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
                            : const Color(0xFF686C75),
                        height: 22 / 14,
                        letterSpacing: -0.3,
                      ),
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
              final isSelected = location == _selectedLocation;
              return GestureDetector(
                onTap: () => setState(() => _selectedLocation = location),
                child: Container(
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
                        : const Color(0xFFEAECF0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    location,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF686C75),
                      height: 22 / 14,
                      letterSpacing: -0.3,
                    ),
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
              final isSelected = condition == _selectedCondition;
              return GestureDetector(
                onTap: () => setState(() => _selectedCondition = condition),
                child: Container(
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
                        : const Color(0xFFEAECF0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    condition,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF686C75),
                      height: 22 / 14,
                      letterSpacing: -0.3,
                    ),
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
              final isSelected = (sealedOption == '밀폐함') == _isSealed;
              return GestureDetector(
                onTap: () => setState(() => _isSealed = sealedOption == '밀폐함'),
                child: Container(
                  margin: EdgeInsets.only(right: sealedOption == '밀폐함' ? 0 : 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF363A48)
                        : const Color(0xFFEAECF0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sealedOption,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF686C75),
                      height: 22 / 14,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
    return days[date.weekday % 7];
  }

  // 권장 폐기일을 위한 DatePicker 표시
  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _recommendedDisposalDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)), // 1년 후까지 선택 가능
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

  void _saveFood() async {
    try {
      // UserLog 객체 생성
      UserLog userLog = _foodDataService.createUserLog(
        food: widget.selectedFood,
        category: _selectedCategory,
        location: _selectedLocation,
        condition: _selectedCondition,
        startDate: _selectedDate,
        isSealed: _isSealed,
      );

      // 디버그 정보 출력
      print('음식 저장 시작: ${widget.selectedFood.name}');
      print('선택된 음식 이미지 경로: ${widget.selectedFood.emojiPath}');
      print('보관 시작일: $_selectedDate');
      print('카테고리: $_selectedCategory');
      print('보관 장소: $_selectedLocation');
      print('손질 상태: $_selectedCondition');
      print('밀폐 여부: $_isSealed');
      print('예상 유효기한: ${userLog.expiryDate}');

      // Provider를 통해 저장 (자동으로 화면 업데이트됨)
      bool success = await context.read<FoodLogProvider>().addFoodLog(userLog);

      if (success) {
        // 저장 성공 시 페이지 닫기
        if (widget.onBack != null) {
          // 모달 내부에서 사용되는 경우 - 모달 전체를 닫기
          Navigator.of(context, rootNavigator: true).pop();
        } else {
          // 독립 페이지인 경우
          Navigator.popUntil(context, (route) => route.isFirst);
        }

        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.selectedFood.name}이(가) 저장되었습니다'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF525866),
          ),
        );
      } else {
        // 저장 실패 시 에러 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장에 실패했습니다. 다시 시도해주세요.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('음식 저장 에러: $e');

      // 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장 중 오류가 발생했습니다.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
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
