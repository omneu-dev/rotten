import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 사용자 ID 관리 서비스
/// - 디바이스 기반 익명 사용자 지원
/// - 소셜 로그인 계정 전환 지원
/// - 데이터 마이그레이션 지원
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _userIdKey = 'device_user_id';
  static const String _isLinkedKey = 'is_account_linked';

  /// 운영자 UID 리스트 (Firebase 규칙의 isAdminUid()와 동일하게 유지)
  /// 이 UID로 로그인한 사용자는 자동으로 개발 모드 기능에 접근 가능
  static const List<String> _adminUids = [
    'V8bVSjONyVdach5ImbHP68rzH0e2',
    'ZOh6e4275MMEKs2Q2a1AUmh7zwB3',
    // 추가 운영자 UID를 여기에 추가
  ];

  /// 개발 모드 활성화 여부 (현재 로그인한 사용자가 운영자인지 자동 체크)
  /// 운영자 UID로 로그인한 경우 true, 그 외에는 false
  static bool get isDevelopmentMode {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    return _adminUids.contains(currentUser.uid);
  }

  /// 운영자 UID 목록 가져오기
  static List<String> get adminUids => _adminUids;

  /// 특정 사용자 ID가 운영자인지 확인
  static bool isAdmin(String userId) {
    return _adminUids.contains(userId);
  }

  String? _cachedUserId;
  bool _isInitialized = false;

  /// 현재 사용자 ID 가져오기
  Future<String> getUserId() async {
    // 캐시된 값이 있으면 반환
    if (_cachedUserId != null) return _cachedUserId!;

    await _ensureInitialized();
    return _cachedUserId!;
  }

  /// 초기화 (앱 시작 시 호출)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. 소셜 로그인된 계정이 있는지 확인
      final currentUser = _auth.currentUser;
      final isLinked = prefs.getBool(_isLinkedKey) ?? false;

      if (currentUser != null && !currentUser.isAnonymous && isLinked) {
        // 소셜 로그인된 계정 사용
        _cachedUserId = currentUser.uid;
        // 💡 'user 문서'가 없는 경우를 대비
        await prefs.setString(
          _userIdKey,
          _cachedUserId!,
        ); // 저장된 UID를 SharedPreferences에 저장
        await _createUserDocument(_cachedUserId!); // 문서 확인 및 버전 갱신

        print('UserService: 소셜 로그인 계정 사용 - $_cachedUserId');
      } else {
        // 2. SharedPreferences에서 디바이스 UID 확인
        String? savedUid = prefs.getString(_userIdKey);

        if (savedUid != null && savedUid.isNotEmpty) {
          // 저장된 디바이스 UID 사용
          _cachedUserId = savedUid;
          // 💡 저장된 UID가 있어도 'user 문서'가 없는 유령 유저일 수 있으므로 체크!
          await prefs.setString(
            _userIdKey,
            _cachedUserId!,
          ); // 저장된 UID를 SharedPreferences에 저장
          await _createUserDocument(_cachedUserId!); // 문서 확인 및 버전 갱신

          print('UserService: 저장된 디바이스 UID 사용 - $_cachedUserId');
        } else {
          // 3. 새로운 익명 사용자 생성
          await _auth.signInAnonymously();
          _cachedUserId = _auth.currentUser?.uid ?? _generateFallbackUid();
          await prefs.setString(_userIdKey, _cachedUserId!);
          await _createUserDocument(_cachedUserId!);
        }
      }

      // 개발 모드 여부 확인 및 로그
      if (currentUser != null) {
        if (isDevelopmentMode) {
          print('UserService: 개발 모드 활성화 - 운영자 UID: ${currentUser.uid}');
        } else {
          print('UserService: 일반 사용자 모드 - UID: ${currentUser.uid}');
        }
      }

      _isInitialized = true;
    } catch (e) {
      print('UserService 초기화 실패: $e');
      // 폴백: 임시 UID 생성
      _cachedUserId = _generateFallbackUid();
      _isInitialized = true;
    }
  }

  /// 초기화 보장
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// 폴백 UID 생성 (Firebase 실패 시)
  String _generateFallbackUid() {
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Firestore에 사용자 문서 초기화
  Future<void> _createUserDocument(String userId) async {
    if (userId.isEmpty || userId.startsWith('device_')) return;

    try {
      // 1. 현재 앱의 버전 정보 가져오기
      final packageInfo = await PackageInfo.fromPlatform();
      final String currentAppVersion = packageInfo.version;

      final userDocRef = _firestore.collection('users').doc(userId);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        // [신규 생성] 첫 설치 시 정보 기록
        await userDocRef.set({
          'uid': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'initialVersion': currentAppVersion, // 첫 설치 버전
          'currentVersion': currentAppVersion, // 현재 버전
          'proEarlyBird': false,
        }, SetOptions(merge: true));
        print('UserService: 신규 유저 문서 생성 ($currentAppVersion)');
      } else {
        // [기존 유저] 접속 시마다 현재 버전과 접속 시간 갱신
        await userDocRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'currentVersion': currentAppVersion, // 업데이트 시 자동 갱신됨
        });
        print('UserService: 기존 유저 정보 업데이트 ($currentAppVersion)');
      }
    } catch (e) {
      print('UserService: 사용자 문서 처리 실패 - $e');
    }
  }

  /// 소셜 로그인 계정으로 전환 (데이터 마이그레이션 포함)
  ///
  /// [credential]: 소셜 로그인 자격 증명 (Google, Apple 등)
  ///
  /// 반환: 성공 여부
  Future<bool> linkToSocialAccount(AuthCredential credential) async {
    try {
      await _ensureInitialized();
      final oldUserId = _cachedUserId!;

      // 1. 현재 익명 계정에 소셜 계정 연결
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('UserService: 현재 사용자 없음');
        return false;
      }

      UserCredential userCredential;

      try {
        // 익명 계정에 소셜 계정 연결 시도
        userCredential = await currentUser.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          // 이미 다른 계정에 연결된 소셜 계정인 경우
          // 해당 소셜 계정으로 로그인하고 데이터 마이그레이션
          userCredential = await _auth.signInWithCredential(credential);

          final newUserId = userCredential.user!.uid;

          // 기존 디바이스 데이터를 새 계정으로 마이그레이션
          await _migrateUserData(oldUserId, newUserId);
        } else {
          rethrow;
        }
      }

      final newUserId = userCredential.user!.uid;

      // 2. 데이터 마이그레이션 (같은 UID가 아닌 경우)
      if (oldUserId != newUserId) {
        await _migrateUserData(oldUserId, newUserId);
      }

      // 3. SharedPreferences 업데이트
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, newUserId);
      await prefs.setBool(_isLinkedKey, true);

      // 4. 캐시 업데이트
      _cachedUserId = newUserId;

      print('UserService: 소셜 계정 연결 완료 - $oldUserId → $newUserId');
      return true;
    } catch (e) {
      print('UserService: 소셜 계정 연결 실패 - $e');
      return false;
    }
  }

  /// 사용자 데이터 마이그레이션
  Future<void> _migrateUserData(String oldUserId, String newUserId) async {
    try {
      print('UserService: 데이터 마이그레이션 시작 - $oldUserId → $newUserId');

      // 1. 기존 사용자의 foodLog 데이터 가져오기
      final oldFoodLogs = await _firestore
          .collection('users')
          .doc(oldUserId)
          .collection('foodLog')
          .get();

      // 2. 새 사용자에게 데이터 복사
      final batch = _firestore.batch();

      for (var doc in oldFoodLogs.docs) {
        final newDocRef = _firestore
            .collection('users')
            .doc(newUserId)
            .collection('foodLog')
            .doc(doc.id);
        batch.set(newDocRef, doc.data());
      }

      // 3. 기존 사용자 문서의 필드 복사 (proEarlyBird 등)
      final oldUserDoc = await _firestore
          .collection('users')
          .doc(oldUserId)
          .get();

      if (oldUserDoc.exists && oldUserDoc.data() != null) {
        final userData = oldUserDoc.data()!;
        // foodLog 컬렉션 외의 필드만 복사
        final newUserDocRef = _firestore.collection('users').doc(newUserId);
        batch.set(newUserDocRef, userData, SetOptions(merge: true));
      }

      await batch.commit();

      // 4. 기존 데이터 삭제 (선택적)
      // await _deleteOldUserData(oldUserId);

      print('UserService: 데이터 마이그레이션 완료 - ${oldFoodLogs.docs.length}개 문서');
    } catch (e) {
      print('UserService: 데이터 마이그레이션 실패 - $e');
      rethrow;
    }
  }

  /// 로그아웃 (디바이스 UID로 복귀)
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 소셜 계정 연결 해제
      await prefs.setBool(_isLinkedKey, false);

      // Firebase 로그아웃
      await _auth.signOut();

      // 익명 로그인으로 복귀
      await _auth.signInAnonymously();

      // 디바이스 UID 유지 (데이터 보존)
      final deviceUid = prefs.getString(_userIdKey);
      if (deviceUid != null) {
        _cachedUserId = deviceUid;
        // 저장된 UID를 SharedPreferences에 저장
        await prefs.setString(_userIdKey, _cachedUserId!);
        // 사용자 문서 확인 및 버전 갱신
        await _createUserDocument(_cachedUserId!);
      } else {
        _cachedUserId = _auth.currentUser?.uid;
        if (_cachedUserId != null) {
          await prefs.setString(_userIdKey, _cachedUserId!);
          // 새 익명 사용자 문서 생성
          await _createUserDocument(_cachedUserId!);
        }
      }

      print('UserService: 로그아웃 완료 - 디바이스 UID: $_cachedUserId');
    } catch (e) {
      print('UserService: 로그아웃 실패 - $e');
    }
  }

  /// 현재 소셜 계정 연결 여부
  Future<bool> isLinkedToSocialAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLinkedKey) ?? false;
  }

  /// 현재 사용자가 익명인지 확인
  bool get isAnonymous {
    final currentUser = _auth.currentUser;
    return currentUser == null || currentUser.isAnonymous;
  }

  /// 현재 로그인된 이메일 (소셜 로그인 시)
  String? get currentEmail {
    return _auth.currentUser?.email;
  }

  /// 현재 로그인된 사용자 이름 (소셜 로그인 시)
  String? get currentDisplayName {
    return _auth.currentUser?.displayName;
  }
}
