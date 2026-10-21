#!/usr/bin/env python3
"""Prepare a complete Arabic-only Nahj al-Balagha collection from CC0 ThaqalaynData.

Source repository: https://github.com/adeeb10abbas/shia-library-json
The selected revision is pinned so upstream changes cannot silently alter the build.
Only the Arabic original is included; English translation fields are never read.
"""
import concurrent.futures
import json
import os
import re
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

SOURCE_REPO = "adeeb10abbas/shia-library-json"
SOURCE_REVISION = "075fe2e9d050bb40bd8147ed516d3592046ebc33"
SOURCE_BASE = (
    f"https://raw.githubusercontent.com/{SOURCE_REPO}/"
    f"{SOURCE_REVISION}/db/hadith/nahj-al-balagha/chapters"
)
API_BASE = (
    f"https://api.github.com/repos/{SOURCE_REPO}/contents/"
    "db/hadith/nahj-al-balagha/chapters"
)
DEST = Path("assets/nahj/nahj.json")
USER_AGENT = "Mithaq-Al-Mumin/1.0 (Arabic-only Nahj preparation)"
EXPECTED_COUNTS = {1: 241, 2: 79, 3: 480}
CATEGORY_TITLES = {1: "خطبة", 2: "رسالة", 3: "حكمة"}
# Distinct Persian-script letters do not belong in Arabic original text.
PERSIAN_ONLY_LETTERS = set("پچژگ")
# Strong language indicators only. Common words shared with Arabic are excluded.
PERSIAN_MARKERS = (
    "برای", "میباشد", "می شود", "ميشود", "نمی توان", "نميتوان",
    "متن فارسی", "زبان فارسی", "متن فارسي", "زبان فارسي",
)


def fetch_bytes(url: str, *, accept: str = "application/json") -> bytes:
    last_error: Exception | None = None
    for attempt in range(4):
        request = urllib.request.Request(
            url,
            headers={"User-Agent": USER_AGENT, "Accept": accept},
        )
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                return response.read()
        except (urllib.error.URLError, TimeoutError, OSError) as exc:
            last_error = exc
            if attempt < 3:
                time.sleep(1.0 * (attempt + 1))
    raise RuntimeError(f"Could not fetch {url}: {last_error}") from last_error


def fetch_json(url: str) -> Any:
    return json.loads(fetch_bytes(url).decode("utf-8"))


def remove_non_arabic_glyphs(text: str) -> tuple[str, int]:
    """Remove stray Persian-only glyphs embedded accidentally in Arabic source lines."""
    cleaned_chars = [char for char in text if char not in PERSIAN_ONLY_LETTERS]
    removed = len(text) - len(cleaned_chars)
    cleaned = "".join(cleaned_chars)
    # Keep Arabic punctuation neat when an accidental foreign glyph touched a mark.
    cleaned = re.sub(r"\s+([،؛:,.!?؟])", r"\1", cleaned)
    cleaned = re.sub(r"([،؛:,.!?؟])(?=\S)", r"\1 ", cleaned)
    cleaned = re.sub(r"[ \t]{2,}", " ", cleaned)
    return cleaned.strip(), removed


def looks_persian(text: str) -> bool:
    # Only strong Persian-language markers are tested here; Arabic vocabulary can overlap.
    return any(marker in text for marker in PERSIAN_MARKERS)


def list_chapters(volume: int) -> list[int]:
    url = f"{API_BASE}/{volume}?ref={SOURCE_REVISION}"
    data = fetch_json(url)
    if not isinstance(data, list):
        raise RuntimeError(f"Unexpected GitHub directory listing for volume {volume}")
    numbers = []
    for item in data:
        if item.get("type") != "file" or not str(item.get("name", "")).endswith(".json"):
            continue
        match = re.fullmatch(r"(\d+)\.json", str(item["name"]))
        if match:
            numbers.append(int(match.group(1)))
    numbers.sort()
    expected = EXPECTED_COUNTS[volume]
    if len(numbers) != expected or numbers != list(range(1, expected + 1)):
        raise RuntimeError(
            f"Nahj volume {volume} is incomplete: found {len(numbers)} chapters; "
            f"expected {expected} numbered chapters."
        )
    return numbers


