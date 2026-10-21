#!/usr/bin/env python3
"""Prepare the CC0 Shia supplication/ziyara and Sahifa dataset for offline use.

Upstream dataset: https://github.com/adeeb10abbas/shia-library-json
It declares CC0 1.0 Universal and records source URLs to Thaqalayn public pages.
"""
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
            if not text.strip() or kind.lower() != "arabic":
                # The app is Arabic-only: omit Persian translations and
                # transliterations instead of merely hiding them in the UI.
                continue
            normalized_lines.append({
                "index": line.get("index", len(normalized_lines) + 1),
                "kind": "arabic",
                "text": text,
            })
            total_lines += 1
            total_arabic_lines += 1

        if not any(item["kind"].lower() == "arabic" for item in normalized_lines):
            raise SystemExit(f"No Arabic lines found in {slug}.")

        # Persian titles must not leak into the app. If the source title
        # contains Persian-script letters, use a safe Arabic label; keep the
        # source URL so the original attribution remains available.
        raw_title = str(raw.get("title") or record.get("title") or "").strip()
        raw_alt = str(raw.get("alternateName") or record.get("alternateName") or "").strip()
        persian_script = re.compile(r"[پچژگ]")
        title = raw_title.replace("ک", "ك").replace("ی", "ي").replace("دعاي ", "دعاء ")
        alternate_name = raw_alt.replace("ک", "ك").replace("ی", "ي").replace("دعاي ", "دعاء ")
        if persian_script.search(raw_title) or not title:
            kind_name = str(raw.get("type") or record.get("type") or "dua").lower()
            title = "زيارة" if "ziyar" in kind_name else ("مناجاة" if "munajat" in kind_name else "دعاء")
        if persian_script.search(raw_alt):
            alternate_name = ""
        prepared.append({
            "slug": slug,
            "title": title,
            "alternateName": alternate_name,
            "type": raw.get("type") or "dua",
            "sourceUrl": raw.get("url") or record.get("url") or "",
            "lines": normalized_lines,
        })

    # Remove exact duplicate prayer texts while retaining distinct entries that
    # happen to share a title. This makes the displayed count reflect unique text.
    def text_key(value: str) -> str:
        value = re.sub(r"[\\u064B-\\u065F\\u0670\\u0640]", "", value)
        value = value.replace("أ", "ا").replace("إ", "ا").replace("آ", "ا").replace("ى", "ي")
        return re.sub(r"[^\\u0600-\\u06FF0-9]", "", value).lower()

    before_dedupe = len(prepared)
    unique_entries = []
    seen_texts = set()
    for entry in prepared:
        joined_text = text_key(" ".join(line["text"] for line in entry["lines"]))
        if not joined_text or joined_text in seen_texts:
            continue
        seen_texts.add(joined_text)
        unique_entries.append(entry)
    prepared = unique_entries
    duplicate_texts_removed = before_dedupe - len(prepared)
    total_arabic_lines = sum(len(entry["lines"]) for entry in prepared)

    result = {
        "metadata": {
            "sourceProject": "adeeb10abbas/shia-library-json",
            "sourceIndex": INDEX_URL,
            "contentSource": "Thaqalayn public pages as recorded in source metadata",
            "license": "CC0 1.0 Universal; see licenses/SHIA_LIBRARY_CC0_1.0.txt",
            "count": len(prepared),
            "duplicateTextsRemoved": duplicate_texts_removed,
            "note": "Arabic text from the selected CC0 Shia library only. Each entry retains sourceUrl; verify wording against a trusted edition. No additional compilation is merged.",
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
        f"Prepared offline Shia library: {len(prepared)} unique texts "
        f"({duplicate_texts_removed} duplicate texts removed), "
        f"{total_arabic_lines} Arabic lines, {total_lines} source lines"
    )


if __name__ == "__main__":
    main()
