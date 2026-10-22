#!/usr/bin/env python3
"""Fetch the licensed Amiri Arabic and Quran fonts for the offline Android app.

The font binaries are retrieved at build time to avoid committing opaque binary
files through the text-only source update workflow. The upstream SIL Open Font
License is stored with the app source and in the generated build workspace.
"""
from pathlib import Path
import os
import tempfile
import urllib.request

BASE = "https://raw.githubusercontent.com/aliftype/amiri/main/"
DEST = Path("assets/fonts")
LICENSE_DEST = Path("licenses/Amiri-OFL.txt")
FILES = {
    "Amiri-Regular.ttf": 350_000,
    "Amiri-Bold.ttf": 350_000,
    "AmiriQuran.ttf": 100_000,
}
USER_AGENT = "Mithaq-Al-Mumin/1.0 (licensed font preparation)"


def fetch(url: str, minimum_size: int) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=60) as response:
        payload = response.read()
    if len(payload) < minimum_size:
        raise SystemExit(f"Downloaded file is too small: {url} ({len(payload)} bytes).")
    if not (payload.startswith(b"\x00\x01\x00\x00") or payload.startswith(b"OTTO")):
        raise SystemExit(f"Downloaded file is not an OpenType/TrueType font: {url}.")
    return payload


def atomic_write(path: Path, payload: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=path.stem + "-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as handle:
            handle.write(payload)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.remove(temporary)


def main() -> None:
    for name, minimum_size in FILES.items():
        payload = fetch(BASE + "fonts/" + name, minimum_size)
        atomic_write(DEST / name, payload)
        print(f"Prepared {name}: {len(payload)} bytes")

    license_request = urllib.request.Request(
        BASE + "OFL.txt",
        headers={"User-Agent": USER_AGENT},
    )
    with urllib.request.urlopen(license_request, timeout=60) as response:
        license_text = response.read()
    if b"SIL OPEN FONT LICENSE" not in license_text.upper():
        raise SystemExit("The Amiri font license could not be verified.")
    atomic_write(LICENSE_DEST, license_text)
    print(f"Prepared {LICENSE_DEST}")


if __name__ == "__main__":
    main()
