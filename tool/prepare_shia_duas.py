#!/usr/bin/env python3
"""Build the fixed 110-text Arabic supplication library from its curated manifest.

Text dataset: KazTronics/AhlulBayt_Treasures (data metadata declares Public Domain).
The source repository code is MIT-licensed; its license notice is copied to licenses/.
The previous 72-item import is replaced rather than merged into this collection.
"""
import json
import os
import re
import tempfile
import time
import urllib.error
import urllib.request
from collections import Counter
from pathlib import Path

SOURCE_URL = "https://raw.githubusercontent.com/KazTronics/AhlulBayt_Treasures/main/duas_data.json"
SOURCE_PAGE = "https://github.com/KazTronics/AhlulBayt_Treasures/blob/main/duas_data.json"
MANIFEST_PATH = Path("tool/shia_dua_manifest.json")
DEST = Path("assets/shia_duas/shia_duas.json")
EXPECTED_COUNT = 110
EXPECTED_CATEGORY_COUNTS = {
    "الأدعية والأذكار اليومية": 30,
    "الأدعية العامة وأدعية الفرج وصاحب الزمان": 35,
    "الأعمال والمناسبات": 20,
    "الزيارات الشريفة": 25,
}
PERSIAN_RE = re.compile(r"[\u067e\u0686\u0698\u06af\u06a9\u06cc]")
LATIN_RE = re.compile(r"[A-Za-z]")
ARABIC_RE = re.compile(r"[\u0600-\u06ff]")


def fetch_json(url: str, attempts: int = 3):
    headers = {"User-Agent": "Mithaq-Al-Mumin/1.0 (offline Arabic text preparation)"}
    for attempt in range(attempts):
        try:
            request = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.loads(response.read().decode("utf-8"))
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
            if attempt + 1 >= attempts:
                raise SystemExit(f"Unable to download/parse source JSON: {url} ({exc})") from exc
            time.sleep(1.5 * (attempt + 1))


def normalize_text(value: str) -> str:
    value = re.sub(r"[\u064b-\u065f\u0670\u0640]", "", value)
    value = value.replace("أ", "ا").replace("إ", "ا").replace("آ", "ا")
    value = value.replace("ٱ", "ا").replace("ى", "ي")
    return re.sub(r"[^\u0600-\u06ff0-9]", "", value).lower()


