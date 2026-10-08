#!/usr/bin/env python3
"""그림 검사 도구 — 게임에 연결된 그림이 규격에 맞는지 확인한다. 그림 파일은 읽기만 하고 절대 바꾸지 않는다.

쓰는 법 (프로젝트 폴더에서):  python3 tools/check_art.py

확인하는 것
- 크기: 칸마다 정한 원본 크기와 같은지 (예: 손님 360×480, 아이콘 16×16, 완성 요리 64×64)
- 표정·우비 그림이 기본 손님 그림과 크기가 같은지 (다르면 표정이 바뀔 때 캐릭터가 흔들린다)
- 배경이 투명해야 하는 그림에 투명한 부분이 있는지
- 가져오기 설정: 손실 압축(색이 바뀜)이나 밉맵(흐려짐)이 켜져 있지 않은지
- assets/art 에 있는데 게임 어디에도 연결되지 않은 그림
규격은 CLAUDE.md 의 "아트 규격"과 docs/discord/art-list.md 를 따른다. 규격이 바뀌면 아래 SPECS 만 고치면 된다.
"""

import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (데이터 종류 또는 장면 파일, 칸 이름) → (가로, 세로, 배경 투명이어야 하는지, 설명)
SPECS = {
    ("AnimalGuest", "portrait"): (360, 480, True, "손님 그림"),
    ("AnimalGuest", "expression_portraits"): (360, 480, True, "손님 표정 그림"),
    ("AnimalGuest", "raincoat_portrait"): (360, 480, True, "손님 우비 그림"),
    ("AnimalGuest", "feast_portrait"): (180, 240, True, "잔치용 앉은 모습"),
    ("AnimalGuest", "icon"): (16, 16, True, "손님 얼굴 아이콘"),
    ("Ingredient", "icon"): (16, 16, True, "재료 아이콘"),
    ("Recipe", "finished_image"): (64, 64, True, "완성 요리"),
    ("Keepsake", "icon"): (43, 43, True, "할머니 기념품"),
    ("StoryChapter", "background_image"): (640, 360, False, "이야기 배경"),
    ("notebook_button", "book_icon"): (32, 32, True, "손님 수첩 책 아이콘"),
    ("goal_button", "board_icon"): (32, 32, True, "목표 버튼 아이콘"),
    ("garden", "basket_full_icon"): (32, 32, True, "이웃 바구니 (찬 것)"),
    ("garden", "basket_empty_icon"): (32, 32, True, "이웃 바구니 (빈 것)"),
    ("recipe_note_book", "book_texture"): (280, 160, True, "펼친 할머니 노트"),
    ("porch:Backdrop", "picture"): (640, 360, False, "저녁 배경"),
    ("porch:Wall", "picture"): (640, 110, True, "등불 달린 돌담"),
    ("porch:Bench", "picture"): (640, 40, False, "평상 끝"),
}
# 기본 손님 그림과 크기가 같아야 하는 칸 (표정이 바뀌어도 캐릭터가 흔들리지 않게)
SAME_AS_PORTRAIT = ("expression_portraits", "raincoat_portrait")


def png_info(path):
    """PNG 의 (가로, 세로, 투명한 부분이 있을 수 있는지). PNG 가 아니면 None."""
    with open(path, "rb") as f:
        head = f.read(8)
        if head != b"\x89PNG\r\n\x1a\n":
            return None
        width = height = color_type = None
        has_trns = False
        while True:
            raw = f.read(8)
            if len(raw) < 8:
                break
            length, kind = struct.unpack(">I4s", raw)
            data = f.read(length)
            f.read(4)
            if kind == b"IHDR":
                width, height, _, color_type = struct.unpack(">IIBB", data[:10])
            elif kind == b"tRNS":
                has_trns = True
            elif kind == b"IDAT":
                break
        can_be_clear = color_type in (4, 6) or has_trns
        return width, height, can_be_clear


def res_to_path(res):
    return os.path.join(ROOT, res.replace("res://", ""))


