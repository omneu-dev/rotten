import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../widgets/food_card.dart';
import '../widgets/common_top_bar.dart';
import '../models/user_log.dart';
import '../providers/food_log_provider.dart';
import 'food_detail_view_screen.dart';

/*
  TODO: 
  1. + 누르면 테스트 데이터 추가 -> 페이지 이동으로 교체
*/

class RefrigeratorScreen extends StatefulWidget {
  const RefrigeratorScreen({super.key});

  @override
  State<RefrigeratorScreen> createState() => _RefrigeratorScreenState();
}

class _RefrigeratorScreenState extends State<RefrigeratorScreen> {
  int _selectedCategoryIndex = 0;
  bool _isTrashSectionExpanded = true; // 드롭다운 상태 관리
  bool _isEditMode = false; // 편집 모드 상태
  Set<String> _selectedCards = {}; // 선택된 카드들의 ID

  final List<String> _categories = [
    '전체',
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
    // Provider 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FoodLogProvider>(context, listen: false).initialize();
    });
  }

  // Provider에서 냉장고 데이터 가져오기는 build 메서드에서 직접 사용

  // UserLog를 FoodItem으로 변환
  FoodItem _userLogToFoodItem(UserLog userLog) {
    // 권장 보관 기간 계산
    int recommendedStorageDays = 7; // 기본값
    if (userLog.expiryDate != null) {
      recommendedStorageDays = userLog.expiryDate!
          .difference(userLog.startDate)
          .inDays;
    }

    // 이미지 경로 보정 (assets/ 경로가 없으면 추가)
    String correctedIconPath = userLog.emojiPath;
    if (correctedIconPath.isNotEmpty &&
        !correctedIconPath.startsWith('assets/')) {
      correctedIconPath = 'assets/images/food_images/$correctedIconPath';
    }

    return FoodItem(
      name: userLog.foodName,
      iconPath: correctedIconPath,
      startDate: userLog.startDate,
      expiryDate:
          userLog.expiryDate ??
          userLog.startDate.add(Duration(days: recommendedStorageDays)),
      recommendedStorageDays: recommendedStorageDays,
      storageType: userLog.storageType, // '냉장' 또는 '냉동'
    );
  }

  // 카테고리별 필터링된 UserLog 리스트
  // _filteredUserLogs getter 제거 - build 메서드에서 직접 처리

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FoodLogProvider>();
    final userLogs = provider.refrigeratorLogs;
    final isLoading = provider.isLoading;
    final hasData = userLogs.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Column(
        children: [
          // 상단바 (시스템바 바로 밑에 배치)
          CommonTopBar(
            isEditMode: _isEditMode,
            selectedCards: _selectedCards,
            onEditToggle: _toggleEditMode,
            onDeleteSelected: _deleteSelectedCards,
          ),
          const SizedBox(height: 20),
          // 카테고리 탭 (가로 스크롤)
          _buildCategoryTab(userLogs),
          const SizedBox(height: 32),
          // 본문 내용
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : hasData
                ? _buildDataContent(userLogs)
                : _buildEmptyContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDataContent(List<UserLog> userLogs) {
    // 카테고리별로 필터링
    List<UserLog> filteredUserLogs;
    if (_selectedCategoryIndex == 0) {
      filteredUserLogs = userLogs; // 전체
    } else {
      final selectedCategory = _categories[_selectedCategoryIndex];
      filteredUserLogs = userLogs
          .where((log) => log.category == selectedCategory)
          .toList();
    }

    // 필터링된 결과가 없으면 빈 화면 표시
    if (filteredUserLogs.isEmpty) {
      return _buildEmptyContent();
    }

    // UserLog를 FoodItem으로 변환
    List<FoodItem> foodItems = filteredUserLogs
        .map((userLog) => _userLogToFoodItem(userLog))
        .toList();

    // 필터링된 결과가 없으면 빈 화면 표시
    if (foodItems.isEmpty) {
      return _buildEmptyContent();
    }

    // 보관기한에 따른 카테고리별 분류
    Map<String, List<FoodItem>> categorizedItems = _categorizeByExpiry(
      foodItems,
    );

    // 표시할 카테고리 순서 (냉장고용)
    List<String> categoryOrder = [
      '버려야 해요',
      '오늘 먹어야 해요',
      '곧 상해요, 빨리 드세요',
      '지금 가장 신선할 때',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 카테고리별로 음식 표시
          ...categoryOrder.map((categoryName) {
            List<FoodItem> categoryItems = categorizedItems[categoryName] ?? [];
            if (categoryItems.isEmpty) return const SizedBox.shrink();

            // 버려야 해요 섹션이 접혀있으면 아이템 숨기기
            if (categoryName == '버려야 해요' && !_isTrashSectionExpanded) {
              return Column(
                children: [
                  _buildCategoryHeader(categoryName, categoryItems.length),
                  const SizedBox(height: 20),
                ],
              );
            }

            return Column(
              children: [
                _buildCategoryHeader(categoryName, categoryItems.length),
                const SizedBox(height: 8),
                ...categoryItems.map(
                  (item) => Column(
                    children: [
                      FoodCard(
                        item: item,
                        isEditMode: _isEditMode,
                        isSelected: _selectedCards.contains(
                          item.name,
                        ), // 임시로 name 사용
                        onSelectionChanged: () =>
                            _toggleCardSelection(item.name),
                        onTap: () => _showFoodDetail(item),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          }),
          const SizedBox(height: 80), // 하단 여백
        ],
      ),
    );
  }

  // 보관기한에 따른 카테고리 분류
  Map<String, List<FoodItem>> _categorizeByExpiry(List<FoodItem> items) {
    Map<String, List<FoodItem>> categories = {
      '버려야 해요': [],
      '오늘 먹어야 해요': [],
      '곧 상해요, 빨리 드세요': [],
      '지금 가장 신선할 때': [],
    };

    for (FoodItem item in items) {
      String category = item.category; // FoodItem의 category getter 사용
      categories[category]?.add(item);
    }

    return categories;
  }

  // 간단한 카테고리 헤더
  Widget _buildCategoryHeader(String title, int count) {
    return GestureDetector(
      onTap: () {
        if (title == '버려야 해요') {
          setState(() {
            _isTrashSectionExpanded = !_isTrashSectionExpanded;
          });
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _getCategoryIcon(title),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 22 / 14,
              letterSpacing: -0.3,
              color: Color(0xFF686C75),
            ),
          ),
          Spacer(),
          Text(
            '$count',
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 22 / 14,
              letterSpacing: -0.3,
              color: Color(0xFF686C75),
            ),
          ),
          const SizedBox(width: 8),
          if (title == '버려야 해요')
            Transform.rotate(
              angle: _isTrashSectionExpanded ? 0 : 3.14159,
              child: SvgPicture.asset(
                'assets/images/arrow_dropdown.svg',
                width: 24,
              ),
            ),
        ],
      ),
    );
  }

  // 카테고리별 아이콘
  Widget _getCategoryIcon(String category) {
    String iconPath;
    switch (category) {
      case '버려야 해요':
        iconPath = 'assets/images/trash.svg';
        break;
      case '오늘 먹어야 해요':
        iconPath = 'assets/images/warning.svg';
        break;
      case '곧 상해요, 빨리 드세요':
        iconPath = 'assets/images/upcoming.svg';
        break;
      case '지금 가장 신선할 때':
        iconPath = 'assets/images/fresh.svg';
        break;
      default:
        iconPath = 'assets/images/fresh.svg';
    }

    return Transform.translate(
      offset: const Offset(0, -2),
      child: SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
        color: const Color(0xFF686C75),
      ),
    );
  }

  Widget _buildCategoryTab(List<UserLog> userLogs) {
    // 각 카테고리별 아이템 개수 계산
    Map<String, int> categoryCounts = {};
    if (userLogs.isNotEmpty) {
      for (int i = 0; i < _categories.length; i++) {
        final category = _categories[i];
        if (i == 0) {
          // '전체' 카테고리
          categoryCounts[category] = userLogs.length;
        } else {
          categoryCounts[category] = userLogs
              .where((userLog) => userLog.category == category)
              .length;
        }
      }
    }

    // 카테고리를 활성화/비활성화 상태에 따라 정렬
    List<String> sortedCategories = [..._categories];
    sortedCategories.sort((a, b) {
      final aHasItems = (categoryCounts[a] ?? 0) > 0;
      final bHasItems = (categoryCounts[b] ?? 0) > 0;

      // 활성화된 카테고리를 앞으로, 비활성화된 카테고리를 뒤로
      if (aHasItems && !bHasItems) return -1;
      if (!aHasItems && bHasItems) return 1;

      // 같은 상태면 기존 순서 유지
      return _categories.indexOf(a).compareTo(_categories.indexOf(b));
    });

    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sortedCategories.length,
        itemBuilder: (context, index) {
          final category = sortedCategories[index];
          final originalIndex = _categories.indexOf(category);
          final isSelected = originalIndex == _selectedCategoryIndex;
          final hasItems = (categoryCounts[category] ?? 0) > 0;

          return Container(
            margin: EdgeInsets.only(
              right: index < _categories.length - 1 ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: hasItems
                  ? () {
                      setState(() {
                        _selectedCategoryIndex = originalIndex;
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
            color: const Color(0xFF686C75),
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

  // 주석 처리된 기존 테스트 데이터 추가 로직
  /*
  Future<void> _addSmokeItem() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('foodLog')
          .add({
            'food_name': '딸기',
            'storedAt': FieldValue.serverTimestamp(),
            'storage_type': '냉장',
            'prep_state': '손질',
            'sealed': true,
            'source': 'smokeTest', // 나중에 구분하기 좋게
          });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Firestore 문서 1건 생성 완료 ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('쓰기 실패: $e')));
    }
  }
  */

  // 편집 모드 토글
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _selectedCards.clear(); // 편집 모드 종료시 선택 초기화
      }
    });
  }

  // 카드 선택 토글
  void _toggleCardSelection(String cardId) {
    setState(() {
      if (_selectedCards.contains(cardId)) {
        _selectedCards.remove(cardId);
      } else {
        _selectedCards.add(cardId);
      }
    });
  }

  // 선택된 카드들 삭제
  void _deleteSelectedCards() async {
    if (_selectedCards.isEmpty) return;

    // 확인 다이얼로그 표시
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '음식 삭제',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '선택한 ${_selectedCards.length}개의 음식을 삭제하시겠습니까?',
          style: const TextStyle(fontFamily: 'Pretendard'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(
                fontFamily: 'Pretendard',
                color: Color(0xFF686C75),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '삭제',
              style: TextStyle(
                fontFamily: 'Pretendard',
                color: Color(0xFF814083),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 삭제할 개수 미리 저장
      int deleteCount = _selectedCards.length;

      // 선택된 음식들을 삭제
      final currentUserLogs = Provider.of<FoodLogProvider>(
        context,
        listen: false,
      ).refrigeratorLogs;
      for (String cardName in _selectedCards) {
        // UserLog에서 해당 음식 찾기
        UserLog logToDelete = currentUserLogs.firstWhere(
          (log) => log.foodName == cardName,
        );

        // Provider를 통해 삭제
        await Provider.of<FoodLogProvider>(
          context,
          listen: false,
        ).deleteFoodLog(logToDelete.id, logToDelete.storageType);
      }

      // 편집 모드 종료
      setState(() {
        _selectedCards.clear();
        _isEditMode = false;
      });

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${deleteCount}개의 음식이 삭제되었습니다'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF525866),
        ),
      );
    }
  }

  // 음식 상세 화면 표시
  void _showFoodDetail(FoodItem foodItem) {
    // FoodItem에서 해당하는 UserLog 찾기
    final userLogs = Provider.of<FoodLogProvider>(
      context,
      listen: false,
    ).refrigeratorLogs;
    final userLog = userLogs.firstWhere(
      (log) => log.foodName == foodItem.name,
      orElse: () => UserLog(
        id: '',
        foodId: '',
        foodName: foodItem.name,
        category: '기타',
        storageType: foodItem.storageType,
        condition: '통째',
        startDate: foodItem.startDate,
        expiryDate: foodItem.expiryDate,
        isSealed: false,
        emojiPath: foodItem.iconPath,
        updatedAt: DateTime.now(),
      ),
    );

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
        child: FoodDetailViewScreen(
          userLog: userLog,
          onBack: () => Navigator.pop(context),
          onSave: () {
            // 저장 로직 구현
            Navigator.pop(context);
          },
          onDelete: () {
            // 삭제 로직 구현
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
