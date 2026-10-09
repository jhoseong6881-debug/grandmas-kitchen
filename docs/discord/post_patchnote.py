#!/usr/bin/env python3
"""디스코드 📝패치노트 채널에 글을 올린다 (웹후크 "패치콩 🌱").

쓰는 법 (프로젝트 폴더에서):
  python3 docs/discord/post_patchnote.py --version 0.7.14     patch-notes.md 에서 그 버전 칸(여러 개면 모두, 순서대로)을 올린다
  python3 docs/discord/post_patchnote.py --file 글.txt        기능 하나의 짧은 패치노트처럼, 파일에 적은 글을 올린다
  끝에 --dry-run 을 붙이면 올리지 않고 무엇을 올릴지(첫 줄, 글자 수)만 보여 준다.
  python3 docs/discord/post_patchnote.py --version 0.7.14 --save-txt   빌드 준비 때: 그 버전 칸을 txt/1_패치노트_NN.txt
      (다음 번호부터, 메시지 하나에 파일 하나)로 저장만 하고 올리지 않는다.

웹후크 주소는 GitHub 저장소 웹훅(692491100) 설정에서 읽고, 화면·파일에 남기지 않는다.
"""
import argparse
import json
import os
import re
import subprocess
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
NOTES = os.path.join(HERE, "patch-notes.md")
HOOK_API = "repos/jhoseong6881-debug/grandmas-kitchen/hooks/692491100"
TXT_DIR = os.path.join(HERE, "txt")
TXT_PREFIX = "1_패치노트_"
LIMIT = 2000


def webhook_url() -> str:
    url = subprocess.run(["gh", "api", HOOK_API, "--jq", ".config.url"],
                         capture_output=True, text=True, check=True).stdout.strip()
    return url.removesuffix("/github")


def version_messages(version: str) -> list[str]:
    """patch-notes.md 는 `---` 줄 사이가 메시지 하나. 첫 줄이 `# ... <버전>` 인 메시지를 모두 고른다."""
    parts = open(NOTES, encoding="utf-8").read().split("\n---\n")
    pattern = re.compile(r"^# .*(?<![\d.])" + re.escape(version) + r"(?![\d.])")
    return [part.strip("\n") for part in parts if pattern.match(part.strip("\n"))]


def save_txt(messages: list[str]) -> None:
    numbers = [int(name[len(TXT_PREFIX):-4]) for name in os.listdir(TXT_DIR)
               if name.startswith(TXT_PREFIX) and name.endswith(".txt") and name[len(TXT_PREFIX):-4].isdigit()]
    number = max(numbers, default=0)
    for message in messages:
        number += 1
        path = os.path.join(TXT_DIR, f"{TXT_PREFIX}{number:02d}.txt")
        with open(path, "w", encoding="utf-8") as file:
            file.write(message + "\n")
        print(f"저장: {os.path.relpath(path, HERE)}")


def post(url: str, content: str) -> None:
    body = json.dumps({"content": content, "allowed_mentions": {"parse": []}}).encode()
    request = urllib.request.Request(url + "?wait=true", data=body, method="POST",
                                     headers={"Content-Type": "application/json", "User-Agent": "grandmas-kitchen"})
    with urllib.request.urlopen(request) as response:
        response.read()


def main() -> None:
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--version")
    group.add_argument("--file")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--save-txt", action="store_true")
    args = parser.parse_args()
    if args.version:
        messages = version_messages(args.version)
        if not messages:
            raise SystemExit(f"patch-notes.md 에 '# ... {args.version}' 칸이 없어요")
    else:
        messages = [open(args.file, encoding="utf-8").read().strip("\n")]
    for message in messages:
        if len(message) > LIMIT:
            raise SystemExit(f"{LIMIT}자를 넘는 글이 있어요 ({len(message)}자): {message.splitlines()[0]}")
    for message in messages:
        print(f"{'(올리지 않음) ' if args.dry_run else ''}{message.splitlines()[0]} — {len(message)}자")
    if args.save_txt:
        save_txt(messages)
        return
    if args.dry_run:
        return
    url = webhook_url()
    for message in messages:
        post(url, message)
    print(f"패치노트 {len(messages)}개를 올렸어요")


if __name__ == "__main__":
    main()
