#!/usr/bin/env python3
"""Install the user-selected Sheikh Shabbar Maalla adhan for Android notifications.

The exact recording must be present at assets/audio/adhan_shabbar_maalla.mp3.
This script deliberately fails rather than silently substituting a different adhan.
"""
import os
import tempfile
from pathlib import Path

SOURCE = Path("assets/audio/adhan_shabbar_maalla.mp3")
DESTINATION = Path("android/app/src/main/res/raw/adhan_shabbar_maalla.mp3")


def main() -> None:
    if not SOURCE.is_file():
        raise SystemExit(
            "Required Sheikh Shabbar Maalla adhan is missing: "
            f"{SOURCE}. Add the supplied recording before building; "
            "the build will not silently substitute another adhan."
        )
    audio = SOURCE.read_bytes()
    if len(audio) < 100_000 or not (
        audio.startswith(b"ID3")
        or audio.startswith(b"\xff\xfb")
        or audio.startswith(b"\xff\xf3")
        or audio.startswith(b"\xff\xf2")
        or audio.startswith(b"\xff\xfa")
    ):
        raise SystemExit("The supplied adhan file does not appear to be a valid MP3.")
    DESTINATION.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix="adhan-shabbar-", suffix=".mp3", dir=DESTINATION.parent)
    try:
        with os.fdopen(fd, "wb") as output:
            output.write(audio)
        os.replace(temporary, DESTINATION)
    finally:
        if os.path.exists(temporary):
            os.remove(temporary)
    print(f"Prepared Sheikh Shabbar Maalla adhan: {DESTINATION} ({len(audio)} bytes)")


if __name__ == "__main__":
    main()
