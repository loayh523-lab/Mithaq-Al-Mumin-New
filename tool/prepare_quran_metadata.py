#!/usr/bin/env python3
"""Build offline Quran juz/hizb metadata from Quran Foundation's public content API."""
import json
import os
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

DEST = Path("assets/quran/verse_metadata.json")
BASE = "https://api.quran.com/api/v4/verses/by_juz/"
EXPECTED_AYAHS = 6236

def get_json(url: str):
    last_error = None
    for attempt in range(4):
        try:
            request = urllib.request.Request(url, headers={
                "User-Agent": "Mithaq-Al-Mumin/1.0 (offline Quran metadata preparation)",
                "Accept": "application/json",
            })
            with urllib.request.urlopen(request, timeout=45) as response:
                return json.loads(response.read().decode("utf-8"))
        except (OSError, urllib.error.URLError, json.JSONDecodeError) as error:
            last_error = error
            if attempt < 3:
                time.sleep(1.5 * (attempt + 1))
    raise SystemExit(f"Unable to retrieve Quran metadata after retries: {last_error}")

def main():
    entries = {}
    for juz in range(1, 31):
        query = urllib.parse.urlencode({
            "per_page": 300,
            "fields": "juz_number,hizb_number,rub_el_hizb_number,page_number",
        })
        payload = get_json(f"{BASE}{juz}?{query}")
        verses = payload.get("verses")
        if not isinstance(verses, list) or not verses:
            raise SystemExit(f"Quran metadata response is empty for juz {juz}")
        pagination = payload.get("pagination", {})
        total_pages = int(pagination.get("total_pages", 1))
        for page in range(2, total_pages + 1):
            page_query = urllib.parse.urlencode({
                "per_page": 300,
                "page": page,
                "fields": "juz_number,hizb_number,rub_el_hizb_number,page_number",
            })
            extra = get_json(f"{BASE}{juz}?{page_query}").get("verses", [])
            verses.extend(extra)
        for verse in verses:
            key = verse.get("verse_key")
            chapter = verse.get("chapter_id")
            number = verse.get("verse_number")
            juz_number = verse.get("juz_number")
            hizb_number = verse.get("hizb_number")
            page_number = verse.get("page_number")
            rub_number = verse.get("rub_el_hizb_number")
            if not all(isinstance(value, int) for value in (chapter, number, juz_number, hizb_number, page_number)):
                raise SystemExit(f"Invalid metadata entry: {verse}")
            if key != f"{chapter}:{number}" or juz_number != juz:
                raise SystemExit(f"Unexpected Quran metadata entry for juz {juz}: {verse}")
            item = {
                "surah": chapter,
                "ayah": number,
                "juz": juz_number,
                "hizb": hizb_number,
                "page": page_number,
            }
            if isinstance(rub_number, int):
                item["rub"] = rub_number
            if key in entries and entries[key] != item:
                raise SystemExit(f"Conflicting Quran metadata for {key}")
            entries[key] = item
    if len(entries) != EXPECTED_AYAHS:
        raise SystemExit(f"Expected metadata for {EXPECTED_AYAHS} ayahs, got {len(entries)}")
    for surah in range(1, 115):
        counts = [key for key in entries if key.startswith(f"{surah}:")]
        if not counts:
            raise SystemExit(f"Missing Quran metadata for surah {surah}")
    result = {
        "metadata": {
            "source": "Quran Foundation Content API v4",
            "source_url": "https://api-docs.quran.com/docs/content_apis_versioned/4.0.0/quran-verses-by-script/",
            "counts": {"ayahs": EXPECTED_AYAHS, "juz": 30, "hizb": 60, "rub_el_hizb": 240},
        },
        "verses": entries,
    }
    DEST.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix="quran-meta-", suffix=".json", dir=DEST.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(result, handle, ensure_ascii=False, separators=(",", ":"))
            handle.write("\n")
        os.replace(temporary, DEST)
    finally:
        if os.path.exists(temporary):
            os.remove(temporary)
    print(f"Prepared offline Quran metadata for {len(entries)} ayahs (30 juz, 60 hizb).")

if __name__ == "__main__":
    main()
