import 'package:cloud_firestore/cloud_firestore.dart';

class UserLog {
  final String id;
  final String foodId;
  final String foodName;
  final String category;
  final String storageType; // 냉장 or 냉동 (Firestore: storage_type)
  final String condition; // 통째, 손질, 조리됨
  final DateTime startDate; // 보관 시작일
  final DateTime? expiryDate;
  final bool isSealed; // 밀폐 여부
  final String emojiPath;
  final DateTime updatedAt;
  final DateTime? trashEntryDate; // 버려야 해요 카테고리 진입 날짜
  final String? lastNotifiedCategory; // 마지막으로 알림 발송된 카테고리

  UserLog({
    required this.id,
    required this.foodId,
    required this.foodName,
    required this.category,
    required this.storageType,
    required this.condition,
    required this.startDate,
    this.expiryDate,
    required this.isSealed,
    required this.emojiPath,
    required this.updatedAt,
    this.trashEntryDate,
    this.lastNotifiedCategory,
  });

  // Firestore 문서로부터 UserLog 객체 생성
  // 기존 데이터 호환성을 위해 storedAt도 지원하지만, 새로 저장할 때는 startDate만 사용
  factory UserLog.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserLog(
      id: doc.id,
      foodId: data['foodId'] ?? '',
      foodName: data['food_name'] ?? data['foodName'] ?? '', // Firebase 규칙 필드명 우선
      category: data['category'] ?? '',
      storageType:
          data['storage_type'] ?? data['location'] ?? '', // 기존 location 필드도 지원
      condition: data['prep_state'] ?? data['condition'] ?? '', // Firebase 규칙 필드명 우선
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : (data['storedAt'] != null
              ? (data['storedAt'] as Timestamp).toDate()
              : DateTime.now()), // 기존 데이터 호환성을 위해 storedAt도 지원
      expiryDate: data['expiryDate'] != null
          ? (data['expiryDate'] as Timestamp).toDate()
          : null,
      isSealed: data['sealed'] ?? data['isSealed'] ?? false, // Firebase 규칙 필드명 우선
      emojiPath: data['emojiPath'] ?? '',
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      trashEntryDate: data['trashEntryDate'] != null
          ? (data['trashEntryDate'] as Timestamp).toDate()
          : null,
      lastNotifiedCategory: data['lastNotifiedCategory'] as String?,
    );
  }

  // Firestore 저장용 Map 변환
  // Firebase 규칙과 일치하도록 필드명 사용: food_name, storage_type, prep_state, sealed
  Map<String, dynamic> toFirestore() {
    return {
      'foodId': foodId,
      'food_name': foodName, // Firebase 규칙과 일치
      'foodName': foodName, // 기존 호환성 유지
      'category': category,
      'storage_type': storageType,
      'prep_state': condition, // Firebase 규칙과 일치 (통째, 손질, 조리됨)
      'condition': condition, // 기존 호환성 유지
      'startDate': Timestamp.fromDate(startDate),
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'sealed': isSealed, // Firebase 규칙과 일치
      'isSealed': isSealed, // 기존 호환성 유지
      'emojiPath': emojiPath,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'trashEntryDate': trashEntryDate != null
          ? Timestamp.fromDate(trashEntryDate!)
          : null,
      'lastNotifiedCategory': lastNotifiedCategory,
    };
  }

  // 복사본 생성 (일부 값 변경 시 사용)
  UserLog copyWith({
    String? id,
    String? foodId,
    String? foodName,
    String? category,
    String? storageType,
    String? condition,
    DateTime? startDate,
    DateTime? expiryDate,
    bool? isSealed,
    String? emojiPath,
    DateTime? updatedAt,
    DateTime? trashEntryDate,
    String? lastNotifiedCategory,
  }) {
    return UserLog(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      foodName: foodName ?? this.foodName,
      category: category ?? this.category,
      storageType: storageType ?? this.storageType,
      condition: condition ?? this.condition,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isSealed: isSealed ?? this.isSealed,
      emojiPath: emojiPath ?? this.emojiPath,
      updatedAt: updatedAt ?? this.updatedAt,
      trashEntryDate: trashEntryDate ?? this.trashEntryDate,
      lastNotifiedCategory: lastNotifiedCategory ?? this.lastNotifiedCategory,
    );
  }
}
