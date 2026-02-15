import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  final String id;
  final String name;
  final String category;
  final String emojiPath;
  final Map<String, int> shelfLifeMap;
  final String? aiStorageTips;
  final DateTime? updatedAt;

  Food({
    required this.id,
    required this.name,
    required this.category,
    required this.emojiPath,
    required this.shelfLifeMap,
    this.aiStorageTips,
    this.updatedAt,
  });

  // JSON에서 Food 객체 생성
  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      emojiPath: json['emojiPath'] as String,
      shelfLifeMap: Map<String, int>.from(json['shelfLifeMap'] as Map),
      aiStorageTips: json['aiStorageTips'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.now() // _serverTimestamp는 현재 시간으로 설정
          : null,
    );
  }

  // Firestore에 저장할 때 사용할 Map 변환
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'emojiPath': emojiPath,
      'shelfLifeMap': shelfLifeMap,
      'aiStorageTips': aiStorageTips,
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
    };
  }

  // Firestore에서 읽어올 때 사용
  factory Food.fromFirestore(Map<String, dynamic> data) {
    return Food(
      id: data['id'] as String,
      name: data['name'] as String,
      category: data['category'] as String,
      emojiPath: data['emojiPath'] as String,
      shelfLifeMap: Map<String, int>.from(data['shelfLifeMap'] as Map),
      aiStorageTips: data['aiStorageTips'] as String?,
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  // JSON 파일 형식으로 변환 (food_data_ko_251215.json 형식)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'emojiPath': emojiPath,
      if (aiStorageTips != null) 'aiStorageTips': aiStorageTips,
      'shelfLifeMap': shelfLifeMap,
      'updatedAt': {'_serverTimestamp': true},
    };
  }
}
