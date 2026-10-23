#!/usr/bin/env python3
"""Prepare generated Android files for Mithaq Al-Mumin and local prayer alarms."""
from pathlib import Path
import re

MANIFEST = Path("android/app/src/main/AndroidManifest.xml")
GRADLE = Path("android/app/build.gradle.kts")
APPLICATION_MARKER = "<application"
APPLICATION_CLOSE = "</application>"

PERMISSIONS = (
    "android.permission.INTERNET",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.SCHEDULE_EXACT_ALARM",
    "android.permission.RECEIVE_BOOT_COMPLETED",
    "android.permission.VIBRATE",
)

SCHEDULED_RECEIVER = (
    '    <receiver android:exported="false" '
    'android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />'
)

BOOT_RECEIVER = """    <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
        <intent-filter>
            <action android:name="android.intent.action.BOOT_COMPLETED" />
            <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
            <action android:name="android.intent.action.QUICKBOOT_POWERON" />
            <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
        </intent-filter>
    </receiver>"""


def main() -> None:
    if not MANIFEST.is_file():
        raise SystemExit(
            f"Generated Android manifest is missing: {MANIFEST}. "
            "Run flutter create --platforms=android first."
        )
    if not GRADLE.is_file():
        raise SystemExit(
            f"Generated Android Gradle file is missing: {GRADLE}. "
            "Run flutter create --platforms=android first."
        )

    manifest = MANIFEST.read_text(encoding="utf-8")
    manifest, label_count = re.subn(
        r'android:label="[^"]*"',
        'android:label="ميثاق المؤمن"',
        manifest,
        count=1,
    )
    if label_count == 0:
        app_position = manifest.find(APPLICATION_MARKER)
        if app_position < 0:
            raise SystemExit("Android application tag was not found.")
        manifest = manifest[:app_position] + (
            '<application android:label="ميثاق المؤمن"'
        ) + manifest[app_position + len(APPLICATION_MARKER):]

    app_position = manifest.find(APPLICATION_MARKER)
    if app_position < 0:
        raise SystemExit("Android application tag was not found.")

    for permission in PERMISSIONS:
        if permission not in manifest:
            app_position = manifest.find(APPLICATION_MARKER)
            manifest = manifest[:app_position] + (
                f'    <uses-permission android:name="{permission}" />\n    '
            ) + manifest[app_position:]

    receivers = []
    if "com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" not in manifest:
        receivers.append(SCHEDULED_RECEIVER)
    if "com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver" not in manifest:
        receivers.append(BOOT_RECEIVER)
    if receivers:
        app_end = manifest.rfind(APPLICATION_CLOSE)
        if app_end < 0:
            raise SystemExit("Android application closing tag was not found.")
        manifest = manifest[:app_end] + "\n" + "\n".join(receivers) + "\n" + manifest[app_end:]
    MANIFEST.write_text(manifest, encoding="utf-8")

    build = GRADLE.read_text(encoding="utf-8")
    if "isCoreLibraryDesugaringEnabled = true" not in build:
        if "compileOptions {" not in build:
            raise SystemExit("Android compileOptions block was not found.")
        build = build.replace(
            "compileOptions {",
            "compileOptions {\n        isCoreLibraryDesugaringEnabled = true",
            1,
        )
    dependency = 'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")'
    if dependency not in build:
        if "dependencies {" in build:
            build = build.replace("dependencies {", "dependencies {\n    " + dependency, 1)
        else:
            build += "\n\ndependencies {\n    " + dependency + "\n}\n"
    GRADLE.write_text(build, encoding="utf-8")
    print("Prepared Android application label, notification permissions/receivers, and core-library desugaring.")


if __name__ == "__main__":
    main()
