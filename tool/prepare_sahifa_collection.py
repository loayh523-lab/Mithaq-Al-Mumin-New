#!/usr/bin/env python3
"""Build the complete offline Sahifa Sajjadiya and Munajat collection.

The source dataset is pinned to a fixed commit. This script creates only the
separate Sahifa asset and never overwrites the 250-entry core library.
"""
from __future__ import annotations

import json
import os
import re
import sys
import tempfile
import time
import urllib.error
import urllib.request
from collections import Counter
from pathlib import Path

SOURCE_COMMIT = "a59bd5f8fe078532622a08ea60c19d164fb425cb"
SOURCE_VERSION = "1.0.1"
SOURCE_URL = (
    "https://raw.githubusercontent.com/KazTronics/AhlulBayt_Treasures/"
    f"{SOURCE_COMMIT}/duas_data.json"
)
SOURCE_PAGE = (
    "https://github.com/KazTronics/AhlulBayt_Treasures/blob/"
    f"{SOURCE_COMMIT}/duas_data.json"
)
MANIFEST_PATH = Path("tool/shia_dua_manifest.json")
DEST = Path("assets/shia_duas/sahifa_sajjadiya.json")
EXPECTED_TOTAL = 76
EXPECTED_CORE_DUAS = 54
EXPECTED_WEEKDAY_APPENDICES = 7
EXPECTED_MUNAJAT = 15
CATEGORY = "الصحيفة السجادية المباركة"
PERSIAN_RE = re.compile(r"[\u067e\u0686\u0698\u06af\u06a9\u06cc]")
LATIN_RE = re.compile(r"[A-Za-z]")
ARABIC_RE = re.compile(r"[\u0600-\u06ff]")


def fail(message: str) -> None:
    raise SystemExit(message)


def fetch_json(url: str, attempts: int = 3):
    headers = {"User-Agent": "Mithaq-Al-Mumin/1.0 (offline Sahifa preparation)"}
    for attempt in range(attempts):
        try:
            request = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.loads(response.read().decode("utf-8"))
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
            if attempt + 1 >= attempts:
                fail(f"Unable to download/parse pinned Sahifa source: {exc}")
            time.sleep(1.5 * (attempt + 1))


def normalize_text(value: str) -> str:
    value = re.sub(r"[\u064b-\u065f\u0670\u0640\s،؛,.!?؟:…()\-]", "", value)
    value = re.sub(r"[أإآٱ]", "ا", value).replace("ى", "ي")
    return value


