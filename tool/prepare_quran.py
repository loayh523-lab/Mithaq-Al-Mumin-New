#!/usr/bin/env python3
"""Prepare a bundled, offline Quran text asset from the Tanzil corpus.

The Arabic verse strings are copied unchanged; only the surrounding JSON shape
is reduced for efficient lookup in the app. Run before flutter pub get/build.
"""
import json
import os
import tempfile
import urllib.request
from pathlib import Path

SOURCE_URL = "https://raw.githubusercontent.com/dotquran/corpus/main/processed/uthmani/quran-uthmani.json"
DEST = Path("assets/quran/uthmani_surahs.json")
EXPECTED_SURAHS = 114
EXPECTED_AYAHS = 6236


def main() -> None:
    request = urllib.request.Request(
        SOURCE_URL,
        headers={"User-Agent": "Mithaq-Al-Mumin/1.0 (offline Quran asset preparation)"},
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        payload = response.read()
    source = json.loads(payload.decode("utf-8"))
    surahs = source.get("surahs")
    if not isinstance(surahs, list) or len(surahs) != EXPECTED_SURAHS:
        raise SystemExit("Quran source schema invalid: expected exactly 114 surahs")

    reduced = []
    total = 0
    for expected_number, surah in enumerate(surahs, start=1):
        number = surah.get("number", surah.get("numberInQuran"))
        if number != expected_number:
            raise SystemExit(f"Quran source surah order mismatch at {expected_number}")
        ayahs = surah.get("ayahs")
        if not isinstance(ayahs, list) or not ayahs:
            raise SystemExit(f"Missing ayahs for surah {expected_number}")
        texts = []
        # The source stores the standalone basmalah as ayah 0 for some surahs.
        # The app renders that preface separately, so keep canonical numbered ayahs only.
        for ayah in ayahs:
            ayah_number = ayah.get("number", ayah.get("numberInSurah"))
            text = ayah.get("text")
            if ayah_number == 0:
                continue
            expected_ayah = len(texts) + 1
            if ayah_number != expected_ayah or not isinstance(text, str) or not text.strip():
                raise SystemExit(f"Invalid ayah {expected_number}:{expected_ayah}")
            texts.append({"number": expected_ayah, "text": text})
        reduced.append({"number": expected_number, "ayahs": texts})
        total += len(texts)

    if total != EXPECTED_AYAHS:
        raise SystemExit(f"Quran source total mismatch: expected 6236 ayahs, got {total}")

    result = {
        "metadata": {
            "source": "Tanzil Project via dotquran/corpus",
            "source_url": "https://tanzil.net/",
            "data_repository": "https://github.com/dotquran/corpus",
            "license": "Creative Commons Attribution 3.0; Arabic text is preserved unchanged.",
        },
        "surahs": reduced,
    }
    DEST.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix="uthmani-", suffix=".json", dir=DEST.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(result, handle, ensure_ascii=False, separators=(",", ":"))
            handle.write("\n")
        os.replace(temporary, DEST)
    finally:
        if os.path.exists(temporary):
            os.remove(temporary)
    print(f"Prepared offline Quran asset: {EXPECTED_SURAHS} surahs, {total} ayahs")


if __name__ == "__main__":
    main()
