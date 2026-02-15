"""OpenGraph.io를 통한 메타데이터 추출 서비스"""
import logging
import httpx
import urllib.parse
from typing import Dict, Optional, Any
from config import settings

logger = logging.getLogger(__name__)


def _log_error_response(resp: httpx.Response, context: str = "") -> None:
    """에러 발생 시 응답 헤더/바디를 로그로 출력 (쿼터 등 확인용)"""
    logger.error(
        f"[OpenGraph {context}] status={resp.status_code}, "
        f"headers={dict(resp.headers)}, "
        f"body={resp.text[:2000] if resp.text else '(empty)'}"
    )


async def _fetch_with_params(url: str, encoded_url: str, full_render: bool, use_proxy: bool) -> Dict[str, Any]:
    """지정된 파라미터로 OpenGraph API 호출"""
    api_key = (settings.OPENGRAPH_API_KEY or "").strip()
    api_url = (
        f"https://opengraph.io/api/1.1/site/{encoded_url}"
        f"?app_id={api_key}&full_render={str(full_render).lower()}&use_proxy={str(use_proxy).lower()}"
    )
    async with httpx.AsyncClient() as client:
        resp = await client.get(api_url, timeout=30.0)
        if resp.status_code != 200:
            _log_error_response(resp, f"full_render={full_render}, use_proxy={use_proxy}")
            resp.raise_for_status()
        return resp.json()


async def fetch_opengraph_data(url: str) -> Dict[str, Any]:
    """
    OpenGraph.io API를 통해 메타데이터 추출.
    403 등 실패 시 full_render/use_proxy=false로 폴백 재시도.
    """
    encoded_url = urllib.parse.quote(url, safe='')

    # 1차: full_render=true, use_proxy=true
    try:
        return await _fetch_with_params(url, encoded_url, full_render=True, use_proxy=True)
    except httpx.HTTPStatusError as e:
        if e.response.status_code in (403, 429):
            logger.warning(
                f"OpenGraph 1차 호출 실패 (status={e.response.status_code}), "
                "full_render=false, use_proxy=false로 폴백 재시도"
            )
            _log_error_response(e.response, "1차 실패")
        try:
            return await _fetch_with_params(url, encoded_url, full_render=False, use_proxy=False)
        except httpx.HTTPStatusError as e2:
            _log_error_response(e2.response, "폴백 실패")
            raise


def _parse_html_metadata(html_content: str) -> Dict[str, Optional[str]]:
    """
    HTML에서 메타 태그 직접 파싱 (간단한 버전)
    
    Args:
        html_content: HTML 문자열
    
    Returns:
        description, og:image, title을 포함한 딕셔너리
    """
    import re
    
    result = {
        'description': None,
        'og:image': None,
        'title': None,
    }
    
    # og:description 추출
    og_desc_match = re.search(r'<meta\s+property=["\']og:description["\']\s+content=["\']([^"\']+)["\']', html_content, re.IGNORECASE)
    if og_desc_match:
        result['description'] = og_desc_match.group(1)
    else:
        # 일반 description 메타 태그 추출
        desc_match = re.search(r'<meta\s+name=["\']description["\']\s+content=["\']([^"\']+)["\']', html_content, re.IGNORECASE)
        if desc_match:
            result['description'] = desc_match.group(1)
    
    # og:image 추출
    og_image_match = re.search(r'<meta\s+property=["\']og:image["\']\s+content=["\']([^"\']+)["\']', html_content, re.IGNORECASE)
    if og_image_match:
        result['og:image'] = og_image_match.group(1)
    
    # og:title 또는 title 추출
    og_title_match = re.search(r'<meta\s+property=["\']og:title["\']\s+content=["\']([^"\']+)["\']', html_content, re.IGNORECASE)
    if og_title_match:
        result['title'] = og_title_match.group(1)
    else:
        title_match = re.search(r'<title>([^<]+)</title>', html_content, re.IGNORECASE)
        if title_match:
            result['title'] = title_match.group(1).strip()
    
    return result

