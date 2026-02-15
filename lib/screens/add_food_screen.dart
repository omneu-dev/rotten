import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/food_data_service.dart';
import '../models/food.dart';
import 'food_detail_screen.dart';

class AddFoodScreen extends StatefulWidget {
  final String defaultLocation; // '냉장' 또는 '냉동'

  const AddFoodScreen({super.key, this.defaultLocation = '냉장'});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FoodDataService _foodDataService = FoodDataService();

  List<Food> _allFoods = [];
  List<Food> _filteredFoods = [];
  Food? _selectedFood; // 선택된 음식을 추적
  Set<String> _expandedCategories = {}; // 펼쳐진 카테고리 추적

  // 냉장고 페이지와 동일한 카테고리 정의
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

  @override
  void initState() {
    super.initState();
    _loadFoodData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 로컬 JSON에서 음식 데이터 로드 (Firestore 백업)
  Future<void> _loadFoodData() async {
    try {
      // 먼저 Firestore에서 시도
      List<Food> foods = await _foodDataService.getAllFoodsFromFirestore();

      // Firestore에서 데이터를 가져오지 못하면 로컬 JSON에서 로드
      if (foods.isEmpty) {
        print('Firestore에서 데이터를 가져오지 못했습니다. 로컬 JSON에서 로드합니다.');
        foods = await _foodDataService.loadFoodDataFromAssets();
      }

      setState(() {
        _allFoods = foods;
        _filteredFoods = foods;
      });

      print('로드된 음식 데이터: ${foods.length}개');
    } catch (e) {
      print('음식 데이터 로드 실패: $e');
    }
  }

  // 검색 필터링
  void _filterFoods(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFoods = _allFoods;
      } else {
        _filteredFoods = _allFoods
            .where(
              (food) =>
                  food.name.toLowerCase().contains(query.toLowerCase()) ||
                  food.category.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  // 카테고리별 음식 필터링 및 가나다순 정렬
  List<Food> _getFoodsByCategory(String category) {
    final foods = _filteredFoods
        .where((food) => food.category == category)
        .toList();
    // 가나다순 정렬
    foods.sort((a, b) => a.name.compareTo(b.name));
    return foods;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: _selectedFood != null
          ? FoodDetailScreen(
              selectedFood: _selectedFood!,
              onBack: () => setState(() => _selectedFood = null),
              isCustomFood:
                  _selectedFood!.emojiPath.isEmpty, // 이모지가 비어있으면 직접 추가
              initialLocation: widget.defaultLocation,
            )
          : Column(
              children: [
                // 헤더
                _buildHeader(),

                // 검색 바
                _buildSearchBar(),

                // 카테고리별 음식 리스트
                Expanded(child: _buildFoodList()),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 28, bottom: 6),
      child: Row(
        children: [
          // 취소 버튼
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
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
            '음식 추가',
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
  }

  Widget _buildSearchBar() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(left: 16, right: 16, top: 30, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/search.svg',
            width: 24,
            height: 24,
            color: Color(0xFFACB1BA),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _filterFoods,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                color: Color(0xFF000000),
                fontWeight: FontWeight.w500,
                letterSpacing: -0.4,
                height: 24 / 16,
              ),
              decoration: const InputDecoration(
                hintText: '검색',
                hintStyle: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  color: Color(0xFFACB1BA),
                  letterSpacing: -0.3,
                  height: 24 / 16,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList() {
    if (_allFoods.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    print('전체 음식 개수: ${_allFoods.length}');
    print('필터링된 음식 개수: ${_filteredFoods.length}');

    // 디버깅: 각 카테고리별 음식 개수 출력
    for (String category in _categories) {
      final categoryFoods = _getFoodsByCategory(category);
      print('카테고리 "$category": ${categoryFoods.length}개');
      if (categoryFoods.isNotEmpty) {
        print(
          '  - 예시 음식들: ${categoryFoods.take(3).map((f) => f.name).join(', ')}',
        );
      }
    }

    // 검색 중일 때는 카테고리 구분 없이 모든 결과를 2열 그리드로 표시
    final isSearching = _searchController.text.isNotEmpty;

    // 검색 결과가 없을 때 직접 추가 버튼 표시
    if (_filteredFoods.isEmpty && isSearching) {
      return Column(
        children: [
          const SizedBox(height: 24),
          // 직접 추가 버튼
          GestureDetector(
            onTap: _addCustomFood,
            child: Container(
              width: double.infinity,
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: ShapeDecoration(
                color: const Color(0xFF353948),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Center(
                child: Text(
                  '직접 추가',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    height: 1.50,
                    letterSpacing: -0.40,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 검색 중일 때는 카테고리 구분 없이 모든 결과 표시
    if (isSearching) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.5, // 가로로 긴 카드 형태
              ),
              itemCount: _filteredFoods.length,
              itemBuilder: (context, index) {
                return _buildFoodItem(_filteredFoods[index]);
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    // 일반 모드: 카테고리별 드롭다운
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // 카테고리별 음식 표시 (드롭다운)
          ..._categories.map((category) {
            final categoryFoods = _getFoodsByCategory(category);

            if (categoryFoods.isEmpty) {
              return const SizedBox.shrink();
            }

            final isExpanded = _expandedCategories.contains(category);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 카테고리 헤더 (클릭 가능, 흰색 박스 없음)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedCategories.remove(category);
                      } else {
                        _expandedCategories.add(category);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF676C74),
                            height: 22 / 14,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${categoryFoods.length}',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFACB1BA),
                            height: 22 / 14,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Transform.rotate(
                          angle: isExpanded ? 3.14159 : 0, // 180도 회전
                          child: SvgPicture.asset(
                            'assets/images/arrow_dropdown.svg',
                            width: 24,
                            height: 24,
                            color: const Color(0xFF686C75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 해당 카테고리의 음식들 (2열 그리드)
                if (isExpanded)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 2.5, // 가로로 긴 카드 형태
                        ),
                    itemCount: categoryFoods.length,
                    itemBuilder: (context, index) {
                      return _buildFoodItem(categoryFoods[index]);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),

          // 하단 여백
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFoodItem(Food food) {
    return GestureDetector(
      onTap: () => _selectFood(food),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: ShapeDecoration(
          color: const Color(0xFFE8ECEF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            // 음식 이미지 (왼쪽)
            Container(
              width: 24,
              height: 24,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  food.emojiPath,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.fastfood,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 음식 이름 (오른쪽)
            Expanded(
              child: Text(
                food.name,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF363A48),
                  letterSpacing: -1,
                  height: 32 / 22,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 음식 선택 시 처리
  void _selectFood(Food food) {
    // 선택된 음식을 설정해서 화면 전환
    setState(() {
      _selectedFood = food;
    });
  }

  // 직접 추가 버튼 클릭 시 처리
  void _addCustomFood() {
    // 검색어를 음식 이름으로 사용하여 새로운 Food 객체 생성
    final customFood = Food(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // 고유 ID 생성
      name: _searchController.text,
      category: '조리된 음식', // 기본 카테고리
      emojiPath: '', // 빈 문자열로 설정하여 빈 동그라미 표시
      shelfLifeMap: {
        '냉장|통째|false': 3,
        '냉장|통째|true': 3,
        '냉장|손질|false': 3,
        '냉장|손질|true': 3,
        '냉장|조리됨|false': 3,
        '냉장|조리됨|true': 3,
        '냉동|통째|false': 60,
        '냉동|통째|true': 60,
        '냉동|손질|false': 60,
        '냉동|손질|true': 60,
        '냉동|조리됨|false': 60,
        '냉동|조리됨|true': 60,
      },
    );

    // 선택된 음식을 설정해서 화면 전환
    setState(() {
      _selectedFood = customFood;
    });
  }
}
