#!/usr/bin/env python3
"""Download and validate the open-source Mafatih al-Jinan data for offline app use.

Upstream project: https://github.com/aminpaydar/Mafatih
The upstream repository declares Apache License 2.0. This script preserves
chapter/section/article/item content, and adds separate provenance metadata.
"""
import html
import json
import re
import os
import tempfile
import urllib.request
from pathlib import Path

SOURCE_URL = "https://raw.githubusercontent.com/aminpaydar/Mafatih/master/mafatih-server/chapters.json"
DEST = Path("assets/mafatih/mafatih.json")


def main() -> None:
    request = urllib.request.Request(
        SOURCE_URL,
        headers={"User-Agent": "Mithaq-Al-Mumin/1.0 (offline Mafatih data preparation)"},
    )
    with urllib.request.urlopen(request, timeout=90) as response:
        payload = response.read()
    source = json.loads(payload.decode("utf-8"))
    if not isinstance(source, list) or not source:
        raise SystemExit("Mafatih source must be a non-empty JSON chapter list.")

    chapters_checked = sections_checked = articles_checked = items_checked = 0
    arabic_chapter_titles = [
        "الباب الأول: تعقيبات الصلوات ودعوات أيام الأسبوع وأعمال ليلة الجمعة ونهارها",
        "الباب الثاني: أعمال أشهر السنة الهجرية",
        "الباب الثالث: الزيارات",
    ]
    # Kaf/yeh variants are not evidence that a title is Persian: many Arabic
    # transcriptions use Persian Unicode forms for ك/ي. Normalize them first.
    persian_only_letters = set("پچژگ")

    def normalize_arabic_script(value: str) -> str:
        return (value.replace("ک", "ك").replace("ی", "ي")
                     .replace("ے", "ي").replace("ہ", "ه"))

    def has_persian_letters(value: str) -> bool:
        return any(character in persian_only_letters for character in value)

    def has_latin_letters(value: str) -> bool:
        return re.search(r"[A-Za-z]", value) is not None

    def has_persian_language_markers(value: str) -> bool:
        normalized = normalize_arabic_script(value)
        both_forms = f"{value} {normalized}"
        return re.search(
            r"دعای|دعاي|روزهای|روزهاي|روزها|هفته|فارسی|فارسي|برای|براي|میباشد|می شود|ميشود|خواهد شد|نمی|نمي",
            both_forms,
        ) is not None

    def is_arabic_recitation(value: str) -> bool:
        plain = html.unescape(re.sub(r"<[^>]*>", " ", value))
        return (
            any(0x0600 <= ord(character) <= 0x06FF for character in plain)
            and not has_latin_letters(plain)
            and not has_persian_letters(plain)
            and not has_persian_language_markers(plain)
        )

    for cidx, chapter in enumerate(source):
        if not isinstance(chapter, dict) or not isinstance(chapter.get("title"), str):
            raise SystemExit(f"Invalid Mafatih chapter at index {cidx}.")
        if (has_persian_letters(chapter["title"]) or has_latin_letters(chapter["title"])
                or has_persian_language_markers(chapter["title"])):
            if cidx < len(arabic_chapter_titles):
                chapter["title"] = arabic_chapter_titles[cidx]
            else:
                chapter["title"] = f"الباب رقم {chapter.get('id', cidx + 1)} من مفاتيح الجنان"
        chapter["title"] = normalize_arabic_script(chapter["title"])
        sections = chapter.get("sections")
        if not isinstance(sections, list):
            raise SystemExit(f"Chapter {cidx} has no sections list.")
        chapters_checked += 1
        for sidx, section in enumerate(sections):
            if not isinstance(section, dict) or not isinstance(section.get("title"), str):
                raise SystemExit(f"Invalid section {sidx} in chapter {cidx}.")
            if (has_persian_letters(section["title"]) or has_latin_letters(section["title"])
                    or has_persian_language_markers(section["title"])):
                section["title"] = f"الفصل رقم {section.get('id', sidx + 1)} من {chapter['title']}"
            section["title"] = normalize_arabic_script(section["title"])
            articles = section.get("articles")
            if not isinstance(articles, list):
                raise SystemExit(f"Section {sidx} in chapter {cidx} has no articles list.")
            sections_checked += 1
            for aidx, article in enumerate(articles):
                if not isinstance(article, dict) or not isinstance(article.get("title"), str):
                    raise SystemExit(f"Invalid article {aidx} in chapter {cidx}, section {sidx}.")
                if (has_persian_letters(article["title"]) or has_latin_letters(article["title"])
                    or has_persian_language_markers(article["title"])):
                    article["title"] = f"النص العربي رقم {article.get('id', aidx + 1)} ضمن {section['title']}"
                article["title"] = normalize_arabic_script(article["title"])
                items = article.get("items")
                if not isinstance(items, list):
                    raise SystemExit(f"Article {aidx} does not have an items list.")
                articles_checked += 1
                for item in items:
                    if not isinstance(item, dict):
                        raise SystemExit("Invalid Mafatih text item.")
                    if not isinstance(item.get("content", ""), str):
                        raise SystemExit("Mafatih item content is not text.")
                    items_checked += 1

                # The upstream source includes Persian translations (Translate) and
                # explanatory text. Keep only Arabic recitation items in the app bundle.
                arabic_items = []
                for item in items:
                    if not (
                        isinstance(item.get("type"), str)
                        and item["type"].strip().lower()
                        in {"text", "arabic", "arabictext", "arabic_text"}
                    ):
                        continue
                    item_content = normalize_arabic_script(item.get("content", ""))
                    # Omit actual Persian-language lines but preserve Arabic text
                    # that simply uses Persian-form kaf/yeh code points.
                    if not is_arabic_recitation(item_content):
                        continue
                    item["content"] = item_content
                    arabic_items.append(item)
                article["items"] = arabic_items

    result = {
        "metadata": {
            "title": "Mafatih al-Jinan data",
            "upstream_project": "aminpaydar/Mafatih",
            "source_url": SOURCE_URL,
            "license": "Apache-2.0 as declared by the upstream repository; see licenses/MAFATIH_APACHE_2.0.txt",
            "note": "Arabic recitation items only; Persian kaf/yeh variants are normalized, Persian-only lines and translations are omitted. Compare religious wording with a trusted printed edition before treating it as a critical text.",
        },
        "chapters": source,
    }
    DEST.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix="mafatih-", suffix=".json", dir=DEST.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(result, handle, ensure_ascii=False, separators=(",", ":"))
            handle.write("\n")
        os.replace(temporary, DEST)
    finally:
        if os.path.exists(temporary):
            os.remove(temporary)

    print(
        "Prepared offline Mafatih library: "
        f"{chapters_checked} chapters, {sections_checked} sections, "
        f"{articles_checked} articles, {items_checked} text items"
    )


if __name__ == "__main__":
    main()