def read_resources(path):
    """.tres/.tscn 하나에서 (종류, 칸 이름, 그림 경로) 를 모은다."""
    text = open(path, encoding="utf-8").read()
    ids = {i: p for p, i in re.findall(r'\[ext_resource type="Texture2D"[^\]]*path="([^"]+)"[^\]]*id="([^"]+)"\]', text)}
    found = []
    base = os.path.splitext(os.path.basename(path))[0]
    kind = base
    match = re.search(r'script_class="(\w+)"', text)
    if match:
        kind = match.group(1)
    node = None
    pending = None  # 여러 줄에 걸친 값 (예: 표정 그림 사전) 의 칸 이름
    for line in text.splitlines():
        node_match = re.match(r'\[node name="([^"]+)"', line)
        if node_match:
            node = node_match.group(1)
            pending = None
            continue
        prop = re.match(r"(\w+) = (.*)", line)
        if prop:
            name, value = prop.groups()
            pending = name if value.strip() in ("{", "[") or value.rstrip().endswith(("{", "[")) else None
        elif pending is not None:
            name, value = pending, line
            if line.strip() in ("}", "]", "})", "])"):
                pending = None
        else:
            continue
        for tex_id in re.findall(r'ExtResource\("([^"]+)"\)', value):
            if tex_id in ids:
                key_kind = kind
                if (f"{base}:{node}", name) in SPECS:
                    key_kind = f"{base}:{node}"
                found.append((key_kind, name, ids[tex_id], node))
    return found


def import_warnings(png_path):
    imp = png_path + ".import"
    if not os.path.exists(imp):
        return ["가져오기 정보(.import)가 아직 없음 — Godot 에디터를 한 번 열면 생겨요"]
    text = open(imp, encoding="utf-8").read()
    warnings = []
    mode = re.search(r"compress/mode=(\d+)", text)
    if mode and mode.group(1) != "0":
        warnings.append("압축이 '손실 없음(Lossless)'이 아니라 색이 바뀔 수 있음")
    if re.search(r"mipmaps/generate=true", text):
        warnings.append("밉맵이 켜져 있어 흐려질 수 있음")
    return warnings


def main():
    problems, ok, used = [], [], set()
    portraits = {}
    entries = []
    for folder in ("data", "scenes"):
        for dirpath, _, files in os.walk(os.path.join(ROOT, folder)):
            for file in files:
                if file.endswith((".tres", ".tscn")):
                    path = os.path.join(dirpath, file)
                    for kind, name, res, node in read_resources(path):
                        entries.append((os.path.relpath(path, ROOT), kind, name, res))
    for source, kind, name, res in entries:
        png = res_to_path(res)
        used.add(os.path.normpath(png))
        spec = SPECS.get((kind, name))
        if not os.path.exists(png):
            problems.append(f"{source} · {name}: 그림 파일이 없음 ({res})")
            continue
        info = png_info(png)
        if info is None:
            problems.append(f"{source} · {name}: PNG 가 아님 ({res})")
            continue
        width, height, can_be_clear = info
        label = spec[3] if spec else name
        line = f"{source} · {label}: {os.path.relpath(png, ROOT)} {width}×{height}"
        issues = []
        if spec:
            if (width, height) != (spec[0], spec[1]):
                issues.append(f"규격 {spec[0]}×{spec[1]} 과 다름")
            if spec[2] and not can_be_clear:
                issues.append("배경 투명이어야 하는데 투명한 부분이 없음")
        if kind == "AnimalGuest" and name == "portrait":
            portraits[source] = (width, height)
        if kind == "AnimalGuest" and name in SAME_AS_PORTRAIT:
            portraits.setdefault(source + "|others", []).append((name, width, height, os.path.relpath(png, ROOT)))
        issues += import_warnings(png)
        (problems if issues else ok).append(line + (" — " + ", ".join(issues) if issues else ""))
    for key, others in portraits.items():
        if not key.endswith("|others"):
            continue
        source = key[: -len("|others")]
        base = portraits.get(source)
        for name, width, height, rel in others:
            if base and (width, height) != base:
                problems.append(f"{source} · {name}: {rel} {width}×{height} 이 기본 그림 {base[0]}×{base[1]} 과 달라 표정이 바뀔 때 흔들림")
    unused = []
    for dirpath, _, files in os.walk(os.path.join(ROOT, "assets", "art")):
        for file in files:
            if file.endswith(".png"):
                path = os.path.normpath(os.path.join(dirpath, file))
                if path not in used:
                    unused.append(os.path.relpath(path, ROOT))
    print(f"✅ 규격에 맞는 그림 {len(ok)}개")
    for line in ok:
        print("   " + line)
    print(f"⚠️ 확인이 필요한 그림 {len(problems)}개")
    for line in problems:
        print("   " + line)
    print(f"📦 assets/art 에 있지만 게임에 연결되지 않은 그림 {len(unused)}개")
    for line in unused:
        print("   " + line)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
