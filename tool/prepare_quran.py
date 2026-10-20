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
EXPECTED_AYAH_COUNTS = [7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,135,112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,53,89,59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,12,30,52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,30,20,15,21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6]


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
        expected_ayah_count = EXPECTED_AYAH_COUNTS[expected_number - 1]
        if len(texts) != expected_ayah_count:
            raise SystemExit(
                f"Surah {expected_number} ayah count mismatch: "
                f"expected {expected_ayah_count}, got {len(texts)}"
            )
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
            "copyright_notice": "Tanzil Quran Text, Copyright (C) 2007-2024 Tanzil Project. License: Creative Commons Attribution 3.0. https://tanzil.net/terms",
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
