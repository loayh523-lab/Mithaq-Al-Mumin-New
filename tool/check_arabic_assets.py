#!/usr/bin/env python3
"""Fail CI if bundled Arabic religious text contains Persian-specific letters."""
import json
import re
from pathlib import Path

ASSETS = (
    Path("assets/quran/chapters.json"),
    Path("assets/quran/uthmani_surahs.json"),
    Path("assets/quran/verse_metadata.json"),
    Path("assets/shia_duas/shia_duas.json"),
    Path("assets/shia_duas/sahifa_sajjadiya.json"),
)
# Includes Persian Yeh/Keheh as well as letters not used in standard Arabic.
FORBIDDEN = re.compile(r"[\u067e\u0686\u0698\u06af\u06cc\u06a9\u06d2\u06d3]")


def strings(value, path="$"):
    if isinstance(value, str):
        yield path, value
    elif isinstance(value, list):
        for index, item in enumerate(value):
            yield from strings(item, f"{path}[{index}]")
    elif isinstance(value, dict):
        for key, item in value.items():
            yield from strings(key, f"{path}.<key>")
            yield from strings(item, f"{path}.{key}")


def main() -> None:
    missing = [str(path) for path in ASSETS if not path.is_file()]
    if missing:
        raise SystemExit("Required offline content assets are missing:\n- " + "\n- ".join(missing))

    errors = []
    for asset in ASSETS:
        try:
            payload = json.loads(asset.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError) as error:
            errors.append(f"{asset}: invalid UTF-8 JSON ({error})")
            continue
        for location, value in strings(payload):
            match = FORBIDDEN.search(value)
            if match:
                errors.append(
                    f"{asset}:{location}: found forbidden Persian character U+{ord(match.group()):04X}"
                )
                if len(errors) >= 30:
                    break
        if len(errors) >= 30:
            break

    if errors:
        raise SystemExit(
            "Offline content validation failed. Normalize Persian characters to Arabic script "
            "and review the source text:\n- " + "\n- ".join(errors)
        )
    print(f"Validated {len(ASSETS)} offline content JSON assets: no Persian-specific characters found.")


if __name__ == "__main__":
    main()
