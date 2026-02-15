// 요리 기능은 현재 GNB에서 제외되어 화면 전체를 주석 처리해둔 상태입니다.
// 추후 요리 기능을 재도입할 때 이 파일의 구현을 복원하여 사용할 수 있습니다.

/*
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../widgets/sort_dialog.dart';
import '../services/sort_preference_service.dart';
import '../models/recipe.dart';
import '../models/user_log.dart';
import '../providers/food_log_provider.dart';
import 'recipe_detail_screen.dart';
import 'add_recipe_screen.dart';

class CookScreen extends StatefulWidget {
  const CookScreen({super.key});

  @override
  State<CookScreen> createState() => _CookScreenState();
}

class _CookScreenState extends State<CookScreen> {
  int _selectedCategoryIndex = 1; // "내가 저장한"이 기본 선택
  SortType _sortType = SortType.createdAt;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _memoController = TextEditingController();
  final FocusNode _memoFocusNode = FocusNode();
  bool _isCalendarExpanded = true; // 캘린더 확장/접기 상태

  // 날짜별로 드래그&드롭으로 등록된 레시피들
  final Map<DateTime, List<Recipe>> _dateRecipes = {};

  final List<String> _categories = ['추천', '내가 저장한', '전체'];

  @override
  void initState() {
    super.initState();
    _loadSortPreference();
    // 메모 입력값 변경 시 UI 업데이트
    _memoController.addListener(() {
      setState(() {});
    });
    // FoodLogProvider 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<FoodLogProvider>(context, listen: false);
      if (!provider.hasInitialized) {
        provider.initialize();
      }
    });
  }

  @override
  void dispose() {
    _memoController.dispose();
    _memoFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSortPreference();
  }

  Future<void> _loadSortPreference() async {
    final sortType = await SortPreferenceService.loadSortType();
    setState(() {
      _sortType = sortType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 커스텀 Topbar
            _buildCustomTopBar(),
            const SizedBox(height: 20),
            // 캘린더 섹션
            _buildCalendarSection(),
            const SizedBox(height: 20),
            // 카테고리 탭
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('recipes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final recipes = snapshot.data!.docs
                    .map((doc) => Recipe.fromFirestore(doc))
                    .toList();
                return _buildCategoryTab(recipes);
              },
            ),
            const SizedBox(height: 20),
            // 본문 내용
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification &&
                      notification.scrollDelta != null &&
                      notification.scrollDelta! > 0 &&
                      _isCalendarExpanded) {
                    setState(() {
                      _isCalendarExpanded = false;
                    });
                  }
                  return false;
                },
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('recipes').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyContent();
                    }

                    final recipes = snapshot.data!.docs
                        .map((doc) => Recipe.fromFirestore(doc))
                        .toList();

                    return _buildDataContent(recipes);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildAddRecipeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCustomTopBar() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: const BoxDecoration(color: Color(0xFFF7F7F7)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 왼쪽: 요리 텍스트
          Row(
            children: [
              Image.asset(
                'assets/images/rotten_logo.png',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '요리',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F222D),
                  letterSpacing: -0.3,
                  height: 22 / 16,
                ),
              ),
            ],
          ),
          const Spacer(),
          // 오른쪽: 정렬 및 필터 아이콘
          Row(
            children: [
              GestureDetector(
                onTap: _showSortDialog,
                child: SvgPicture.asset(
                  'assets/images/system-uicons_sort.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF686C75),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 필터 아이콘 (임시로 SVG 없으면 아이콘 사용)
              Icon(Icons.filter_alt, size: 24, color: const Color(0xFF686C75)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    final yearMonth =
        '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}';
    final weekStart = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday % 7),
    );
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // 년월 및 화살표
          Row(
            children: [
              Row(
                children: [
                  Text(
                    yearMonth,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF686C75),
                      height: 22 / 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            // 이전 주로 이동 (7일 전)
                            _selectedDate = _selectedDate.subtract(
                              const Duration(days: 7),
                            );
                          });
                        },
                        child: Transform.scale(
                          scaleX: -1,
                          child: SvgPicture.asset(
                            'assets/images/ic_ic_arrowsmall_right.svg',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF686C75),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            // 다음 주로 이동 (7일 후)
                            _selectedDate = _selectedDate.add(
                              const Duration(days: 7),
                            );
                          });
                        },
                        child: SvgPicture.asset(
                          'assets/images/ic_ic_arrowsmall_right.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF686C75),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isCalendarExpanded = !_isCalendarExpanded;
                  });
                },
                child: Transform.rotate(
                  angle: _isCalendarExpanded
                      ? 1.5708
                      : -1.5708, // 펼쳐진 상태: 90도 회전 (아래), 접힌 상태: -90도 (위)
                  child: SvgPicture.asset(
                    'assets/images/ic_ic_arrowsmall_right.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF686C75),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 요일 헤더
          Row(
            children: ['일', '월', '화', '수', '목', '금', '토'].map((day) {
              final index = ['일', '월', '화', '수', '목', '금', '토'].indexOf(day);
              final isSunday = index == 0;
              final isSaturday = index == 6;
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isSunday
                          ? const Color(0xFFD04466)
                          : isSaturday
                          ? const Color(0xFF814083)
                          : const Color(0xFF757575),
                      height: 20 / 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // 날짜 선택기 (각 날짜는 드롭 타겟 역할도 수행)
          Row(
            children: weekDays.map((date) {
              final normalized = _normalizeDate(date);
              final isSelected = _isSameDate(normalized, _selectedDate);
              final isToday = _isSameDate(
                normalized,
                _normalizeDate(DateTime.now()),
              );
              return Expanded(
                child: DragTarget<Recipe>(
                  onWillAccept: (_) => true,
                  onAccept: (recipe) {
                    setState(() {
                      final key = normalized;
                      final list = _dateRecipes[key] ?? [];
                      if (!list.any((r) => r.id == recipe.id)) {
                        _dateRecipes[key] = [...list, recipe];
                      }
                      _selectedDate = key;
                      _isCalendarExpanded = true;
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHighlighted = candidateData.isNotEmpty;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = normalized;
                          if (!_isCalendarExpanded) {
                            _isCalendarExpanded = true;
                          }
                        });
                      },
                      child: Container(
                        height: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? const Color(0xFFDDE3EE)
                              : isSelected
                              ? const Color(0xFF2C2C2C)
                              : isToday
                              ? const Color(0xFFDDE3EE)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: isSelected
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFF1E1E1E),
                              height: 22.4 / 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // 요일 아래 점 표시 (해당 날짜에 레시피가 있는 경우에만)
          Row(
            children: weekDays.map((date) {
              final normalized = _normalizeDate(date);
              final hasDot =
                  (_dateRecipes[normalized] ?? const <Recipe>[]).isNotEmpty;
              return Expanded(
                child: Center(
                  child: hasDot
                      ? Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDDE3EE),
                            shape: BoxShape.circle,
                          ),
                        )
                      : const SizedBox(height: 6),
                ),
              );
            }).toList(),
          ),
          // 접힌 상태가 아닐 때만 표시
          if (_isCalendarExpanded) ...[
            const SizedBox(height: 24),
            //구분선
            Container(
              width: double.infinity,
              decoration: const ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 0.4,
                    strokeAlign: BorderSide.strokeAlignCenter,
                    color: Color(0xFFEFF1F4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // 선택된 날짜의 레시피 목록
            _buildSelectedDateRecipes(),
            const SizedBox(height: 12),

            // 메모 입력 필드
            Focus(
              onFocusChange: (hasFocus) {
                setState(() {});
              },
              child: Builder(
                builder: (context) {
                  final hasFocus = _memoFocusNode.hasFocus;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 2,
                    ),
                    decoration: const ShapeDecoration(
                      color: Color(0xFFEAECF0),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(width: 1, color: Colors.white),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    child: TextField(
                      controller: _memoController,
                      focusNode: _memoFocusNode,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) {
                        _saveMemo();
                      },
                      decoration: const InputDecoration(
                        hintText: '메모',
                        hintStyle: TextStyle(
                          color: Color(0xFFACB1BA),
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                          height: 1.71,
                          letterSpacing: -0.40,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        color: hasFocus || _memoController.text.isNotEmpty
                            ? const Color(0xFF686C75)
                            : const Color(0xFFACB1BA),
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        height: 1.71,
                        letterSpacing: -0.40,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedDateRecipes() {
    // 선택된 날짜의 레시피 목록
    final recipes = _getRecipesForDate(_selectedDate);
    if (recipes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: recipes.map((recipe) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  recipe.menuName,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF686C75),
                    letterSpacing: -0.3,
                    height: 22 / 14,
                  ),
                ),
              ),
              SvgPicture.asset(
                'assets/images/ic_ic_arrowsmall_right.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF686C75),
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 사용자의 foodLog에서 특정 재료 이름을 가지고 있는지 확인
  bool _hasIngredient(String ingredientName, List<UserLog> userLogs) {
    final normalizedIngredient = ingredientName.trim().toLowerCase();

    for (final log in userLogs) {
      final normalizedLogName = log.foodName.trim().toLowerCase();

      // 정확한 매칭 또는 포함 관계 확인
      if (normalizedLogName == normalizedIngredient ||
          normalizedLogName.contains(normalizedIngredient) ||
          normalizedIngredient.contains(normalizedLogName)) {
        return true;
      }
    }
    return false;
  }

  /// 레시피의 재료 중 사용자가 가지고 있는 재료 개수 계산
  Future<int> _countMatchingIngredients(
    Recipe recipe,
    List<UserLog> userLogs,
  ) async {
    try {
      final ingredientsSnapshot = await _firestore
          .collection('recipes')
          .doc(recipe.id)
          .collection('recipe_ingredients')
          .where('type', isEqualTo: 'ingredient') // 소스 제외
          .get();

      int matchCount = 0;
      for (final doc in ingredientsSnapshot.docs) {
        final data = doc.data();
        final ingredientName = (data['rawItemName'] as String?) ?? '';
        if (ingredientName.isNotEmpty &&
            _hasIngredient(ingredientName, userLogs)) {
          matchCount++;
        }
      }
      return matchCount;
    } catch (e) {
      print('재료 개수 계산 오류: $e');
      return 0;
    }
  }

  Widget _buildDataContent(List<Recipe> recipes) {
    return Consumer<FoodLogProvider>(
      builder: (context, foodLogProvider, _) {
        // 냉장고와 냉동고의 모든 로그 가져오기
        final allUserLogs = [
          ...foodLogProvider.refrigeratorLogs,
          ...foodLogProvider.freezerLogs,
        ];

        // 카테고리별로 필터링
        List<Recipe> filteredRecipes;
        if (_selectedCategoryIndex == 0) {
          // 추천: 유저가 가지고 있는 재료가 하나 이상인 항목만
          filteredRecipes = [];
          // 비동기로 재료 개수 계산 후 필터링
          return FutureBuilder<List<Recipe>>(
            future: _filterRecommendedRecipes(recipes, allUserLogs),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              filteredRecipes = snapshot.data ?? [];
              return _buildRecipeList(filteredRecipes);
            },
          );
        } else if (_selectedCategoryIndex == 1) {
          // 내가 저장한: 사용자가 저장한 레시피 (임시로 전체 표시)
          filteredRecipes = List.from(recipes);
        } else if (_selectedCategoryIndex == 2) {
          // 전체: 모든 레시피
          filteredRecipes = List.from(recipes);
        } else {
          filteredRecipes = List.from(recipes);
        }

        // 정렬 적용
        filteredRecipes = _sortRecipes(filteredRecipes);
        return _buildRecipeList(filteredRecipes);
      },
    );
  }

  /// 추천 레시피 필터링 및 정렬
  Future<List<Recipe>> _filterRecommendedRecipes(
    List<Recipe> recipes,
    List<UserLog> userLogs,
  ) async {
    final List<MapEntry<Recipe, int>> recipeWithCounts = [];

    for (final recipe in recipes) {
      final matchCount = await _countMatchingIngredients(recipe, userLogs);
      if (matchCount > 0) {
        recipeWithCounts.add(MapEntry(recipe, matchCount));
      }
    }

    // 재료 개수가 많은 순서대로 정렬
    recipeWithCounts.sort((a, b) => b.value.compareTo(a.value));

    return recipeWithCounts.map((entry) => entry.key).toList();
  }

  Widget _buildRecipeList(List<Recipe> filteredRecipes) {
    if (filteredRecipes.isEmpty) {
      return _buildEmptyContent();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "가장 많이 사용되는 재료" 섹션 + 유저 레시피 카드들 (내가 저장한 탭 전용)
          if (_selectedCategoryIndex == 1) ...[
            _buildMostUsedIngredientsSection(),
            const SizedBox(height: 80),
          ] else ...[
            // 추천 탭, 전체 탭: DB 레시피 카드들만 표시
            ...filteredRecipes.map(
              (recipe) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildDBRecipeCard(recipe),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ],
      ),
    );
  }

  /// 특정 날짜의 레시피 목록을 반환 (드래그&드롭으로 등록된 실제 데이터)
  List<Recipe> _getRecipesForDate(DateTime date) {
    final key = _normalizeDate(date);
    return List<Recipe>.unmodifiable(_dateRecipes[key] ?? const <Recipe>[]);
  }

  Widget _buildMostUsedIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '가장 많이 사용되는 재료',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF686C75),
                letterSpacing: -0.3,
                height: 22 / 14,
              ),
            ),
            const Spacer(),
            SvgPicture.asset(
              'assets/images/ic_ic_arrowsmall_right.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                Color(0xFF686C75),
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 레시피 카드들 (예시 데이터, 유저 레시피 카드 디자인 재사용)
        // 사용자가 직접 등록한 레시피도 드래그 가능하도록 임시 Recipe 객체 생성
        _buildRecipeCard(
          recipeName: '토마토 스파게티',
          availableIngredients: 4,
          serves: 2,
          channelName: '김진순 점심시간',
          snsLogoAssetPath:
              'assets/images/youtube_logo.png', // TODO: 실제 SNS 로고 에셋 경로로 교체
          ingredientIcons: ['🍅'],
          draggableData: Recipe(
            id: 'user_recipe_1',
            menuName: '토마토 스파게티',
            servingNum: 2.0,
            youtubeUrl: null,
            recipeText: null,
            updatedAt: DateTime.now(),
          ),
        ),
        const SizedBox(height: 12),
        _buildRecipeCard(
          recipeName: '김치볶음밥',
          availableIngredients: 2,
          serves: 1,
          channelName: '내 레시피',
          snsLogoAssetPath:
              'assets/images/youtube_logo.png', // TODO: 실제 SNS 로고 에셋 경로로 교체
          ingredientIcons: [],
          draggableData: Recipe(
            id: 'user_recipe_2',
            menuName: '김치볶음밥',
            servingNum: 1.0,
            youtubeUrl: null,
            recipeText: null,
            updatedAt: DateTime.now(),
          ),
        ),
      ],
    );
  }

  /// 통합 레시피 카드 빌더
  /// [draggableData]가 제공되면 드래그 가능한 카드로 생성
  Widget _buildRecipeCard({
    required String recipeName,
    required int availableIngredients,
    required int serves,
    required String channelName,
    required String snsLogoAssetPath,
    required List<String> ingredientIcons,
    Recipe? draggableData,
    void Function()? onTap,
  }) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAECF0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 영역: 텍스트 컬럼 3개 + 우측 썸네일 이미지
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 좌측: 요리명, 출처(SNS+채널), 캡션 2개
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipeName,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF495874),
                        letterSpacing: -1,
                        height: 32 / 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // SNS 로고 + 채널명
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // SNS 로고
                        Image.asset(
                          snsLogoAssetPath,
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 4),
                        // 채널명
                        Flexible(
                          child: Text(
                            channelName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF686C75),
                              letterSpacing: -0.2,
                              height: 18 / 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 캡션 두 개: 내 재료 / 인분 + 왼쪽에 재료 아이콘들
                    Row(
                      children: [
                        // 왼쪽: 재료 아이콘들
                        if (ingredientIcons.isNotEmpty ||
                            availableIngredients > ingredientIcons.length)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (ingredientIcons.isNotEmpty)
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD04466),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      ingredientIcons[0],
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                              if (availableIngredients >
                                  ingredientIcons.length) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDDE3EE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '+ ${availableIngredients - ingredientIcons.length}',
                                      style: const TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF495874),
                                        letterSpacing: -0.2,
                                        height: 18 / 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        if (ingredientIcons.isNotEmpty ||
                            availableIngredients > ingredientIcons.length)
                          const SizedBox(width: 12),
                        // 오른쪽: 캡션 두 개 (내 재료 / 인분)
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDDE3EE),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$serves인분',
                                  style: const TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF495874),
                                    letterSpacing: -0.2,
                                    height: 18 / 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 우측: 썸네일 이미지 영역 (정사각형)
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFFDDE3EE),
                ),
                clipBehavior: Clip.antiAlias,
                // TODO: 실제 SNS 썸네일 이미지로 교체 (예: Image.network(thumbnailUrl))
                child: const Center(
                  child: Icon(Icons.image, size: 32, color: Color(0xFFB0B8C4)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // 드래그 가능한 데이터가 제공되면 LongPressDraggable로 감싸기
    final card = onTap != null
        ? GestureDetector(onTap: onTap, child: content)
        : content;

    if (draggableData != null) {
      return LongPressDraggable<Recipe>(
        data: draggableData,
        feedback: Opacity(
          opacity: 0.7,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 343, // 카드 기본 폭과 맞춤 (캘린더 카드와 동일)
              child: card,
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: card),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        child: card,
      );
    }

    return card;
  }

  Widget _buildDBRecipeCard(Recipe recipe) {
    // recipes.tsv 기반 레시피 카드 (드래그 가능)
    final serves = recipe.servingNum.toInt();
    final channelName = _extractChannelNameFromUrl(recipe.youtubeUrl);
    final snsLogoAssetPath = _getSnsLogoFromUrl(recipe.youtubeUrl);

    return _buildRecipeCard(
      recipeName: recipe.menuName,
      availableIngredients: 0, // TODO: 실제 활용 가능한 재료 개수로 교체
      serves: serves,
      channelName: channelName,
      snsLogoAssetPath: snsLogoAssetPath,
      ingredientIcons: const [], // TODO: 실제 재료 아이콘 리스트로 교체
      draggableData: recipe, // 드래그 가능하도록 Recipe 객체 전달
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Color(0xFFF7F7F7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: RecipeDetailScreen(
              recipe: recipe,
              onBack: () => Navigator.pop(context),
              onSave: () => Navigator.pop(context),
            ),
          ),
        );
      },
    );
  }

  /// youtube_url 등에서 채널/출처명을 유추 (간단한 기본값)
  String _extractChannelNameFromUrl(String? url) {
    if (url == null || url.isEmpty) {
      return '레시피';
    }
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return 'YouTube 레시피';
    }
    return '레시피';
  }

  /// URL 기반으로 SNS 로고 에셋 선택
  String _getSnsLogoFromUrl(String? url) {
    if (url == null || url.isEmpty) {
      return 'assets/images/youtube_logo.png'; // 기본값
    }
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return 'assets/images/youtube_logo.png';
    }
    // TODO: 다른 SNS 도입 시 분기 추가 (예: Instagram, TikTok 등)
    return 'assets/images/youtube_logo.png';
  }

  // 날짜 비교용 헬퍼 (연/월/일만 비교)
  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // 날짜 정규화 (시/분/초 제거)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Widget _buildCategoryTab(List<Recipe> recipes) {
    return Consumer<FoodLogProvider>(
      builder: (context, foodLogProvider, _) {
        // 각 카테고리별 아이템 개수 계산
        Map<String, int> categoryCounts = {};
        for (int i = 0; i < _categories.length; i++) {
          final category = _categories[i];
          if (i == 0) {
            // 추천: 유저가 가지고 있는 재료가 하나 이상인 항목 개수 (비동기 계산 필요)
            categoryCounts[category] = recipes.length; // 임시로 전체 개수 표시
          } else if (i == 1) {
            // 내가 저장한: 항상 활성화
            categoryCounts[category] = recipes.isEmpty ? 1 : recipes.length;
          } else if (i == 2) {
            // 전체: 모든 레시피
            categoryCounts[category] = recipes.isEmpty ? 1 : recipes.length;
          } else {
            categoryCounts[category] = 0;
          }
        }

        return SizedBox(
          height: 34,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = index == _selectedCategoryIndex;
              final hasItems = (categoryCounts[category] ?? 0) > 0;

              return Container(
                margin: EdgeInsets.only(
                  right: index < _categories.length - 1 ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: hasItems
                      ? () {
                          setState(() {
                            _selectedCategoryIndex = index;
                          });
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: !hasItems
                          ? const Color(0xFFF5F5F5)
                          : isSelected
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
                        color: !hasItems
                            ? const Color(0xFFBDBDBD)
                            : isSelected
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
        );
      },
    );
  }

  Widget _buildAddRecipeButton() {
    // 플로팅 버튼 및 기능은 현재 HomeScreen으로 이동되었습니다.
    return const SizedBox.shrink();
  }

  Widget _buildEmptyContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/empty.svg',
            width: 28,
            height: 28,
            colorFilter: const ColorFilter.mode(
              Color(0xFF686C75),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '텅 비었어요',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF686C75),
              height: 22 / 14,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showSortDialog(context, _sortType, (newSortType) {
      setState(() {
        _sortType = newSortType;
      });
    });
  }

  List<Recipe> _sortRecipes(List<Recipe> recipes) {
    final sorted = List<Recipe>.from(recipes);

    if (_sortType == SortType.createdAt) {
      sorted.sort((a, b) {
        final aDate = a.updatedAt ?? DateTime(1970);
        final bDate = b.updatedAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
    } else if (_sortType == SortType.remainingDays) {
      // 레시피에는 남은 기간 개념이 없으므로 이름순 정렬
      sorted.sort((a, b) => a.menuName.compareTo(b.menuName));
    }

    return sorted;
  }

  Future<void> _saveMemo() async {
    final memo = _memoController.text.trim();
    if (memo.isEmpty) return;

    try {
      // 날짜를 문자열 키로 변환 (YYYY-MM-DD 형식)
      final dateKey =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      // Firestore에 메모 저장 (users/{uid}/cookMemos/{dateKey})
      // TODO: 사용자 ID 가져오기 및 실제 저장 로직 구현
      // final uid = FirebaseAuth.instance.currentUser?.uid;
      // if (uid == null) return;
      // await _firestore
      //     .collection('users')
      //     .doc(uid)
      //     .collection('cookMemos')
      //     .doc(dateKey)
      //     .set({'memo': memo, 'date': Timestamp.fromDate(_selectedDate)});

      // 임시: 로컬에 저장 (SharedPreferences 또는 메모리)
      // 실제 구현 시 위의 Firestore 코드를 활성화하세요
      print('메모 저장: $dateKey - $memo');

      // 포커스 해제
      _memoFocusNode.unfocus();

      // 성공 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메모가 저장되었습니다'),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xFF525866),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('메모 저장 실패: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFFD04466),
          ),
        );
      }
    }
  }
}
*/
