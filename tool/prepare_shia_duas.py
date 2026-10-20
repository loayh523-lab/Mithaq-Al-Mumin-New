#!/usr/bin/env python3
"""Prepare the CC0 Shia supplication/ziyara and Sahifa dataset for offline use.

Upstream dataset: https://github.com/adeeb10abbas/shia-library-json
It declares CC0 1.0 Universal and records source URLs to Thaqalayn public pages.
"""
import html
import json
import os
import re
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

BASE = "https://raw.githubusercontent.com/adeeb10abbas/shia-library-json/main"
INDEX_URL = f"{BASE}/index/duas.json"
DEST = Path("assets/shia_duas/shia_duas.json")


def fetch_json(url: str, attempts: int = 3):
    headers = {"User-Agent": "Mithaq-Al-Mumin/1.0 (offline Shia library preparation)"}
    for attempt in range(attempts):
        try:
            request = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(request, timeout=45) as response:
                return json.loads(response.read().decode("utf-8"))
        except (urllib.error.URLError, TimeoutError) as exc:
            if attempt + 1 >= attempts:
                raise SystemExit(f"Unable to download source JSON: {url} ({exc})") from exc
            time.sleep(1.5 * (attempt + 1))


CATEGORY_MAP = {
    "أدعية عامة": "أدعية عامة",
    "أدعية الصباح": "أدعية الصباح",
    "أدعية المساء": "أدعية المساء",
    "أذكار مشتركة": "الأذكار المشتركة",
    "الزيارات": "الزيارات",
    "تعقيبات": "تعقيبات الصلوات",
    "أدعية الأيام": "أدعية الأيام",
    "الأعمال اليومية والمناسبات": "الأعمال اليومية والمناسبات",
    "الأعمال الشهرية والمناسبات": "الأعمال الشهرية والمناسبات",
    "أدعية صاحب الزمان": "أدعية صاحب الزمان",
    "أدعية الحاجات والشفاء": "أدعية الحاجات والشفاء",
    "أدعية الأشهر والمناسبات": "أدعية الأشهر والمناسبات",
    "المناجيات الخمس عشرة": "المناجيات الخمس عشرة",
    "الصحيفة السجادية": "الصحيفة السجادية",
}


def plain_arabic_text(value: str) -> str:
    value = html.unescape(value)
    value = re.sub(r"<br\\s*/?>", "\\n", value, flags=re.IGNORECASE)
    value = re.sub(r"</(p|div|li|h[1-6])\\s*>", "\\n\\n", value, flags=re.IGNORECASE)
    value = re.sub(r"<[^>]*>", " ", value)
    value = value.replace("ک", "ك").replace("ی", "ي").replace("ے", "ي").replace("ہ", "ه")
    return re.sub(r"\\n{3,}", "\\n\\n", value).strip()


def is_arabic_recitation(value: str) -> bool:
    value = plain_arabic_text(value)
    if not any(0x0600 <= ord(char) <= 0x06FF for char in value):
        return False
    if re.search(r"[A-Za-zپچژگ]", value):
        return False
    # These are Persian-language markers even when every letter is shared with Arabic.
    if re.search(
        r"دعای|دعاي|دعاهای|دعاهاي|روزهای|روزهاي|روزها|هفته|فارسی|فارسي|برای|براي|میباشد|می شود|ميشود|خواهد شد|نمی|نمي|هنگام|آفتاب|شامگاه|صبحگاه|صبح و شام|صبح و مساء|زیارت|زيارت|زیارات|زيارات|مناجات",
        value,
    ):
        return False
    return True


