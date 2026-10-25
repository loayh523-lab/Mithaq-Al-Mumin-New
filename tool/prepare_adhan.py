#!/usr/bin/env python3
"""Prepare the selected Sheikh Shabbar Maalla adhan for preview and Android alarms.

The original user-selected recording is retained at SOURCE and is never replaced.
Build outputs are encoded once at a notification-friendly bitrate, then reused for
Flutter preview and Android's notification channel to avoid bundling the 10 MB
source recording twice in the release APK.
"""
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

SOURCE = Path("assets/audio/adhan_shabbar_maalla.mp3")
PREVIEW = Path("assets/audio/adhan_shabbar_maalla_preview.mp3")
DESTINATION = Path("android/app/src/main/res/raw/adhan_shabbar_maalla.mp3")


def valid_mp3(path: Path) -> bool:
    if not path.is_file() or path.stat().st_size < 80_000:
        return False
    with path.open("rb") as stream:
        header = stream.read(4)
    return (
        header.startswith(b"ID3")
        or header.startswith(b"\xff\xfb")
        or header.startswith(b"\xff\xf3")
        or header.startswith(b"\xff\xf2")
        or header.startswith(b"\xff\xfa")
    )


def atomic_copy(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(
        prefix="adhan-shabbar-", suffix=".mp3", dir=destination.parent
    )
    try:
        with os.fdopen(fd, "wb") as output, source.open("rb") as original:
            shutil.copyfileobj(original, output)
        os.replace(temporary, destination)
    finally:
        if os.path.exists(temporary):
            os.remove(temporary)


def main() -> None:
    if not SOURCE.is_file():
        raise SystemExit(
            "Required Sheikh Shabbar Maalla adhan is missing: "
            f"{SOURCE}. Add the supplied recording before building; "
            "the build will not silently substitute another adhan."
        )
    if not valid_mp3(SOURCE):
        raise SystemExit("The supplied Sheikh Shabbar Maalla recording does not appear to be a valid MP3.")

    encoder = shutil.which("ffmpeg")
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    if encoder:
        fd, temporary = tempfile.mkstemp(
            prefix="adhan-preview-", suffix=".mp3", dir=PREVIEW.parent
        )
        os.close(fd)
        try:
            command = [
                encoder, "-hide_banner", "-loglevel", "error", "-y",
                "-i", str(SOURCE), "-vn", "-ac", "1", "-ar", "32000",
                "-b:a", "80k", "-map_metadata", "-1", temporary,
            ]
            result = subprocess.run(command, check=False, capture_output=True, text=True)
            if result.returncode != 0 or not valid_mp3(Path(temporary)):
                raise SystemExit(
                    "Could not prepare the compact adhan recording with ffmpeg: "
                    + (result.stderr.strip() or "unknown encoder error")
                )
            os.replace(temporary, PREVIEW)
        finally:
            if os.path.exists(temporary):
                os.remove(temporary)
        print(
            "Prepared compact adhan preview: "
            f"{PREVIEW} ({PREVIEW.stat().st_size} bytes; mono 32 kHz, 80 kbps)."
        )
    else:
        # Preserve build portability: if ffmpeg is absent, use the original audio
        # rather than failing or substituting a different recording.
        atomic_copy(SOURCE, PREVIEW)
        print("WARNING: ffmpeg is unavailable; using the original adhan audio without size optimization.")

    atomic_copy(PREVIEW, DESTINATION)
    print(
        "Prepared Android notification adhan: "
        f"{DESTINATION} ({DESTINATION.stat().st_size} bytes). "
        "Original source retained at " + str(SOURCE) + "."
    )


if __name__ == "__main__":
    main()
