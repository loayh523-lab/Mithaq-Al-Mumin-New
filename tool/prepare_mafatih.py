#!/usr/bin/env python3
"""Download and validate the open-source Mafatih al-Jinan data for offline app use.

Upstream project: https://github.com/aminpaydar/Mafatih
The upstream repository declares Apache License 2.0. This script preserves
chapter/section/article/item content, and adds separate provenance metadata.
"""
import json
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
    for cidx, chapter in enumerate(source):
        if not isinstance(chapter, dict) or not isinstance(chapter.get("title"), str):
            raise SystemExit(f"Invalid Mafatih chapter at index {cidx}.")
        sections = chapter.get("sections")
        if not isinstance(sections, list):
            raise SystemExit(f"Chapter {cidx} has no sections list.")
        chapters_checked += 1
        for sidx, section in enumerate(sections):
            if not isinstance(section, dict) or not isinstance(section.get("title"), str):
                raise SystemExit(f"Invalid section {sidx} in chapter {cidx}.")
            articles = section.get("articles")
            if not isinstance(articles, list):
                raise SystemExit(f"Section {sidx} in chapter {cidx} has no articles list.")
            sections_checked += 1
            for aidx, article in enumerate(articles):
                if not isinstance(article, dict) or not isinstance(article.get("title"), str):
                    raise SystemExit(f"Invalid article {aidx} in chapter {cidx}, section {sidx}.")
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
                article["items"] = [
                    item for item in items
                    if isinstance(item.get("type"), str)
                    and item["type"].strip().lower() in {"text", "arabic", "arabictext", "arabic_text"}
                    and item.get("content", "").strip()
                ]

            # Empty articles would appear as broken/blank entries after Persian
            # translations have been excluded, so remove them from the offline UI.
            section["articles"] = [article for article in articles if article["items"]]

        # Hide sections and chapters that contain no remaining Arabic recitation.
        chapter["sections"] = [section for section in sections if section["articles"]]

    source = [chapter for chapter in source if chapter["sections"]]
    retained_sections = sum(len(chapter["sections"]) for chapter in source)
    retained_articles = sum(
        len(section["articles"])
        for chapter in source
        for section in chapter["sections"]
    )
    retained_items = sum(
        len(article["items"])
        for chapter in source
        for section in chapter["sections"]
        for article in section["articles"]
    )
    if not source:
        raise SystemExit("No chapters with Arabic recitation remain after filtering.")

    result = {
        "metadata": {
            "title": "Mafatih al-Jinan data",
            "upstream_project": "aminpaydar/Mafatih",
            "source_url": SOURCE_URL,
            "license": "Apache-2.0 as declared by the upstream repository; see licenses/MAFATIH_APACHE_2.0.txt",
            "note": "Persian translation/explanatory items and any empty article, section or chapter are omitted; retained Arabic source items are otherwise preserved.",
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
        f"{len(source)} retained chapters, {retained_sections} retained sections, "
        f"{retained_articles} retained articles, {retained_items} retained Arabic items "
        f"(validated {chapters_checked} chapters, {sections_checked} sections, "
        f"{articles_checked} articles, {items_checked} source items)"
    )


if __name__ == "__main__":
    main()
