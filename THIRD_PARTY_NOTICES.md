# Third-party content and attribution

## Quran text

- Source: Tanzil Project data distributed through [dotquran/corpus](https://github.com/dotquran/corpus).
- Source URL: https://tanzil.net/
- Build step: `python3 tool/prepare_quran.py`
- The preparation script validates 114 surahs and 6,236 numbered verses and preserves the Arabic text unchanged.
- The asset is generated into `assets/quran/uthmani_surahs.json` before CI builds the APK.

## Mafatih al-Jinan

- Source project: [aminpaydar/Mafatih](https://github.com/aminpaydar/Mafatih).
- Source data file: `mafatih-server/chapters.json`.
- Build step: `python3 tool/prepare_mafatih.py`
- The preparation script validates the chapter/section/article/item structure and carries the source text into `assets/mafatih/mafatih.json`.
- The upstream repository declares Apache License 2.0; a copy is included at [licenses/MAFATIH_APACHE_2.0.txt](licenses/MAFATIH_APACHE_2.0.txt).
- This app's library UI shows the upstream source. Differences between published editions may exist, so exact scholarly citations should be checked against a named printed edition.

## Religious source policy

The app distinguishes general reminder phrases from texts assigned to a book/source. It does not claim a specific hadith isnad or printed page number unless that has been verified. Prayer times and tabular Hijri dates are labelled approximate and should be compared with local Ja'fari timetables and moon-sighting decisions.

## Third-party code and data

Keep upstream notices with redistributed source/builds. This project does not claim ownership of the third-party Quran or Mafatih text assets.
