import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/*
  TODO: 
  1. ✅ 냉동고는 카테고리 유형과 분류 기준 다름 - 완료
  2. 카드 디자인 수정
  3. 냉동 전용 아이콘 추가 필요
*/

// 음식 데이터 모델
class FoodItem {
  final String id; // 고유 ID (UserLog.id)
  final String name;
  final String iconPath;
  final DateTime startDate;
  final DateTime expiryDate;
  final int recommendedStorageDays;
  final String storageType; // '냉장' 또는 '냉동'

  FoodItem({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.startDate,
    required this.expiryDate,
    required this.recommendedStorageDays,
    required this.storageType,
  });

  // 경과일수 계산
  int get elapsedDays => DateTime.now().difference(startDate).inDays;

  // 경과 비율 계산 (0.0 ~ 1.0+)
  double get elapsedRatio => elapsedDays / recommendedStorageDays;

  // D-day 계산 (당일 포함, 음수면 이미 지남)
  int get dDay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  // 카테고리 분류 (D-day 기반)
  String get category {
    if (storageType == '냉동') {
      // 냉동 식품의 경우 (더 긴 보관 기간을 고려한 카테고리)
      if (dDay < 0) {
        // 권장 보관 기한이 지난 경우
        return '버려야 해요';
      }
      if (dDay <= 30) {
        // 권장 기한까지 30일 이내
        return '먹어도 안전해요';
      }
      // 권장 기한까지 아직 여유가 많은 경우
      return '지금 가장 신선할 때';
    } else {
      // 냉장 식품의 경우
      if (dDay < 0) return '버려야 해요'; // 이미 지남
      if (dDay == 0) return '오늘 먹어야 해요'; // 오늘
      if (dDay <= 2) return '곧 상해요, 빨리 드세요'; // 1-2일 이내
      return '지금 가장 신선할 때'; // 3일 이상
    }
  }

  // 카드 색상 정보 (보관 방법에 따라 다른 색상 적용)
  // 👉🏻 TODO: 냉동고 카드 색상 수정 필요
  Map<String, Color> get cardColors {
    if (storageType == '냉동') {
      if (dDay < 0) {
        return {
          // 버려야 해요
          'background': const Color(0xFF494459),
          'text': const Color(0xFFFFCD44),
        };
      }
      if (dDay <= 30) {
        return {
          // 먹어도 안전해요
          'background': const Color(0xFFAAF1EA),
          'text': const Color(0xFF753873),
        };
      }
      return {
        // 지금 가장 신선할 때
        'background': const Color(0xFFE8E1E1),
        'text': const Color(0xFF338EEF),
      };
    } else {
      // 냉장 식품 색상
      if (dDay < 0) {
        return {
          'background': const Color(0xFF814083), // 버려야 해요
          'text': const Color(0xFFDBCFCE),
        };
      }
      if (dDay == 0) {
        return {
          'background': const Color(0xFFD04466), // 오늘 먹어야 해요
          'text': const Color(0xFFFEF868),
        };
      }
      if (dDay <= 2) {
        return {
          'background': const Color(0xFFFBE67B), // 곧 상해요, 빨리 드세요
          'text': const Color(0xFFE15611),
        };
      }
      return {
        'background': const Color(0xFFDDE3EE), // 지금 가장 신선할 때
        'text': const Color(0xFF495874),
      };
    }
  }
}

// 음식 카드 위젯
class FoodCard extends StatelessWidget {
  final FoodItem item;
  final bool isEditMode;
  final bool isSelected;
  final VoidCallback? onSelectionChanged;
  final VoidCallback? onTap;

