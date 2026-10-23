#!/usr/bin/env python3
"""Apply the supplied Mithaq emblem as the generated Android application icon."""
import re
import shutil
from pathlib import Path

SOURCE = Path("assets/images/mithaq_launcher.jpg")
RES_DIR = Path("android/app/src/main/res/drawable-nodpi")
MANIFEST = Path("android/app/src/main/AndroidManifest.xml")


def main() -> None:
    if not SOURCE.is_file():
        raise SystemExit(f"Original Mithaq launcher image is missing: {SOURCE}")
    if not MANIFEST.is_file():
        raise SystemExit(f"Generated Android manifest is missing: {MANIFEST}")

    RES_DIR.mkdir(parents=True, exist_ok=True)
    target = RES_DIR / "mithaq_launcher.jpg"
    shutil.copyfile(SOURCE, target)

    content = MANIFEST.read_text(encoding="utf-8")
    content, icon_count = re.subn(
        r'android:icon="@mipmap/ic_launcher"',
        'android:icon="@drawable/mithaq_launcher"',
        content,
        count=1,
    )
    content, round_count = re.subn(
        r'android:roundIcon="@mipmap/ic_launcher"',
        'android:roundIcon="@drawable/mithaq_launcher"',
        content,
        count=1,
    )
    if icon_count != 1:
        raise SystemExit("Could not find the default application icon reference in AndroidManifest.xml")
    MANIFEST.write_text(content, encoding="utf-8")
    print(f"Applied original Mithaq launcher icon: {target}; roundIcon references updated: {round_count}")


if __name__ == "__main__":
    main()
