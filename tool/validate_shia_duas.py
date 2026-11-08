#!/usr/bin/env python3
"""Validate the committed offline Arabic dua/ziyarat asset without regenerating it."""
from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path

ASSET = Path("assets/shia_duas/shia_duas.json")
EXPECTED_TOTAL = 250
MAX_DATABASE_ONLY_ENTRIES = 92
SOURCE_DATASET_COMMIT = "a59bd5f8fe078532622a08ea60c19d164fb425cb"
SOURCE_DATASET_URL = f"https://github.com/KazTronics/AhlulBayt_Treasures/blob/{SOURCE_DATASET_COMMIT}/duas_data.json"
EXPECTED_CATEGORIES = {
    "الورد اليومي والتعقيبات": 32,
    "الأدعية الكبرى والمناجاة الشريفة": 25,
    "أدعية المناسبات والشهور العبادية": 50,
    "الصحيفة السجادية المباركة (نفحات مختارة)": 35,
    "أدعية الحوائج، التحصينات والرزق": 50,
    "الزيارات الشريفة والمقامات المقدسة": 58,
}
ALLOWED_TYPES = {"dua", "dhikr", "daily", "munajat", "occasion", "sahifa", "quran", "ziyarat"}
EXPECTED_QURAN_REFERENCES = {
    "hajat-137": "سورة البقرة، الآيات 255–257 (2:255–257)",
    "hajat-287": "سورة آل عمران، الآيتان 18–19 (3:18–19)",
    "hajat-288": "سورة آل عمران، الآيتان 26–27 (3:26–27)",
    "hajat-317": "سورة الأنبياء، الآيتان 87–88 (21:87–88)",
    "hajat-318": "سورة الأنعام، الآية 59 (6:59)",
    "major-292": "سورة آل عمران، الآية 147 (3:147)",
    "major-293": "سورة آل عمران، الآية 8 (3:8)",
}
EXPECTED_DUA_SOURCE_REFERENCES = {
    "daily-283": "جنة الأمان الواقية وجنة الإيمان الباقية",
    "daily-284": "مفاتيح الجنان",
    "daily-285": "الكفعمي",
    "daily-286": "مدارك العروة",
    "daily-296": "من لا يحضره الفقيه",
    "daily-380": "من لا يحضره الفقيه",
    "daily-396": "الأمالي",
    "daily-397": "وسائل الشيعة",
    "major-17": "مفاتيح الجنان",
    "major-107": "مصباح الزائر",
    "major-358": "الكافي",
    "major-359": "مهج الدعوات",
    "major-362": "مصباح المتهجد",
    "major-405": "مصباح المتهجد",
    "major-408": "مكارم الأخلاق",
    "major-409": "مستدرك الوسائل",
    "major-410": "البلد الأمين",
    "major-415": "مفاتيح الجنان",
}

PERSIAN = re.compile(r"[\u067e\u0686\u0698\u06af\u06a9\u06cc]")
LATIN = re.compile(r"[A-Za-z]")
ARABIC = re.compile(r"[\u0600-\u06ff]")


def normalize(value: str) -> str:
    value = re.sub(r"[\u064b-\u065f\u0670\u0640\s،؛,.!?؟:…()\-]", "", value)
    value = re.sub(r"[أإآٱ]", "ا", value).replace("ى", "ي")
    return value


