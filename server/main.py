"""FastAPI 메인 애플리케이션"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, HttpUrl
from typing import Optional
import uvicorn
import traceback
import logging

from config import settings
from services.recipe_extractor import extract_recipe

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# FastAPI 앱 생성
app = FastAPI(
    title="Rotten Recipe Extractor API",
    description="인스타그램 레시피 추출 및 Firebase 연동 API",
    version="1.0.0"
)

# CORS 설정 (Flutter 앱에서 호출 가능하도록)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 프로덕션에서는 특정 도메인으로 제한 권장
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# 요청 모델
class ExtractRequest(BaseModel):
    url: str
    uid: str


# 응답 모델
class ExtractResponse(BaseModel):
    success: bool
    document_id: Optional[str] = None
    title: Optional[str] = None
    thumbnail: Optional[str] = None
    source_name: Optional[str] = None
    ingredients: Optional[list] = None
    error: Optional[str] = None


@app.get("/")
async def root():
    """헬스 체크 엔드포인트"""
    return {
        "status": "ok",
        "message": "Rotten Recipe Extractor API is running"
    }


@app.post("/extract", response_model=ExtractResponse)
async def extract_recipe_endpoint(request: ExtractRequest):
    """
    레시피 URL에서 정보를 추출하고 Firestore에 저장
    
    Request Body:
        - url: 레시피 URL (string)
        - uid: 사용자 ID (string)
    
    Response:
        - success: 성공 여부 (bool)
        - document_id: 저장된 문서 ID (string, optional)
        - title: 레시피 제목 (string, optional)
        - thumbnail: 썸네일 이미지 URL (string, optional)
        - ingredients: 추출된 재료 리스트 (list, optional)
        - error: 오류 메시지 (string, optional)
    """
    try:
        logger.info(f"레시피 추출 요청: url={request.url}, uid={request.uid}")
        result = await extract_recipe(request.url, request.uid)
        
        if not result.get('success'):
            error_msg = result.get('error', '레시피 추출 중 오류가 발생했습니다.')
            logger.error(f"레시피 추출 실패: {error_msg}")
            raise HTTPException(
                status_code=500,
                detail=error_msg
            )
        
        logger.info(f"레시피 추출 성공: document_id={result.get('document_id')}")
        return ExtractResponse(**result)
        
    except HTTPException:
        raise
    except Exception as e:
        error_trace = traceback.format_exc()
        logger.error(f"서버 오류 발생:\n{error_trace}")
        raise HTTPException(
            status_code=500,
            detail=f"서버 오류: {str(e)}"
        )


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.SERVER_HOST,
        port=settings.SERVER_PORT,
        reload=settings.DEBUG
    )