def atomic_json(path: Path, value) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(
        prefix=path.stem + "-", suffix=".json", dir=path.parent
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(value, handle, ensure_ascii=False, separators=(",", ":"))
            handle.write("\n")
        Path(temporary).replace(path)
    finally:
        if Path(temporary).exists():
            Path(temporary).unlink()


def main() -> None:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    items = manifest.get("sahifaEntries")
    if not isinstance(items, list) or len(items) != EXPECTED_TOTAL:
        fail(f"Manifest must contain exactly {EXPECTED_TOTAL} Sahifa/Munajat records.")
    if (
        manifest.get("sourceCommit") != SOURCE_COMMIT
        or manifest.get("sourceVersion") != SOURCE_VERSION
        or manifest.get("downloadUrl") != SOURCE_URL
        or manifest.get("sourceUrl") != SOURCE_PAGE
        or manifest.get("sahifaCount") != EXPECTED_TOTAL
    ):
        fail("Manifest source commit/version/count does not match the pinned source.")

    source = fetch_json(SOURCE_URL)
    metadata = source.get("metadata") if isinstance(source, dict) else None
    records = source.get("duas") if isinstance(source, dict) else None
    if not isinstance(metadata, dict) or not isinstance(records, list):
        fail("Pinned source metadata or duas list is missing.")
    if str(metadata.get("license", "")).strip().lower() != "public domain":
        fail("Pinned source no longer declares Public Domain; review licensing.")
    if str(metadata.get("version", "")).strip() != SOURCE_VERSION:
        fail("Pinned source version differs from the manifest.")
    if metadata.get("total_duas") != len(records):
        fail("Source total_duas does not match the actual record count.")

    records_by_id = {}
    for record in records:
        try:
            source_id = int(record.get("id"))
        except (AttributeError, TypeError, ValueError):
            continue
        if source_id in records_by_id:
            fail(f"Duplicate source record ID {source_id}.")
        records_by_id[source_id] = record

    prepared = []
    ids_seen: set[int] = set()
    slugs_seen: set[str] = set()
    texts_seen: dict[str, str] = {}
    types = Counter()
    prayer_numbers: set[int] = set()
    munajat_numbers: set[int] = set()

    for item in items:
        if not isinstance(item, dict):
            fail("Malformed Sahifa manifest entry.")
        source_id = item.get("sourceId")
        slug = item.get("slug")
        title = item.get("title")
        source_name = item.get("sourceName")
        source_reference = item.get("sourceReference")
        if not isinstance(source_id, int) or source_id in ids_seen:
            fail(f"Invalid or duplicate source ID: {source_id!r}")
        if not isinstance(slug, str) or not slug or slug in slugs_seen:
            fail(f"Invalid or duplicate slug: {slug!r}")
        if not isinstance(title, str) or not title.strip():
            fail(f"Missing Arabic title for {slug}.")
        if PERSIAN_RE.search(title) or LATIN_RE.search(title) or not ARABIC_RE.search(title):
            fail(f"Title must be Arabic-only: {slug}.")
        if item.get("sourceUrl") != SOURCE_PAGE:
            fail(f"Wrong pinned source page for {slug}.")
        if not isinstance(source_reference, str) or not source_reference.strip():
            fail(f"Missing Sahifa reference for {slug}.")

        sahifa_match = re.fullmatch(r"sahifa-sajjadiya-(\d{2})", slug)
        munajat_match = re.fullmatch(r"munajat-sahifa-(\d{2})", slug)
        if sahifa_match:
            number = int(sahifa_match.group(1))
            if number < 1 or number > 61 or number in prayer_numbers:
                fail(f"Invalid or duplicate Sahifa prayer number in {slug}.")
            prayer_numbers.add(number)
            entry_type = "sahifa" if number <= 54 else "sahifaSupplement"
        elif munajat_match:
            number = int(munajat_match.group(1))
            if number < 1 or number > 15 or number in munajat_numbers:
                fail(f"Invalid or duplicate Munajat number in {slug}.")
            munajat_numbers.add(number)
            entry_type = "munajat"
        else:
            fail(f"Unexpected Sahifa/Munajat slug: {slug}.")

        raw = records_by_id.get(source_id)
        if not isinstance(raw, dict):
            fail(f"Source record {source_id} is missing for {slug}.")
        if raw.get("name") != source_name:
            fail(f"Source identity changed for {slug}: {raw.get('name')!r}.")
        rows = raw.get("rows")
        if not isinstance(rows, list) or not rows:
            fail(f"Missing complete source rows for {slug}.")

        omitted_instruction_count = sum(
            1 for row in rows
            if isinstance(row, dict) and str(row.get("instruction") or "").strip()
        )
        omitted_blank_row_ids = [
            str(row.get("show_id") or "").strip()
            for row in rows
            if isinstance(row, dict)
            and not str(row.get("arabic") or "").strip()
            and not str(row.get("instruction") or "").strip()
            and not str(row.get("title") or "").strip()
        ]
        if any(value and not value.isdecimal() for value in omitted_blank_row_ids):
            fail(f"Invalid blank-row display ID in {slug}.")

        lines = []
        for row in rows:
            if not isinstance(row, dict):
                fail(f"Malformed source row in {slug}.")
            display_id = str(row.get("show_id") or "").strip()
            if display_id and not display_id.isdecimal():
                fail(f"Invalid non-numeric show_id in {slug}: {display_id!r}.")
            value = row.get("arabic")
            if not isinstance(value, str):
                fail(f"Missing Arabic field in {slug}.")
            value = value.strip().replace("ک", "ك").replace("ی", "ي")
            if not value:
                continue
            if PERSIAN_RE.search(value) or LATIN_RE.search(value) or not ARABIC_RE.search(value):
                fail(f"Persian/Latin/non-Arabic text found in {slug}.")
            lines.append({
                "index": row.get("index") if isinstance(row.get("index"), int) else len(lines) + 1,
                "displayId": display_id,
                "kind": "arabic",
                "text": value,
            })
        if not lines:
            fail(f"No Arabic text found in {slug}.")

        signature = normalize_text(" ".join(line["text"] for line in lines))
        if not signature:
            fail(f"Empty normalized text for {slug}.")
        if signature in texts_seen:
            fail(f"Duplicate full text: {slug} duplicates {texts_seen[signature]}.")
        texts_seen[signature] = slug

        prepared.append({
            "sourceId": source_id,
            "sourceName": source_name,
            "slug": slug,
            "title": title.strip(),
            "alternateName": str(item.get("alternateName") or "").strip(),
            "category": CATEGORY,
            "sourceReference": source_reference.strip(),
            "sourceUrl": SOURCE_PAGE,
            "type": entry_type,
            "omittedSourceInstructionCount": omitted_instruction_count,
            "omittedSourceBlankRowIds": omitted_blank_row_ids,
            "lines": lines,
        })
        ids_seen.add(source_id)
        slugs_seen.add(slug)
        types[entry_type] += 1

    if prayer_numbers != set(range(1, 62)):
        fail("The Sahifa collection must include prayers 1 through 61 exactly once.")
    if munajat_numbers != set(range(1, 16)):
        fail("The Munajat collection must include all 15 texts exactly once.")
    if types != Counter({
        "sahifa": EXPECTED_CORE_DUAS,
        "sahifaSupplement": EXPECTED_WEEKDAY_APPENDICES,
        "munajat": EXPECTED_MUNAJAT,
    }):
        fail(f"Unexpected Sahifa/Munajat type counts: {dict(types)!r}.")
    if len(prepared) != EXPECTED_TOTAL or len(texts_seen) != EXPECTED_TOTAL:
        fail("The prepared Sahifa/Munajat collection is incomplete or duplicated.")

    result = {
        "metadata": {
            "sourceProject": "KazTronics/AhlulBayt_Treasures",
            "sourceVersion": SOURCE_VERSION,
            "sourceCommit": SOURCE_COMMIT,
            "sourceIndex": SOURCE_URL,
            "sourcePage": SOURCE_PAGE,
            "count": EXPECTED_TOTAL,
            "categoryCounts": {CATEGORY: EXPECTED_TOTAL},
            "typeCounts": dict(types),
            "note": (
                "Full offline collection: 54 core Sahifa supplications, "
                "7 separately typed weekday appendices (numbers 55-61), "
                "and all 15 Sahifa Munajat. Source text is pinned; editorial "
                "comparison against a trusted printed edition remains required."
            ),
            "license": "Text data declared Public Domain by the pinned source dataset.",
        },
        "entries": prepared,
    }
    atomic_json(DEST, result)
    print(
        f"Prepared {len(prepared)} Sahifa/Munajat texts: "
        f"{types['sahifa']} core prayers, {types['sahifaSupplement']} weekday appendices, "
        f"{types['munajat']} Munajat."
    )


if __name__ == "__main__":
    main()
