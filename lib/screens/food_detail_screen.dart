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
  final bool isCustomFood; // 직접 추가한 음식인지 여부
  final String initialLocation; // 진입 화면 기준 기본 보관 장소 ('냉장' or '냉동')

  const FoodDetailScreen({
    super.key,
    required this.selectedFood,
    this.onBack,
    this.isCustomFood = false, // 기본값: false
    this.initialLocation = '냉장',
  });

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
  late bool _isAIAutoPrediction; // AI 자동 예측 체크박스 상태
  bool _isExpiryManuallyEdited = false; // 사용자가 권장 폐기일을 직접 수정했는지
  bool _isStorageTipInfoVisible = false; // 보관 TIP 안내 말풍선 표시 여부
  bool _isExpiryTipInfoVisible = false; // 권장 폐기일 안내 말풍선 표시 여부
  bool _hasShownStorageTipAnimation = false; // 보관 TIP 타이프라이터 효과를 이미 보여줬는지 여부

  final GlobalKey _recommendedSectionKey = GlobalKey(); // 권장 폐기일 섹션 위치 추적용
  final ScrollController _categoryScrollController =
      ScrollController(); // 카테고리 스크롤 컨트롤러
  final Map<String, GlobalKey> _categoryKeys = {}; // 각 카테고리 아이템의 GlobalKey

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
    '국·반찬·메인요리',
    '조미료·양념',
    '기타',
  ];

  final List<String> _locations = ['냉장', '냉동'];
  final List<String> _conditions = ['통째', '손질', '조리됨'];

  @override
  void initState() {
    super.initState();
    // 각 카테고리에 대한 GlobalKey 초기화
    for (final category in _categories) {
      _categoryKeys[category] = GlobalKey();
    }

    // 선택된 음식의 카테고리로 초기화
    if (_categories.contains(widget.selectedFood.category)) {
      _selectedCategory = widget.selectedFood.category;
    }
    // 진입 시 기본 보관 장소 (냉장/냉동 화면에 따라)
    _selectedLocation = widget.initialLocation;
    // 선택된 음식의 이모지 경로로 초기화
    _selectedEmojiPath = widget.selectedFood.emojiPath;
    // 직접 추가한 음식인 경우 AI 자동 예측 체크 해제
    _isAIAutoPrediction = !widget.isCustomFood;

    // 초기 권장 폐기일을 AI 기준으로 설정 (가능한 경우)
    if (_isAIAutoPrediction) {
      final aiDate = _foodDataService.calculateExpiryDate(
        widget.selectedFood,
        _selectedLocation,
        _selectedCondition,
        _isSealed,
        _selectedDate,
      );
      if (aiDate != null) {
        _recommendedDisposalDate = aiDate;
      }
    }

    // 선택된 카테고리가 보이도록 스크롤 위치 설정 (여러 프레임 대기로 안정성 확보)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 첫 프레임에서 위젯이 완전히 렌더링되지 않을 수 있으므로 여러 프레임 더 대기
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSelectedCategory();
        });
      });
    });
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  // 선택된 카테고리로 스크롤
  void _scrollToSelectedCategory({int retryCount = 0}) {
    final selectedIndex = _categories.indexOf(_selectedCategory);
    if (selectedIndex == -1) {
      return;
    }

    // ScrollController가 준비되지 않았으면 재시도 (최대 5번)
    if (!_categoryScrollController.hasClients) {
      if (retryCount < 5) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSelectedCategory(retryCount: retryCount + 1);
        });
      }
      return;
    }

    // '국·반찬·메인요리'부터 이후 카테고리들은 선택된 버튼이 완전히 보이도록 스크롤
    // '국·반찬·메인요리'는 인덱스 9
    if (selectedIndex >= 9) {
      // 선택된 카테고리 버튼의 위치 측정
      final selectedCategoryKey = _categoryKeys[_selectedCategory];
      if (selectedCategoryKey?.currentContext != null) {
        final RenderBox? selectedBox =
            selectedCategoryKey!.currentContext!.findRenderObject()
                as RenderBox?;
        if (selectedBox != null && selectedBox.hasSize) {
          // 선택된 버튼까지의 누적 너비 계산
          double scrollPosition = 0.0;
          bool allBoxesMeasured = true;

          for (int i = 0; i < selectedIndex; i++) {
            final categoryKey = _categoryKeys[_categories[i]];
            if (categoryKey?.currentContext != null) {
              final RenderBox? box =
                  categoryKey!.currentContext!.findRenderObject() as RenderBox?;
              if (box != null && box.hasSize) {
                scrollPosition += box.size.width;
                if (i < selectedIndex - 1) {
                  scrollPosition += 8; // margin right (각 아이템 사이)
                }
              } else {
                allBoxesMeasured = false;
                break;
              }
            } else {
              allBoxesMeasured = false;
              break;
            }
          }

          if (allBoxesMeasured) {
            // 선택된 버튼의 오른쪽 끝이 보이도록 스크롤 위치 계산
            // 화면 너비를 고려하여 선택된 버튼이 완전히 보이도록 조정
            final viewportWidth =
                _categoryScrollController.position.viewportDimension;
            final targetScrollPosition =
                scrollPosition +
                selectedBox.size.width -
                viewportWidth +
                16; // 약간의 여유 공간

            _categoryScrollController.jumpTo(
              targetScrollPosition.clamp(
                0.0,
                _categoryScrollController.position.maxScrollExtent,
              ),
            );
            return;
          }
        }
      }

      // 위치 측정 실패 시 재시도 (최대 5번)
      if (retryCount < 5) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSelectedCategory(retryCount: retryCount + 1);
        });
        return;
      }

      // 재시도 실패 시 스크롤 끝까지 이동 (애니메이션 없이 즉시)
      _categoryScrollController.jumpTo(
        _categoryScrollController.position.maxScrollExtent,
      );
      return;
    }

    // 선택된 칩의 이전 칩이 보이도록 스크롤 위치 계산
    if (selectedIndex > 0) {
      // 이전 칩의 위치 측정
      final prevCategoryKey = _categoryKeys[_categories[selectedIndex - 1]];
      if (prevCategoryKey?.currentContext != null) {
        final RenderBox? prevBox =
            prevCategoryKey!.currentContext!.findRenderObject() as RenderBox?;
        if (prevBox != null && prevBox.hasSize) {
          // 이전 칩까지의 누적 너비 계산 (각 아이템의 실제 너비 + margin)
          double scrollPosition = 0.0;
          bool allBoxesMeasured = true;

          for (int i = 0; i < selectedIndex - 1; i++) {
            final categoryKey = _categoryKeys[_categories[i]];
            if (categoryKey?.currentContext != null) {
              final RenderBox? box =
                  categoryKey!.currentContext!.findRenderObject() as RenderBox?;
              if (box != null && box.hasSize) {
                scrollPosition += box.size.width;
                scrollPosition += 8; // margin right (각 아이템 사이)
              } else {
                allBoxesMeasured = false;
                break;
              }
            } else {
              allBoxesMeasured = false;
              break;
            }
          }

          // 모든 박스가 측정되었을 때만 스크롤
          if (allBoxesMeasured) {
            // 이전 칩의 시작 위치로 스크롤 (애니메이션 없이 즉시 이동)
            scrollPosition = scrollPosition.clamp(
              0.0,
              _categoryScrollController.position.maxScrollExtent,
            );

            _categoryScrollController.jumpTo(scrollPosition);
            return;
          }
        }
      }

      // 위치 측정 실패 시 재시도 (최대 5번)
      if (retryCount < 5) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSelectedCategory(retryCount: retryCount + 1);
        });
        return;
      }
    }

    // 첫 번째 칩이거나 위치 측정 실패 시 시작 위치로 (애니메이션 없이 즉시 이동)
    if (_categoryScrollController.hasClients) {
      _categoryScrollController.jumpTo(0.0);
    }
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
                      if (widget.selectedFood.aiStorageTips != null &&
                          widget.selectedFood.aiStorageTips!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildStorageTipSection(),
                      ],
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
                      // 권장 폐기일 섹션 (스크롤 위치 추적용 키 부여)
                      Container(
                        key: _recommendedSectionKey,
                        child: _buildRecommendedDisposalSection(),
                      ),

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
        // 날짜 선택 + DatePicker를 위한 GestureDetector
        GestureDetector(
          onTap: _showDatePickerForStartDate,
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
                  onTap: () => setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));

                    // AI 자동 예측이 켜져 있고 사용자가 권장 폐기일을 직접 수정하지 않았다면
                    // 새 보관 시작일을 기준으로 권장 폐기일을 다시 계산
                    if (_isAIAutoPrediction && !_isExpiryManuallyEdited) {
                      final aiDate = _foodDataService.calculateExpiryDate(
                        widget.selectedFood,
                        _selectedLocation,
                        _selectedCondition,
                        _isSealed,
                        _selectedDate,
                      );
                      if (aiDate != null) {
                        _recommendedDisposalDate = aiDate;
                      }
                    }
                  }),
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

  Widget _buildRecommendedDisposalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목과 Info 아이콘, AI 자동 예측 체크박스
        Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
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
                if (_isAIAutoPrediction) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpiryTipInfoVisible = !_isExpiryTipInfoVisible;
                      });
                    },
                    child: const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Color(0xFFACB1BA),
                    ),
                  ),
                ],
              ],
            ),
            const Spacer(),
            // AI 자동 예측 체크박스
            GestureDetector(
              onTap: () {
                // 직접 추가한 음식이고 체크박스가 꺼져있는 경우 팝업 표시
                if (widget.isCustomFood && !_isAIAutoPrediction) {
                  _showProFeatureDialog();
                } else {
                  setState(() {
                    final newValue = !_isAIAutoPrediction;
                    _isAIAutoPrediction = newValue;
                    _isExpiryTipInfoVisible = false;
                    _isExpiryManuallyEdited = false;

                    if (newValue) {
                      final aiDate = _foodDataService.calculateExpiryDate(
                        widget.selectedFood,
                        _selectedLocation,
                        _selectedCondition,
                        _isSealed,
                        _selectedDate,
                      );
                      if (aiDate != null) {
                        _recommendedDisposalDate = aiDate;
                      }
                    }
                  });

                  // 토글 시 권장 폐기일 섹션이 화면에 보이도록 스크롤
                  if (_recommendedSectionKey.currentContext != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Scrollable.ensureVisible(
                        _recommendedSectionKey.currentContext!,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: 0.2,
                      );
                    });
                  }
                }
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
        const SizedBox(height: 8),
        // 날짜 선택 + 툴팁을 위한 Stack
        Stack(
          clipBehavior: Clip.none,
          children: [
            // 날짜 선택 컴포넌트 (항상 표시, 단 AI 예측 On 상태에서 값은 자동 채움)
            GestureDetector(
              onTap: _showDatePicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // 이전 날짜 버튼
                    GestureDetector(
                      onTap: () => setState(() {
                        _recommendedDisposalDate = _recommendedDisposalDate
                            .subtract(const Duration(days: 1));
                        // 사용자가 날짜를 직접 수정한 것이므로 AI 자동 예측 해제
                        _isExpiryManuallyEdited = true;
                        if (_isAIAutoPrediction) {
                          _isAIAutoPrediction = false;
                        }
                        _isExpiryTipInfoVisible = false;
                      }),
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
                      onTap: () => setState(() {
                        _recommendedDisposalDate = _recommendedDisposalDate.add(
                          const Duration(days: 1),
                        );
                        // 사용자가 날짜를 직접 수정한 것이므로 AI 자동 예측 해제
                        _isExpiryManuallyEdited = true;
                        if (_isAIAutoPrediction) {
                          _isAIAutoPrediction = false;
                        }
                        _isExpiryTipInfoVisible = false;
                      }),
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

            // 권장 폐기일 안내 말풍선 (info 아이콘 아래, 기존 레이어 위에 오버레이)
            if (_isExpiryTipInfoVisible)
              Positioned(
                left: 0,
                top: 8,
                child: Container(
                  width: 230,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Expanded(
                        child: Text(
                          'GPT로 생성된 날짜입니다.\nAI는 실수할 수 있습니다.',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF676C74),
                            letterSpacing: -0.3,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          setState(() {
                            _isExpiryTipInfoVisible = false;
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Color(0xFFACB1BA),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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
            controller: _categoryScrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;

              return Container(
                key: _categoryKeys[category],
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
                onTap: () => setState(() {
                  _selectedLocation = location;

                  // AI 자동 예측 활성화 & 수동 수정 전인 경우 권장 폐기일 재계산
                  if (_isAIAutoPrediction && !_isExpiryManuallyEdited) {
                    final aiDate = _foodDataService.calculateExpiryDate(
                      widget.selectedFood,
                      _selectedLocation,
                      _selectedCondition,
                      _isSealed,
                      _selectedDate,
                    );
                    if (aiDate != null) {
                      _recommendedDisposalDate = aiDate;
                    }
                  }
                }),
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
                onTap: () => setState(() {
                  _selectedCondition = condition;

                  // AI 자동 예측 활성화 & 수동 수정 전인 경우 권장 폐기일 재계산
                  if (_isAIAutoPrediction && !_isExpiryManuallyEdited) {
                    final aiDate = _foodDataService.calculateExpiryDate(
                      widget.selectedFood,
                      _selectedLocation,
                      _selectedCondition,
                      _isSealed,
                      _selectedDate,
                    );
                    if (aiDate != null) {
                      _recommendedDisposalDate = aiDate;
                    }
                  }
                }),
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
                onTap: () => setState(() {
                  _isSealed = sealedOption == '밀폐함';

                  // AI 자동 예측 활성화 & 수동 수정 전인 경우 권장 폐기일 재계산
                  if (_isAIAutoPrediction && !_isExpiryManuallyEdited) {
                    final aiDate = _foodDataService.calculateExpiryDate(
                      widget.selectedFood,
                      _selectedLocation,
                      _selectedCondition,
                      _isSealed,
                      _selectedDate,
                    );
                    if (aiDate != null) {
                      _recommendedDisposalDate = aiDate;
                    }
                  }
                }),
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

  Widget _buildStorageTipSection() {
    final rawTips = widget.selectedFood.aiStorageTips ?? '';

    // '•' 기준으로 분리해 목록 형태로 변환
    String formattedTips = rawTips;
    if (rawTips.contains('•')) {
      String withoutFirstBullet = rawTips.startsWith('•')
          ? rawTips.substring(1)
          : rawTips;
      final parts = withoutFirstBullet
          .split('•')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        formattedTips = parts.map((p) => '• $p').join('\n');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '보관 TIP',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF676C74),
                    letterSpacing: -0.3,
                    height: 22 / 14,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isStorageTipInfoVisible = !_isStorageTipInfoVisible;
                    });
                  },
                  child: const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Color(0xFFACB1BA),
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            // 기본 TIP 카드 (typewriter effect - 한 번만 재생)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECEF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _hasShownStorageTipAnimation
                  ? Text(
                      formattedTips,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        color: Color(0xff363A48),
                        fontWeight: FontWeight.w500,
                        height: 1.71,
                        letterSpacing: -0.40,
                      ),
                    )
                  : TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 3800),
                      onEnd: () {
                        // 한 번 효과를 보여준 뒤에는 다시 재생하지 않도록 플래그 설정
                        if (!_hasShownStorageTipAnimation && mounted) {
                          setState(() {
                            _hasShownStorageTipAnimation = true;
                          });
                        }
                      },
                      builder: (context, value, child) {
                        final int textLength = formattedTips.length;
                        final int currentCount = (textLength * value)
                            .clamp(0, textLength)
                            .toInt();
                        final String visibleText = formattedTips.substring(
                          0,
                          currentCount,
                        );

                        return Text(
                          visibleText,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            color: Color(0xff363A48),
                            fontWeight: FontWeight.w500,
                            height: 1.71,
                            letterSpacing: -0.40,
                          ),
                        );
                      },
                    ),
            ),

            // Info 말풍선 오버레이 (info 아이콘 아래)
            if (_isStorageTipInfoVisible)
              Positioned(
                left: 0,
                top: 8,
                child: Container(
                  width: 230,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Expanded(
                        child: Text(
                          'GPT로 생성된 TIP입니다.\nAI는 실수할 수 있습니다.',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF676C74),
                            letterSpacing: -0.3,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          setState(() {
                            _isStorageTipInfoVisible = false;
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Color(0xFFACB1BA),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
    return days[date.weekday % 7];
  }

  // 보관 시작일을 위한 DatePicker 표시
  void _showDatePickerForStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(
        const Duration(days: 365),
      ), // 1년 전부터 선택 가능
      lastDate: DateTime.now().add(const Duration(days: 365)), // 1년 후까지 선택 가능
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF353948), // 헤더 색상
              onPrimary: Colors.white, // 헤더 텍스트 색상
              onSurface: Color(0xFF363A48), // 날짜 텍스트 색상
              surface: Colors.white, // 배경 색상
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF353948),
                textStyle: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: const Color(0xFF353948),
              headerForegroundColor: Colors.white,
              headerHeadlineStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              dayStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              weekdayStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF676C74),
              ),
              yearStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF353948);
                }
                return null;
              }),
              todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF353948);
                }
                return const Color(0xFFEAECF0);
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return const Color(0xFF363A48);
              }),
              todayBorder: BorderSide.none,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;

        // AI 자동 예측이 켜져 있고 사용자가 권장 폐기일을 직접 수정하지 않았다면
        // 새 보관 시작일을 기준으로 권장 폐기일을 다시 계산
        if (_isAIAutoPrediction && !_isExpiryManuallyEdited) {
          final aiDate = _foodDataService.calculateExpiryDate(
            widget.selectedFood,
            _selectedLocation,
            _selectedCondition,
            _isSealed,
            _selectedDate,
          );
          if (aiDate != null) {
            _recommendedDisposalDate = aiDate;
          }
        }
      });
    }
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
              primary: Color(0xFF353948), // 헤더 색상
              onPrimary: Colors.white, // 헤더 텍스트 색상
              onSurface: Color(0xFF363A48), // 날짜 텍스트 색상
              surface: Colors.white, // 배경 색상
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF353948),
                textStyle: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: const Color(0xFF353948),
              headerForegroundColor: Colors.white,
              headerHeadlineStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              dayStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              weekdayStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF676C74),
              ),
              yearStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF353948);
                }
                return null;
              }),
              todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF353948);
                }
                return const Color(0xFFEAECF0);
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return const Color(0xFF363A48);
              }),
              todayBorder: BorderSide.none,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _recommendedDisposalDate) {
      setState(() {
        _recommendedDisposalDate = picked;
        // 사용자가 날짜를 직접 선택했으므로 AI 자동 예측 해제
        _isExpiryManuallyEdited = true;
        if (_isAIAutoPrediction) {
          _isAIAutoPrediction = false;
        }
        _isExpiryTipInfoVisible = false;
      });
    }
  }

  void _saveFood() async {
    try {
      // UserLog 객체 생성
      UserLog userLog = await _foodDataService.createUserLog(
        food: widget.selectedFood,
        category: _selectedCategory,
        location: _selectedLocation,
        condition: _selectedCondition,
        startDate: _selectedDate,
        isSealed: _isSealed,
        customEmojiPath: _selectedEmojiPath, // 사용자가 선택한 이모지 경로 전달
        // 사용자가 권장 폐기일을 직접 수정한 경우에만 수동 값 사용
        manualExpiryDate: _isExpiryManuallyEdited
            ? _recommendedDisposalDate
            : null,
      );

      // 디버그 정보 출력
      print('음식 저장 시작: ${widget.selectedFood.name}');
      print('선택된 음식 이미지 경로: $_selectedEmojiPath');
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

  // PRO 기능 안내 팝업
  void _showProFeatureDialog() async {
    // 기존 proEarlyBird 값 확인
    bool isAlreadyRegistered = await _foodDataService.getUserProEarlyBird();
    bool isEarlyBirdChecked = isAlreadyRegistered;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    const Text(
                      '[PRO] GPT로 모든 음식의\n권장 폐기일 계산',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF363A48),
                        letterSpacing: -0.4,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 세부 내용
                    const Text(
                      '현재 준비 중입니다.\n얼리버드 등록 시, 첫 한 달 무료로 제공됩니다!',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF676C74),
                        letterSpacing: -0.3,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // PRO 얼리버드 대기 체크박스
                    GestureDetector(
                      onTap: isAlreadyRegistered
                          ? null // 이미 등록된 경우 비활성화
                          : () {
                              setState(() {
                                isEarlyBirdChecked = !isEarlyBirdChecked;
                              });
                            },
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/images/checkbox.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              isAlreadyRegistered
                                  ? const Color(0xFFACB1BA) // 비활성화 회색
                                  : (isEarlyBirdChecked
                                        ? const Color(0xFFD04466) // 체크됨 - 빨간색
                                        : const Color(
                                            0xFFEAECF0,
                                          )), // 체크 안 됨 - 연한 회색
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PRO 얼리버드 대기',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isAlreadyRegistered
                                  ? const Color(0xFFACB1BA) // 비활성화 색상
                                  : const Color(0xFF363A48),
                              letterSpacing: -0.3,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 이미 등록된 경우 메시지 표시
                    if (isAlreadyRegistered) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '이미 얼리버드 대기자..♡',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFD04466),
                          letterSpacing: -0.3,
                          height: 1.5,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 확인 버튼
                    GestureDetector(
                      onTap: () async {
                        // 이미 등록되지 않았고 체크박스가 체크되어 있으면 Firebase에 저장
                        if (!isAlreadyRegistered && isEarlyBirdChecked) {
                          bool success = await _foodDataService
                              .updateUserProEarlyBird(true);
                          if (success) {
                            print('proEarlyBird 필드 저장 완료');
                          } else {
                            print('proEarlyBird 필드 저장 실패');
                          }
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF353948),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            '확인',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