def fail(errors: list[str]) -> None:
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    if not ASSET.is_file():
        fail([f"Missing asset: {ASSET}"])
    try:
        data = json.loads(ASSET.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail([f"Cannot read valid UTF-8 JSON: {exc}"])

    metadata = data.get("metadata", {})
    entries = data.get("entries")
    if not isinstance(entries, list):
        fail(["The asset must contain an entries array."])

    errors: list[str] = []
    if len(entries) != EXPECTED_TOTAL:
        errors.append(f"Expected {EXPECTED_TOTAL} entries, found {len(entries)}.")
    if metadata.get("count") != EXPECTED_TOTAL:
        errors.append(f"Metadata count must be {EXPECTED_TOTAL}.")
    if metadata.get("categoryCounts") != EXPECTED_CATEGORIES:
        errors.append("Metadata categoryCounts do not match the approved six-section distribution.")

    if metadata.get("sourceIndex") != SOURCE_DATASET_URL:
        errors.append("metadata.sourceIndex must point to the pinned Shia Devotions dataset commit.")

    categories: Counter[str] = Counter()
    types: Counter[str] = Counter()
    slugs: set[str] = set()
    signatures: dict[str, str] = {}
    database_only = 0

    for index, entry in enumerate(entries, start=1):
        if not isinstance(entry, dict):
            errors.append(f"Entry {index} is not an object.")
            continue
        slug = entry.get("slug")
        title = entry.get("title")
        category = entry.get("category")
        kind = entry.get("type")
        if not isinstance(slug, str) or not slug.strip():
            errors.append(f"Entry {index} has an empty slug.")
            slug = f"<entry-{index}>"
        elif slug in slugs:
            errors.append(f"Duplicate slug: {slug}")
        slugs.add(slug)

        if not isinstance(title, str) or not title.strip():
            errors.append(f"{slug}: missing title.")
        if category not in EXPECTED_CATEGORIES:
            errors.append(f"{slug}: unknown category {category!r}.")
        else:
            categories[category] += 1
        if kind not in ALLOWED_TYPES:
            errors.append(f"{slug}: unknown type {kind!r}.")
        else:
            types[kind] += 1
        if not isinstance(entry.get("sourceReference"), str) or not entry["sourceReference"].strip():
            errors.append(f"{slug}: missing source reference.")
        elif "لا يذكر السجل اسم الكتاب التراثي الأصلي" in entry["sourceReference"]:
            database_only += 1
        if not isinstance(entry.get("sourceUrl"), str) or not entry["sourceUrl"].startswith("https://"):
            errors.append(f"{slug}: missing HTTPS source URL.")

        source_url = entry.get("sourceUrl", "")
        if "github.com/KazTronics/AhlulBayt_Treasures/blob/main/" in source_url:
            errors.append(f"{slug}: mutable main-branch database URL; pin it to {SOURCE_DATASET_COMMIT}.")
        if "github.com/KazTronics/AhlulBayt_Treasures/blob/" in source_url and SOURCE_DATASET_COMMIT not in source_url:
            errors.append(f"{slug}: database URL does not use the pinned source commit.")

        lines = entry.get("lines")
        if not isinstance(lines, list) or not lines:
            errors.append(f"{slug}: missing Arabic text lines.")
            continue
        text_parts: list[str] = []
        for line_number, line in enumerate(lines, start=1):
            if not isinstance(line, dict):
                errors.append(f"{slug}: malformed line {line_number}.")
                continue
            text = line.get("text")
            if line.get("kind") != "arabic":
                errors.append(f"{slug}: line {line_number} is not marked Arabic.")
            if not isinstance(text, str) or not text.strip():
                errors.append(f"{slug}: empty line {line_number}.")
                continue
            if PERSIAN.search(text) or LATIN.search(text) or not ARABIC.search(text):
                errors.append(f"{slug}: non-Arabic/Persian/Latin characters in line {line_number}.")
            text_parts.append(text)

        signature = normalize("\n".join(text_parts))
        if not signature:
            errors.append(f"{slug}: empty normalized text.")
        elif signature in signatures:
            errors.append(f"Duplicate complete text: {slug} duplicates {signatures[signature]}.")
        else:
            signatures[signature] = slug

    if dict(categories) != EXPECTED_CATEGORIES:
        errors.append(f"Actual section counts differ: {dict(categories)}.")
    if len(slugs) != EXPECTED_TOTAL:
        errors.append(f"Expected {EXPECTED_TOTAL} unique slugs, found {len(slugs)}.")
    if len(signatures) != EXPECTED_TOTAL:
        errors.append(f"Expected {EXPECTED_TOTAL} unique complete texts, found {len(signatures)}.")

    entry_by_slug = {
        entry.get("slug"): entry
        for entry in entries
        if isinstance(entry, dict) and isinstance(entry.get("slug"), str)
    }
    for slug, expected_reference in EXPECTED_QURAN_REFERENCES.items():
        entry = entry_by_slug.get(slug)
        if entry is None:
            errors.append(f"{slug}: required Quranic source-verification entry is missing.")
            continue
        if entry.get("type") != "quran":
            errors.append(f"{slug}: Quranic source-verification entry must have type='quran'.")
        source_reference = entry.get("sourceReference", "")
        if expected_reference not in source_reference:
            errors.append(f"{slug}: expected direct Quran reference {expected_reference!r}.")
        if "لا يذكر السجل اسم الكتاب التراثي الأصلي" in source_reference:
            errors.append(f"{slug}: verified Quranic entry still carries an unresolved-source marker.")

    for slug, expected_reference in EXPECTED_DUA_SOURCE_REFERENCES.items():
        entry = entry_by_slug.get(slug)
        if entry is None:
            errors.append(f"{slug}: required source-verification entry is missing.")
            continue
        source_reference = entry.get("sourceReference", "")
        if expected_reference not in source_reference:
            errors.append(f"{slug}: expected historical source reference {expected_reference!r}.")
        if "لا يذكر السجل اسم الكتاب التراثي الأصلي" in source_reference:
            errors.append(f"{slug}: verified daily entry still carries an unresolved-source marker.")

    if database_only > MAX_DATABASE_ONLY_ENTRIES:
        errors.append(
            f"Source audit regression: {database_only} database-only records; "
            f"expected no more than {MAX_DATABASE_ONLY_ENTRIES}."
        )

    if entry_by_slug.get("major-415", {}).get("type") != "occasion":
        errors.append("major-415 must be classified as an act, not a standalone dua.")

    if types["sahifa"] != 20 or types["munajat"] != 15:
        errors.append("Sahifa section must contain 20 selected supplications and 15 Munajat.")
    if any(
        entry.get("type") == "munajat"
        and entry.get("category") != "الصحيفة السجادية المباركة (نفحات مختارة)"
        for entry in entries if isinstance(entry, dict)
    ):
        errors.append("All 15 Sahifa Munajat must remain in the Sahifa section.")

    if errors:
        fail(errors)

    print(
        f"Validated {len(entries)} Arabic texts across six sections; "
        f"{len(slugs)} unique slugs; {len(signatures)} unique complete texts; "
        f"{database_only} entries still cite only a database record and need source review."
    )


if __name__ == "__main__":
    main()
