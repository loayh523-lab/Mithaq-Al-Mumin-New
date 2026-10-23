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
    # Guard every Dart source line, including regular-expression patterns. Persian
    # detector patterns should use Unicode escapes rather than embedding Persian letters.
    source_root = Path("lib")
    if source_root.exists():
        for source in sorted(source_root.rglob("*.dart")):
            try:
                lines = source.read_text(encoding="utf-8").splitlines()
            except (OSError, UnicodeError) as error:
                errors.append(f"{source}: cannot read UTF-8 source ({error})")
                continue
            for line_number, line in enumerate(lines, start=1):
                match = FORBIDDEN.search(line)
                if match:
                    errors.append(
                        f"{source}:{line_number}: found forbidden Persian character "
                        f"U+{ord(match.group()):04X}"
                    )
                    if len(errors) >= 30:
                        break
            if len(errors) >= 30:
                break

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
            "Arabic source/content validation failed. Normalize Persian characters to Arabic script "
            "and review the source text:\n- " + "\n- ".join(errors)
        )
    print(f"Validated {len(ASSETS)} offline content JSON assets: no Persian-specific characters found.")


if __name__ == "__main__":
    main()