  const FoodCard({
    super.key,
    required this.item,
    this.isEditMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = item.cardColors;

    return Row(
      children: [
        // 편집 모드에서 라디오 버튼 표시
        if (isEditMode) ...[
          GestureDetector(
            onTap: onSelectionChanged,
            child: SvgPicture.asset(
              isSelected
                  ? 'assets/images/radio_button_checked.svg'
                  : 'assets/images/radio_button_unchecked.svg',
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 8),
        ],
        // 음식 카드
        Expanded(
          child: GestureDetector(
            onTap: isEditMode ? null : onTap, // 편집 모드가 아닐 때만 탭 가능
            child: Container(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: colors['background'],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 음식 아이콘 (이미지가 있을 때만 표시)
                      if (item.iconPath.isNotEmpty) ...[
                        Image.asset(
                          item.iconPath,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox.shrink(); // 이미지 로드 실패 시 아무것도 표시하지 않음
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      const SizedBox(width: 2),
                      // 음식명
                      Text(
                        item.name,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          height: 32 / 24,
                          color: colors['text'],
                          letterSpacing: -1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.dDay >= 0 ? 'D-${item.dDay}' : 'D+${-item.dDay}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: colors['text'],
                          fontSize: 32,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                          height: 1.06,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // 보관 시작
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '보관 시작',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              height: 18 / 14,
                              fontWeight: FontWeight.w500,
                              color: colors['text']!.withOpacity(0.6),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatDate(item.startDate)}',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              height: 18 / 14,
                              fontWeight: FontWeight.w500,
                              color: colors['text'],
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // 권장 폐기일
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '권장 폐기일',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              height: 18 / 14,
                              fontWeight: FontWeight.w500,
                              color: colors['text']!.withOpacity(0.6),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatDate(item.expiryDate)}',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              height: 18 / 14,
                              fontWeight: FontWeight.w500,
                              color: colors['text'],
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 날짜 포맷 함수
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

// 카테고리별 음식 카드 리스트 위젯
class FoodCardList extends StatelessWidget {
  final List<FoodItem> foodItems;
  final String category;

  const FoodCardList({
    super.key,
    required this.foodItems,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final categoryItems = foodItems
        .where((item) => item.category == category)
        .toList();

    return Column(
      children: categoryItems
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FoodCard(item: item),
            ),
          )
          .toList(),
    );
  }
}

// 음식 데이터 유틸리티 클래스
class FoodDataUtils {
  // 보관 방법별 음식 필터링
  static List<FoodItem> filterByStorageType(
    List<FoodItem> items,
    String storageType,
  ) {
    return items.where((item) => item.storageType == storageType).toList();
  }

  // 카테고리별 음식 필터링
  static List<FoodItem> filterByCategory(
    List<FoodItem> items,
    String category,
  ) {
    return items.where((item) => item.category == category).toList();
  }

  // 보관 방법과 카테고리로 이중 필터링
  static List<FoodItem> filterByStorageAndCategory(
    List<FoodItem> items,
    String storageType,
    String category,
  ) {
    return items
        .where(
          (item) =>
              item.storageType == storageType && item.category == category,
        )
        .toList();
  }

  // 카테고리별 개수 계산 (보관 방법에 따라 다른 카테고리 적용)
  static Map<String, int> getCategoryCounts(
    List<FoodItem> items,
    String storageType,
  ) {
    final filteredItems = filterByStorageType(items, storageType);

    if (storageType == '냉동') {
      return {
        '버려야 해요': filterByCategory(filteredItems, '버려야 해요').length,
        '곧 먹어야 해요': filterByCategory(filteredItems, '곧 먹어야 해요').length,
        '보관 중': filterByCategory(filteredItems, '보관 중').length,
        '신선한 음식': filterByCategory(filteredItems, '신선한 음식').length,
      };
    } else {
      return {
        '버려야 해요': filterByCategory(filteredItems, '버려야 해요').length,
        '오늘 먹어야 해요': filterByCategory(filteredItems, '오늘 먹어야 해요').length,
        '곧 먹어야 해요': filterByCategory(filteredItems, '곧 먹어야 해요').length,
        '신선한 음식': filterByCategory(filteredItems, '신선한 음식').length,
      };
    }
  }

  // 보관 방법별 카테고리 목록 반환
  static List<Map<String, dynamic>> getCategoriesByStorageType(
    String storageType,
  ) {
    if (storageType == '냉동') {
      return [
        {'title': '버려야 해요', 'icon': 'assets/images/trash.svg'},
        {'title': '곧 먹어야 해요', 'icon': 'assets/images/upcoming.svg'},
        {
          'title': '보관 중',
          'icon': 'assets/images/fresh.svg', // 임시로 fresh 아이콘 사용
        },
        {'title': '신선한 음식', 'icon': 'assets/images/fresh.svg'},
      ];
    } else {
      return [
        {'title': '버려야 해요', 'icon': 'assets/images/trash.svg'},
        {'title': '오늘 먹어야 해요', 'icon': 'assets/images/warning.svg'},
        {'title': '곧 먹어야 해요', 'icon': 'assets/images/upcoming.svg'},
        {'title': '신선한 음식', 'icon': 'assets/images/fresh.svg'},
      ];
    }
  }
}