def prepare_chapter(args: tuple[int, int]) -> dict[str, Any]:
    volume, number = args
    url = f"{SOURCE_BASE}/{volume}/{number}.json"
    page = fetch_json(url)
    if page.get("book") != "nahj-al-balagha":
        raise RuntimeError(f"Unexpected book slug in {url}")

    raw_records = page.get("records")
    if not isinstance(raw_records, list) or not raw_records:
        raise RuntimeError(f"No records found in Arabic Nahj chapter {volume}/{number}")

    arabic_parts = []
    source_urls = []
    for record in raw_records:
        arabic = record.get("arabic") if isinstance(record, dict) else None
        text = arabic.get("text", "") if isinstance(arabic, dict) else ""
        if not isinstance(text, str):
            continue
        text = text.strip()
        if text:
            arabic_parts.append(text)
        source = record.get("source", {}) if isinstance(record, dict) else {}
        source_url = source.get("sourceUrl") if isinstance(source, dict) else None
        if isinstance(source_url, str) and source_url.startswith("https://thaqalayn.net/"):
            if source_url not in source_urls:
                source_urls.append(source_url)

    text = "\n\n".join(arabic_parts).strip()
    if not text:
        raise RuntimeError(f"Arabic text missing from Nahj chapter {volume}/{number}")
    text, removed_glyphs = remove_non_arabic_glyphs(text)
    if not text:
        raise RuntimeError(f"Arabic text became empty after cleanup in {volume}/{number}")
    if looks_persian(text):
        raise RuntimeError(
            f"Persian-language marker detected in source chapter {volume}/{number}; "
            "refusing to bundle it."
        )

    return {
        "id": (volume * 1000) + number,
        "category": volume,
        "number": str(number),
        "title": f"{CATEGORY_TITLES[volume]} رقم {number}",
        "text": text,
        "sourceUrl": source_urls,
        "sourceLicense": "CC0-1.0",
        "_removedPersianOnlyGlyphs": removed_glyphs,
    }


def main() -> None:
    chapter_tasks = [
        (volume, number)
        for volume in (1, 2, 3)
        for number in list_chapters(volume)
    ]
    entries: list[dict[str, Any]] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=16) as executor:
        for entry in executor.map(prepare_chapter, chapter_tasks):
            entries.append(entry)

    entries.sort(key=lambda item: (item["category"], int(item["number"])))
    removed_glyphs = sum(
        int(item.pop("_removedPersianOnlyGlyphs", 0)) for item in entries
    )
    counts = {
        category: sum(1 for item in entries if item["category"] == category)
        for category in EXPECTED_COUNTS
    }
    if counts != EXPECTED_COUNTS or len(entries) != sum(EXPECTED_COUNTS.values()):
        raise RuntimeError(
            f"Nahj source count mismatch: total={len(entries)}, category_counts={counts}"
        )

    # Audit every field users can see. The Arabic dataset is never translated.
    for entry in entries:
        for field in ("title", "text"):
            if any(char in PERSIAN_ONLY_LETTERS for char in entry[field]) or looks_persian(entry[field]):
                raise RuntimeError(
                    f"Persian content detected after preparation in {entry['category']}:{entry['number']}"
                )

    result = {
        "metadata": {
            "title": "نهج البلاغة",
            "sourceProject": SOURCE_REPO,
            "sourceRevision": SOURCE_REVISION,
            "sourceUrl": "https://github.com/adeeb10abbas/shia-library-json",
            "license": "CC0-1.0; source records identify ThaqalaynData content as CC0-1.0",
            "contentNote": (
                "Arabic original only. English translation and non-Arabic fields are excluded. "
                "Accidental Persian-only glyphs embedded in Arabic lines are removed. "
                "Chapter numbering follows the selected ThaqalaynData edition and may differ "
                "from other printed editions."
            ),
            "counts": {
                "sermons": counts[1],
                "letters": counts[2],
                "wisdoms": counts[3],
                "total": len(entries),
            },
        },
        "entries": entries,
    }

    DEST.parent.mkdir(parents=True, exist_ok=True)
    temporary = DEST.with_suffix(".json.tmp")
    try:
        with temporary.open("w", encoding="utf-8", newline="\n") as handle:
            json.dump(result, handle, ensure_ascii=False, separators=(",", ":"))
            handle.write("\n")
        os.replace(temporary, DEST)
    finally:
        if temporary.exists():
            temporary.unlink()

    print(
        f"Prepared complete Arabic-only Nahj al-Balagha: {len(entries)} entries; "
        f"sermons={counts[1]}, letters={counts[2]}, wisdoms={counts[3]}; "
        f"Persian-language audit passed; removed {removed_glyphs} stray Persian-only glyphs."
    )


if __name__ == "__main__":
    main()
