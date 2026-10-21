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

## Additional Shia duas, ziyarat, and Sahifa text

- Source repository: [adeeb10abbas/shia-library-json](https://github.com/adeeb10abbas/shia-library-json).
- The repository declares CC0 1.0 Universal for its dataset and notes its source data at Thaqalayn public pages.
- Build step: `python3 tool/prepare_shia_duas.py`, run after `python3 tool/prepare_mafatih.py`.
- The build runs `python3 tool/prepare_mafatih.py` first to validate and filter the upstream Mafatih chapter structure, then `python3 tool/prepare_shia_duas.py` to merge Arabic-only entries from both sources into `assets/shia_duas/shia_duas.json`.
- Imported Mafatih entries appear inside the ordinary app categories, with an Arabic title, a category override, a link to the Arabic edition, and a breadcrumb naming the book, chapter, section, and entry.
- Only vetted Arabic recitation lines are included in the unified library; translations, explanatory items, and entries without Arabic recitation are excluded from the packaged reading data.
- A sunrise-and-sunset text remains in the shared adhkar category. A separately sourced sunset-only invocation is in the evening category, not copied into the morning list.
- The base collection includes listed Sahifa Sajjadiya entries from the source index; this is not a critical-edition verification of every variant. Source URLs remain available for base entries.
- The base source repository's CC0 notice is included at [licenses/SHIA_LIBRARY_CC0_1.0.txt](licenses/SHIA_LIBRARY_CC0_1.0.txt). The Mafatih source remains separately covered by [licenses/MAFATIH_APACHE_2.0.txt](licenses/MAFATIH_APACHE_2.0.txt).

 
## Nahj al-Balagha

- Source project: [saber13812002/application-nahj-al-balaghah](https://github.com/saber13812002/application-nahj-al-balaghah).
- Source database: `nahj-sqlite.db`, table `nahj`; categories 1, 2, and 3 are used for sermons, letters, and maxims.
- Build step: `python3 tool/prepare_nahj.py`.
- The generated offline catalogue is written to `assets/nahj/nahj.json`.
- The upstream project is licensed under MIT. A copy of the license and attribution is included at [licenses/NAHJ_MIT_LICENSE.txt](licenses/NAHJ_MIT_LICENSE.txt).
- Numbering and wording can vary across editions; the app keeps the source's wording and flags the need to compare critical quotations against a named printed edition.

## Quran juz and hizb boundaries

- Metadata source: [quran-center/quran-meta](https://github.com/quran-center/quran-meta/blob/master/src/lists/HafsLists.ts), Hafs 'an Asim division boundaries.
- The app derives the 30 juz starts and 60 hizb starts from the source's global ayah IDs; it does not copy Quran verse text from this package.
- Upstream code is licensed under MIT; the source repository includes the license.
