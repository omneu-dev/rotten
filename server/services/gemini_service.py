"""Google Gemini API를 통한 텍스트 분석 및 재료 추출 서비스"""
import json
import re
from typing import List, Dict, Any

import httpx
import difflib

from config import settings
from firebase_config import get_food_data

# Gemini v1 REST 엔드포인트 및 모델 후보 설정
GEMINI_API_ENDPOINT = "https://generativelanguage.googleapis.com"

# v1 REST에서 사용할 모델 후보들 (우선순위 순)
# REST 호출 시에는 전체 리소스 이름인 "models/..." 형식을 사용합니다.
# AI Studio에서 확인한 프로젝트 지원 모델: Gemini 2.5 계열 (Flash 전용)
MODEL_CANDIDATES = [
    "models/gemini-2.5-flash",
    #"models/gemini-pro",
]


def _call_gemini_v1(prompt: str) -> str:
    """
    Gemini v1 REST API를 직접 호출하여 텍스트 응답을 반환합니다.

    여러 모델 후보를 순차적으로 시도하며, 첫 번째 성공한 모델의 응답을 반환합니다.
    """
    last_error = None

    # generation 설정: JSON 응답이 중간에 끊기지 않도록 토큰 수를 2048로 증가, 일관성 향상을 위해 temperature 낮춤
    generation_config = {
        "maxOutputTokens": 2048,
        "temperature": 0.1,
    }

    for model_name in MODEL_CANDIDATES:
        url = f"{GEMINI_API_ENDPOINT}/v1/{model_name}:generateContent"
        params = {"key": settings.GEMINI_API_KEY}
        # body 구조: generationConfig를 최상단에 명시적으로 배치
        body = {
            "generationConfig": generation_config,
            "contents": [
                {
                    "parts": [
                        {"text": prompt}
                    ]
                }
            ],
        }

        try:
            # 인스타그램 링크의 텍스트 길이를 고려해도 15초 이내로 응답받도록 타임아웃 제한
            resp = httpx.post(url, params=params, json=body, timeout=15.0)

            if resp.status_code == 404:
                # 모델이 해당 버전에서 지원되지 않는 경우
                print(
                    f"[Gemini 404] url={url}, status=404, "
                    f"model_name={model_name}, body={resp.text}"
                )
                last_error = resp.text
                continue

            resp.raise_for_status()
            data = resp.json()

            # v1 응답 구조에서 첫 번째 candidate의 텍스트 추출
            candidates = data.get("candidates") or []
            if not candidates:
                print(f"[Gemini Warning] candidates 비어 있음: model_name={model_name}, data={data}")
                last_error = "no candidates"
                continue

            content = candidates[0].get("content") or {}
            parts = content.get("parts") or []
            if not parts or "text" not in parts[0]:
                print(f"[Gemini Warning] parts 비어 있거나 text 없음: model_name={model_name}, data={data}")
                last_error = "no text in parts"
                continue

            text = parts[0]["text"]
            print(
                f"[Gemini] 모델 호출 성공: model_name={model_name}, "
                f"endpoint={GEMINI_API_ENDPOINT}/v1"
            )
            return text

        except httpx.TimeoutException as e:
            last_error = str(e)
            print(f"[Gemini Timeout] url={url}, model_name={model_name}, error={e}")
            # 타임아웃 시 바로 다음 후보로 넘어가거나, 후보가 더 없으면 빠르게 종료
            continue
        except httpx.HTTPStatusError as e:
            last_error = str(e)
            print(
                f"[Gemini HTTP Error] url={url}, model_name={model_name}, error={e}, "
                f"response={getattr(e, 'response', None)}"
            )
            continue
        except Exception as e:
            last_error = str(e)
            print(
                f"[Gemini Error] url={url}, model_name={model_name}, error={e}"
            )
            continue

    print(
        f"[Gemini Fatal] 모든 모델 후보 호출 실패. "
        f"endpoint={GEMINI_API_ENDPOINT}/v1, "
        f"candidates={MODEL_CANDIDATES}, "
        f"last_error={last_error}"
    )
    return ""


