import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/update_request.dart';

class UpdateRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 업데이트 요청 컬렉션 참조
  CollectionReference get _updateRequestsCollection {
    return _firestore.collection('updateRequests');
  }

  // 현재 사용자 ID 가져오기
  String get _currentUserId {
    return _auth.currentUser?.uid ?? 'anonymous';
  }

  // 현재 사용자 닉네임 가져오기
  String get _currentUserNickname {
    return UpdateRequest.generateNickname(_currentUserId);
  }

  // 새 업데이트 요청 생성
  Future<String?> createUpdateRequest({
    required String title,
    required String content,
    required String category,
  }) async {
    try {
      final now = DateTime.now();

      final updateRequest = UpdateRequest(
        id: '', // Firestore에서 자동 생성
        userId: _currentUserId,
        userNickname: _currentUserNickname,
        title: title,
        content: content,
        category: category,
        status: '요청',
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _updateRequestsCollection.add(
        updateRequest.toFirestore(),
      );

      print('업데이트 요청 생성 완료: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('업데이트 요청 생성 실패: $e');
      return null;
    }
  }

  // 모든 업데이트 요청 목록 가져오기 (최신순)
  Stream<List<UpdateRequest>> getUpdateRequests() {
    print('Firebase 연결 시도: updateRequests 컬렉션');
    return _updateRequestsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Firebase 데이터 수신: ${snapshot.docs.length}개 문서');
          try {
            return snapshot.docs.map((doc) {
              print('문서 처리: ${doc.id}');
              return UpdateRequest.fromFirestore(doc);
            }).toList();
          } catch (e) {
            print('문서 변환 오류: $e');
            rethrow;
          }
        });
  }

  // 특정 업데이트 요청 가져오기
  Future<UpdateRequest?> getUpdateRequest(String id) async {
    try {
      final doc = await _updateRequestsCollection.doc(id).get();
      if (doc.exists) {
        return UpdateRequest.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('업데이트 요청 조회 실패: $e');
      return null;
    }
  }

  // 내가 작성한 업데이트 요청 목록 가져오기
  Stream<List<UpdateRequest>> getMyUpdateRequests() {
    return _updateRequestsCollection
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UpdateRequest.fromFirestore(doc))
              .toList();
        });
  }

  // 업데이트 요청 상태 변경 (관리자용)
  Future<bool> updateRequestStatus(String id, String status) async {
    try {
      await _updateRequestsCollection.doc(id).update({
        'status': status,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('업데이트 요청 상태 변경 완료: $id -> $status');
      return true;
    } catch (e) {
      print('업데이트 요청 상태 변경 실패: $e');
      return false;
    }
  }

  // 업데이트 요청 삭제 (작성자만 가능)
  Future<bool> deleteUpdateRequest(String id) async {
    try {
      final doc = await _updateRequestsCollection.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['userId'] == _currentUserId) {
          await _updateRequestsCollection.doc(id).delete();
          print('업데이트 요청 삭제 완료: $id');
          return true;
        } else {
          print('권한 없음: 다른 사용자의 요청을 삭제할 수 없습니다');
          return false;
        }
      }
      return false;
    } catch (e) {
      print('업데이트 요청 삭제 실패: $e');
      return false;
    }
  }

  // 카테고리별 통계
  Future<Map<String, int>> getCategoryStats() async {
    try {
      final snapshot = await _updateRequestsCollection.get();
      Map<String, int> stats = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] ?? '기타';
        stats[category] = (stats[category] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('카테고리 통계 조회 실패: $e');
      return {};
    }
  }

  // Firebase 연결 테스트
  Future<void> testConnection() async {
    try {
      print('Firebase 연결 테스트 시작...');
      print('현재 사용자: ${_auth.currentUser?.uid ?? 'anonymous'}');

      final snapshot = await _updateRequestsCollection.limit(1).get();
      print('Firebase 연결 성공! 문서 개수: ${snapshot.docs.length}');

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        print('첫 번째 문서: ${doc.id}');
        print('문서 데이터: ${doc.data()}');
      }
    } catch (e) {
      print('Firebase 연결 테스트 실패: $e');
    }
  }
}
