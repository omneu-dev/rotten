class Food {
  final String id;
  final String name;
  final String category;
  final String emojiPath;
  final Map<String, int> shelfLifeMap;
  final DateTime? updatedAt;

  Food({
    required this.id,
    required this.name,
    required this.category,
    required this.emojiPath,
    required this.shelfLifeMap,
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
      'updatedAt': updatedAt ?? DateTime.now(),
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
      updatedAt: data['updatedAt']?.toDate(),
    );
  }
}
