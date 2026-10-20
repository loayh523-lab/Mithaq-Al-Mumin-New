#!/usr/bin/env python3
"""Download and validate the open-source Mafatih al-Jinan data for offline app use.

Upstream project: https://github.com/aminpaydar/Mafatih
The upstream repository declares Apache License 2.0. This script preserves
chapter/section/article/item content, and adds separate provenance metadata.
"""
import html
import json
import re
import os
import tempfile
import urllib.request
from pathlib import Path

SOURCE_URL = "https://raw.githubusercontent.com/aminpaydar/Mafatih/master/mafatih-server/chapters.json"
DEST = Path("assets/mafatih/mafatih.json")


def main() -> None:
    request = urllib.request.Request(
        SOURCE_URL,
        headers={"User-Agent": "Mithaq-Al-Mumin/1.0 (offline Mafatih data preparation)"},
    )
    with urllib.request.urlopen(request, timeout=90) as response:
        payload = response.read()
    source = json.loads(payload.decode("utf-8"))
    if not isinstance(source, list) or not source:
        raise SystemExit("Mafatih source must be a non-empty JSON chapter list.")

    chapters_checked = sections_checked = articles_checked = items_checked = 0
    arabic_chapter_titles = [
        "الباب الأول: تعقيبات الصلوات ودعوات أيام الأسبوع وأعمال ليلة الجمعة ونهارها",
        "الباب الثاني: أعمال أشهر السنة الهجرية",
        "الباب الثالث: الزيارات",
    ]
    # Kaf/yeh variants are not evidence that a title is Persian: many Arabic
    # transcriptions use Persian Unicode forms for ك/ي. Normalize them first.
    persian_only_letters = set("پچژگ")

    def normalize_arabic_script(value: str) -> str:
        return (value.replace("ک", "ك").replace("ی", "ي")
                     .replace("ے", "ي").replace("ہ", "ه"))

    def has_persian_letters(value: str) -> bool:
        return any(character in persian_only_letters for character in value)

    def has_latin_letters(value: str) -> bool:
        return re.search(r"[A-Za-z]", value) is not None

    def has_persian_language_markers(value: str) -> bool:
        normalized = normalize_arabic_script(value)
        both_forms = f"{value} {normalized}"
        return re.search(
            r"دعای|دعاي|روزهای|روزهاي|روزها|هفته|فارسی|فارسي|برای|براي|میباشد|می شود|ميشود|خواهد شد|نمی|نمي",
            both_forms,
        ) is not None

    def is_arabic_recitation(value: str) -> bool:
        plain = html.unescape(re.sub(r"<[^>]*>", " ", value))
        return (
            any(0x0600 <= ord(character) <= 0x06FF for character in plain)
            and not has_latin_letters(plain)
            and not has_persian_letters(plain)
            and not has_persian_language_markers(plain)
        )

    def arabic_title(value: str, kind: str, index: int, parent: str = "") -> str:
        """Translate common Persian/transliterated headings and never emit Persian/Latin labels."""
        raw = normalize_arabic_script(value.strip())
        if (not has_persian_letters(raw) and not has_latin_letters(raw)
                and not has_persian_language_markers(raw)):
            return raw

        lower = raw.lower()
        known_titles = [
            (("ziyarat ashura", "ziyārat ʿāshūrā", "زیارت عاشورا"), "زيارة عاشوراء"),
            (("ziyarat warith", "ziyārat wārith", "زیارت وارث"), "زيارة وارث"),
            (("ziyarat arbaeen", "ziyarat arba'in", "زیارت اربعین"), "زيارة الأربعين"),
            (("dua al-sabah", "du'a al-sabah", "دعای صباح", "دعای الصباح"), "دعاء الصباح"),
            (("dua kumayl", "du'a kumayl", "دعای کمیل"), "دعاء كميل"),
            (("dua al-iftitah", "du'a al-iftitah", "دعای افتتاح"), "دعاء الافتتاح"),
            (("dua nudba", "du'a al-nudba", "دعای ندبه"), "دعاء الندبة"),
            (("dua al-ahd", "du'a al-ahd", "دعای عهد"), "دعاء العهد"),
            (("dua tawassul", "du'a tawassul", "دعای توسل"), "دعاء التوسل"),
            (("ziyara jamia", "ziyarat jamia", "زیارت جامعه"), "الزيارة الجامعة"),
            (("munajat", "مناجات"), "المناجاة"),
            (("sahifa sajjadiya", "sahifa sajjadiyyah"), "الصحيفة السجادية"),
        ]
        for needles, arabic in known_titles:
            if any(needle in lower for needle in needles):
                return arabic

        translated = raw
        phrase_replacements = [
            (r"دعای", "دعاء"),
            (r"دعاهای", "أدعية"),
            (r"زیارت", "زيارة"),
            (r"مناجات", "مناجاة"),
            (r"روزهای هفته", "أيام الأسبوع"),
            (r"روز جمعه", "يوم الجمعة"),
            (r"روز شنبه", "يوم السبت"),
            (r"روز یکشنبه", "يوم الأحد"),
            (r"روز دوشنبه", "يوم الاثنين"),
            (r"روز سه.?شنبه", "يوم الثلاثاء"),
            (r"روز چهارشنبه", "يوم الأربعاء"),
            (r"روز پنجشنبه", "يوم الخميس"),
            (r"روز", "يوم"),
            (r"شب", "ليلة"),
            (r"هفته", "الأسبوع"),
            (r"اعمال", "أعمال"),
            (r"سوره", "سورة"),
            (r"امام حسین", "الإمام الحسين"),
            (r"امام علی", "أمير المؤمنين"),
            (r"امام رضا", "الإمام الرضا"),
        ]
        for pattern, replacement in phrase_replacements:
            translated = re.sub(pattern, replacement, translated, flags=re.IGNORECASE)

        latin_replacements = [
            (r"\\bdu[aāe']+\\b", "دعاء"),
            (r"\\bziyar(at|ah)\\b", "زيارة"),
            (r"\\ba'amal|aamal|amal\\b", "أعمال"),
            (r"\\bmunajat\\b", "مناجاة"),
            (r"\\bsahifa\\b", "الصحيفة"),
            (r"\\bkumayl\\b", "كميل"),
            (r"\\bashura\\b", "عاشوراء"),
            (r"\\barba(een|'een)\\b", "الأربعين"),
            (r"\\biftitah\\b", "الافتتاح"),
            (r"\\bnudba\\b", "الندبة"),
            (r"\\btawassul\\b", "التوسل"),
            (r"\\bahd\\b", "العهد"),
            (r"\\bsabah\\b", "الصباح"),
            (r"\\bmas(a|aa|e)\\b", "المساء"),
            (r"\\bjum(a|'a|ah)\\b", "الجمعة"),
            (r"\\bshab(an|aan)\\b", "شعبان"),
            (r"\\bramadan\\b", "رمضان"),
            (r"\\brajab\\b", "رجب"),
            (r"\\bday\\b", "يوم"),
            (r"\\bnight\\b", "ليلة"),
            (r"\\bchapter\\b", "الباب"),
            (r"\\bsection\\b", "الفصل"),
        ]
        for pattern, replacement in latin_replacements:
            translated = re.sub(pattern, replacement, translated, flags=re.IGNORECASE)
        translated = re.sub(r"[A-Za-z]+", " ", translated)
        translated = re.sub(r"\\s+", " ", translated).strip(" -_:،")
        translated = normalize_arabic_script(translated)
        if (translated and not has_persian_letters(translated)
                and not has_latin_letters(translated)
                and not has_persian_language_markers(translated)):
            return translated

        # Fallbacks remain descriptive Arabic labels, never untranslated or blank titles.
        if re.search(r"ziyar|زیارت|زيارة", lower):
            return f"زيارة رقم {index} ضمن {parent or 'الزيارات'}"
        if re.search(r"munajat|مناجات|مناجاة", lower):
            return f"مناجاة رقم {index} ضمن {parent or 'المناجيات'}"
        if re.search(r"amal|اعمال|أعمال|عمل", lower):
            return f"عمل رقم {index} ضمن {parent or 'الأعمال'}"
        if re.search(r"dua|دعای|دعا|دعاء", lower):
            return f"دعاء رقم {index} ضمن {parent or 'الأدعية'}"
        return {
            "chapter": f"الباب رقم {index} من مفاتيح الجنان",
            "section": f"قسم رقم {index} ضمن {parent or 'مفاتيح الجنان'}",
            "article": f"نص رقم {index} ضمن {parent or 'مفاتيح الجنان'}",
        }.get(kind, f"نص رقم {index} من مفاتيح الجنان")

    for cidx, chapter in enumerate(source):
        if not isinstance(chapter, dict) or not isinstance(chapter.get("title"), str):
            raise SystemExit(f"Invalid Mafatih chapter at index {cidx}.")
        chapter_title = arabic_title(chapter["title"], "chapter", cidx + 1)
        if cidx < len(arabic_chapter_titles) and chapter_title.startswith("الباب رقم "):
            chapter_title = arabic_chapter_titles[cidx]
        chapter["title"] = chapter_title
        sections = chapter.get("sections")
        if not isinstance(sections, list):
            raise SystemExit(f"Chapter {cidx} has no sections list.")
        chapters_checked += 1
        for sidx, section in enumerate(sections):
            if not isinstance(section, dict) or not isinstance(section.get("title"), str):
                raise SystemExit(f"Invalid section {sidx} in chapter {cidx}.")
            section["title"] = arabic_title(section["title"], "section", sidx + 1, chapter["title"])
            articles = section.get("articles")
            if not isinstance(articles, list):
                raise SystemExit(f"Section {sidx} in chapter {cidx} has no articles list.")
            sections_checked += 1
            for aidx, article in enumerate(articles):
                if not isinstance(article, dict) or not isinstance(article.get("title"), str):
                    raise SystemExit(f"Invalid article {aidx} in chapter {cidx}, section {sidx}.")
                article["title"] = arabic_title(article["title"], "article", aidx + 1, section["title"])
                items = article.get("items")
                if not isinstance(items, list):
                    raise SystemExit(f"Article {aidx} does not have an items list.")
                articles_checked += 1
                arabic_items = []
                for item in items:
                    if not isinstance(item, dict):
                        raise SystemExit("Invalid Mafatih text item.")
                    if not isinstance(item.get("content", ""), str):
                        raise SystemExit("Mafatih item content is not text.")
                    items_checked += 1
                    # The source has Persian translations/explanations; keep Arabic recitation only.
                    if not (
                        isinstance(item.get("type"), str)
                        and item["type"].strip().lower()
                        in {"text", "arabic", "arabictext", "arabic_text"}
                    ):
                        continue
                    item_content = normalize_arabic_script(item.get("content", ""))
                    if not is_arabic_recitation(item_content):
                        continue
                    item["content"] = item_content
                    arabic_items.append(item)
                article["items"] = arabic_items

            # Do not ship article cards that contain no Arabic recitation; they would open blank.
            section["articles"] = [article for article in articles if article.get("items")]
        # Do not ship empty headings after filtering the Persian-only source items.
        chapter["sections"] = [section for section in sections if section.get("articles")]

    source[:] = [chapter for chapter in source if chapter.get("sections")]
    if not source:
        raise SystemExit("Mafatih Arabic filtering produced no readable chapters.")

    result = {
        "metadata": {
            "title": "Mafatih al-Jinan data",
            "upstream_project": "aminpaydar/Mafatih",
            "source_url": SOURCE_URL,
            "license": "Apache-2.0 as declared by the upstream repository; see licenses/MAFATIH_APACHE_2.0.txt",
            "note": "Arabic recitation items only; Persian kaf/yeh variants are normalized, Persian-only lines and translations are omitted. Compare religious wording with a trusted printed edition before treating it as a critical text.",
        },
        "chapters": source,
    }
    DEST.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix="mafatih-", suffix=".json", dir=DEST.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(result, handle, ensure_ascii=False, separators=(",", ":"))
            handle.write("\n")
        os.replace(temporary, DEST)
    finally:
        if os.path.exists(temporary):
            os.remove(temporary)

    print(
        "Prepared offline Mafatih library: "
        f"{chapters_checked} chapters, {sections_checked} sections, "
        f"{articles_checked} articles, {items_checked} text items"
    )


if __name__ == "__main__":
    main()
