import 'package:shared_preferences/shared_preferences.dart';

enum SortType {
  createdAt, // 생성일 (추가된 순서)
  remainingDays, // 남은 보관 기간
}

class SortPreferenceService {
  static const String _sortTypeKey = 'sort_type';

  /// 정렬 타입 저장 (냉장고와 냉동고 공통)
  static Future<void> saveSortType(SortType sortType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortTypeKey, sortType.name);
  }

  /// 정렬 타입 로드 (냉장고와 냉동고 공통)
  static Future<SortType> loadSortType() async {
    final prefs = await SharedPreferences.getInstance();
    final sortTypeName = prefs.getString(_sortTypeKey);
    if (sortTypeName == null) {
      return SortType.createdAt; // 기본값: 생성일
    }
    return SortType.values.firstWhere(
      (e) => e.name == sortTypeName,
      orElse: () => SortType.createdAt,
    );
  }

  // 하위 호환성을 위한 메서드들 (deprecated)
  @Deprecated('Use saveSortType instead')
  static Future<void> saveRefrigeratorSortType(SortType sortType) async {
    return saveSortType(sortType);
  }

  @Deprecated('Use loadSortType instead')
  static Future<SortType> loadRefrigeratorSortType() async {
    return loadSortType();
  }

  @Deprecated('Use saveSortType instead')
  static Future<void> saveFreezerSortType(SortType sortType) async {
    return saveSortType(sortType);
  }

  @Deprecated('Use loadSortType instead')
  static Future<SortType> loadFreezerSortType() async {
    return loadSortType();
  }
}