def merge_mafatih_entries(base_entries: list[dict]) -> tuple[list[dict], int]:
    """Merge the generated Arabic Mafatih data into the app's one dua/ziyara asset."""
    source_path = Path("assets/mafatih/mafatih.json")
    if not source_path.is_file():
        raise SystemExit(
            "Arabic Mafatih data is missing. Run tool/prepare_mafatih.py before preparing the unified dua library."
        )
    try:
        mafatih = json.loads(source_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise SystemExit(f"Could not read generated Mafatih data: {exc}") from exc

    chapters = mafatih.get("chapters") if isinstance(mafatih, dict) else None
    if not isinstance(chapters, list) or not chapters:
        raise SystemExit("Generated Mafatih data has no readable chapters.")

    seen = {
        (
            entry.get("categoryOverride", "") or "",
            str(entry.get("title", "")).strip(),
            plain_arabic_text("\\n".join(
                line.get("text", "")
                for line in entry.get("lines", [])
                if isinstance(line, dict) and line.get("kind") == "arabic"
            )),
        )
        for entry in base_entries
    }
    added = 0
    category_counts: dict[str, int] = {}

    for chapter in chapters:
        if not isinstance(chapter, dict):
            continue
        chapter_title = str(chapter.get("title", "")).strip()
        for section in chapter.get("sections", []) or []:
            if not isinstance(section, dict):
                continue
            section_title = str(section.get("title", "")).strip()
            for article in section.get("articles", []) or []:
                if not isinstance(article, dict):
                    continue
                items = article.get("items", [])
                if not isinstance(items, list):
                    continue

                lines = []
                for item in items:
                    if not isinstance(item, dict) or not isinstance(item.get("content"), str):
                        continue
                    if not (
                        isinstance(item.get("type"), str)
                        and item["type"].strip().lower()
                        in {"text", "arabic", "arabictext", "arabic_text"}
                    ):
                        continue
                    text = plain_arabic_text(item["content"])
                    if not text or not is_arabic_recitation(text):
                        continue
                    lines.append({
                        "index": len(lines) + 1,
                        "kind": "arabic",
                        "text": text,
                    })
                if not lines:
                    continue

                raw_category = str(article.get("category", "")).strip()
                category = CATEGORY_MAP.get(raw_category, "أدعية عامة")
                title = str(article.get("title", "")).strip()
                if not title or re.search(r"[A-Za-zپچژگ]", title):
                    title = "نص عربي من الأدعية والزيارات"
                if not any(0x0600 <= ord(char) <= 0x06FF for char in title):
                    title = "نص عربي من الأدعية والزيارات"

                normalized_body = plain_arabic_text("\\n".join(line["text"] for line in lines))
                key = (category, title, normalized_body)
                if key in seen:
                    continue
                seen.add(key)

                chapter_id = chapter.get("id", 0)
                section_id = section.get("id", 0)
                article_id = article.get("id", len(base_entries) + added + 1)
                base_entries.append({
                    "slug": f"mafatih-{chapter_id}-{section_id}-{article_id}",
                    "title": title,
                    "alternateName": "",
                    "type": "mafatih",
                    "sourceUrl": "",
                    "sourceLabel": (
                        f"مفاتيح الجنان، باب: {chapter_title}، "
                        f"فصل: {section_title}، عنوان النص: {title}"
                    ),
                    "categoryOverride": category,
                    "lines": lines,
                })
                added += 1
                category_counts[category] = category_counts.get(category, 0) + 1

    if added == 0:
        raise SystemExit(
            "Mafatih merge produced no Arabic entries. Check the source types and Arabic filtering rules."
        )
    return base_entries, added


def main() -> None:
    index = fetch_json(INDEX_URL)
    entries = index.get("duas") if isinstance(index, dict) else None
    if not isinstance(entries, list) or not entries:
        raise SystemExit("Shia dua source index is empty or has an unexpected shape.")

    prepared = []
    total_arabic_lines = 0
    total_lines = 0
    slugs_seen = set()
    for record in entries:
        slug = record.get("slug")
        if not isinstance(slug, str) or not slug or slug in slugs_seen:
            raise SystemExit("Invalid or duplicate slug in the Shia dua index.")
        slugs_seen.add(slug)
        raw = fetch_json(f"{BASE}/db/duas/{slug}.json")
        if raw.get("slug") != slug:
            raise SystemExit(f"Slug mismatch for {slug}.")
        lines = raw.get("lines")
        if not isinstance(lines, list) or not lines:
            raise SystemExit(f"Missing line-by-line content for {slug}.")

        normalized_lines = []
        for line in lines:
            if not isinstance(line, dict):
                raise SystemExit(f"Invalid line in {slug}.")
            kind = line.get("kind")
            text = line.get("text")
            if not isinstance(kind, str) or not isinstance(text, str):
                raise SystemExit(f"Missing line type/text in {slug}.")
            if not text.strip():
                continue
            normalized_lines.append({
                "index": line.get("index", len(normalized_lines) + 1),
                "kind": kind,
                "text": text,
            })
            total_lines += 1
            if kind.lower() == "arabic":
                total_arabic_lines += 1

        if not any(item["kind"].lower() == "arabic" for item in normalized_lines):
            raise SystemExit(f"No Arabic lines found in {slug}.")

        prepared.append({
            "slug": slug,
            "title": raw.get("title") or record.get("title") or slug,
            "alternateName": raw.get("alternateName") or record.get("alternateName") or "",
            "type": raw.get("type") or "dua",
            "sourceUrl": raw.get("url") or record.get("url") or "",
            "lines": normalized_lines,
        })

    # The build workflow prepares Mafatih first. Merge its Arabic entries now so
    # opening the library on the device requires one asset load, not a 5 MB
    # second catalogue parse and runtime merge.
    prepared, mafatih_count = merge_mafatih_entries(prepared)

    result = {
        "metadata": {
            "sourceProject": "مكتبة الأدعية والزيارات العربية الموحدة",
            "sourceIndex": INDEX_URL,
            "contentSource": "Arabic entries from the Shia library dataset and Mafatih al-Jinan",
            "license": "Per-entry sources/licenses: CC0 1.0 for the base dataset; Apache-2.0 for Mafatih entries; see THIRD_PARTY_NOTICES.md.",
            "count": len(prepared),
            "baseSourceCount": len(entries),
            "mafatihCount": mafatih_count,
            "note": "Mafatih entries are merged into destination categories and keep a human-readable book/chapter/section citation. Persian-only lines are omitted.",
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
        f"Prepared offline Shia library: {len(prepared)} texts, "
        f"{total_arabic_lines} Arabic lines, {total_lines} total lines, "
        f"{mafatih_count} merged Mafatih entries"
    )


if __name__ == "__main__":
    main()
