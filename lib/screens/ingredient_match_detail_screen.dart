import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/recipe_data_service.dart';
import '../services/food_data_service.dart';
import '../models/food.dart';

class IngredientMatchDetailScreen extends StatefulWidget {
  final IngredientMatchDryRunResult result;

  const IngredientMatchDetailScreen({super.key, required this.result});

  @override
  State<IngredientMatchDetailScreen> createState() =>
      _IngredientMatchDetailScreenState();
}

class _IngredientMatchDetailScreenState
    extends State<IngredientMatchDetailScreen>
    with SingleTickerProviderStateMixin {
  static const String _checkedPrefsKey = 'ingredient_match_checked_v1';
  static const String _itemsDataPrefsKey = 'ingredient_match_items_data_v1';

  late TabController _tabController;
  final FoodDataService _foodDataService = FoodDataService();
  List<IngredientMatchItem> _matchedItems = [];
  List<IngredientMatchItem> _unmatchedItems = [];
  // 체크박스 상태 관리 (rawItemName을 키로 사용)
  Map<String, bool> _checkedItems = {};
  // 원본 rawItemName 추적 (변경된 rawItemName -> 원본 rawItemName)
  Map<String, String> _originalRawItemNames = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 매칭 성공 항목 초기화 및 체크박스 상태 설정
    // foodNames가 null이거나 비어있을 수 있는 경우를 처리
    final sortedMatched = widget.result.matchedItems.map((item) {
      // foodNames가 null이거나 비어있으면 빈 리스트로 설정
      final foodNames = item.foodNames.isNotEmpty
          ? List<String>.from(item.foodNames)
          : <String>[];
      final rawItemName = item.rawItemName;
      // 원본 rawItemName 추적
      _originalRawItemNames[rawItemName] = rawItemName;
      return IngredientMatchItem(
        rawItemName: rawItemName,
        foodNames: foodNames,
      );
    }).toList();

    // 체크박스 상태 초기화: 정확히 일치하는 항목은 기본적으로 체크됨
    for (final item in sortedMatched) {
      // 여러 foodName 중 하나라도 정확히 일치하면 체크
      final isExactMatch = item.foodNames.any(
        (foodName) =>
            item.rawItemName.trim().toLowerCase() ==
            foodName.trim().toLowerCase(),
      );
      _checkedItems[item.rawItemName] = isExactMatch;
    }

    _matchedItems = sortedMatched;
    _unmatchedItems = widget.result.unmatchedItems.map((item) {
      // foodNames가 null이거나 비어있으면 빈 리스트로 설정
      final foodNames = item.foodNames.isNotEmpty
          ? List<String>.from(item.foodNames)
          : <String>[];
      final rawItemName = item.rawItemName;
      // 원본 rawItemName 추적
      _originalRawItemNames[rawItemName] = rawItemName;
      return IngredientMatchItem(
        rawItemName: rawItemName,
        foodNames: foodNames,
      );
    }).toList();

    // 저장된 데이터 불러오기 (체크 상태 및 수정된 rawItemName, foodName)
    _loadSavedData();
  }

  // 저장된 데이터 불러오기 (체크 상태 및 수정된 rawItemName, foodName)
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 먼저 rawItemName과 foodName 변경사항을 불러옴 (체크 상태를 올바른 키로 매핑하기 위해)
      final itemsJsonString = prefs.getString(_itemsDataPrefsKey);
      final Map<String, String> rawItemNameMapping =
          {}; // 원본 -> 현재 rawItemName 매핑

      if (itemsJsonString != null) {
        final Map<String, dynamic> itemsData = json.decode(itemsJsonString);
        setState(() {
          // matchedItems 업데이트
          for (int i = 0; i < _matchedItems.length; i++) {
            final currentRawItemName = _matchedItems[i].rawItemName;
            final originalRawItemName =
                _originalRawItemNames[currentRawItemName] ?? currentRawItemName;

            if (itemsData.containsKey(originalRawItemName)) {
              final itemData =
                  itemsData[originalRawItemName] as Map<String, dynamic>;
              final newRawItemName =
                  itemData['rawItemName'] as String? ?? originalRawItemName;
              final foodNames =
                  (itemData['foodNames'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  _matchedItems[i].foodNames;

              _matchedItems[i] = IngredientMatchItem(
                rawItemName: newRawItemName,
                foodNames: foodNames,
              );

              // 원본 rawItemName 추적 업데이트
              _originalRawItemNames[newRawItemName] = originalRawItemName;

              // rawItemName 매핑 저장 (원본 -> 현재)
              rawItemNameMapping[originalRawItemName] = newRawItemName;
            } else {
              // 변경사항이 없어도 매핑 저장
              rawItemNameMapping[originalRawItemName] = currentRawItemName;
            }
          }

          // unmatchedItems 업데이트
          for (int i = 0; i < _unmatchedItems.length; i++) {
            final currentRawItemName = _unmatchedItems[i].rawItemName;
            final originalRawItemName =
                _originalRawItemNames[currentRawItemName] ?? currentRawItemName;

            if (itemsData.containsKey(originalRawItemName)) {
              final itemData =
                  itemsData[originalRawItemName] as Map<String, dynamic>;
              final newRawItemName =
                  itemData['rawItemName'] as String? ?? originalRawItemName;
              final foodNames =
                  (itemData['foodNames'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  _unmatchedItems[i].foodNames;

              _unmatchedItems[i] = IngredientMatchItem(
                rawItemName: newRawItemName,
                foodNames: foodNames,
              );

              // 원본 rawItemName 추적 업데이트
              _originalRawItemNames[newRawItemName] = originalRawItemName;

              // rawItemName 매핑 저장
              rawItemNameMapping[originalRawItemName] = newRawItemName;
            } else {
              rawItemNameMapping[originalRawItemName] = currentRawItemName;
            }
          }
        });
      } else {
        // 변경사항이 없으면 모든 원본 rawItemName을 현재 rawItemName으로 매핑
        for (final item in _matchedItems) {
          final originalRawItemName =
              _originalRawItemNames[item.rawItemName] ?? item.rawItemName;
          rawItemNameMapping[originalRawItemName] = item.rawItemName;
        }
        for (final item in _unmatchedItems) {
          final originalRawItemName =
              _originalRawItemNames[item.rawItemName] ?? item.rawItemName;
          rawItemNameMapping[originalRawItemName] = item.rawItemName;
        }
      }

      // 체크 상태 불러오기 (원본 rawItemName을 현재 rawItemName으로 매핑)
      final checkedJsonString = prefs.getString(_checkedPrefsKey);
      if (checkedJsonString != null) {
        final Map<String, dynamic> checkedData = json.decode(checkedJsonString);
        setState(() {
          // 원본 rawItemName을 키로 사용하여 체크 상태를 불러오고, 현재 rawItemName으로 매핑
          for (final entry in checkedData.entries) {
            final originalRawItemName = entry.key;
            final currentRawItemName =
                rawItemNameMapping[originalRawItemName] ?? originalRawItemName;
            _checkedItems[currentRawItemName] = entry.value == true;
          }
        });
      }
    } catch (e) {
      debugPrint('저장된 데이터 로드 실패: $e');
    }
  }

  // 체크 상태 저장 (현재 rawItemName을 원본 rawItemName으로 변환하여 저장)
  Future<void> _saveCheckedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 현재 rawItemName을 원본 rawItemName으로 변환하여 저장
      final Map<String, dynamic> checkedDataToSave = {};
      for (final entry in _checkedItems.entries) {
        final currentRawItemName = entry.key;
        final originalRawItemName =
            _originalRawItemNames[currentRawItemName] ?? currentRawItemName;
        checkedDataToSave[originalRawItemName] = entry.value;
      }

      final jsonString = json.encode(checkedDataToSave);
      await prefs.setString(_checkedPrefsKey, jsonString);
    } catch (e) {
      debugPrint('체크 상태 저장 실패: $e');
    }
  }

  // rawItemName과 foodName 변경사항 저장
  Future<void> _saveItemsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> itemsData = {};

      // matchedItems 저장
      for (final item in _matchedItems) {
        // 원본 rawItemName 찾기
        final originalRawItemName =
            _originalRawItemNames[item.rawItemName] ?? item.rawItemName;

        // 원본 데이터와 비교
        final originalItem = widget.result.matchedItems.firstWhere(
          (original) => original.rawItemName == originalRawItemName,
          orElse: () => IngredientMatchItem(
            rawItemName: originalRawItemName,
            foodNames: [],
          ),
        );

        // 변경사항이 있는 경우만 저장
        if (originalRawItemName != item.rawItemName ||
            !_listsEqual(originalItem.foodNames, item.foodNames)) {
          itemsData[originalRawItemName] = {
            'rawItemName': item.rawItemName,
            'foodNames': item.foodNames,
          };
        }
      }

      // unmatchedItems 저장
      for (final item in _unmatchedItems) {
        final originalRawItemName =
            _originalRawItemNames[item.rawItemName] ?? item.rawItemName;

        final originalItem = widget.result.unmatchedItems.firstWhere(
          (original) => original.rawItemName == originalRawItemName,
          orElse: () => IngredientMatchItem(
            rawItemName: originalRawItemName,
            foodNames: [],
          ),
        );

        if (originalRawItemName != item.rawItemName ||
            !_listsEqual(originalItem.foodNames, item.foodNames)) {
          itemsData[originalRawItemName] = {
            'rawItemName': item.rawItemName,
            'foodNames': item.foodNames,
          };
        }
      }

      final jsonString = json.encode(itemsData);
      await prefs.setString(_itemsDataPrefsKey, jsonString);
    } catch (e) {
      debugPrint('항목 데이터 저장 실패: $e');
    }
  }

  // 리스트 비교 헬퍼 함수
  bool _listsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateItem(
    String rawItemName,
    List<String> newFoodNames, {
    required bool isMatched,
  }) {
    setState(() {
      if (isMatched) {
        // rawItemName으로 원본 리스트에서 해당 항목 찾기
        final itemIndex = _matchedItems.indexWhere(
          (item) => item.rawItemName == rawItemName,
        );

        if (itemIndex != -1) {
          // 선택된 foodNames로 완전히 교체 (선택 해제도 반영)
          final updatedFoodNames = List<String>.from(newFoodNames);

          _matchedItems[itemIndex] = IngredientMatchItem(
            rawItemName: rawItemName,
            foodNames: updatedFoodNames,
          );

          // 음식 추가/변경 시: foodName이 있으면 체크박스 자동 체크
          if (updatedFoodNames.isNotEmpty) {
            // 여러 foodName 중 하나라도 정확히 일치하면 체크
            final isExactMatch = updatedFoodNames.any(
              (foodName) =>
                  rawItemName.trim().toLowerCase() ==
                  foodName.trim().toLowerCase(),
            );
            _checkedItems[rawItemName] = isExactMatch;
          } else {
            // foodName이 비어있으면 체크 해제
            _checkedItems[rawItemName] = false;
          }

          _saveCheckedState();
          _saveItemsData();
        } else {
          debugPrint('⚠️ rawItemName을 찾을 수 없음: $rawItemName');
        }
      } else {
        // unmatchedItems에서도 rawItemName으로 찾기
        final itemIndex = _unmatchedItems.indexWhere(
          (item) => item.rawItemName == rawItemName,
        );

        if (itemIndex != -1) {
          // 선택된 foodNames로 완전히 교체 (선택 해제도 반영)
          final updatedFoodNames = List<String>.from(newFoodNames);

          _unmatchedItems[itemIndex] = IngredientMatchItem(
            rawItemName: rawItemName,
            foodNames: updatedFoodNames,
          );
        } else {
          debugPrint('⚠️ rawItemName을 찾을 수 없음: $rawItemName');
        }
      }
    });
  }

  void _updateRawItemName(
    int index,
    String newRawItemName, {
    required bool isMatched,
  }) {
    if (isMatched) {
      // 인덱스가 유효한지 확인
      if (index < 0 || index >= _matchedItems.length) {
        debugPrint('⚠️ 인덱스가 유효하지 않음: $index (리스트 길이: ${_matchedItems.length})');
        return;
      }

      final oldRawItemName = _matchedItems[index].rawItemName;

      // 새 rawItemName이 이미 존재하는지 확인
      final existingIndex = _matchedItems.indexWhere(
        (item) =>
            item.rawItemName == newRawItemName &&
            item.rawItemName != oldRawItemName,
      );
      if (existingIndex != -1) {
        // 이미 존재하는 rawItemName이면 업데이트하지 않음
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미 존재하는 rawItemName입니다: $newRawItemName'),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      // 원본 리스트에서 해당 항목 찾기 (oldRawItemName으로)
      final itemIndex = _matchedItems.indexWhere(
        (item) => item.rawItemName == oldRawItemName,
      );

      if (itemIndex != -1) {
        setState(() {
          // 체크박스 상태를 이전 키에서 새 키로 이동
          final checkedState = _checkedItems[oldRawItemName] ?? false;
          _checkedItems.remove(oldRawItemName);
          _checkedItems[newRawItemName] = checkedState;

          // 항목 업데이트
          _matchedItems[itemIndex] = IngredientMatchItem(
            rawItemName: newRawItemName,
            foodNames: _matchedItems[itemIndex].foodNames,
          );

          // 원본 rawItemName 추적 업데이트
          final originalRawItemName =
              _originalRawItemNames[oldRawItemName] ?? oldRawItemName;
          _originalRawItemNames.remove(oldRawItemName);
          _originalRawItemNames[newRawItemName] = originalRawItemName;

          _saveCheckedState();
          _saveItemsData();
        });
      }
    } else {
      if (index >= 0 && index < _unmatchedItems.length) {
        final oldRawItemName = _unmatchedItems[index].rawItemName;

        // 새 rawItemName이 이미 존재하는지 확인
        final existingIndex = _unmatchedItems.indexWhere(
          (item) =>
              item.rawItemName == newRawItemName &&
              item.rawItemName != oldRawItemName,
        );
        if (existingIndex != -1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('이미 존재하는 rawItemName입니다: $newRawItemName'),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        setState(() {
          final oldRawItemName = _unmatchedItems[index].rawItemName;
          _unmatchedItems[index] = IngredientMatchItem(
            rawItemName: newRawItemName,
            foodNames: _unmatchedItems[index].foodNames,
          );

          // 원본 rawItemName 추적 업데이트
          final originalRawItemName =
              _originalRawItemNames[oldRawItemName] ?? oldRawItemName;
          _originalRawItemNames.remove(oldRawItemName);
          _originalRawItemNames[newRawItemName] = originalRawItemName;

          _saveItemsData();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('재료 매칭 상세'),
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '매칭 성공'),
            Tab(text: '매칭 실패'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMatchedTab(), _buildUnmatchedTab()],
      ),
    );
  }

  Widget _buildMatchedTab() {
    if (widget.result.matchedItems.isEmpty) {
      return const Center(
        child: Text(
          '매칭 성공한 항목이 없습니다.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // 체크 상태에 따라 필터링 및 정렬된 리스트 생성
    final sortedItems = List<IngredientMatchItem>.from(_matchedItems);
    sortedItems.sort((a, b) {
      final aChecked = _checkedItems[a.rawItemName] ?? false;
      final bChecked = _checkedItems[b.rawItemName] ?? false;

      // 체크 안 된 항목을 위로
      if (aChecked && !bChecked) return 1;
      if (!aChecked && bChecked) return -1;
      return 0;
    });

    // 체크된 항목과 체크 안 된 항목 개수 계산
    int checkedCount = 0;
    int uncheckedCount = 0;
    for (final item in _matchedItems) {
      if (_checkedItems[item.rawItemName] ?? false) {
        checkedCount++;
      } else {
        uncheckedCount++;
      }
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '총 ${widget.result.matchedItems.length}개 항목',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '체크됨: $checkedCount',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '체크 안 됨: $uncheckedCount',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildItemTable(sortedItems, isMatched: true)),
      ],
    );
  }

  Widget _buildUnmatchedTab() {
    if (widget.result.unmatchedItems.isEmpty) {
      return const Center(
        child: Text(
          '매칭 실패한 항목이 없습니다.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            '총 ${widget.result.unmatchedItems.length}개 항목',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: _buildItemTable(_unmatchedItems, isMatched: false)),
      ],
    );
  }

  Widget _buildItemTable(
    List<IngredientMatchItem> items, {
    required bool isMatched,
  }) {
    return Column(
      children: [
        // 고정 헤더
        Container(
          decoration: BoxDecoration(
            color: isMatched ? Colors.green[100] : Colors.red[100],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Text(
                    'rawItemName',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              Container(width: 1, color: Colors.grey[300]),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Text(
                    'foodName',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              if (isMatched) ...[
                Container(width: 1, color: Colors.grey[300]),
                SizedBox(
                  width: 50,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // 스크롤 가능한 본문
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: () => _showRawItemNameEditDialog(
                            index,
                            item.rawItemName,
                            isMatched: isMatched,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(minHeight: 48),
                            decoration: BoxDecoration(color: Colors.orange[50]),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item.rawItemName,
                                style: TextStyle(
                                  color: isMatched
                                      ? Colors.green[900]
                                      : Colors.red[900],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, color: Colors.grey[300]),
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: () => _showFoodNameEditDialog(
                            index,
                            item.rawItemName,
                            item.foodNames,
                            isMatched: isMatched,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(minHeight: 48),
                            decoration: BoxDecoration(color: Colors.blue[50]),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: item.foodNames.isEmpty
                                  ? Text(
                                      '-',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                        fontSize: 14,
                                      ),
                                    )
                                  : Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: item.foodNames.map((foodName) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isMatched
                                                ? Colors.green[100]
                                                : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: isMatched
                                                  ? Colors.green[300]!
                                                  : Colors.grey[400]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            foodName,
                                            style: TextStyle(
                                              color: isMatched
                                                  ? Colors.green[800]
                                                  : Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      if (isMatched) ...[
                        Container(width: 1, color: Colors.grey[300]),
                        SizedBox(
                          width: 50,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Checkbox(
                              value: _checkedItems[item.rawItemName] ?? false,
                              onChanged: (bool? value) {
                                setState(() {
                                  _checkedItems[item.rawItemName] =
                                      value ?? false;
                                });
                                _saveCheckedState();
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showFoodNameEditDialog(
    int index,
    String rawItemName,
    List<String> currentFoodNames, {
    required bool isMatched,
  }) async {
    final allFoods = await _foodDataService.getAllFoodsFromFirestore();
    String searchQuery = '';
    List<Food> filteredFoods = allFoods;
    // 선택된 foodName들을 Set으로 관리
    Set<String> selectedFoodNames = Set.from(currentFoodNames);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.teal[600]),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'foodName 선택/추가 (다중 선택 가능)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // 선택된 항목 표시
                  if (selectedFoodNames.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.blue[50],
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedFoodNames.map((foodName) {
                          return Chip(
                            label: Text(foodName),
                            onDeleted: () {
                              setDialogState(() {
                                selectedFoodNames.remove(foodName);
                              });
                            },
                            deleteIcon: const Icon(Icons.close, size: 18),
                          );
                        }).toList(),
                      ),
                    ),
                  // 검색 필드
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: '음식 이름 검색...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setDialogState(() {
                                    searchQuery = '';
                                    filteredFoods = allFoods;
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value;
                          if (value.isEmpty) {
                            filteredFoods = allFoods;
                          } else {
                            filteredFoods = allFoods
                                .where(
                                  (food) => food.name.toLowerCase().contains(
                                    value.toLowerCase(),
                                  ),
                                )
                                .toList();
                          }
                        });
                      },
                    ),
                  ),
                  // 검색 결과 리스트
                  Expanded(
                    child: filteredFoods.isEmpty && searchQuery.isNotEmpty
                        ? Column(
                            children: [
                              const Spacer(),
                              Text(
                                '검색 결과가 없습니다',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await _showAddFoodDialog(
                                    context,
                                    searchQuery,
                                    rawItemName,
                                    0, // index는 더 이상 사용하지 않음
                                    isMatched: isMatched,
                                  );
                                  // 새 음식 추가 후 다이얼로그를 다시 열어서 선택할 수 있도록
                                  // 여기서는 다이얼로그를 닫지 않고 유지
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('새 음식 추가'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal[600],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const Spacer(),
                            ],
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredFoods.length,
                            itemBuilder: (context, i) {
                              final food = filteredFoods[i];
                              final isSelected = selectedFoodNames.contains(
                                food.name,
                              );
                              return CheckboxListTile(
                                title: Text(food.name),
                                subtitle: Text(food.category),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      selectedFoodNames.add(food.name);
                                    } else {
                                      selectedFoodNames.remove(food.name);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  // 하단 버튼
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _showAddFoodDialog(
                                context,
                                searchQuery.isNotEmpty ? searchQuery : '',
                                rawItemName,
                                0, // index는 더 이상 사용하지 않음
                                isMatched: isMatched,
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('새 음식 추가'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _updateItem(
                                rawItemName,
                                selectedFoodNames.toList(),
                                isMatched: isMatched,
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    selectedFoodNames.isEmpty
                                        ? 'foodName이 제거되었습니다'
                                        : '${selectedFoodNames.length}개의 foodName이 선택되었습니다',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('확인'),
                          ),
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

  Future<void> _showRawItemNameEditDialog(
    int index,
    String currentRawItemName, {
    required bool isMatched,
  }) async {
    // 정렬된 리스트의 인덱스를 원본 리스트의 인덱스로 변환
    int originalIndex = index;
    if (isMatched) {
      originalIndex = _matchedItems.indexWhere(
        (item) => item.rawItemName == currentRawItemName,
      );
      if (originalIndex == -1) {
        originalIndex = index;
      }
    } else {
      originalIndex = _unmatchedItems.indexWhere(
        (item) => item.rawItemName == currentRawItemName,
      );
      if (originalIndex == -1) {
        originalIndex = index;
      }
    }

    final TextEditingController controller = TextEditingController(
      text: currentRawItemName,
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('rawItemName 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'rawItemName',
            hintText: 'rawItemName을 입력하세요',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final newRawItemName = controller.text.trim();
              if (newRawItemName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('rawItemName은 비어있을 수 없습니다'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              if (newRawItemName == currentRawItemName) {
                Navigator.pop(context);
                return;
              }

              _updateRawItemName(
                originalIndex,
                newRawItemName,
                isMatched: isMatched,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('rawItemName이 "$newRawItemName"으로 업데이트되었습니다'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddFoodDialog(
    BuildContext context,
    String foodName,
    String rawItemName,
    int index, {
    required bool isMatched,
  }) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => _AddFoodDialog(
        foodName: foodName,
        rawItemName: rawItemName,
        index: index, // index는 더 이상 사용하지 않지만 호환성을 위해 유지
        isMatched: isMatched,
        onUpdate: _updateItem,
      ),
    );
  }
}

class _AddFoodDialog extends StatefulWidget {
  final String foodName;
  final String rawItemName;
  final int index;
  final bool isMatched;
  final Function(
    String rawItemName,
    List<String> newFoodNames, {
    required bool isMatched,
  })
  onUpdate;

  const _AddFoodDialog({
    required this.foodName,
    required this.rawItemName,
    required this.index,
    required this.isMatched,
    required this.onUpdate,
  });

  @override
  State<_AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<_AddFoodDialog> {
  // 카테고리 목록
  final categories = [
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
    '조미료·양념',
    '기타',
  ];

  // 이모지 이미지 목록 (일부만 표시)
  final emojiImages = [
    'Avocado.png',
    'Baby_Bottle.png',
    'Bacon.png',
    'Bagel.png',
    'Baguette_Bread.png',
    'Banana.png',
    'Beer_Mug.png',
    'Bell_Pepper.png',
    'Bento_Box.png',
    'Beverage_Box.png',
    'Birthday_Cake.png',
    'Blueberries.png',
    'Bone.png',
    'Bottle_With_Popping_Cork.png',
    'Bowl_With_Spoon.png',
    'Bread.png',
    'Broccoli.png',
    'Bubble_Tea.png',
    'Burrito.png',
    'Butter.png',
    'Candy.png',
    'Canned_Food.png',
    'Carrot.png',
    'Cheese_Wedge.png',
    'Cherries.png',
    'Chestnut.png',
    'Chocolate_Bar.png',
    'Chopsticks.png',
    'Clinking_Beer_Mugs.png',
    'Clinking_Glasses.png',
    'Cocktail_Glass.png',
    'Coconut.png',
    'Cooked_Rice.png',
    'Cookie.png',
    'Cooking.png',
    'Croissant.png',
    'Cucumber.png',
    'Cup_With_Straw.png',
    'Cupcake.png',
    'Curry_Rice.png',
    'Custard.png',
    'Cut_Of_Meat.png',
    'Dango.png',
    'Doughnut.png',
    'Dumpling.png',
    'Ear_Of_Corn.png',
    'Egg.png',
    'Eggplant.png',
    'Falafel.png',
    'Flatbread.png',
    'Fondue.png',
    'Fork_And_Knife.png',
    'Fork_And_Knife_With_Plate.png',
    'Fortune_Cookie.png',
    'French_Fries.png',
    'Fried_Shrimp.png',
    'Garlic.png',
    'Glass_Of_Milk.png',
    'Grapes.png',
    'Green_Apple.png',
    'Green_Salad.png',
    'Hamburger.png',
    'Honey_Pot.png',
    'Hot_Beverage.png',
    'Hot_Dog.png',
    'Hot_Pepper.png',
    'Ice.png',
    'Ice_Cream.png',
    'Kitchen_Knife.png',
    'Kiwi_Fruit.png',
    'Leafy_Green.png',
    'Lemon.png',
    'Lollipop.png',
    'Mango.png',
    'Mate.png',
    'Meat_On_Bone.png',
    'Melon.png',
    'Moon_Cake.png',
    'Mushroom.png',
    'Oden.png',
    'Olive.png',
    'Onion.png',
    'Oyster.png',
    'Pancakes.png',
    'Peach.png',
    'Peanuts.png',
    'Pear.png',
    'Pie.png',
    'Pineapple.png',
    'Pizza.png',
    'Popcorn.png',
    'Pot_Of_Food.png',
    'Potato.png',
    'Poultry_Leg.png',
    'Pretzel.png',
    'Red_Apple.png',
    'Rice_Ball.png',
    'Rice_Cracker.png',
    'Roasted_Sweet_Potato.png',
    'Sake.png',
    'Salt.png',
    'Sandwich.png',
    'Shallow_Pan_Of_Food.png',
    'Shaved_Ice.png',
    'Shortcake.png',
    'Soft_Ice_Cream.png',
    'Spaghetti.png',
    'Spoon.png',
    'Steaming_Bowl.png',
    'Strawberry.png',
    'Stuffed_Flatbread.png',
    'Sushi.png',
    'Taco.png',
    'Takeout_Box.png',
    'Tamale.png',
    'Tangerine.png',
    'Teacup_Without_Handle.png',
    'Tomato.png',
    'Tropical_Drink.png',
    'Tumbler_Glass.png',
    'Waffle.png',
    'Watermelon.png',
    'Wine_Glass.png',
  ];

  late String selectedCategory;
  late String selectedEmoji;
  late TextEditingController aiStorageTipsController;
  late TextEditingController foodIdController;
  late Map<String, int> shelfLifeMap;

  @override
  void initState() {
    super.initState();
    // 기본값 추정
    selectedCategory = '기타';
    selectedEmoji = 'Ear_Of_Corn.png';
    aiStorageTipsController = TextEditingController();
    // foodId는 foodName 기반으로 자동 생성하되 수정 가능
    final autoId = widget.foodName.toLowerCase().replaceAll(
      RegExp(r'[^\w가-힣]'),
      '_',
    );
    foodIdController = TextEditingController(text: autoId);
    // shelfLifeMap을 빈 Map으로 초기화 (디폴트 값 없음)
    shelfLifeMap = {};

    // 카테고리 추정 로직
    final nameLower = widget.foodName.toLowerCase();
    if (nameLower.contains('고기') ||
        nameLower.contains('생선') ||
        nameLower.contains('닭') ||
        nameLower.contains('돼지') ||
        nameLower.contains('소')) {
      selectedCategory = '육류·생선';
      // 디폴트 값 제거 - shelfLifeMap은 빈 상태로 유지
    } else if (nameLower.contains('채소') ||
        nameLower.contains('과일') ||
        nameLower.contains('야채')) {
      selectedCategory = '채소·과일';
    } else if (nameLower.contains('계란') ||
        nameLower.contains('달걀') ||
        nameLower.contains('두부')) {
      selectedCategory = '계란·두부';
    } else if (nameLower.contains('김치') || nameLower.contains('절임')) {
      selectedCategory = '김치·절임류';
    } else if (nameLower.contains('우유') ||
        nameLower.contains('치즈') ||
        nameLower.contains('요구르트')) {
      selectedCategory = '유제품';
    } else if (nameLower.contains('쌀') || nameLower.contains('곡물')) {
      selectedCategory = '건과류·쌀';
    } else if (nameLower.contains('빵') || nameLower.contains('케이크')) {
      selectedCategory = '베이커리';
    }
  }

  @override
  void dispose() {
    aiStorageTipsController.dispose();
    foodIdController.dispose();
    super.dispose();
  }

  // Food를 JSON 형식으로 변환 (food_data_ko_251215.json 형식)
  String _formatFoodAsJson(Food food) {
    final json = food.toJson();
    final encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }

  // JSON 다이얼로그 표시
  void _showJsonDialog(
    BuildContext context,
    String foodName,
    String jsonString,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$foodName JSON 형식'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '아래 내용을 food_data_ko_251215.json 파일에 추가하세요:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  jsonString,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('JSON이 클립보드에 복사되었습니다'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('복사'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('새 음식 추가'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('음식 이름: ${widget.foodName}'),
            const SizedBox(height: 16),
            const Text('음식 ID:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: foodIdController,
              decoration: InputDecoration(
                hintText: '음식 ID (문서 ID로 사용됩니다)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText: 'Firestore 문서 ID와 Food 모델의 id 필드에 사용됩니다',
              ),
            ),
            const SizedBox(height: 16),
            const Text('카테고리:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: selectedCategory,
              isExpanded: true,
              items: categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              '이모지 선택:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // 현재 선택된 이모지 미리보기
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/food_images/$selectedEmoji',
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported, size: 40);
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedEmoji.replaceAll('.png', ''),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showEmojiPicker(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('변경'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI 보관 Tip:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '보관 팁을 입력하세요 (예: 냉장 보관 시 밀폐 용기 사용 권장)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              controller: aiStorageTipsController,
            ),
            const SizedBox(height: 16),
            const Text(
              '보관 기간 (일):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: shelfLifeMap.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          '보관 기간을 직접 입력하세요',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: shelfLifeMap.entries.map((entry) {
                          final key = entry.key;
                          final value = entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    key,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.all(8),
                                    ),
                                    controller: TextEditingController(
                                      text: value.toString(),
                                    ),
                                    onChanged: (val) {
                                      final intVal = int.tryParse(val);
                                      if (intVal != null) {
                                        setState(() {
                                          shelfLifeMap = Map<String, int>.from(
                                            shelfLifeMap,
                                          )..[key] = intVal;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Food 생성 및 Firestore에 추가
            final foodId = foodIdController.text.trim();

            if (foodId.isEmpty) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('음식 ID를 입력해주세요'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            final newFood = Food(
              id: foodId,
              name: widget.foodName,
              category: selectedCategory,
              emojiPath: 'assets/images/food_images/$selectedEmoji',
              shelfLifeMap: shelfLifeMap,
              aiStorageTips: aiStorageTipsController.text.isEmpty
                  ? null
                  : aiStorageTipsController.text,
              updatedAt: DateTime.now(),
            );

            try {
              print('🍽️ 새 음식 추가 시작:');
              print('  - ID: $foodId');
              print('  - 이름: ${widget.foodName}');
              print('  - 카테고리: $selectedCategory');
              print('  - 이모지: $selectedEmoji');
              print('  - 보관 기간 맵: $shelfLifeMap');

              final foodData = newFood.toFirestore();
              print('  - Firestore 데이터: $foodData');

              await FirebaseFirestore.instance
                  .collection('foodData')
                  .doc(foodId) // 사용자가 입력한 ID를 문서 ID로 사용
                  .set(foodData);

              print('✅ Firestore 저장 완료: $foodId');

              // 저장 확인
              final savedDoc = await FirebaseFirestore.instance
                  .collection('foodData')
                  .doc(foodId)
                  .get();

              if (savedDoc.exists) {
                print('✅ 저장 확인 완료: 문서가 존재합니다');
                print('  - 저장된 데이터: ${savedDoc.data()}');
              } else {
                print('❌ 저장 확인 실패: 문서가 존재하지 않습니다');
              }

              // UI 업데이트 - 새로 추가된 foodName을 리스트에 추가
              // onUpdate 콜백이 기존 foodNames와 병합하도록 처리됨
              widget.onUpdate(
                widget.rawItemName,
                [widget.foodName], // 새로 추가된 foodName
                isMatched: widget.isMatched,
              );

              // JSON 형식으로 출력
              final jsonString = _formatFoodAsJson(newFood);
              print('📋 JSON 형식 (food_data_ko_251215.json에 추가할 내용):');
              print(jsonString);

              if (context.mounted) {
                Navigator.pop(context); // 추가 다이얼로그 닫기
                Navigator.pop(context); // 검색 다이얼로그 닫기

                // JSON 형식을 다이얼로그로 표시
                _showJsonDialog(context, newFood.name, jsonString);
              }
            } catch (e, stackTrace) {
              print('❌ 음식 추가 실패:');
              print('  - 에러: $e');
              print('  - 스택 트레이스: $stackTrace');
              if (context.mounted) {
                // Firebase 권한 오류 감지
                final errorMessage = e.toString();
                final isPermissionError =
                    errorMessage.contains('permission-denied') ||
                    errorMessage.contains('PERMISSION_DENIED') ||
                    errorMessage.contains('권한');

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isPermissionError
                          ? '음식 데이터 추가는 운영자만 가능합니다. 운영자에게 요청해주세요.'
                          : '추가 실패: $e',
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[600],
            foregroundColor: Colors.white,
          ),
          child: const Text('확인'),
        ),
      ],
    );
  }

  void _showEmojiPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal[600],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '이모지 선택',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: emojiImages.length,
                  itemBuilder: (context, i) {
                    final emoji = emojiImages[i];
                    final isSelected = selectedEmoji == emoji;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedEmoji = emoji;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.teal : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected ? Colors.teal[50] : Colors.white,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/food_images/$emoji',
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.image_not_supported,
                                size: 20,
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
