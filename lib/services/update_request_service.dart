import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/update_request.dart';
import 'user_service.dart';
import 'notification_service.dart';

class UpdateRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();

  // 이전 상태를 추적하기 위한 맵 (알림 중복 방지)
  final Map<String, String> _previousStatusMap = {};

  // 백그라운드 리스너 구독 (앱 전체에서 상태 변경 감지)
  StreamSubscription<QuerySnapshot>? _statusChangeListener;

  // 업데이트 요청 컬렉션 참조
  CollectionReference get _updateRequestsCollection {
    return _firestore.collection('updateRequests');
  }

  // 현재 사용자 ID 가져오기 (비동기)
  Future<String> _getCurrentUserId() async {
    return await _userService.getUserId();
  }

  // 현재 사용자 닉네임 가져오기 (비동기)
  Future<String> _getCurrentUserNickname() async {
    final userId = await _getCurrentUserId();
    return UpdateRequest.generateNickname(userId);
  }

  // 새 업데이트 요청 생성
  Future<String?> createUpdateRequest({
    required String title,
    required String content,
    required String category,
  }) async {
    try {
      final now = DateTime.now();
      final userId = await _getCurrentUserId();
      final userNickname = await _getCurrentUserNickname();

      final updateRequest = UpdateRequest(
        id: '', // Firestore에서 자동 생성
        userId: userId,
        userNickname: userNickname,
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
        .asyncMap((snapshot) async {
          print('Firebase 데이터 수신: ${snapshot.docs.length}개 문서');
          try {
            final requests = snapshot.docs.map((doc) {
              print('문서 처리: ${doc.id}');
              return UpdateRequest.fromFirestore(doc);
            }).toList();

            // 현재 사용자가 작성한 요청만 필터링하여 상태 변경 감지
            final currentUserId = await _getCurrentUserId();
            final myRequests = requests
                .where((r) => r.userId == currentUserId)
                .toList();
            _checkStatusChanges(myRequests);

            return requests;
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
  Future<Stream<List<UpdateRequest>>> getMyUpdateRequests() async {
    final userId = await _getCurrentUserId();
    return _updateRequestsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => UpdateRequest.fromFirestore(doc))
              .toList();

          // 상태 변경 감지 및 알림 발송
          // 비동기로 실행 (스트림이므로 await 없이 실행)
          _checkStatusChanges(requests);

          return requests;
        });
  }

  // 상태 변경 감지 및 알림 발송
  void _checkStatusChanges(List<UpdateRequest> requests) async {
    // 현재 사용자 ID 가져오기
    final currentUserId = await _getCurrentUserId();

    for (final request in requests) {
      // 현재 사용자가 요청 작성자인지 확인
      if (request.userId != currentUserId) {
        // 다른 유저의 요청이면 상태만 저장하고 알림은 발송하지 않음
        _previousStatusMap[request.id] = request.status;
        continue;
      }

      final previousStatus = _previousStatusMap[request.id];

      // 이전 상태가 있고, 상태가 변경된 경우
      if (previousStatus != null && previousStatus != request.status) {
        // FCM 알림 요청 저장 (Cloud Functions가 처리)
        await _requestFCMNotification(
          userId: currentUserId,
          requestId: request.id,
          status: request.status,
        );

        // 요청 작성자(현재 유저)에게만 5초 후 로컬 알림 발송
        _notificationService.showUpdateRequestStatusChangeNotification(
          status: request.status,
        );
        print(
          '상태 변경 감지 및 알림 발송 예약 (5초 후): ${request.id} - $previousStatus -> ${request.status} (작성자: $currentUserId)',
        );
      }

      // 현재 상태 저장 (초기 로딩 시에도 상태를 저장하여 다음 변경 감지 준비)
      _previousStatusMap[request.id] = request.status;
    }
  }

  // 업데이트 요청 상태 변경 (관리자용)
  Future<bool> updateRequestStatus(String id, String status) async {
    try {
      // 이전 상태 확인을 위해 현재 요청 정보 가져오기
      final currentRequest = await getUpdateRequest(id);
      if (currentRequest == null) {
        print('업데이트 요청을 찾을 수 없습니다: $id');
        return false;
      }

      final previousStatus = currentRequest.status;
      final requestUserId = currentRequest.userId;

      // 상태 업데이트
      await _updateRequestsCollection.doc(id).update({
        'status': status,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('업데이트 요청 상태 변경 완료: $id -> $status (이전: $previousStatus)');

      // 상태가 변경되었고, 이전 상태와 다른 경우 알림 발송
      if (previousStatus != status) {
        // 요청 작성자에게 FCM 알림 요청 저장 (Cloud Functions가 처리)
        await _requestFCMNotification(
          userId: requestUserId,
          requestId: id,
          status: status,
        );

        // 현재 사용자가 요청 작성자인 경우 로컬 알림도 발송
        final currentUserId = await _getCurrentUserId();
        if (requestUserId == currentUserId) {
          // 요청 작성자에게 5초 후 로컬 알림 발송
          _notificationService.showUpdateRequestStatusChangeNotification(
            status: status,
          );
          print('소통 창구 로컬 알림 발송 예약 (5초 후): 사용자 $requestUserId, 상태 $status');
        } else {
          print(
            '로컬 알림 발송 건너뜀: 현재 사용자($currentUserId)가 요청 작성자($requestUserId)가 아님',
          );
        }

        // 상태 맵 업데이트 (중복 알림 방지)
        _previousStatusMap[id] = status;
      } else {
        // 상태 맵 업데이트 (알림을 보내지 않더라도 상태 추적)
        _previousStatusMap[id] = status;
      }

      return true;
    } catch (e) {
      print('업데이트 요청 상태 변경 실패: $e');
      return false;
    }
  }

  // 업데이트 요청 삭제 (작성자만 가능)
  Future<bool> deleteUpdateRequest(String id) async {
    try {
      final userId = await _getCurrentUserId();
      final doc = await _updateRequestsCollection.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['userId'] == userId) {
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

  /// FCM 알림 요청 저장 (Cloud Functions가 처리)
  Future<void> _requestFCMNotification({
    required String userId,
    required String requestId,
    required String status,
  }) async {
    try {
      // 알림 요청 문서 생성 (Cloud Functions가 이를 감지하여 FCM 발송)
      await _firestore.collection('notification_requests').add({
        'type': 'update_request_status_change',
        'userId': userId,
        'requestId': requestId,
        'status': status,
        'createdAt': Timestamp.now(),
        'processed': false,
      });
      print('FCM 알림 요청 저장: 사용자 $userId, 요청 $requestId, 상태 $status');
    } catch (e) {
      print('FCM 알림 요청 저장 실패: $e');
    }
  }

  /// 백그라운드 상태 변경 리스너 시작 (앱 전체에서 상태 변경 감지)
  ///
  /// 목적: 앱이 실행 중일 때 항상 현재 유저의 요청 상태 변경을 감지하여 알림 발송
  /// 사용 위치: main.dart (앱 시작 시)
  ///
  /// 동작: Firestore의 실시간 리스너를 구독하여 status가 변경될 때마다 알림 발송
  Future<void> startStatusChangeListener() async {
    try {
      // 기존 리스너가 있으면 취소
      await _statusChangeListener?.cancel();

      final currentUserId = await _getCurrentUserId();
      print('상태 변경 리스너 시작: 사용자 $currentUserId');

      // 현재 유저의 요청만 필터링하여 실시간 감지
      _statusChangeListener = _updateRequestsCollection
          .where('userId', isEqualTo: currentUserId)
          .snapshots()
          .listen((snapshot) async {
            print('상태 변경 감지: ${snapshot.docs.length}개 문서');

            final requests = snapshot.docs
                .map((doc) => UpdateRequest.fromFirestore(doc))
                .toList();

            // 상태 변경 감지 및 알림 발송
            _checkStatusChanges(requests);
          });

      print('상태 변경 리스너 구독 완료');
    } catch (e) {
      print('상태 변경 리스너 시작 실패: $e');
    }
  }

  /// 백그라운드 상태 변경 리스너 중지
  Future<void> stopStatusChangeListener() async {
    await _statusChangeListener?.cancel();
    _statusChangeListener = null;
    print('상태 변경 리스너 중지');
  }

  // Firebase 연결 테스트
  Future<void> testConnection() async {
    try {
      print('Firebase 연결 테스트 시작...');
      final userId = await _getCurrentUserId();
      print('현재 사용자: $userId');

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
