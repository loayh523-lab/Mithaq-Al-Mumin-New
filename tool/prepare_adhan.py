#!/usr/bin/env python3
"""Download the CC BY-SA 4.0 adhan recording for Android notifications and offline preview.

This recording is described as Persian-style Mahur; its Jafari wording has not been independently verified.
"""
import json
import os
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

API_URL = (
    "https://commons.wikimedia.org/w/api.php?"
    + urllib.parse.urlencode({
        "action": "query",
        "titles": "File:AzaanMaahur.ogg",
        "prop": "imageinfo",
        "iiprop": "url",
        "format": "json",
    })
)
DESTS = [
    Path("android/app/src/main/res/raw/adhan_persian.ogg"),
    Path("assets/audio/adhan_persian.ogg"),
]
USER_AGENT = "Mithaq-Al-Mumin/1.0 (openly licensed adhan asset preparation)"


def read_url(url: str, attempts: int = 3) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    for attempt in range(attempts):
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return response.read()
        except (urllib.error.URLError, TimeoutError) as exc:
            if attempt + 1 >= attempts:
                raise SystemExit(f"Failed to fetch {url}: {exc}") from exc
            time.sleep(1.5 * (attempt + 1))
    raise SystemExit("Download failed unexpectedly.")


def main() -> None:
    payload = json.loads(read_url(API_URL).decode("utf-8"))
    pages = payload.get("query", {}).get("pages", {})
    page = next(iter(pages.values()), {})
    info = page.get("imageinfo", [])
    if page.get("title") != "File:AzaanMaahur.ogg" or not info:
        raise SystemExit("Wikimedia Commons did not return the expected adhan file.")
    source_url = info[0].get("url")
    if not isinstance(source_url, str) or not source_url.startswith("https://upload.wikimedia.org/"):
        raise SystemExit("Unexpected Wikimedia source URL; refusing to download.")
    audio = read_url(source_url)
    if len(audio) < 100_000 or not audio.startswith(b"OggS"):
        raise SystemExit("Downloaded file is not a valid Ogg adhan recording.")
    for destination in DESTS:
        destination.parent.mkdir(parents=True, exist_ok=True)
        fd, temp_name = tempfile.mkstemp(prefix="adhan-", suffix=".ogg", dir=destination.parent)
        try:
            with os.fdopen(fd, "wb") as handle:
                handle.write(audio)
            os.replace(temp_name, destination)
        finally:
            if os.path.exists(temp_name):
                os.remove(temp_name)
        print(f"Prepared adhan audio: {destination} ({len(audio)} bytes)")


if __name__ == "__main__":
    main()
