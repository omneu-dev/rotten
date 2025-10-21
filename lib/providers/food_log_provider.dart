import 'package:flutter/foundation.dart';
import '../models/user_log.dart';
import '../services/food_data_service.dart';
import '../services/notification_service.dart';

class FoodLogProvider with ChangeNotifier {
  final FoodDataService _foodDataService = FoodDataService();
  final NotificationService _notificationService = NotificationService();

  // 데이터 저장
  List<UserLog> _refrigeratorLogs = [];
  List<UserLog> _freezerLogs = [];

  // 로딩 상태
  bool _isLoading = false;
  bool _hasInitialized = false;

  // Getters
  List<UserLog> get refrigeratorLogs => _refrigeratorLogs;
  List<UserLog> get freezerLogs => _freezerLogs;
  bool get isLoading => _isLoading;
  bool get hasInitialized => _hasInitialized;

  /// 초기 데이터 로드 (빠른 초기화)
  Future<void> initialize() async {
    if (_hasInitialized) return; // 중복 초기화 방지
    _hasInitialized = true; // 즉시 마킹으로 중복 방지

    // 백그라운드에서 로딩 (UI 블로킹 없음)
    loadRefrigeratorLogs();
    loadFreezerLogs();
  }

  /// 냉장고 데이터 로드
  Future<void> loadRefrigeratorLogs() async {
    try {
      final logs = await _foodDataService.getUserLogsByLocation('냉장');
      _refrigeratorLogs = logs;
      print('Provider: 냉장고 로그 ${_refrigeratorLogs.length}개 로드');
      if (mounted) notifyListeners();
    } catch (e) {
      print('Provider: 냉장고 로그 로드 실패 - $e');
    }
  }

  /// 냉동고 데이터 로드
  Future<void> loadFreezerLogs() async {
    try {
      final logs = await _foodDataService.getUserLogsByLocation('냉동');
      _freezerLogs = logs;
      print('Provider: 냉동고 로그 ${_freezerLogs.length}개 로드');
      if (mounted) notifyListeners();
    } catch (e) {
      print('Provider: 냉동고 로그 로드 실패 - $e');
    }
  }

  bool get mounted => _hasInitialized;

