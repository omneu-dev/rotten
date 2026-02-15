import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../models/user_log.dart';
import '../providers/food_log_provider.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onBack;
  final VoidCallback? onSave;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.onBack,
    this.onSave,
  });

  static List<_IngredientRow> get _exampleIngredients => const [
        _IngredientRow(emoji: '🍅', name: '토마토', amount: '2', unit: '개'),
        _IngredientRow(emoji: '🧅', name: '양파', amount: '1', unit: '개'),
        _IngredientRow(emoji: '🥕', name: '당근', amount: '1', unit: '개'),
        _IngredientRow(emoji: '🥔', name: '감자', amount: '2', unit: '개'),
        _IngredientRow(emoji: '🧄', name: '마늘', amount: '3', unit: '쪽'),
        _IngredientRow(emoji: '🫒', name: '올리브오일', amount: '2', unit: '큰술'),
      ];

  @override
  Widget build(BuildContext context) {
    final ingredients = recipe.ingredients.isNotEmpty
        ? _toIngredientRows(recipe.ingredients)
        : _exampleIngredients;

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildRecipeInfoCard(),
                const SizedBox(height: 24),
                _buildMyIngredientsSection(ingredients),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_IngredientRow> _toIngredientRows(List<RecipeIngredient> items) {
    return items
        .where((i) => i.type != 'sauce')
        .map((i) {
          final amountValue = i.amount;
          final amountText = amountValue == null
              ? ''
              : (amountValue % 1 == 0
                  ? amountValue.toInt().toString()
                  : amountValue.toString());
          return _IngredientRow(
            emoji: '🍅',
            name: i.rawItemName,
            amount: amountText,
            unit: i.unit,
          );
        })
        .toList();
  }

  Widget _buildRecipeInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SNS 링크 썸네일 영역
          Container(
            width: double.infinity,
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: ShapeDecoration(
              color: const Color(0xFFEAECF0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Center(
              child: Text(
                'SNS 링크 썸네일',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  height: 2,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 매칭률 + 재료 아이콘 영역
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      '내 재료 매칭률',
                      style: TextStyle(
                        color: Color(0xFF495874),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        height: 1.63,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      '70%',
                      style: TextStyle(
                        color: Color(0xFF495874),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        height: 1.63,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(
                    height: 36,
                    padding: const EdgeInsets.all(5.93),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFD04466),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11.87),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '🍅',
                        style: TextStyle(
                          color: Color(0xFF495874),
                          fontSize: 24,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                          height: 1.33,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 35.6,
                    height: 35.6,
                    padding: const EdgeInsets.all(5.93),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFDDE3EE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11.87),
                      ),
                    ),
                    child: const Center(
                      child: Opacity(
                        opacity: 0.6,
                        child: Text(
                          '+ 3',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF495874),
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            height: 1.29,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 스케줄 영역
          Row(
            children: [
              const Expanded(
                child: Text(
                  '스케줄',
                  style: TextStyle(
                    color: Color(0xFF495874),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    height: 1.63,
                    letterSpacing: -1,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 35.6,
                    height: 35.6,
                    padding: const EdgeInsets.all(5.93),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11.87),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '월',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFF5F5F5),
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                          height: 1.29,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 35.6,
                    height: 35.6,
                    padding: const EdgeInsets.all(5.93),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFDDE3EE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11.87),
                      ),
                    ),
                    child: const Center(
                      child: Opacity(
                        opacity: 0.6,
                        child: Text(
                          '2명',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF495874),
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            height: 1.29,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF686C75),
        letterSpacing: -0.3,
        height: 22 / 14,
      ),
    );
  }

  bool _hasIngredient(String ingredientName, List<UserLog> userLogs) {
    final normalizedIngredient = ingredientName.trim().toLowerCase();
    for (final log in userLogs) {
      final normalizedLogName = log.foodName.trim().toLowerCase();
      if (normalizedLogName == normalizedIngredient ||
          normalizedLogName.contains(normalizedIngredient) ||
          normalizedIngredient.contains(normalizedLogName)) {
        return true;
      }
    }
    return false;
  }

  Widget _buildMyIngredientsSection(List<_IngredientRow> ingredients) {
    return Consumer<FoodLogProvider>(
      builder: (context, foodLogProvider, _) {
        final allUserLogs = [
          ...foodLogProvider.refrigeratorLogs,
          ...foodLogProvider.freezerLogs,
        ];

        final matchedIngredients = <_IngredientRow>[];
        final unmatchedIngredients = <_IngredientRow>[];

        for (final ingredient in ingredients) {
          if (_hasIngredient(ingredient.name, allUserLogs)) {
            matchedIngredients.add(ingredient);
          } else {
            unmatchedIngredients.add(ingredient);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('내가 가진 재료'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  if (matchedIngredients.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...matchedIngredients.asMap().entries.map((entry) {
                      final index = entry.key;
                      final ingredient = entry.value;
                      return Column(
                        children: [
                          _buildMyIngredientRow(ingredient, hasIngredient: true),
                          if (index != matchedIngredients.length - 1 ||
                              unmatchedIngredients.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              height: 0.5,
                              color: const Color(0xFFEFF1F4),
                            ),
                          ],
                        ],
                      );
                    }),
                    if (unmatchedIngredients.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        height: 0.5,
                        color: const Color(0xFFEFF1F4),
                      ),
                    ],
                  ],
                  if (unmatchedIngredients.isNotEmpty) ...[
                    if (matchedIngredients.isEmpty) const SizedBox(height: 12),
                    ...unmatchedIngredients.asMap().entries.map((entry) {
                      final index = entry.key;
                      final ingredient = entry.value;
                      return Column(
                        children: [
                          _buildMyIngredientRow(ingredient, hasIngredient: false),
                          if (index != unmatchedIngredients.length - 1) ...[
                            const SizedBox(height: 12),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              height: 0.5,
                              color: const Color(0xFFEFF1F4),
                            ),
                          ],
                        ],
                      );
                    }),
                  ],
                  if (matchedIngredients.isEmpty &&
                      unmatchedIngredients.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        '재료 정보가 없습니다',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF686C75),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyIngredientRow(
    _IngredientRow row, {
    required bool hasIngredient,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: hasIngredient
                ? SvgPicture.asset(
                    'assets/images/si_check-line.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF4CAF50),
                      BlendMode.srcIn,
                    ),
                  )
                : SvgPicture.asset(
                    'assets/images/si_check-line.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFBDBDBD),
                      BlendMode.srcIn,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.name,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: hasIngredient
                    ? const Color(0xFF363A48)
                    : const Color(0xFFBDBDBD),
                letterSpacing: -1,
                height: 32 / 16,
              ),
            ),
          ),
          Text(
            row.amount,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: hasIngredient
                  ? const Color(0xFF363A48)
                  : const Color(0xFFBDBDBD),
              letterSpacing: -0.3,
              height: 22 / 16,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            row.unit,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: hasIngredient
                  ? const Color(0xFF363A48)
                  : const Color(0xFFBDBDBD),
              letterSpacing: -0.3,
              height: 22 / 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 28, bottom: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack ?? () => Navigator.of(context).pop(),
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
          const Text(
            '레시피 상세',
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
          GestureDetector(
            onTap: onSave ?? () => Navigator.of(context).pop(),
            child: const Text(
              '저장',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF363A48),
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

class _IngredientRow {
  final String emoji;
  final String name;
  final String amount;
  final String unit;

  const _IngredientRow({
    required this.emoji,
    required this.name,
    required this.amount,
    required this.unit,
  });
}