def main() -> None:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    items = manifest.get("entries")
    if not isinstance(items, list) or len(items) != EXPECTED_COUNT:
        raise SystemExit(f"Manifest must contain exactly {EXPECTED_COUNT} items.")
    if manifest.get("downloadUrl") != SOURCE_URL or manifest.get("sourceUrl") != SOURCE_PAGE:
        raise SystemExit("Manifest source URL does not match the pinned dataset.")
    if manifest.get("expectedCategoryCounts") != EXPECTED_CATEGORY_COUNTS:
        raise SystemExit("Manifest category counts differ from the agreed five sections.")

    source = fetch_json(SOURCE_URL)
    source_meta = source.get("metadata") if isinstance(source, dict) else None
    records = source.get("duas") if isinstance(source, dict) else None
    if not isinstance(source_meta, dict) or not isinstance(records, list) or not records:
        raise SystemExit("Source dataset metadata or 'duas' list is missing.")
    if str(source_meta.get("license", "")).strip().lower() != "public domain":
        raise SystemExit("Source data no longer declares Public Domain; review its license.")

    records_by_id = {}
    for record in records:
        try:
            source_id = int(record.get("id"))
        except (AttributeError, TypeError, ValueError):
            continue
        if source_id in records_by_id:
            raise SystemExit(f"Duplicate source record ID {source_id}.")
        records_by_id[source_id] = record

    prepared = []
    category_counter = Counter()
    slugs_seen, ids_seen, texts_seen = set(), set(), {}
    total_arabic_lines = 0

    for item in items:
        if not isinstance(item, dict):
            raise SystemExit("Malformed item in the curated manifest.")
        source_id = item.get("sourceId")
        slug = item.get("slug")
        title = item.get("title")
        category = item.get("category")
        source_reference = item.get("sourceReference")
        source_url = item.get("sourceUrl")
        expected_source_name = item.get("sourceName")

        if not isinstance(source_id, int) or source_id in ids_seen:
            raise SystemExit(f"Invalid or duplicate source ID: {source_id!r}")
        if not isinstance(slug, str) or not slug or slug in slugs_seen:
            raise SystemExit(f"Invalid or duplicate slug: {slug!r}")
        if not isinstance(title, str) or not title.strip():
            raise SystemExit(f"Missing Arabic title for {slug}.")
        if PERSIAN_RE.search(title) or LATIN_RE.search(title) or not ARABIC_RE.search(title):
            raise SystemExit(f"Title must be Arabic-only: {slug}.")
        if category not in EXPECTED_CATEGORY_COUNTS:
            raise SystemExit(f"Unknown category on {slug}: {category!r}")
        if not isinstance(source_reference, str) or not source_reference.strip():
            raise SystemExit(f"Missing exact source reference for {slug}.")
        if source_url != SOURCE_PAGE:
            raise SystemExit(f"Wrong source URL for {slug}.")

        raw = records_by_id.get(source_id)
        if not isinstance(raw, dict):
            raise SystemExit(f"Source record {source_id} is missing for {slug}.")
        if raw.get("name") != expected_source_name:
            raise SystemExit(f"Source identity changed for {slug}: {raw.get('name')!r}.")
        rows = raw.get("rows")
        if not isinstance(rows, list) or not rows:
            raise SystemExit(f"Missing full rows for {slug}.")

        lines = []
        for row in rows:
            if not isinstance(row, dict):
                raise SystemExit(f"Malformed row for {slug}.")
            value = row.get("arabic")
            if not isinstance(value, str):
                raise SystemExit(f"Missing Arabic field in {slug}.")
            value = value.strip()
            if not value:
                continue
            if PERSIAN_RE.search(value) or LATIN_RE.search(value):
                raise SystemExit(f"Persian/Latin characters found in supposed Arabic text: {slug}.")
            if not ARABIC_RE.search(value):
                raise SystemExit(f"Non-Arabic content found in {slug}.")
            lines.append({
                "index": row.get("index") if isinstance(row.get("index"), int) else len(lines) + 1,
                "kind": "arabic",
                "text": value,
            })
        if not lines:
            raise SystemExit(f"No Arabic text found in {slug}.")

        key = normalize_text(" ".join(line["text"] for line in lines))
        if not key:
            raise SystemExit(f"Empty normalized text for {slug}.")
        if key in texts_seen:
            raise SystemExit(f"Duplicate full texts: {slug} duplicates {texts_seen[key]}.")
        texts_seen[key] = slug

        slug_category = (
            "الصحيفة السجادية والمناجيات" if slug.startswith(("sahifa-sajjadiya-", "munajat-sahifa-")) else
            "الزيارات الشريفة" if slug.startswith("ziyarat-") else
            "الأعمال والمناسبات" if slug.startswith("occasion-") else
            "الأدعية والأذكار اليومية" if slug.startswith(("daily-", "taqib-")) else
            "الأدعية العامة وأدعية الفرج وصاحب الزمان" if slug.startswith("general-") else None
        )
        if slug_category != category:
            raise SystemExit(f"Slug/category mismatch for {slug}.")

        category_counter[category] += 1
        total_arabic_lines += len(lines)
        slugs_seen.add(slug)
        ids_seen.add(source_id)
        prayer_type = (
            "sahifa" if slug.startswith("sahifa-sajjadiya-") else
            "munajat" if slug.startswith("munajat-sahifa-") else
            "ziyarat" if slug.startswith("ziyarat-") else
            "daily" if slug.startswith(("daily-", "taqib-")) else
            "occasion" if slug.startswith("occasion-") else "dua"
        )
        prepared.append({
            "sourceId": source_id,
            "sourceName": expected_source_name,
            "slug": slug,
            "title": title.strip(),
            "alternateName": str(item.get("alternateName") or "").strip(),
            "category": category,
            "sourceReference": source_reference.strip(),
            "sourceUrl": source_url,
            "type": prayer_type,
            "lines": lines,
        })

    if len(prepared) != EXPECTED_COUNT or len(slugs_seen) != EXPECTED_COUNT:
        raise SystemExit(f"Prepared {len(prepared)} unique items, expected {EXPECTED_COUNT}.")
    if dict(category_counter) != EXPECTED_CATEGORY_COUNTS:
        raise SystemExit(f"Wrong section counts: {dict(category_counter)!r}.")
    if len(texts_seen) != EXPECTED_COUNT:
        raise SystemExit("Full-text uniqueness validation failed.")

    result = {
        "metadata": {
            "sourceProject": "KazTronics/AhlulBayt_Treasures",
            "sourceIndex": SOURCE_URL,
            "contentSource": "Shia Devotions dataset; source record IDs are retained in each entry's reference",
            "license": "Text data declared Public Domain in source metadata; source repository code is MIT",
            "count": EXPECTED_COUNT,
            "categoryCounts": EXPECTED_CATEGORY_COUNTS,
            "duplicateTextsRemoved": 0,
            "note": "Curated 110-item offline Arabic collection. The build stops on missing, changed, incomplete, duplicated or non-Arabic content.",
        },
        "entries": prepared,
    }

    DEST.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix="shia-duas-", suffix=".json", dir=DEST.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(result, handle, ensure_ascii=False, separators=(",", ":"))
            handle.write("\n")
        os.replace(temporary, DEST)
    finally:
        if os.path.exists(temporary):
            os.remove(temporary)

    print(
        f"Prepared {len(prepared)} complete Arabic texts in five categories; "
        f"{total_arabic_lines} Arabic lines; no duplicate full texts, Persian or Latin."
    )


if __name__ == "__main__":
    main()
