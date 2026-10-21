#!/usr/bin/env python3
"""Do not bundle an unrelated adhan recording.

The selected Alawi Shrine recording is linked from the app's source page. The public
YouTube page is not a direct audio download URL and does not itself grant redistribution
permission. Until a direct, reuse-authorized audio asset is supplied, prayer reminders
use Android's default notification sound rather than a different recording.
"""


def main() -> None:
    print(
        "No third-party adhan audio bundled. The selected Alawi Shrine recording "
        "is linked in-app; notifications use the device default sound until an "
        "official downloadable asset with reuse permission is available."
    )


if __name__ == "__main__":
    main()
