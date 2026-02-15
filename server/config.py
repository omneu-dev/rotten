import os
from pathlib import Path
from dotenv import load_dotenv
from pydantic_settings import BaseSettings

# 1. .env 파일의 절대 경로를 명확히 지정합니다.
# 현재 config.py 파일이 있는 폴더에서 .env를 찾습니다.
env_path = Path(__file__).parent / ".env"
load_dotenv(dotenv_path=env_path)

class Settings(BaseSettings):
    # 2. 환경 변수에서 값을 읽어옵니다. (공백 제거 - 403 등 오류 방지)
    OPENGRAPH_API_KEY: str = (os.getenv("OPENGRAPH_API_KEY", "") or "").strip()
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    FIREBASE_CREDENTIALS_PATH: str = os.getenv("FIREBASE_CREDENTIALS_PATH", "serviceAccountKey.json")
    
    # 서버 설정
    SERVER_HOST: str = os.getenv("SERVER_HOST", "0.0.0.0")
    SERVER_PORT: int = int(os.getenv("SERVER_PORT", "8000"))
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"

    class Config:
        extra = "allow"

# 설정 객체 생성
settings = Settings()

# 3. 디버깅용: 서버 실행 시 터미널에 키가 로드됐는지 살짝 보여줍니다.
if not settings.GEMINI_API_KEY:
    print("⚠️ 경고: GEMINI_API_KEY를 .env에서 읽어오지 못했습니다!")
else:
    print(f"✅ Gemini 키 로드 완료: {settings.GEMINI_API_KEY[:5]}***")

if not settings.OPENGRAPH_API_KEY:
    print("⚠️ 경고: OPENGRAPH_API_KEY를 .env에서 읽어오지 못했습니다! (선택사항)")
else:
    key_preview = settings.OPENGRAPH_API_KEY[:5] if len(settings.OPENGRAPH_API_KEY) >= 5 else settings.OPENGRAPH_API_KEY
    key_len = len(settings.OPENGRAPH_API_KEY)
    print(f"✅ OpenGraph 키 로드 완료: {key_preview}*** (길이: {key_len}자, 공백 포함 여부 확인용)")

if not settings.FIREBASE_CREDENTIALS_PATH:
    print("⚠️ 경고: FIREBASE_CREDENTIALS_PATH를 .env에서 읽어오지 못했습니다!")
else:
    print(f"✅ Firebase 인증 파일 경로: {settings.FIREBASE_CREDENTIALS_PATH}")

