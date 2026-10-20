#!/usr/bin/env python3
"""Prepare an offline Arabic Nahj al-Balagha collection from a MIT-licensed SQLite source.

Upstream: https://github.com/saber13812002/application-nahj-al-balaghah
The application database stores entries in table 'nahj': id, cat, num, title, cnt, fav.
Categories 1, 2, and 3 are sermons, letters, and maxims respectively.
"""
import json
import os
import sqlite3
import tempfile
import urllib.error
import urllib.request
from pathlib import Path

SOURCE_URL = (
    "https://raw.githubusercontent.com/"
    "saber13812002/application-nahj-al-balaghah/master/nahj-sqlite.db"
)
DEST = Path("assets/nahj/nahj.json")
USER_AGENT = "Mithaq-Al-Mumin/1.0 (offline Nahj al-Balagha preparation)"


def normalize_arabic(value: str) -> str:
    """Normalize Persian keyboard forms found in Arabic text without translating or rewriting it."""
    return (
        value.replace("ک", "ك")
        .replace("ی", "ي")
        .replace("ے", "ي")
        .replace("ہ", "ه")
        .strip()
    )


def main() -> None:
    request = urllib.request.Request(SOURCE_URL, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(request, timeout=90) as response:
            database_bytes = response.read()
    except (urllib.error.URLError, TimeoutError) as exc:
        raise SystemExit(f"Could not download the Nahj source database: {exc}") from exc

    if not database_bytes.startswith(b"SQLite format 3\\x00"):
        raise SystemExit("Nahj source did not return a valid SQLite database.")

    fd, database_path = tempfile.mkstemp(prefix="nahj-source-", suffix=".db")
    try:
        with os.fdopen(fd, "wb") as handle:
            handle.write(database_bytes)

        connection = sqlite3.connect(database_path)
        connection.row_factory = sqlite3.Row
        try:
            tables = {
                row["name"]
                for row in connection.execute(
                    "SELECT name FROM sqlite_master WHERE type='table'"
                )
            }
            if "nahj" not in tables:
                raise SystemExit("The upstream database has no 'nahj' table.")

            columns = {
                row["name"] for row in connection.execute("PRAGMA table_info(nahj)")
            }
            required = {"id", "cat", "num", "title", "cnt"}
            if not required.issubset(columns):
                raise SystemExit(
                    f"Unexpected Nahj schema. Required columns missing: {sorted(required - columns)}"
                )

            rows = connection.execute(
                """
                SELECT id, cat, num, title, cnt
                FROM nahj
                WHERE cat IN (1, 2, 3)
                  AND TRIM(COALESCE(cnt, '')) <> ''
                ORDER BY cat ASC, CAST(num AS INTEGER) ASC, id ASC
                """
            ).fetchall()
        finally:
            connection.close()
    finally:
        if os.path.exists(database_path):
            os.remove(database_path)

    entries = []
    counts = {1: 0, 2: 0, 3: 0}
    for row in rows:
        category = int(row["cat"])
        title = normalize_arabic(str(row["title"] or ""))
        text = normalize_arabic(str(row["cnt"] or ""))
        number = normalize_arabic(str(row["num"] or "")).strip()
        if not text or not title:
            continue
        # Keep the Arabic source wording intact; only strip empty/invalid records.
        entries.append(
            {
                "id": int(row["id"]),
                "category": category,
                "number": number,
                "title": title,
                "text": text,
            }
        )
        counts[category] += 1

    if len(entries) < 500 or any(counts[category] < 50 for category in (1, 2, 3)):
        raise SystemExit(
            f"Nahj export looks incomplete: total={len(entries)}, category_counts={counts}"
        )

    result = {
        "metadata": {
            "title": "نهج البلاغة",
            "sourceProject": "saber13812002/application-nahj-al-balagha",
            "sourceUrl": SOURCE_URL,
            "license": "MIT; see licenses/NAHJ_MIT_LICENSE.txt",
            "contentNote": "Arabic text preserved from the upstream database. Numbering may vary across editions; verify quotations against a trusted printed edition.",
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
    fd, temporary = tempfile.mkstemp(prefix="nahj-", suffix=".json", dir=DEST.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\\n") as handle:
            json.dump(result, handle, ensure_ascii=False, separators=(",", ":"))
            handle.write("\\n")
        os.replace(temporary, DEST)
    finally:
        if os.path.exists(temporary):
            os.remove(temporary)

    print(f"Prepared offline Nahj al-Balagha: {len(entries)} entries; category counts={counts}")


if __name__ == "__main__":
    main()
