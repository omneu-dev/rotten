import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/food_data_service.dart';
import '../models/food.dart';
import 'food_detail_screen.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FoodDataService _foodDataService = FoodDataService();

  List<Food> _allFoods = [];
  List<Food> _filteredFoods = [];
  Food? _selectedFood; // 선택된 음식을 추적

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
    '조리된 음식',
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

  // 카테고리별 음식 필터링
  List<Food> _getFoodsByCategory(String category) {
    return _filteredFoods.where((food) => food.category == category).toList();
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

    // 검색 결과가 없을 때 직접 추가 버튼 표시
    if (_filteredFoods.isEmpty && _searchController.text.isNotEmpty) {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // 카테고리별 음식 표시
          ..._categories.map((category) {
            final categoryFoods = _getFoodsByCategory(category);

            if (categoryFoods.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 카테고리 제목
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
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
                ),

                // 해당 카테고리의 음식들
                ...categoryFoods.map((food) => _buildFoodItem(food)).toList(),

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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        height: 64,
        decoration: ShapeDecoration(
          color: const Color(0xFFEAECF0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          children: [
            // 음식 이미지
            Container(
              width: 24,
              height: 24,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  food.emojiPath,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.fastfood,
                      color: Colors.grey[400],
                      size: 24,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 음식 정보
            Expanded(
              child: Text(
                food.name,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF363A48),
                  letterSpacing: -0.3,
                  height: 32 / 22,
                ),
              ),
            ),

            // 선택 화살표 (표시용)
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(4),
              child: Transform.rotate(
                angle: -1.5708, // -90도 (라디안)
                child: SvgPicture.asset(
                  'assets/images/arrow_dropdown.svg',
                  width: 24,
                  height: 24,
                  color: const Color(0xFF686C75),
                ),
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
      category: '기타', // 기본 카테고리
      emojiPath: '', // 빈 문자열로 설정하여 빈 동그라미 표시
      shelfLifeMap: {
        '냉장': 7, // 기본 보관 기간
        '냉동': 30,
      },
    );

    // 선택된 음식을 설정해서 화면 전환
    setState(() {
      _selectedFood = customFood;
    });
  }
}
