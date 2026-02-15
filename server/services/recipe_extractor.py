"""레시피 추출 메인 로직"""
from typing import Dict, List, Any
import logging
from urllib.parse import urlparse
from services.opengraph_service import fetch_opengraph_data
from services.gemini_service import extract_ingredients_with_gemini
from firebase_config import get_food_data, save_recipe_to_firestore

logger = logging.getLogger(__name__)


async def extract_recipe(url: str, uid: str) -> Dict[str, Any]:
    """
    레시피 URL에서 정보를 추출하고 Firestore에 저장
    
    Args:
        url: 레시피 URL
        uid: 사용자 ID
    
    Returns:
        저장된 문서 ID와 추출된 재료 리스트를 포함한 딕셔너리
    """
    # OpenGraph 실패 시 사용할 더미 데이터 (프론트엔드 디자인 작업용)
    DUMMY_METADATA = {
        'hybridGraph': {
            'title': '닭다리살 배추 우동',
            'description': '',
            'image': 'https://images.unsplash.com/photo-1569718212165-3a2454018c15?w=200',
            'site_name': 'Instagram',
        },
        'openGraph': {
            'title': '닭다리살 배추 우동',
            'image': 'https://images.unsplash.com/photo-1569718212165-3a2454018c15?w=200',
            'site_name': 'instagram.com',
        },
        'title': '닭다리살 배추 우동',
        'og:image': 'https://images.unsplash.com/photo-1569718212165-3a2454018c15?w=200',
        'site_name': 'instagram.com',
    }

    try:
        # 1. OpenGraph를 통해 메타데이터 추출
        logger.info(f"1단계: OpenGraph 메타데이터 추출 시작 - {url}")
        try:
            metadata = await fetch_opengraph_data(url)
        except Exception as og_error:
            logger.warning(
                f"OpenGraph 호출 실패, 더미 데이터로 대체합니다. (디자인 작업용) error={og_error}"
            )
            metadata = DUMMY_METADATA
        logger.info(
            f"메타데이터 추출 완료: raw_title={metadata.get('title')}, "
            f"has_hybridGraph={'hybridGraph' in metadata}, "
            f"has_openGraph={'openGraph' in metadata}"
        )
        
        # OpenGraph 응답 구조에 따라 title을 우선순위대로 조회
        # 인스타그램의 경우 hybridGraph 내부에 본문이 들어오는 경우가 많음
        hybrid = metadata.get('hybridGraph') or {}
        open_graph = metadata.get('openGraph') or {}
        title = (
            hybrid.get('title')
            or open_graph.get('title')
            or metadata.get('title')
            or '레시피'
        )
        logger.info(f"결정된 타이틀: {title}")
        # OpenGraph 응답 구조에 따라 thumbnail(이미지 URL)을 우선순위대로 조회
        # hybridGraph['image'] 또는 openGraph['image'] 사용, 없으면 루트 og:image
        thumbnail = (
            hybrid.get('image')
            or open_graph.get('image')
            or metadata.get('og:image')
            or metadata.get('image')
            or ''
        )
        if thumbnail:
            logger.info(f"썸네일 이미지 URL 추출 완료: {thumbnail[:80]}...")
        else:
            logger.info("썸네일 이미지 URL을 찾지 못했습니다. 빈 문자열로 저장합니다.")
        # source_name: site_name 또는 URL에서 도메인 추출
        source_name = (
            hybrid.get('site_name')
            or open_graph.get('site_name')
            or metadata.get('site_name')
            or metadata.get('og:site_name')
        )
        if not source_name:
            try:
                parsed = urlparse(url)
                source_name = parsed.netloc or parsed.path or ''
                if source_name.startswith('www.'):
                    source_name = source_name[4:]
            except Exception:
                source_name = ''
        source_name = source_name or ''
        logger.info(f"source_name: {source_name}")
        # OpenGraph 응답 구조에 따라 description을 우선순위대로 조회
        description = (
            metadata.get('hybridGraph', {}).get('description')
            or metadata.get('openGraph', {}).get('description')
            or metadata.get('description')
            or ''
        )
        # 인스타그램 본문이 title에 몰려 있는 경우를 대비해 fallback 적용
        if not description and title:
            logger.info("description이 비어 있어 title 내용을 분석 본문으로 사용합니다.")
            description = title
        
        # 2. foodData 컬렉션에서 표준 음식 데이터 가져오기
        logger.info("2단계: foodData 컬렉션에서 음식 데이터 가져오기")
        food_data = get_food_data()
        logger.info(f"foodData 로드 완료: {len(food_data)}개 항목")
        
        # 3. Gemini를 사용하여 재료 추출 및 표준화
        logger.info("3단계: Gemini를 통한 재료 추출 및 표준화")
        ai_extracted_ingredients = []
        if description:
            ai_extracted_ingredients = extract_ingredients_with_gemini(
                description,
                food_data
            )
            logger.info(f"재료 추출 완료: {len(ai_extracted_ingredients)}개 재료")
        else:
            logger.warning("description이 없어 재료 추출을 건너뜁니다.")
        
        # 4. Firestore에 저장
        logger.info("4단계: Firestore에 레시피 저장")
        doc_id = save_recipe_to_firestore(
            uid=uid,
            original_url=url,
            title=title,
            thumbnail=thumbnail,
            source_name=source_name,
            ai_extracted_ingredients=ai_extracted_ingredients,
            final_ingredients=None  # 초기값은 ai_extracted_ingredients와 동일
        )
        logger.info(f"Firestore 저장 완료: document_id={doc_id}")
        
        return {
            'success': True,
            'document_id': doc_id,
            'title': title,
            'thumbnail': thumbnail,
            'source_name': source_name,
            'ingredients': ai_extracted_ingredients,
        }
        
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        logger.error(f"레시피 추출 중 오류 발생:\n{error_trace}")
        return {
            'success': False,
            'error': str(e),
        }

