import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food.dart';
import '../models/user_log.dart';
import 'user_service.dart';

class FoodDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();
  final String _collectionName = 'foodData';

  /// 사용자별 foodLog 컬렉션 참조 반환 (비동기)
  Future<CollectionReference> _getUserFoodLogCollection() async {
    final userId = await _userService.getUserId();
    return _firestore.collection('users').doc(userId).collection('foodLog');
  }

  /// 현재 사용자 문서 참조 반환 (비동기)
  Future<DocumentReference> _getUserDocument() async {
    final userId = await _userService.getUserId();
    return _firestore.collection('users').doc(userId);
  }

  /// JSON 파일에서 음식 데이터를 로드
  Future<List<Food>> loadFoodDataFromAssets() async {
    try {
      // assets에서 JSON 파일 읽기
      final String jsonString = await rootBundle.loadString(
        'assets/seed/food_data_ko_251215.json',
      );

      // JSON 파싱
      final List<dynamic> jsonList = json.decode(jsonString);

      // Food 객체 리스트로 변환
      final List<Food> foods = jsonList
          .map((json) => Food.fromJson(json as Map<String, dynamic>))
          .toList();

      print('로드된 음식 데이터: ${foods.length}개');

      // 디버깅: 카테고리별 개수 출력
      Map<String, int> categoryCount = {};
      for (Food food in foods) {
        categoryCount[food.category] = (categoryCount[food.category] ?? 0) + 1;
      }
      print('카테고리별 음식 개수:');
      categoryCount.forEach((category, count) {
        print('  $category: $count개');
      });

      return foods;
    } catch (e) {
      print('음식 데이터 로드 실패: $e');
      return [];
    }
  }

  /// Firestore에 음식 데이터 일괄 업로드
  /// 주의: 운영자 권한이 필요합니다.
  Future<bool> uploadFoodDataToFirestore() async {
    try {
      print('음식 데이터 업로드 시작...');

      // JSON에서 데이터 로드
      final List<Food> foods = await loadFoodDataFromAssets();

      if (foods.isEmpty) {
        print('업로드할 데이터가 없습니다.');
        return false;
      }

      // Firestore batch 작업 준비
      final WriteBatch batch = _firestore.batch();

      // 각 음식 데이터를 batch에 추가
      for (final Food food in foods) {
        final DocumentReference docRef = _firestore
            .collection(_collectionName)
            .doc(food.id);

        batch.set(docRef, food.toFirestore());
      }

      // batch 실행
      await batch.commit();

      print('음식 데이터 업로드 완료: ${foods.length}개');
      return true;
    } catch (e) {
      final errorMessage = e.toString();
      final isPermissionError = errorMessage.contains('permission-denied') ||
          errorMessage.contains('PERMISSION_DENIED');
      
      if (isPermissionError) {
        print('음식 데이터 업로드 실패: 운영자 권한이 필요합니다.');
      } else {
        print('음식 데이터 업로드 실패: $e');
      }
      return false;
    }
  }

  /// Firestore에서 모든 음식 데이터 조회
  Future<List<Food>> getAllFoodsFromFirestore() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .get();

      final List<Food> foods = snapshot.docs
          .map((doc) => Food.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();

      print('Firestore에서 조회된 음식 데이터: ${foods.length}개');
      return foods;
    } catch (e) {
      print('음식 데이터 조회 실패: $e');
      return [];
    }
  }

  /// 특정 음식 데이터 조회
  Future<Food?> getFoodById(String id) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();

      if (doc.exists) {
        return Food.fromFirestore(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('음식 데이터 조회 실패: $e');
      return null;
    }
  }

  /// 카테고리별 음식 데이터 조회
  Future<List<Food>> getFoodsByCategory(String category) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('category', isEqualTo: category)
          .get();

      final List<Food> foods = snapshot.docs
          .map((doc) => Food.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();

      return foods;
    } catch (e) {
      print('카테고리별 음식 데이터 조회 실패: $e');
      return [];
    }
  }

  /// Firestore 컬렉션 데이터 전체 삭제 (재업로드 시 사용)
  /// 주의: 운영자 권한이 필요합니다.
  Future<bool> clearFoodDataCollection() async {
    try {
      print('기존 음식 데이터 삭제 시작...');

      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .get();

      final WriteBatch batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      print('기존 음식 데이터 삭제 완료: ${snapshot.docs.length}개');
      return true;
    } catch (e) {
      final errorMessage = e.toString();
      final isPermissionError = errorMessage.contains('permission-denied') ||
          errorMessage.contains('PERMISSION_DENIED');
      
      if (isPermissionError) {
        print('음식 데이터 삭제 실패: 운영자 권한이 필요합니다.');
      } else {
        print('음식 데이터 삭제 실패: $e');
      }
      return false;
    }
  }

  /// 전체 재업로드 (기존 데이터 삭제 후 새로 업로드)
  /// 주의: 운영자 권한이 필요합니다.
  Future<bool> reuploadAllFoodData() async {
    try {
      // 기존 데이터 삭제
      final deleteSuccess = await clearFoodDataCollection();
      if (!deleteSuccess) {
        return false;
      }

      // 새 데이터 업로드
      return await uploadFoodDataToFirestore();
    } catch (e) {
      final errorMessage = e.toString();
      final isPermissionError = errorMessage.contains('permission-denied') ||
          errorMessage.contains('PERMISSION_DENIED');
      
      if (isPermissionError) {
        print('음식 데이터 재업로드 실패: 운영자 권한이 필요합니다.');
      } else {
        print('음식 데이터 재업로드 실패: $e');
      }
      return false;
    }
  }

  // ========== UserLog 관련 메서드들 ==========

  /// 사용자 음식 로그를 Firestore에 저장
  Future<bool> saveUserLog(UserLog userLog) async {
    try {
      print('사용자 음식 로그 저장 시작: ${userLog.foodName}');

      final collection = await _getUserFoodLogCollection();
      await collection.doc(userLog.id).set(userLog.toFirestore());

      print('사용자 음식 로그 저장 완료: ${userLog.foodName}');
      return true;
    } catch (e) {
      print('사용자 음식 로그 저장 실패: $e');
      return false;
    }
  }

  /// UserLog 생성 헬퍼 메서드
  ///
  /// [manualExpiryDate]가 제공되면 해당 값을 사용하고,
  /// null인 경우 음식 데이터 기반으로 유효기한을 계산합니다.
  Future<UserLog> createUserLog({
    required Food food,
    required String category,
    required String location,
    required String condition,
    required DateTime startDate,
    required bool isSealed,
    String? customEmojiPath, // 커스텀 이모지 경로 (선택적)
    DateTime? manualExpiryDate, // 사용자가 직접 지정한 권장 폐기일 (선택적)
  }) async {
    final now = DateTime.now();
    final expiryDate =
        manualExpiryDate ??
        calculateExpiryDate(food, location, condition, isSealed, startDate);

    final collection = await _getUserFoodLogCollection();

    return UserLog(
      id: collection.doc().id,
      foodId: food.id,
      foodName: food.name,
      category: category,
      storageType: location, // location을 storageType으로 매핑
      condition: condition,
      startDate: startDate,
      expiryDate: expiryDate,
      isSealed: isSealed,
      emojiPath: customEmojiPath ?? food.emojiPath, // 커스텀 경로 우선 사용
      updatedAt: now,
    );
  }

  /// 유효기한 계산 (음식의 shelfLifeMap 기반)
  DateTime? calculateExpiryDate(
    Food food,
    String location,
    String condition,
    bool isSealed,
    DateTime startDate,
  ) {
    try {
      // shelfLifeMap 키 생성: "냉장|통째|false"
      String key = '$location|$condition|$isSealed';

      if (food.shelfLifeMap.containsKey(key)) {
        int shelfLifeDays = food.shelfLifeMap[key]!;
        return startDate.add(Duration(days: shelfLifeDays));
      } else {
        print('해당 조건의 유효기한 정보를 찾을 수 없습니다: $key');
        return null;
      }
    } catch (e) {
      print('유효기간 계산 실패: $e');
      return null;
    }
  }

  /// 모든 사용자 로그 조회
  Future<List<UserLog>> getAllUserLogs() async {
    try {
      print('사용자 음식 로그 조회 시작');

      final collection = await _getUserFoodLogCollection();
      QuerySnapshot querySnapshot = await collection
          .orderBy('startDate', descending: true)
          .get();

      List<UserLog> userLogs = querySnapshot.docs
          .map((doc) => UserLog.fromFirestore(doc))
          .toList();

      print('사용자 음식 로그 조회 완료: ${userLogs.length}개');
      return userLogs;
    } catch (e) {
      print('사용자 음식 로그 조회 실패: $e');
      return [];
    }
  }

  /// 특정 보관 장소의 사용자 로그 조회 (냉장 or 냉동)
  Future<List<UserLog>> getUserLogsByLocation(String location) async {
    try {
      print('$location 음식 로그 조회 시작');

      final collection = await _getUserFoodLogCollection();

      // storage_type 필드로 직접 쿼리 (빠른 조회)
      QuerySnapshot querySnapshot = await collection
          .where('storage_type', isEqualTo: location)
          .get();

      // storage_type으로 찾지 못하면 location 필드로 시도 (기존 데이터 호환성)
      if (querySnapshot.docs.isEmpty) {
        print('storage_type으로 찾지 못함, location 필드로 재시도');
        querySnapshot = await collection
            .where('location', isEqualTo: location)
            .get();
      }

      List<UserLog> userLogs = querySnapshot.docs
          .map((doc) => UserLog.fromFirestore(doc))
          .toList();

      // 클라이언트에서 최신순 정렬
      userLogs.sort((a, b) => b.startDate.compareTo(a.startDate));

      print('$location 음식 로그 조회 완료: ${userLogs.length}개');

      // 디버깅용: 모든 항목 정보 출력
      for (var log in userLogs) {
        print('  - ${log.foodName} (${log.category}, ${log.storageType})');
      }

      return userLogs;
    } catch (e) {
      print('$location 음식 로그 조회 실패: $e');
      return [];
    }
  }

  /// 사용자 로그 삭제
  Future<bool> deleteUserLog(String logId) async {
    try {
      print('사용자 음식 로그 삭제 시작: $logId');

      final collection = await _getUserFoodLogCollection();
      await collection.doc(logId).delete();

      print('사용자 음식 로그 삭제 완료: $logId');
      return true;
    } catch (e) {
      print('사용자 음식 로그 삭제 실패: $e');
      return false;
    }
  }

  /// 사용자 로그의 권장폐기일 업데이트
  Future<bool> updateUserLogExpiryDate(
    String logId,
    DateTime newExpiryDate,
  ) async {
    try {
      print('사용자 음식 로그 권장폐기일 업데이트 시작: $logId -> ${newExpiryDate.toString()}');

      final collection = await _getUserFoodLogCollection();
      await collection.doc(logId).update({
        'expiryDate': Timestamp.fromDate(newExpiryDate),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('사용자 음식 로그 권장폐기일 업데이트 완료: $logId');
      return true;
    } catch (e) {
      print('사용자 음식 로그 권장폐기일 업데이트 실패: $e');
      return false;
    }
  }

  /// 사용자 로그의 이모지 경로 업데이트
  Future<bool> updateUserLogEmojiPath(String logId, String newEmojiPath) async {
    try {
      print('사용자 음식 로그 이모지 경로 업데이트 시작: $logId -> $newEmojiPath');

      final collection = await _getUserFoodLogCollection();
      await collection.doc(logId).update({
        'emojiPath': newEmojiPath,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('사용자 음식 로그 이모지 경로 업데이트 완료: $logId');
      return true;
    } catch (e) {
      print('사용자 음식 로그 이모지 경로 업데이트 실패: $e');
      return false;
    }
  }

  /// 사용자 로그의 카테고리 업데이트
  Future<bool> updateUserLogCategory(String logId, String newCategory) async {
    try {
      print('사용자 음식 로그 카테고리 업데이트 시작: $logId -> $newCategory');

      Map<String, dynamic> updateData = {
        'category': newCategory,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      // 버려야 해요 카테고리로 변경 시 진입 날짜 기록
      if (newCategory == '버려야 해요') {
        updateData['trashEntryDate'] = Timestamp.fromDate(DateTime.now());
      }

      final collection = await _getUserFoodLogCollection();
      await collection.doc(logId).update(updateData);

      print('사용자 음식 로그 카테고리 업데이트 완료: $logId');
      return true;
    } catch (e) {
      print('사용자 음식 로그 카테고리 업데이트 실패: $e');
      return false;
    }
  }

  /// 사용자 로그의 특정 필드 업데이트 (범용)
  Future<bool> updateUserLogField(
    String logId,
    String fieldName,
    dynamic value,
  ) async {
    try {
      print('사용자 음식 로그 필드 업데이트 시작: $logId - $fieldName');

      final collection = await _getUserFoodLogCollection();
      await collection.doc(logId).update({fieldName: value});

      print('사용자 음식 로그 필드 업데이트 완료: $logId - $fieldName');
      return true;
    } catch (e) {
      print('사용자 음식 로그 필드 업데이트 실패: $e');
      return false;
    }
  }

  /// 현재 사용자의 proEarlyBird 필드 업데이트
  Future<bool> updateUserProEarlyBird(bool value) async {
    try {
      final userDoc = await _getUserDocument();
      print('사용자 proEarlyBird 필드 업데이트 시작: ${userDoc.id} -> $value');

      await userDoc.set({
        'proEarlyBird': value,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true)); // merge: true로 기존 데이터 유지하면서 업데이트

      print('사용자 proEarlyBird 필드 업데이트 완료: ${userDoc.id}');
      return true;
    } catch (e) {
      print('사용자 proEarlyBird 필드 업데이트 실패: $e');
      return false;
    }
  }

  /// 현재 사용자의 proEarlyBird 필드 조회
  Future<bool> getUserProEarlyBird() async {
    try {
      final userDoc = await _getUserDocument();
      print('사용자 proEarlyBird 필드 조회 시작: ${userDoc.id}');

      final doc = await userDoc.get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final proEarlyBird = data['proEarlyBird'] as bool?;
        print('사용자 proEarlyBird 필드 조회 완료: $proEarlyBird');
        return proEarlyBird ?? false;
      }

      print('사용자 proEarlyBird 필드 없음, 기본값 false 반환');
      return false;
    } catch (e) {
      print('사용자 proEarlyBird 필드 조회 실패: $e');
      return false;
    }
  }

  /// 특정 음식 이름으로 조회하여 JSON 형식으로 반환
  Future<String?> getFoodJsonByName(String name) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('name', isEqualTo: name)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final food = Food.fromFirestore(doc.data());

      final json = food.toJson();
      final encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (e) {
      print('음식 JSON 조회 실패: $e');
      return null;
    }
  }

  /// 특정 ID로 조회하여 JSON 형식으로 반환
  Future<String?> getFoodJsonById(String id) async {
    try {
      final food = await getFoodById(id);
      if (food == null) {
        return null;
      }

      final json = food.toJson();
      final encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (e) {
      print('음식 JSON 조회 실패: $e');
      return null;
    }
  }
}
