#!/usr/bin/env python3
"""Prepare the bundled Sheikh Shabbar Maalla adhan as an Android notification sound."""

from pathlib import Path
import shutil


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "audio" / "adhan_shabbar_maalla.mp3"
DESTINATION = (
    ROOT / "android" / "app" / "src" / "main" / "res" / "raw"
    / "adhan_shabbar_maalla.mp3"
)


def main() -> None:
    if not SOURCE.is_file():
        raise SystemExit(f"Required adhan asset is missing: {SOURCE}")
    DESTINATION.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SOURCE, DESTINATION)
    print(f"Prepared Android adhan resource: {DESTINATION}")


if __name__ == "__main__":
    main()
