#!/usr/bin/env python3
"""한국어 검사 훅 (Stop): Claude 가 답을 마칠 때, 이번 차례에 쓴 글이 한국어인지 확인한다.

- 마지막 사용자 메시지 뒤로 Claude 가 쓴 글(최종 답과 작업 중간의 진행 메모)을 모두 본다.
- 코드 블록, `인라인 코드`, 주소(URL), 파일 경로는 빼고 글자를 센다.
- 영어 글자가 한글보다 많은 글이 하나라도 있으면 답을 막고 "한국어로 다시 쓰라"고 돌려보낸다.
- 사용자가 영어를 요청한 경우를 위해: 사용자 메시지에 "영어로"가 있으면 검사하지 않는다.
CLAUDE.md 의 "응답 언어 — 최우선 규칙"을 프로그램으로 지키게 하려고 만들었다.
"""
import json
import re
import sys

# 이 글자 수보다 짧은 글(예: "OK")은 검사하지 않는다
MIN_LETTERS = 20


def visible_text(text: str) -> str:
    text = re.sub(r"```.*?```", " ", text, flags=re.S)
    text = re.sub(r"`[^`\n]*`", " ", text)
    text = re.sub(r"https?://\S+", " ", text)
    text = re.sub(r"[\w./~-]*/[\w./-]+", " ", text)  # 파일 경로
    text = re.sub(r"\b[\w-]+\.(gd|tscn|tres|py|json|md|png|zip|txt|cfg|import|godot)\b", " ", text)
    return text


def is_mostly_english(text: str) -> bool:
    shown = visible_text(text)
    hangul = len(re.findall(r"[가-힣]", shown))
    latin = len(re.findall(r"[A-Za-z]", shown))
    return hangul + latin >= MIN_LETTERS and latin > hangul


def user_text(entry: dict) -> "str | None":
    """진짜 사용자 메시지면 그 글, 아니면(도구 결과·시스템 메모) None."""
    if entry.get("type") != "user" or entry.get("isMeta"):
        return None
    content = entry.get("message", {}).get("content")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        if any(part.get("type") == "tool_result" for part in content if isinstance(part, dict)):
            return None
        return " ".join(part.get("text", "") for part in content if isinstance(part, dict) and part.get("type") == "text")
    return None


def main() -> None:
    data = json.load(sys.stdin)
    path = data.get("transcript_path")
    if not path:
        return
    entries = []
    with open(path, encoding="utf-8") as file:
        for line in file:
            try:
                entries.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    last_user = -1
    request = ""
    for i, entry in enumerate(entries):
        text = user_text(entry)
        if text is not None:
            last_user, request = i, text
    if "영어로" in request:
        return
    texts = []
    for entry in entries[last_user + 1:]:
        if entry.get("type") != "assistant":
            continue
        for part in entry.get("message", {}).get("content", []) or []:
            if isinstance(part, dict) and part.get("type") == "text" and part.get("text", "").strip():
                texts.append(part["text"])
    # 이미 한 번 막혀서 다시 쓰는 중이면 마지막 글만 본다 (앞선 영어 글 때문에 끝없이 막히지 않게)
    if data.get("stop_hook_active"):
        texts = texts[-1:]
    english = [text.strip().splitlines()[0][:80] for text in texts if is_mostly_english(text)]
    if english:
        print(json.dumps({
            "decision": "block",
            "reason": "응답 언어 규칙 위반: 이번 차례에 영어로 쓴 글이 있습니다 (" + " / ".join(english[:3]) + "). "
                      "사용자는 영어를 읽지 못합니다. 지금 바로 이번 차례의 진행 상황과 결과를 처음부터 끝까지 한국어로 다시 보고하세요. "
                      "코드·파일 이름·명령어만 영어로 둡니다.",
        }, ensure_ascii=False))


if __name__ == "__main__":
    main()
