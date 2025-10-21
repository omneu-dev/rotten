import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateRequest {
  final String id;
  final String userId;
  final String userNickname;
  final String title;
  final String content;
  final String category;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? url; // Optional external URL for stories

  UpdateRequest({
    required this.id,
    required this.userId,
    required this.userNickname,
    required this.title,
    required this.content,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.url,
  });

  // Firestore에서 데이터를 가져올 때 사용
  factory UpdateRequest.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      print('문서 데이터: $data');

      return UpdateRequest(
        id: doc.id,
        userId: data['userId'] ?? '',
        userNickname: data['userNickname'] ?? '익명 사용자',
        title: data['title'] ?? '',
        content: data['content'] ?? '',
        category: data['category'] ?? '기타',
        status: data['status'] ?? '요청',
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        url: (data['url'] as String?)?.trim().isEmpty == true
            ? null
            : data['url'] as String?,
      );
    } catch (e) {
      print('UpdateRequest.fromFirestore 오류: $e');
      print('문서 ID: ${doc.id}');
      print('문서 데이터: ${doc.data()}');
      rethrow;
    }
  }

  // Firestore에 데이터를 저장할 때 사용
  Map<String, dynamic> toFirestore() {
    final map = {
      'userId': userId,
      'userNickname': userNickname,
      'title': title,
      'content': content,
      'category': category,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
    if (url != null && url!.trim().isNotEmpty) {
      map['url'] = url!;
    }
    return map;
  }

  // 닉네임 생성 (사용자 ID의 마지막 4자리 사용)
  static String generateNickname(String userId) {
    if (userId.length >= 4) {
      return '익명 사용자 ${userId.substring(userId.length - 4)}';
    }
    return '익명 사용자';
  }
}
