#!/usr/bin/env python3
"""디스코드 🎨그림-목록 채널을 docs/discord/art-list.md 에 맞춰 고친다.

- art-list.md 를 `---` 로 나눈 메시지마다 txt/2_그림목록_NN.txt 를 다시 만들고,
- art-list-ids.json 에 적힌 메시지(그림콩 웹후크가 올린 것)와 내용이 다르면 그 자리에서 고친다.
- 메시지가 늘었으면 맨 아래에 새로 올리고 번호를 적어 둔다.
웹후크 주소는 이 맥 키체인(gk-discord-art-webhook)에서 읽는다. 저장소에는 주소를 넣지 않는다.
쓰는 법: python3 docs/discord/sync_art_list.py
"""
import glob
import json
import os
import subprocess
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.join(HERE, "art-list.md")
IDS_PATH = os.path.join(HERE, "art-list-ids.json")
TXT_FORMAT = os.path.join(HERE, "txt", "2_그림목록_{:02d}.txt")


def webhook_url() -> str:
    return subprocess.run(
        ["security", "find-generic-password", "-a", "grandmas-kitchen", "-s", "gk-discord-art-webhook", "-w"],
        capture_output=True, text=True, check=True).stdout.strip()


def call(method: str, url: str, content: "str | None" = None) -> dict:
    body = None
    if content is not None:
        body = json.dumps({"content": content, "allowed_mentions": {"parse": []}}).encode()
    request = urllib.request.Request(url, data=body, method=method,
                                     headers={"Content-Type": "application/json", "User-Agent": "grandmas-kitchen"})
    with urllib.request.urlopen(request) as response:
        return json.load(response)


def main() -> None:
    parts = open(SOURCE, encoding="utf-8").read().split("\n---\n")[1:]
    messages = [part.strip("\n") for part in parts if part.strip()]
    for path in glob.glob(TXT_FORMAT.replace("{:02d}", "*")):
        os.remove(path)
    for i, text in enumerate(messages, 1):
        if len(text) > 2000:
            raise SystemExit(f"{i}번 메시지가 2000자를 넘어요 ({len(text)}자)")
        with open(TXT_FORMAT.format(i), "w", encoding="utf-8") as file:
            file.write(text + "\n")
    data = json.load(open(IDS_PATH, encoding="utf-8"))
    ids: dict = data["messages"]
    url = webhook_url()
    for i, text in enumerate(messages, 1):
        key = f"{i:02d}"
        if key in ids:
            current = call("GET", f"{url}/messages/{ids[key]}")
            if current.get("content", "") == text:
                print(f"{key}: 그대로")
                continue
            call("PATCH", f"{url}/messages/{ids[key]}", text)
            print(f"{key}: 고침")
        else:
            posted = call("POST", f"{url}?wait=true", text)
            ids[key] = posted["id"]
            print(f"{key}: 새로 올림")
        time.sleep(1)
    extra = [key for key in ids if int(key) > len(messages)]
    for key in extra:
        call("DELETE", f"{url}/messages/{ids.pop(key)}")
        print(f"{key}: 메시지가 줄어서 지움")
    json.dump(data, open(IDS_PATH, "w", encoding="utf-8"), ensure_ascii=False, indent=2)


if __name__ == "__main__":
    main()