  /// 새 음식 로그 추가
  Future<bool> addFoodLog(UserLog userLog) async {
    try {
      _setLoading(true);

      // Firestore에 저장
      bool success = await _foodDataService.saveUserLog(userLog);

      if (success) {
        // 로컬 상태 업데이트
        if (userLog.storageType == '냉장') {
          _refrigeratorLogs.add(userLog);
          // 최신순 정렬
          _refrigeratorLogs.sort((a, b) => b.startDate.compareTo(a.startDate));
        } else if (userLog.storageType == '냉동') {
          _freezerLogs.add(userLog);
          // 최신순 정렬
          _freezerLogs.sort((a, b) => b.startDate.compareTo(a.startDate));
        }

        print('Provider: 새 음식 로그 추가 완료 - ${userLog.foodName}');
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      print('Provider: 음식 로그 추가 실패 - $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 음식 로그 삭제
  Future<bool> deleteFoodLog(String logId, String storageType) async {
    try {
      _setLoading(true);

      // Firestore에서 삭제
      bool success = await _foodDataService.deleteUserLog(logId);

      if (success) {
        // 로컬 상태 업데이트
        if (storageType == '냉장') {
          _refrigeratorLogs.removeWhere((log) => log.id == logId);
        } else if (storageType == '냉동') {
          _freezerLogs.removeWhere((log) => log.id == logId);
        }

        print('Provider: 음식 로그 삭제 완료 - $logId');
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      print('Provider: 음식 로그 삭제 실패 - $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 전체 데이터 새로고침
  Future<void> refresh() async {
    print('Provider: 데이터 새로고침 시작');
    _setLoading(true);
    await Future.wait([loadRefrigeratorLogs(), loadFreezerLogs()]);
    _setLoading(false);
    print('Provider: 데이터 새로고침 완료');
  }

  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 특정 카테고리 음식들 가져오기
  List<UserLog> getLogsByCategory(String storageType, String category) {
    List<UserLog> logs = storageType == '냉장' ? _refrigeratorLogs : _freezerLogs;
    if (category == '전체') return logs;
    return logs.where((log) => log.category == category).toList();
  }

  /// 권장폐기일 업데이트
  Future<bool> updateExpiryDate(
    String logId,
    String storageType,
    DateTime newExpiryDate,
  ) async {
    try {
      _setLoading(true);

      // Firestore에서 업데이트
      bool success = await _foodDataService.updateUserLogExpiryDate(
        logId,
        newExpiryDate,
      );

      if (success) {
        // 로컬 상태 업데이트
        List<UserLog> logs = storageType == '냉장'
            ? _refrigeratorLogs
            : _freezerLogs;
        int index = logs.indexWhere((log) => log.id == logId);

        if (index != -1) {
          // UserLog의 copyWith 메서드를 사용하여 새로운 expiryDate로 업데이트
          UserLog updatedLog = logs[index].copyWith(
            expiryDate: newExpiryDate,
            updatedAt: DateTime.now(),
          );
          logs[index] = updatedLog;

          print(
            'Provider: 권장폐기일 업데이트 완료 - ${updatedLog.foodName}: ${newExpiryDate.toString()}',
          );
          notifyListeners();
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Provider: 권장폐기일 업데이트 실패 - $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 이모지 경로 업데이트
  Future<bool> updateEmojiPath(
    String logId,
    String storageType,
    String newEmojiPath,
  ) async {
    try {
      _setLoading(true);

      // Firestore에서 업데이트
      bool success = await _foodDataService.updateUserLogEmojiPath(
        logId,
        newEmojiPath,
      );

      if (success) {
        // 로컬 상태 업데이트
        List<UserLog> logs = storageType == '냉장'
            ? _refrigeratorLogs
            : _freezerLogs;
        int index = logs.indexWhere((log) => log.id == logId);

        if (index != -1) {
          // UserLog의 copyWith 메서드를 사용하여 새로운 emojiPath로 업데이트
          UserLog updatedLog = logs[index].copyWith(
            emojiPath: newEmojiPath,
            updatedAt: DateTime.now(),
          );
          logs[index] = updatedLog;

          print(
            'Provider: 이모지 경로 업데이트 완료 - ${updatedLog.foodName}: $newEmojiPath',
          );
          notifyListeners();
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Provider: 이모지 경로 업데이트 실패 - $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 카테고리 변경 및 알림 스케줄링
  Future<bool> updateCategory(
    String logId,
    String storageType,
    String newCategory,
  ) async {
    try {
      _setLoading(true);

      // 현재 UserLog 찾기
      List<UserLog> logs = storageType == '냉장'
          ? _refrigeratorLogs
          : _freezerLogs;
      int index = logs.indexWhere((log) => log.id == logId);

      if (index == -1) return false;

      UserLog currentLog = logs[index];
      String oldCategory = currentLog.category;

      // Firestore에서 업데이트
      bool success = await _foodDataService.updateUserLogCategory(
        logId,
        newCategory,
      );

      if (success) {
        // 로컬 상태 업데이트
        UserLog updatedLog = currentLog.copyWith(
          category: newCategory,
          updatedAt: DateTime.now(),
        );

        // 버려야 해요 카테고리 진입 시 날짜 기록
        if (newCategory == '버려야 해요' && oldCategory != '버려야 해요') {
          updatedLog = updatedLog.copyWith(trashEntryDate: DateTime.now());
        }

        logs[index] = updatedLog;

        // 알림 스케줄링
        await _scheduleNotificationsForCategoryChange(updatedLog, oldCategory);

        print(
          'Provider: 카테고리 업데이트 완료 - ${updatedLog.foodName}: $oldCategory -> $newCategory',
        );
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      print('Provider: 카테고리 업데이트 실패 - $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 카테고리 변경에 따른 알림 스케줄링
  Future<void> _scheduleNotificationsForCategoryChange(
    UserLog userLog,
    String oldCategory,
  ) async {
    try {
      // 특정 카테고리 진입 알림
      if (userLog.category == '곧 상해요, 빨리 드세요' ||
          userLog.category == '오늘 먹어야 해요') {
        await _notificationService.scheduleCategoryEntryNotification(userLog);
      }

      // 버려야 해요 카테고리 진입 시 3일 후 알림
      if (userLog.category == '버려야 해요' && oldCategory != '버려야 해요') {
        await _notificationService.scheduleTrashExpiredNotification(userLog);
      }
    } catch (e) {
      print('알림 스케줄링 실패: $e');
    }
  }
}
