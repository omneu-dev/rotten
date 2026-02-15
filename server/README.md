# Rotten Recipe Extractor API

인스타그램 레시피 링크에서 정보를 추출하고 Firebase에 저장하는 FastAPI 서버입니다.

## 기능

- OpenGraph.io를 통한 메타데이터 추출 (description, og:image)
- Google Gemini 1.5 Flash를 사용한 재료 추출 및 표준화
- Firebase Firestore에 레시피 데이터 저장
- Flutter 앱과의 CORS 연동 지원

## 설치 및 설정

### 1. 의존성 설치

```bash
pip install -r requirements.txt
```

### 2. 환경 변수 설정

`.env.example` 파일을 참고하여 `.env` 파일을 생성하고 필요한 값들을 설정하세요:

```bash
cp .env.example .env
```

필수 설정:
- `GEMINI_API_KEY`: Google Gemini API 키
- `FIREBASE_CREDENTIALS_PATH`: Firebase 서비스 계정 키 JSON 파일 경로

선택 설정:
- `OPENGRAPH_API_KEY`: OpenGraph.io API 키 (없으면 직접 HTML 파싱)

### 3. Firebase 서비스 계정 키 설정

1. Firebase 콘솔에서 서비스 계정 키를 다운로드합니다.
2. 다운로드한 JSON 파일의 경로를 `.env` 파일의 `FIREBASE_CREDENTIALS_PATH`에 설정합니다.

## 실행

### 개발 모드

```bash
python main.py
```

또는 uvicorn 직접 실행:

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 프로덕션 모드

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

## API 엔드포인트

### POST /extract

레시피 URL에서 정보를 추출하고 Firestore에 저장합니다.

**Request Body:**
```json
{
  "url": "https://www.instagram.com/p/example/",
  "uid": "user_id_here"
}
```

**Response:**
```json
{
  "success": true,
  "document_id": "document_id_here",
  "title": "레시피 제목",
  "thumbnail": "https://example.com/image.jpg",
  "ingredients": [
    {
      "standard_name": "표준화된 재료명",
      "food_id": "food_data_id",
      "category": "카테고리명",
      "amount": 100,
      "unit": "g"
    }
  ]
}
```

## 데이터 구조

### Firestore 저장 경로

```
users/{uid}/recipeLog/{document_id}
```

### 저장되는 데이터 스키마

```json
{
  "original_url": "string",
  "title": "string",
  "thumbnail": "string",
  "ai_extracted_ingredients": [
    {
      "standard_name": "string",
      "food_id": "string",
      "category": "string",
      "amount": number | null,
      "unit": "string"
    }
  ],
  "final_ingredients": [
    // ai_extracted_ingredients와 동일한 구조
  ],
  "status": "planned",
  "created_at": "timestamp"
}
```

## 프로젝트 구조

```
server/
├── main.py                 # FastAPI 메인 애플리케이션
├── config.py              # 환경 변수 및 설정 관리
├── firebase_config.py     # Firebase 초기화 및 Firestore 저장
├── services/
│   ├── opengraph_service.py    # OpenGraph 메타데이터 추출
│   ├── gemini_service.py        # Gemini 재료 추출 및 표준화
│   └── recipe_extractor.py     # 레시피 추출 메인 로직
├── requirements.txt       # Python 의존성
├── .env.example          # 환경 변수 예시
└── README.md             # 이 파일
```

## 주의사항

1. **Firebase 인증**: 서비스 계정 키 파일을 안전하게 관리하세요. Git에 커밋하지 마세요.
2. **API 키 보안**: `.env` 파일을 Git에 커밋하지 마세요. `.gitignore`에 추가하세요.
3. **CORS 설정**: 프로덕션 환경에서는 `allow_origins`를 특정 도메인으로 제한하세요.
4. **Gemini API 할당량**: API 사용량을 모니터링하고 필요시 할당량을 조정하세요.

## 문제 해결

### Firebase 초기화 오류
- 서비스 계정 키 파일 경로가 올바른지 확인하세요.
- Firebase 프로젝트 ID가 올바른지 확인하세요.

### Gemini API 오류
- API 키가 유효한지 확인하세요.
- API 할당량을 확인하세요.

### OpenGraph 데이터 추출 실패
- URL이 접근 가능한지 확인하세요.
- OpenGraph.io API 키를 설정하면 더 안정적으로 작동합니다.

