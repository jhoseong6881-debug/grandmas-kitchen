#!/usr/bin/env python3
"""디스코드 🎮게임-파일 채널의 안내 글을 최신 빌드로 맞춘다. 채널에는 안내 글 하나만 두고 계속 고쳐 쓴다 (옛 버전이 남지 않게).

- game-file-post.md 의 안내 글에서 `(여기에 드라이브 링크)` 를 받은 링크로 바꾸고, txt/3_게임파일_01.txt 도 다시 만든다.
- gamefile-id.json 에 적힌 글(플레이콩 웹후크가 올린 것)이 있으면 그 자리에서 고친다. 없으면 새로 올리고 번호를 적어 둔다.
- 고친 글은 디스코드 알림이 가지 않으니, 새 빌드 소식은 📝패치노트 글로 알린다.
웹후크 주소는 이 맥 키체인(gk-discord-gamefile-webhook)에서 읽는다. 저장소에는 주소를 넣지 않는다.
쓰는 법: python3 docs/discord/post_gamefile.py <구글 드라이브 링크>
"""
import json
import os
import subprocess
import sys
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.join(HERE, "game-file-post.md")
ID_PATH = os.path.join(HERE, "gamefile-id.json")
TXT_PATH = os.path.join(HERE, "txt", "3_게임파일_01.txt")
LINK_MARK = "(여기에 드라이브 링크)"


def webhook_url() -> str:
    return subprocess.run(
        ["security", "find-generic-password", "-a", "grandmas-kitchen", "-s", "gk-discord-gamefile-webhook", "-w"],
        capture_output=True, text=True, check=True).stdout.strip()


def call(method: str, url: str, content: str) -> dict:
    body = json.dumps({"content": content, "allowed_mentions": {"parse": []}}).encode()
    request = urllib.request.Request(url, data=body, method=method,
                                     headers={"Content-Type": "application/json", "User-Agent": "grandmas-kitchen"})
    with urllib.request.urlopen(request) as response:
        return json.load(response)


def main() -> None:
    if len(sys.argv) < 2 or not sys.argv[1].startswith("https://"):
        raise SystemExit("쓰는 법: python3 docs/discord/post_gamefile.py <구글 드라이브 링크>")
    link = sys.argv[1]
    text = open(SOURCE, encoding="utf-8").read().split("\n---\n")[1].strip("\n")
    if LINK_MARK not in text:
        raise SystemExit(f"안내 글에 {LINK_MARK} 자리가 없어요")
    with open(TXT_PATH, "w", encoding="utf-8") as file:
        file.write(text + "\n")
    message = text.replace(LINK_MARK, link)
    if len(message) > 2000:
        raise SystemExit(f"안내 글이 2000자를 넘어요 ({len(message)}자)")
    data = json.load(open(ID_PATH, encoding="utf-8")) if os.path.exists(ID_PATH) else {}
    url = webhook_url()
    if data.get("message_id"):
        call("PATCH", f"{url}/messages/{data['message_id']}", message)
        print("안내 글을 최신 버전으로 고쳤어요")
    else:
        posted = call("POST", f"{url}?wait=true", message)
        data["message_id"] = posted["id"]
        print("안내 글을 새로 올리고 번호를 적어 뒀어요")
    json.dump(data, open(ID_PATH, "w", encoding="utf-8"), ensure_ascii=False, indent=2)


if __name__ == "__main__":
    main()
