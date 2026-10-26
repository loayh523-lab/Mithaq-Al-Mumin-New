#!/usr/bin/env python3
"""Generate the Mithaq launcher emblem and a distinct Android status icon."""
from pathlib import Path
import re

RES_DIR = Path("android/app/src/main/res/drawable")
MANIFEST = Path("android/app/src/main/AndroidManifest.xml")

# Full-colour launcher icon: emerald field, gold architectural frame, dome and
# twin minarets. Keep it vector-based so it remains crisp at every density.
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
        android:strokeWidth="2"
        android:strokeLineCap="round"
        android:pathData="M25,82V65C26,43 39,26 54,16C69,26 82,43 83,65V82" />
    <path android:fillColor="#FFD9B66D"
        android:pathData="M20,83V50H24V43L27,36L30,43V50H34V83Z" />
    <path android:fillColor="#FFD9B66D"
        android:pathData="M74,83V50H78V43L81,36L84,43V50H88V83Z" />
    <path android:fillColor="#FFF5D99A"
        android:pathData="M18,49H36V52H18Z M72,49H90V52H72Z" />
    <path android:fillColor="#FFD9B66D"
        android:pathData="M31,65C32,50 42,36 54,27C66,36 76,50 77,65C71,72 37,72 31,65Z" />
    <path android:fillColor="#FFD9B66D"
        android:pathData="M29,66H79V71H29Z" />
    <path android:fillColor="#FF8D6A32"
        android:pathData="M32,72H76V83H32Z" />
    <path android:fillColor="#FF0D2B21"
        android:pathData="M39,83V77C39,73 44,71 47,74V83Z M51,83V75C51,71 57,71 57,75V83Z M61,83V74C64,71 69,73 69,77V83Z" />
    <path android:fillColor="#FFF5D99A"
        android:pathData="M55,17C49,18 47,24 51,28C55,31 61,27 62,23C58,27 53,25 52,22C52,20 53,18 55,17Z" />
    <path android:fillColor="#FFD9B66D"
        android:pathData="M54,29a1.5,1.5 0,1 0,0.01 0Z" />
    <path
        android:fillColor="#00000000"
        android:strokeColor="#FFD9B66D"
        android:strokeWidth="1.7"
        android:strokeLineCap="round"
        android:pathData="M28,86Q54,91 80,86" />
</vector>
"""

# Android status-bar notifications should use a simple white, transparent icon,
# not the colourful launcher artwork.
NOTIFICATION_VECTOR = """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#FFFFFFFF"
        android:pathData="M16,88V50H22V39L27,28L32,39V50H38V88Z" />
    <path android:fillColor="#FFFFFFFF"
        android:pathData="M70,88V50H76V39L81,28L86,39V50H92V88Z" />
    <path android:fillColor="#FFFFFFFF"
        android:pathData="M29,65C31,49 41,35 54,25C67,35 77,49 79,65C73,72 35,72 29,65Z" />
    <path android:fillColor="#FFFFFFFF"
        android:pathData="M27,66H81V73H27Z M31,73H77V88H31Z" />
    <path android:fillColor="#00000000"
        android:strokeColor="#FFFFFFFF"
        android:strokeWidth="4"
        android:strokeLineCap="round"
        android:pathData="M43,88V79 M54,88V77 M65,88V79" />
</vector>
"""


def main() -> None:
    if not MANIFEST.is_file():
        raise SystemExit(f"Generated Android manifest is missing: {MANIFEST}")
    RES_DIR.mkdir(parents=True, exist_ok=True)
    (RES_DIR / "mithaq_launcher.xml").write_text(VECTOR, encoding="utf-8")
    (RES_DIR / "mithaq_notification.xml").write_text(
        NOTIFICATION_VECTOR, encoding="utf-8"
    )

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
        content = content.replace(
            'android:icon="@drawable/mithaq_launcher"',
            'android:icon="@drawable/mithaq_launcher" android:roundIcon="@drawable/mithaq_launcher"',
            1,
        )
    MANIFEST.write_text(content, encoding="utf-8")
    print("Generated emerald-and-gold launcher and monochrome notification icons.")


if __name__ == "__main__":
    main()
