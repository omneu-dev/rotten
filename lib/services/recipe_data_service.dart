import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'food_data_service.dart';

/// Dry-run 결과 모델
class RecipeDryRunResult {
  final int totalRecipes;
  final int newRecipes;
  final int updatedRecipes;
  final int duplicateMenuNames;
  final Map<String, int> menuNameCounts;

  RecipeDryRunResult({
    required this.totalRecipes,
    required this.newRecipes,
    required this.updatedRecipes,
    required this.duplicateMenuNames,
    required this.menuNameCounts,
  });
}

class IngredientDryRunResult {
  final int totalIngredients;
  final int recipeCount;
  final Map<String, int> ingredientsPerRecipe;

  IngredientDryRunResult({
    required this.totalIngredients,
    required this.recipeCount,
    required this.ingredientsPerRecipe,
  });
}

class IngredientMatchItem {
  final String rawItemName;
  final List<String> foodNames; // 매칭 성공 시 foodName 리스트, 실패 시 빈 리스트

  IngredientMatchItem({required this.rawItemName, List<String>? foodNames})
    : foodNames = foodNames ?? [];

  // 기존 코드 호환성을 위한 getter
  String? get foodName => foodNames.isNotEmpty ? foodNames.first : null;
}

class IngredientMatchDryRunResult {
  final int totalIngredients;
  final int matchedCount;
  final double matchRate;
  final List<String> unmatchedTopN;
  final List<String> potentialMatches; // 규칙 추가하면 잡힐 것 같은 애들
  final List<IngredientMatchItem> matchedItems; // 매칭 성공 리스트
  final List<IngredientMatchItem> unmatchedItems; // 매칭 실패 리스트

  IngredientMatchDryRunResult({
    required this.totalIngredients,
    required this.matchedCount,
    required this.matchRate,
    required this.unmatchedTopN,
    required this.potentialMatches,
    required this.matchedItems,
    required this.unmatchedItems,
  });
}

class RecipeDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FoodDataService _foodDataService = FoodDataService();

  /// TSV 파일 로드 (assets) - CSV/TSV 파서 사용
  Future<List<Map<String, dynamic>>> _loadTsv(String path) async {
    final raw = await rootBundle.loadString(path);

    // CSV 파서로 TSV 파싱 (delimiter를 탭으로 설정, 따옴표 처리 활성화)
    final converter = const CsvToListConverter(
      fieldDelimiter: '\t',
      eol: '\n',
      shouldParseNumbers: false, // 모든 값을 문자열로 유지
      textDelimiter: '"', // 따옴표로 감싸진 필드 처리
      textEndDelimiter: '"',
    );

    final List<List<dynamic>> csvData;
    try {
      csvData = converter.convert(raw);
    } catch (e) {
      print('❌ TSV 파싱 오류: $e');
      rethrow;
    }

    if (csvData.isEmpty) {
      return [];
    }

    // 첫 번째 행이 헤더
    final headers = csvData.first.map((e) => e.toString().trim()).toList();
    final List<Map<String, dynamic>> rows = [];

    // 나머지 행들을 맵으로 변환
    for (int i = 1; i < csvData.length; i++) {
      final values = csvData[i];
      final Map<String, dynamic> row = {};

      // 빈 행은 건너뛰기
      if (values.isEmpty ||
          values.every((v) => v == null || v.toString().trim().isEmpty)) {
        continue;
      }

      for (int j = 0; j < headers.length; j++) {
        if (j < values.length) {
          final value = values[j]?.toString();
          // null이거나 빈 문자열이면 null로 저장
          row[headers[j]] = (value == null || value.trim().isEmpty)
              ? null
              : value;
        } else {
          row[headers[j]] = null;
        }
      }

      rows.add(row);
    }

    return rows;
  }

  /// recipes.tsv Dry-run (미리보기)
  Future<RecipeDryRunResult> dryRunRecipes() async {
    try {
      final rows = await _loadTsv('assets/seed/recipes.tsv');

      // Firestore에서 기존 recipe_id 목록 가져오기
      final existingRecipes = await _firestore.collection('recipes').get();
      final existingRecipeIds = existingRecipes.docs
          .map((doc) => doc.id)
          .toSet();

      int newCount = 0;
      int updateCount = 0;
      Map<String, int> menuNameCounts = {};

      for (final row in rows) {
        final recipeId = row['recipe_id']?.toString() ?? '';
        final menuName = row['menu_name']?.toString() ?? '';

        // recipe_id가 없으면 건너뛰기
        if (recipeId.isEmpty) {
          continue;
        }

        if (existingRecipeIds.contains(recipeId)) {
          updateCount++;
        } else {
          newCount++;
        }

        if (menuName.isNotEmpty) {
          menuNameCounts[menuName] = (menuNameCounts[menuName] ?? 0) + 1;
        }
      }

      // 중복 메뉴명 개수 계산
      int duplicateCount = menuNameCounts.values
          .where((count) => count > 1)
          .length;

      return RecipeDryRunResult(
        totalRecipes: rows.length,
        newRecipes: newCount,
        updatedRecipes: updateCount,
        duplicateMenuNames: duplicateCount,
        menuNameCounts: menuNameCounts,
      );
    } catch (e) {
      print('❌ recipes dry-run 실패: $e');
      rethrow;
    }
  }

  /// recipe_ingredients.tsv Dry-run (미리보기)
  Future<IngredientDryRunResult> dryRunIngredients() async {
    try {
      final rows = await _loadTsv('assets/seed/recipe_ingredients.tsv');

      Map<String, int> ingredientsPerRecipe = {};

      for (final row in rows) {
        final recipeId = row['recipe_id']?.toString() ?? '';

        // recipe_id가 없으면 건너뛰기
        if (recipeId.isEmpty) {
          continue;
        }

        ingredientsPerRecipe[recipeId] =
            (ingredientsPerRecipe[recipeId] ?? 0) + 1;
      }

      return IngredientDryRunResult(
        totalIngredients: rows.length,
        recipeCount: ingredientsPerRecipe.length,
        ingredientsPerRecipe: ingredientsPerRecipe,
      );
    } catch (e) {
      print('❌ recipe_ingredients dry-run 실패: $e');
      rethrow;
    }
  }

  /// recipes.tsv → Firestore 업로드 (Upsert)
  /// 주의: 업데이트/삭제는 운영자 권한이 필요합니다. 생성은 로그인한 사용자만 가능합니다.
  Future<bool> uploadRecipes({bool dryRun = false}) async {
    try {
      print('📥 recipes.tsv 업로드 시작 (dryRun: $dryRun)');

      final rows = await _loadTsv('assets/seed/recipes.tsv');

      if (dryRun) {
        print('🔍 Dry-run 모드: 실제 업로드하지 않습니다.');
        return true;
      }

      // Firestore batch 작업 (최대 500개씩)
      const int batchSize = 500;
      int processed = 0;

      while (processed < rows.length) {
        final batch = _firestore.batch();
        final endIndex = (processed + batchSize < rows.length)
            ? processed + batchSize
            : rows.length;

        for (int i = processed; i < endIndex; i++) {
          final row = rows[i];
          final recipeId = row['recipe_id']?.toString() ?? '';

          // recipe_id가 없으면 건너뛰기
          if (recipeId.isEmpty) {
            continue;
          }

          final docRef = _firestore.collection('recipes').doc(recipeId);

          // serving_num 파싱 (double 또는 int)
          final servingNumStr = row['serving_num']?.toString() ?? '0';
          final servingNum = servingNumStr.contains('.')
              ? double.parse(servingNumStr)
              : int.parse(servingNumStr).toDouble();

          batch.set(docRef, {
            'menuName': row['menu_name']?.toString() ?? '',
            'servingNum': servingNum,
            'youtubeUrl': row['youtube_url']?.toString() ?? '',
            'recipeText': row['recipe_text']?.toString() ?? '',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)); // Upsert: 있으면 업데이트, 없으면 생성
        }

        await batch.commit();
        processed = endIndex;
        print('📤 진행 중: $processed/${rows.length}');
      }

      print('✅ recipes 업로드 완료 (${rows.length}개)');
      return true;
    } catch (e) {
      final errorMessage = e.toString();
      final isPermissionError = errorMessage.contains('permission-denied') ||
          errorMessage.contains('PERMISSION_DENIED');
      
      if (isPermissionError) {
        print('❌ recipes 업로드 실패: 운영자 권한이 필요합니다.');
      } else {
        print('❌ recipes 업로드 실패: $e');
      }
      return false;
    }
  }

  /// recipe_ingredients.tsv → Firestore 업로드 (기존 subcollection 삭제 후 재삽입)
  /// 주의: 삭제 작업은 운영자 권한이 필요합니다.
  Future<bool> uploadRecipeIngredients({bool dryRun = false}) async {
    try {
      print('📥 recipe_ingredients.tsv 업로드 시작 (dryRun: $dryRun)');

      final rows = await _loadTsv('assets/seed/recipe_ingredients.tsv');

      if (dryRun) {
        print('🔍 Dry-run 모드: 실제 업로드하지 않습니다.');
        return true;
      }

      // recipe_id별로 그룹화
      Map<String, List<Map<String, dynamic>>> groupedByRecipe = {};
      for (final row in rows) {
        final recipeId = row['recipe_id']?.toString() ?? '';

        // recipe_id가 없으면 건너뛰기
        if (recipeId.isEmpty) {
          continue;
        }

        if (!groupedByRecipe.containsKey(recipeId)) {
          groupedByRecipe[recipeId] = [];
        }
        groupedByRecipe[recipeId]!.add(row);
      }

      // 각 recipe의 기존 ingredients 삭제 후 재삽입
      for (final entry in groupedByRecipe.entries) {
        final recipeId = entry.key;
        final ingredients = entry.value;

        // 1. 기존 subcollection 삭제
        final existingIngredients = await _firestore
            .collection('recipes')
            .doc(recipeId)
            .collection('recipe_ingredients')
            .get();

        if (existingIngredients.docs.isNotEmpty) {
          final deleteBatch = _firestore.batch();
          for (final doc in existingIngredients.docs) {
            deleteBatch.delete(doc.reference);
          }
          await deleteBatch.commit();
        }

        // 2. 새로운 ingredients 삽입
        if (ingredients.isNotEmpty) {
          final insertBatch = _firestore.batch();
          for (final row in ingredients) {
            final docRef = _firestore
                .collection('recipes')
                .doc(recipeId)
                .collection('recipe_ingredients')
                .doc();

            // amount 파싱
            double? amount;
            final amountStr = row['amount']?.toString();
            if (amountStr != null && amountStr.isNotEmpty) {
              try {
                amount = double.parse(amountStr);
              } catch (e) {
                amount = null;
              }
            }

            insertBatch.set(docRef, {
              'type': row['type'] ?? 'ingredient', // ingredient / sauce
              'rawItemName': row['raw_item_name'] ?? '',
              'amount': amount,
              'unit': row['unit'] ?? '',
              'foodRef': row['food_ref_id']?.toString().isNotEmpty == true
                  ? row['food_ref_id']
                  : null,
              'order':
                  int.tryParse(row['ingredient_order']?.toString() ?? '0') ?? 0,
            });
          }
          await insertBatch.commit();
        }

        print(
          '📤 진행 중: ${groupedByRecipe.keys.toList().indexOf(recipeId) + 1}/${groupedByRecipe.length}',
        );
      }

      print(
        '✅ recipe_ingredients 업로드 완료 (${rows.length}개, ${groupedByRecipe.length}개 레시피)',
      );
      return true;
    } catch (e) {
      final errorMessage = e.toString();
      final isPermissionError = errorMessage.contains('permission-denied') ||
          errorMessage.contains('PERMISSION_DENIED');
      
      if (isPermissionError) {
        print('❌ recipe_ingredients 업로드 실패: 운영자 권한이 필요합니다.');
      } else {
        print('❌ recipe_ingredients 업로드 실패: $e');
      }
      return false;
    }
  }

  /// rawItemName 정규화 (공백 제거, 소문자 변환 등)
  String _normalizeName(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '') // 모든 공백 제거
        .replaceAll(RegExp(r'[^\w가-힣]'), ''); // 특수문자 제거
  }

  /// 접두어 제거 규칙
  String _removePrefixes(String normalized) {
    final prefixes = [
      '다진',
      '썬',
      '잘게',
      '굵게',
      '얇게',
      '작게',
      '큰',
      '작은',
      '신선한',
      '신선',
      '냉동',
      '냉장',
      '생',
      '익은',
      '구운',
      '볶은',
      '튀긴',
      '삶은',
      '데친',
    ];

    for (final prefix in prefixes) {
      if (normalized.startsWith(prefix)) {
        return normalized.substring(prefix.length);
      }
    }
    return normalized;
  }

  /// 동의어 매핑
  String _applySynonyms(String normalized) {
    final synonyms = {
      '대파': '파',
      '쪽파': '파',
      '다진대파': '파',
      '다진파': '파',
      '마늘': '통마늘',
      '다진마늘': '마늘',
      '양파': '양파',
      '당근': '당근',
      '무': '무',
      '배추': '배추',
      '상추': '상추',
      '시금치': '시금치',
      '고추': '고추',
      '청양고추': '고추',
      '고춧가루': '고추가루',
      '고추가루': '고추가루',
      '소금': '소금',
      '꽃소금': '소금',
      '굵은소금': '소금',
      '설탕': '설탕',
      '간장': '진간장',
      '진간장': '진간장',
      '액젓': '액젓',
      '까나리액젓': '액젓',
      '새우젓': '새우젓',
      '고추장': '고추장',
      '된장': '된장',
      '마요네즈': '마요네즈',
      '케첩': '케첩',
      '올리브오일': '올리브오일',
      '식용유': '식용유',
      '들기름': '들기름',
      '참기름': '참기름',
      '계란': '계란',
      '달걀': '계란',
      '닭고기': '닭가슴살',
      '닭가슴살': '닭가슴살',
      '돼지고기': '돼지고기',
      '소고기': '소고기',
      '생굴': '굴',
      '굴': '굴',
      '고등어': '고등어',
      '순살고등어': '고등어',
      '골뱅이': '골뱅이',
      '유동골뱅이': '골뱅이',
      '버섯': '버섯',
      '느타리버섯': '버섯',
      '팽이버섯': '버섯',
      '양송이버섯': '버섯',
      '두부': '두부',
      '순두부': '두부',
      '부침두부': '두부',
      '소면': '소면',
      '국수': '소면',
      '라면': '라면',
      '당면': '당면',
    };

    return synonyms[normalized] ?? normalized;
  }

  /// 재료 매칭 (정확 매칭 → 규칙 매칭 → 부분 매칭)
  DocumentReference? _matchIngredientToFood(
    String rawItemName,
    Map<String, DocumentReference> foodNameToRef,
  ) {
    if (rawItemName.isEmpty) return null;

    final normalized = _normalizeName(rawItemName);
    final withoutPrefix = _removePrefixes(normalized);
    final withSynonyms = _applySynonyms(withoutPrefix);

    // 1. 정확 매칭 (원본)
    if (foodNameToRef.containsKey(normalized)) {
      return foodNameToRef[normalized];
    }

    // 2. 정확 매칭 (접두어 제거 후)
    if (foodNameToRef.containsKey(withoutPrefix)) {
      return foodNameToRef[withoutPrefix];
    }

    // 3. 정확 매칭 (동의어 적용 후)
    if (foodNameToRef.containsKey(withSynonyms)) {
      return foodNameToRef[withSynonyms];
    }

    // 4. 부분 매칭 (포함 관계)
    for (final entry in foodNameToRef.entries) {
      final foodName = entry.key;
      if (normalized.contains(foodName) || foodName.contains(normalized)) {
        return entry.value;
      }
      if (withoutPrefix.contains(foodName) ||
          foodName.contains(withoutPrefix)) {
        return entry.value;
      }
      if (withSynonyms.contains(foodName) || foodName.contains(withSynonyms)) {
        return entry.value;
      }
    }

    return null;
  }

  /// 재료 매칭 미리보기 (Dry-run)
  Future<IngredientMatchDryRunResult> dryRunMatchIngredientsToFoodData() async {
    try {
      print('🔍 재료 매칭 미리보기 시작...');

      // 1. 모든 recipe_ingredients 가져오기 (collectionGroup 사용)
      final ingredientsQuery = await _firestore
          .collectionGroup('recipe_ingredients')
          .get();

      // foodRef == null인 것만 필터링
      final unmatchedIngredients = ingredientsQuery.docs
          .where((doc) => doc.data()['foodRef'] == null)
          .toList();

      print(
        '📊 매칭 대상 재료: ${unmatchedIngredients.length}개 (전체: ${ingredientsQuery.docs.length}개)',
      );

      // 2. foodData 전체 읽어서 매칭 사전 생성
      final foods = await _foodDataService.getAllFoodsFromFirestore();
      final Map<String, DocumentReference> foodNameToRef = {};
      final Map<String, String> refIdToFoodName = {}; // 역매핑용 (문서 ID 사용)

      for (final food in foods) {
        final normalized = _normalizeName(food.name);
        final ref = _firestore.collection('foodData').doc(food.id);
        foodNameToRef[normalized] = ref;
        refIdToFoodName[food.id] = food.name; // 원본 이름 저장 (문서 ID를 키로 사용)
      }

      print('📚 foodData 사전 생성 완료: ${foods.length}개');

      // 3. 매칭 수행
      int matchedCount = 0;
      final Map<String, int> unmatchedCounts = {};
      final Map<String, int> potentialMatches = {};
      final List<IngredientMatchItem> matchedItems = [];
      final List<IngredientMatchItem> unmatchedItems = [];

      for (final doc in unmatchedIngredients) {
        final rawItemName = doc.data()['rawItemName']?.toString() ?? '';
        if (rawItemName.isEmpty) continue;

        final match = _matchIngredientToFood(rawItemName, foodNameToRef);
        if (match != null) {
          matchedCount++;
          final foodId = match.id; // DocumentReference에서 ID 추출
          final foodName = refIdToFoodName[foodId] ?? '';
          matchedItems.add(
            IngredientMatchItem(
              rawItemName: rawItemName,
              foodNames: [foodName],
            ),
          );
        } else {
          // 미매칭 통계
          unmatchedCounts[rawItemName] =
              (unmatchedCounts[rawItemName] ?? 0) + 1;
          unmatchedItems.add(
            IngredientMatchItem(rawItemName: rawItemName, foodNames: []),
          );

          // 부분 매칭 후보 찾기 (규칙 추가하면 잡힐 것 같은 애들)
          final normalized = _normalizeName(rawItemName);
          final withoutPrefix = _removePrefixes(normalized);

          // 접두어만 제거하면 매칭될 가능성이 있는 경우
          if (withoutPrefix != normalized) {
            for (final entry in foodNameToRef.entries) {
              if (withoutPrefix.contains(entry.key) ||
                  entry.key.contains(withoutPrefix)) {
                potentialMatches[rawItemName] =
                    (potentialMatches[rawItemName] ?? 0) + 1;
                break;
              }
            }
          }
        }
      }

      // 4. 미매칭 TOP N 추출
      final unmatchedTopN = unmatchedCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topN = unmatchedTopN.take(10).map((e) => e.key).toList();

      // 5. 잠재적 매칭 후보 추출
      final potentialList = potentialMatches.keys.toList();

      final matchRate = unmatchedIngredients.isEmpty
          ? 0.0
          : (matchedCount / unmatchedIngredients.length) * 100;

      print(
        '✅ 매칭 완료: $matchedCount/${unmatchedIngredients.length} (${matchRate.toStringAsFixed(1)}%)',
      );

      return IngredientMatchDryRunResult(
        totalIngredients: unmatchedIngredients.length,
        matchedCount: matchedCount,
        matchRate: matchRate,
        unmatchedTopN: topN,
        potentialMatches: potentialList,
        matchedItems: matchedItems,
        unmatchedItems: unmatchedItems,
      );
    } catch (e) {
      print('❌ 재료 매칭 미리보기 실패: $e');
      rethrow;
    }
  }

  /// 재료 매칭 적용 (Commit)
  Future<bool> commitMatchIngredientsToFoodData() async {
    try {
      print('📥 재료 매칭 적용 시작...');

      // 1. 모든 recipe_ingredients 가져오기 (collectionGroup 사용)
      final ingredientsQuery = await _firestore
          .collectionGroup('recipe_ingredients')
          .get();

      // foodRef == null인 것만 필터링
      final unmatchedIngredients = ingredientsQuery.docs
          .where((doc) => doc.data()['foodRef'] == null)
          .toList();

      print(
        '📊 매칭 대상 재료: ${unmatchedIngredients.length}개 (전체: ${ingredientsQuery.docs.length}개)',
      );

      // 2. foodData 전체 읽어서 매칭 사전 생성
      final foods = await _foodDataService.getAllFoodsFromFirestore();
      final Map<String, DocumentReference> foodNameToRef = {};

      for (final food in foods) {
        final normalized = _normalizeName(food.name);
        foodNameToRef[normalized] = _firestore
            .collection('foodData')
            .doc(food.id);
      }

      print('📚 foodData 사전 생성 완료: ${foods.length}개');

      // 3. 매칭 및 업데이트
      const int batchSize = 500;
      int processed = 0;
      int matchedCount = 0;

      while (processed < unmatchedIngredients.length) {
        final batch = _firestore.batch();
        final endIndex = (processed + batchSize < unmatchedIngredients.length)
            ? processed + batchSize
            : unmatchedIngredients.length;

        for (int i = processed; i < endIndex; i++) {
          final doc = unmatchedIngredients[i];
          final rawItemName = doc.data()['rawItemName']?.toString() ?? '';

          if (rawItemName.isEmpty) continue;

          final match = _matchIngredientToFood(rawItemName, foodNameToRef);
          if (match != null) {
            batch.update(doc.reference, {'foodRef': match});
            matchedCount++;
          }
        }

        await batch.commit();
        processed = endIndex;
        print('📤 진행 중: $processed/${unmatchedIngredients.length}');
      }

      print('✅ 재료 매칭 적용 완료: $matchedCount/${unmatchedIngredients.length}개 매칭');
      return true;
    } catch (e) {
      print('❌ 재료 매칭 적용 실패: $e');
      return false;
    }
  }
}
