#!/usr/bin/env python3
"""Generate a crisp vector launcher emblem for Mithaq Al-Mumin."""
from pathlib import Path
import re

RES_DIR = Path("android/app/src/main/res/drawable")
MANIFEST = Path("android/app/src/main/AndroidManifest.xml")

VECTOR = """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#FF071713" android:pathData="M0,0h108v108H0z" />
    <path
        android:fillColor="#FF0D2B21"
        android:strokeColor="#FFD9B66D"
        android:strokeWidth="1.7"
        android:pathData="M20,5H88A15,15 0,0 1,103 20V88A15,15 0,0 1,88 103H20A15,15 0,0 1,5 88V20A15,15 0,0 1,20 5Z" />
    <path
        android:fillColor="#00000000"
        android:strokeColor="#FFD9B66D"
        android:strokeWidth="2.1"
        android:strokeLineCap="round"
        android:strokeLineJoin="round"
        android:pathData="M25,79V62C26,44 40,25 54,15C68,25 82,44 83,62V79" />
    <path
        android:fillColor="#00000000"
        android:strokeColor="#FFF5D99A"
        android:strokeAlpha="0.8"
        android:strokeWidth="1.4"
        android:strokeLineCap="round"
        android:pathData="M36,77V62C38,48 47,36 54,30C61,36 70,48 72,62V77" />
    <path android:fillColor="#FFD9B66D" android:pathData="M38,76C39,63 46,54 54,47C62,54 69,63 70,76C65,83 43,83 38,76Z" />
    <path android:fillColor="#FFF5D99A" android:pathData="M56,18C50,18 49,25 53,28C57,30 61,27 62,24C58,27 54,25 54,22C54,20 55,19 56,18Z" />
    <path android:fillColor="#FFD9B66D" android:pathData="M54,31a1.7,1.7 0,1 0,0.01 0Z" />
    <path
        android:fillColor="#00000000"
        android:strokeColor="#FFD9B66D"
        android:strokeWidth="1.7"
        android:strokeLineCap="round"
        android:pathData="M35,80Q54,86 73,80" />
</vector>
"""

def main() -> None:
    if not MANIFEST.is_file():
        raise SystemExit(f"Generated Android manifest is missing: {MANIFEST}")
    RES_DIR.mkdir(parents=True, exist_ok=True)
    (RES_DIR / "mithaq_launcher.xml").write_text(VECTOR, encoding="utf-8")

    content = MANIFEST.read_text(encoding="utf-8")
    content, icon_count = re.subn(
        r'android:icon="@(?:mipmap/ic_launcher|drawable/mithaq_launcher)"',
        'android:icon="@drawable/mithaq_launcher"',
        content,
        count=1,
    )
    content, round_count = re.subn(
        r'android:roundIcon="@(?:mipmap/ic_launcher|drawable/mithaq_launcher)"',
        'android:roundIcon="@drawable/mithaq_launcher"',
        content,
        count=1,
    )
    if icon_count != 1:
        raise SystemExit("Could not find the Android launcher icon reference")
    if round_count != 1:
        # Some generated manifests omit roundIcon; the regular icon still works.
        content = content.replace(
            'android:icon="@drawable/mithaq_launcher"',
            'android:icon="@drawable/mithaq_launcher" android:roundIcon="@drawable/mithaq_launcher"',
            1,
        )
    MANIFEST.write_text(content, encoding="utf-8")
    print(f"Generated vector launcher icon: {RES_DIR / 'mithaq_launcher.xml'}")


if __name__ == "__main__":
    main()