def extract_ingredients_with_gemini(
    description: str,
    food_data: List[Dict[str, Any]]
) -> List[Dict[str, Any]]:
    """
    Gemini를 사용하여 텍스트에서 재료를 추출하고,
    Python에서 foodData와 매칭하여 표준화된 재료 리스트를 반환합니다.

    Args:
        description: 분석할 텍스트 (레시피 설명 또는 제목)
        food_data: Firebase의 foodData 컬렉션 데이터

    Returns:
        표준화된 재료 리스트 (standard_name, food_id, category, amount, unit 포함)
    """
    # 프롬프트 축소: Gemini에게는 재료명/수량만 추출하도록만 요청
    # foodData 전체 리스트는 보내지 않고, 매칭은 Python 코드에서 후처리로 수행
    prompt = f"""다음은 인스타그램 레시피 본문입니다. 이 텍스트에서 '재료명'과 '수량' 정보를 JSON 배열로만 추출해 주세요.

텍스트:
\"\"\"{description}\"\"\"

작업 지시사항:
1. 텍스트 속에 등장하는 식재료(예: 사과, 루꼴라, 피스타치오 등)를 찾아주세요.
2. 각 재료에 대해 다음 정보를 JSON 객체로 작성하세요:
   - name: 재료 이름 (텍스트에 나온 그대로, 예: "사과대추", "루꼴라")
   - amount: 수량 또는 대략적인 개수 (숫자, 없으면 null)
   - unit: 단위 (예: "개", "컵", "큰술", "g", "ml" 등, 없으면 빈 문자열)
3. 계량 정보가 전혀 없으면 amount는 null, unit은 ""(빈 문자열)로 두세요.
4. 최종 응답은 아래와 같은 JSON 배열 형식이어야 합니다:

[
  {{
    "name": "사과대추",
    "amount": 5,
    "unit": "개"
  }},
  {{
    "name": "루꼴라",
    "amount": null,
    "unit": ""
  }}
]

재료가 전혀 없다면 빈 배열 []만 반환하세요.

중요: 마크다운 코드 블록(```json ... ```)을 절대 사용하지 말고, 순수 JSON 배열만 출력하세요.
설명이나 자연어 문장도 포함하지 말고, 오직 JSON 배열만 반환하세요.

경고: 중간에 응답을 끊지 말고 반드시 JSON 배열을 완성하세요. 모든 재료 정보를 포함한 완전한 JSON 배열을 반환해야 합니다.

CRITICAL: 절대 중간에 끊지 말고 마지막 대괄호 ]를 닫을 때까지 응답하세요. / Never cut off the response in the middle. You must complete the JSON array by closing the final bracket ]."""

    try:
        # Gemini v1 REST API 직접 호출
        response_text = _call_gemini_v1(prompt).strip()

        if not response_text:
            # 호출 실패 또는 비어 있는 응답
            return []

        # JSON 파싱 시도
        # 마크다운 코드 블록 제거 (```json ... ``` 형식)
        if response_text.startswith("```"):
            lines = response_text.split("\n")
            response_text = "\n".join(lines[1:-1]) if len(lines) > 2 else response_text

        try:
            ingredients = json.loads(response_text)
        except json.JSONDecodeError as e:
            # JSON 파싱 실패 시, 응답이 중간에 끊겼는지 확인
            # 응답이 "["로 시작하지만 완전하지 않은 경우를 감지
            is_partial = (
                response_text.strip().startswith("[") 
                and not response_text.strip().endswith("]")
            )
            
            if is_partial:
                print(
                    f"[Gemini Partial Response] 응답이 중간에 끊김:\n"
                    f"길이: {len(response_text)}자\n"
                    f"끊긴 내용: {response_text}\n"
                    f"에러: {str(e)}"
                )
                # 강제 복구 로직: 끊긴 JSON을 강제로 닫아서라도 파싱 시도
                fixed_text = response_text.strip()
                try:
                    # 마지막 문자가 "}"가 아니면 불완전한 객체를 닫기
                    if not fixed_text.endswith("}"):
                        # 마지막에 "name"으로 시작하는 불완전한 필드가 있는 경우 처리
                        if '"name"' in fixed_text and fixed_text.rfind('"name"') > fixed_text.rfind('}'):
                            # 불완전한 name 필드를 닫고 객체와 배열을 닫기
                            fixed_text += '": null, "amount": null, "unit": ""}]'
                        else:
                            fixed_text += '}]'
                    else:
                        # "}"로 끝나면 배열만 닫기
                        fixed_text += "]"
                    
                    ingredients = json.loads(fixed_text)
                    print(f"[Gemini 복구 성공] 끊긴 JSON을 강제로 복구하여 {len(ingredients)}개 재료를 추출했습니다.")
                except Exception as recovery_error:
                    print(
                        f"[Gemini 복구 실패] 강제 복구 시도 중 오류: {str(recovery_error)}\n"
                        f"복구 시도한 텍스트: {fixed_text}"
                    )
                    return []
            
            # JSON 파싱 실패 시, 응답에서 JSON 부분만 추출 시도
            json_match = re.search(r"\[.*\]", response_text, re.DOTALL)
            if json_match:
                try:
                    ingredients = json.loads(json_match.group(0))
                except json.JSONDecodeError:
                    # 정규식으로 추출한 부분도 파싱 실패
                    print(
                        f"[Gemini JSON 파싱 실패] 원본 응답 전문:\n"
                        f"길이: {len(response_text)}자\n"
                        f"내용: {response_text}\n"
                        f"에러: {str(e)}"
                    )
                    return []
            else:
                # JSON 배열 패턴을 찾지 못함
                print(
                    f"[Gemini JSON 파싱 실패] 원본 응답 전문:\n"
                    f"길이: {len(response_text)}자\n"
                    f"내용: {response_text}\n"
                    f"에러: {str(e)}"
                )
                return []

        # 결과 검증
        if not isinstance(ingredients, list):
            return []

        # -------- 후처리: Python에서 foodData와 매칭 --------
        # 1) foodData의 이름 목록 준비
        food_name_to_food: Dict[str, Dict[str, Any]] = {}
        food_names: List[str] = []
        for food in food_data:
            name = (food.get("name") or "").strip()
            if name:
                food_names.append(name)
                food_name_to_food[name] = food

        matched_ingredients: List[Dict[str, Any]] = []

        for ing in ingredients:
            if not isinstance(ing, Dict):
                continue

            raw_name = (ing.get("name") or "").strip()
            if not raw_name:
                continue

            # fuzzy matching: 가장 유사한 foodData.name 찾기 (cutoff 0.4로 낮춰서 '아보카도'와 '후숙된 아보카도' 같은 경우도 매칭)
            candidates = difflib.get_close_matches(raw_name, food_names, n=1, cutoff=0.4)
            if not candidates:
                # 매칭이 불확실하면 제외
                continue

            best_name = candidates[0]
            food = food_name_to_food.get(best_name) or {}

            matched_ingredients.append(
                {
                    "standard_name": best_name,
                    "food_id": food.get("id", ""),
                    "category": food.get("category", ""),
                    "amount": ing.get("amount"),
                    "unit": ing.get("unit", ""),
                }
            )

        return matched_ingredients

    except Exception as e:
        error_msg = str(e)
        print(
            f"Gemini API 호출 중 오류: {error_msg} "
            f"(endpoint={GEMINI_API_ENDPOINT}/v1, "
            f"model_candidates={MODEL_CANDIDATES})"
        )
        return []

