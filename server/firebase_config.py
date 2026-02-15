"""Firebase Admin SDK 초기화 및 Firestore 저장 모듈"""
import os
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime
from firebase_admin import initialize_app, credentials, firestore
from firebase_admin.exceptions import FirebaseError
import firebase_admin

from config import settings


# Firebase 앱 초기화 여부 추적
_firebase_app = None


def initialize_firebase():
    """Firebase Admin SDK 초기화"""
    global _firebase_app
    
    if _firebase_app is not None:
        return _firebase_app
    
    try:
        # 서비스 계정 키 파일 경로 확인
        cred_path = settings.FIREBASE_CREDENTIALS_PATH
        
        # 상대 경로인 경우 현재 파일 기준으로 절대 경로 변환
        if cred_path and not os.path.isabs(cred_path):
            cred_path = str(Path(__file__).parent / cred_path)
        
        if cred_path and os.path.exists(cred_path):
            # 서비스 계정 키 파일 사용
            cred = credentials.Certificate(cred_path)
            _firebase_app = initialize_app(cred)
        else:
            # 환경 변수에서 직접 인증 정보 가져오기 (또는 기본 인증 사용)
            # 프로덕션에서는 서비스 계정 키 파일 사용 권장
            try:
                _firebase_app = firebase_admin.get_app()
            except ValueError:
                # 앱이 초기화되지 않은 경우
                _firebase_app = initialize_app()
        
        return _firebase_app
    except Exception as e:
        raise RuntimeError(f"Firebase 초기화 실패: {str(e)}")


def get_firestore_client():
    """Firestore 클라이언트 반환"""
    initialize_firebase()
    return firestore.client()


def get_food_data() -> List[Dict[str, Any]]:
    """Firestore의 foodData 컬렉션에서 모든 음식 데이터 가져오기"""
    db = get_firestore_client()
    
    try:
        food_data_ref = db.collection('foodData')
        docs = food_data_ref.stream()
        
        food_list = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            food_list.append(data)
        
        return food_list
    except Exception as e:
        raise RuntimeError(f"foodData 조회 실패: {str(e)}")


def save_recipe_to_firestore(
    uid: str,
    original_url: str,
    title: str,
    thumbnail: Optional[str],
    source_name: str,
    ai_extracted_ingredients: List[Dict[str, Any]],
    final_ingredients: Optional[List[Dict[str, Any]]] = None
) -> str:
    """
    레시피 데이터를 Firestore에 저장
    
    Args:
        uid: 사용자 ID
        original_url: 원본 레시피 URL
        title: 레시피 제목
        thumbnail: 썸네일 이미지 URL
        ai_extracted_ingredients: AI가 추출한 재료 리스트
        final_ingredients: 최종 확인된 재료 리스트 (없으면 ai_extracted_ingredients와 동일)
    
    Returns:
        저장된 문서 ID
    """
    db = get_firestore_client()
    
    # final_ingredients가 없으면 ai_extracted_ingredients와 동일하게 설정
    if final_ingredients is None:
        final_ingredients = ai_extracted_ingredients.copy()
    
    # 저장할 데이터 구조 (이미지가 없으면 빈 문자열 또는 None)
    recipe_data = {
        'original_url': original_url,
        'title': title,
        'thumbnail': thumbnail if thumbnail else '',
        'source_name': source_name or '',
        'ai_extracted_ingredients': ai_extracted_ingredients,
        'final_ingredients': final_ingredients,
        'status': 'planned',
        'created_at': firestore.SERVER_TIMESTAMP,
    }
    
    try:
        # users/{uid}/recipeLog 경로에 저장
        doc_ref = db.collection('users').document(uid).collection('recipeLog').add(recipe_data)
        # add()는 (timestamp, DocumentReference) 튜플을 반환
        return doc_ref[1].id  # 문서 ID 반환
    except Exception as e:
        raise RuntimeError(f"Firestore 저장 실패: {str(e)}")

