#!/usr/bin/env python3
"""Prepare one Arabic-only offline collection from the CC0 Shia library and Mafatih al-Jinan."""
import html
import json
import os
import re
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path
from urllib.parse import unquote

BASE = "https://raw.githubusercontent.com/adeeb10abbas/shia-library-json/main"
INDEX_URL = f"{BASE}/index/duas.json"
DEST = Path("assets/shia_duas/shia_duas.json")
MAFATIH_PATH = Path("assets/mafatih/mafatih.json")
MAFATIH_BOOK_URL = "https://lib.rafed.net/view.php?b_id=1731&type=c_fbook"
MAFATIH_SUNSET_URL = "https://lib.rafed.net/view.php?b_id=1731&page=757&type=c_fbook"


def fetch_json(url: str, attempts: int = 3):
    headers = {"User-Agent": "Mithaq-Al-Mumin/1.0 (offline Arabic Shia library preparation)"}
    for attempt in range(attempts):
        try:
            request = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(request, timeout=45) as response:
                return json.loads(response.read().decode("utf-8"))
        except (urllib.error.URLError, TimeoutError) as exc:
            if attempt + 1 >= attempts:
                raise SystemExit(f"Unable to download source JSON: {url} ({exc})") from exc
            time.sleep(1.5 * (attempt + 1))


def normalize_script(value: str) -> str:
    return value.replace("ک", "ك").replace("ی", "ي").replace("ے", "ي").replace("ہ", "ه")


def plain_arabic_text(value: str) -> str:
    value = html.unescape(value)
    value = re.sub(r"<br\s*/?>", "\n", value, flags=re.IGNORECASE)
    value = re.sub(r"</(p|div|li|h[1-6])\s*>", "\n\n", value, flags=re.IGNORECASE)
    value = re.sub(r"<[^>]*>", " ", value)
    value = normalize_script(value)
    return re.sub(r"\n{3,}", "\n\n", value).strip()


def contains_arabic(value: str) -> bool:
    return any(0x0600 <= ord(char) <= 0x06FF for char in value)


def contains_persian_language_markers(value: str) -> bool:
    normalized = normalize_script(value)
    return re.search(
        r"دعای|دعاي|دعاهای|دعاهاي|روزهای|روزهاي|فارسی|فارسي|برای|براي|میباشد|می شود|ميشود|خواهد شد|نمی|نمي|هنگام|آفتاب|شامگاه|صبحگاه|هفته|هزار رکعت|هزار ركعت",
        f"{value} {normalized}",
    ) is not None


def is_arabic_recitation(value: str) -> bool:
    value = plain_arabic_text(value)
    if not contains_arabic(value) or re.search(r"[A-Za-zپچژگ]", value):
        return False
    return not contains_persian_language_markers(value)


def _hint(value: str) -> str:
    return normalize_script(unquote(str(value or ""))).lower()


def _mafatih_title(raw_title: str, href: str, section_title: str, article_number: int) -> str:
    hint = _hint(href)
    rules = [
        ("دعای-وقت-طلوع-و-غروب-آفتاب", "دعاء وقت طلوع الشمس وغروبها"),
        ("تعقیبات-مشترک", "التعقيبات المشتركة"),
        ("تعقیب-نماز-ظهر", "تعقيب صلاة الظهر"),
        ("تعقیب-نماز-عصر", "تعقيب صلاة العصر"),
        ("تعقیب-نماز-مغرب", "تعقيب صلاة المغرب"),
        ("تعقیب-نماز-عشاء", "تعقيب صلاة العشاء"),
        ("تعقیب-نماز-صبح", "تعقيب صلاة الصبح"),
        ("دعای-روز-شنبه", "دعاء يوم السبت"),
        ("دعای-روز-یکشنبه", "دعاء يوم الأحد"),
        ("دعای-روز-دوشنبه", "دعاء يوم الاثنين"),
        ("دعای-روز-سه-شنبه", "دعاء يوم الثلاثاء"),
        ("دعای-روز-چهارشنبه", "دعاء يوم الأربعاء"),
        ("دعای-روز-پنجشنبه", "دعاء يوم الخميس"),
        ("دعای-روز-جمعه", "دعاء يوم الجمعة"),
        ("دعای-صباح", "دعاء الصباح"),
        ("دعای-کمیل", "دعاء كميل"),
        ("دعای-عشرات", "دعاء العشرات"),
        ("دعای-سمات", "دعاء السمات"),
        ("دعای-مشلول", "دعاء المشلول"),
        ("دعای-توسل", "دعاء التوسل"),
        ("دعای-فرج", "دعاء الفرج"),
        ("دعای-ندبه", "دعاء الندبة"),
        ("دعای-عهد", "دعاء العهد"),
        ("زیارت-عاشورا", "زيارة عاشوراء"),
        ("زیارت-اربعین", "زيارة الأربعين"),
        ("زیارت-وارث", "زيارة وارث"),
        ("زیارت-جامعه", "الزيارة الجامعة"),
        ("زیارت-حضرت-امیرالمومنین", "زيارة أمير المؤمنين عليه السلام"),
        ("زیارت-حضرت-زهرا", "زيارة السيدة فاطمة الزهراء عليها السلام"),
        ("اعمال-شب-جمعه", "أعمال ليلة الجمعة"),
        ("اعمال-روز-جمعه", "أعمال يوم الجمعة"),
        ("اعمال-ماه-رجب", "أعمال شهر رجب"),
        ("اعمال-ماه-شعبان", "أعمال شهر شعبان"),
        ("اعمال-ماه-رمضان", "أعمال شهر رمضان"),
        ("اعمال-ماه-شوال", "أعمال شهر شوال"),
        ("اعمال-ماه-ذی-القعده", "أعمال شهر ذي القعدة"),
        ("اعمال-ماه-ذی-الحجه", "أعمال شهر ذي الحجة"),
        ("مناجات-اول", "المناجاة الأولى: مناجاة التائبين"),
        ("مناجات-دوم", "المناجاة الثانية: مناجاة الشاكين"),
        ("مناجات-سوم", "المناجاة الثالثة: مناجاة الخائفين"),
        ("مناجات-چهارم", "المناجاة الرابعة: مناجاة الراجين"),
        ("مناجات-پنجم", "المناجاة الخامسة: مناجاة الراغبين"),
        ("مناجات-ششم", "المناجاة السادسة: مناجاة الشاكرين"),
        ("مناجات-هفتم", "المناجاة السابعة: مناجاة المطيعين"),
        ("مناجات-هشتم", "المناجاة الثامنة: مناجاة المريدين"),
        ("مناجات-نهم", "المناجاة التاسعة: مناجاة المحبين"),
        ("مناجات-دهم", "المناجاة العاشرة: مناجاة المتوسلين"),
        ("مناجات-یازدهم", "المناجاة الحادية عشرة: مناجاة المفتقرين"),
        ("مناجات-دوازدهم", "المناجاة الثانية عشرة: مناجاة العارفين"),
        ("مناجات-سیزدهم", "المناجاة الثالثة عشرة: مناجاة الذاكرين"),
        ("مناجات-چهاردهم", "المناجاة الرابعة عشرة: مناجاة المعتصمين"),
        ("مناجات-پانزدهم", "المناجاة الخامسة عشرة: مناجاة الزاهدين"),
    ]
    for marker, arabic_title in rules:
        if _hint(marker) in hint:
            return arabic_title
    title = plain_arabic_text(str(raw_title or ""))
    if title and contains_arabic(title) and not re.search(r"[A-Za-zپچژگ]", title) and not contains_persian_language_markers(title):
        return title
    return f"نص عربي رقم {article_number} ضمن {plain_arabic_text(section_title)}"


def _mafatih_category(chapter_index: int, chapter_title: str, section_title: str, article_title: str, href: str) -> str:
    context = " ".join([chapter_title, section_title, article_title, unquote(str(href or ""))])
    hint = _hint(context)

    if chapter_index == 2 or re.search(r"زيارة|زيارات|ziyarat|ziyarah", hint):
        return "الزيارات"
    if re.search(r"مناجاة|munajat", hint):
        return "المناجيات الخمس عشرة"
    if re.search(r"صاحب الزمان|الإمام المهدي|الامام المهدي|المهدي|الحجة|الاستغاثة|دعاء العهد|دعاء الندبة|دعاء الفرج|faraj|nudba|al-ahd", hint):
        return "أدعية صاحب الزمان"

    # A record explicitly tied to both sunrise and sunset belongs only to shared adhkar.
    combined = (
        ("طلوع" in hint and "غروب" in hint)
        or ("صباح" in hint and "مساء" in hint)
        or ("صبح" in hint and "غروب" in hint)
        or ("morning" in hint and "evening" in hint)
    )
    if combined:
        return "الأذكار المشتركة"

    if chapter_index == 1 or re.search(r"أعمال أشهر السنة|أعمال شهر|اعمال-ماه-|ماه-رجب|ماه-شعبان|ماه-رمضان|ماه-ذي-القعدة|ماه-ذي-الحجة", hint):
        return "الأعمال الشهرية والمناسبات"
    if re.search(r"دعاء يوم|دعای-روز-|روز-شنبه|روز-یکشنبه|روز-دوشنبه|روز-سه-شنبه|روز-چهارشنبه|روز-پنجشنبه|روز-جمعه", hint):
        return "أدعية الأيام"
    if re.search(r"تعقيب|تعقيبات|تعقیب|تعقیبات|taqib", hint):
        return "تعقيبات الصلوات"
    if re.search(r"الصباح|دعاء الصباح|دعای-صباح|sabah|asbah|طلوع الصبح", hint):
        return "أدعية الصباح"
    if re.search(r"المساء|دعاء المساء|مساء|غروب|غروب الشمس|دعای-مساء|evening|masa|amsa|sunset", hint):
        return "أدعية المساء"
    if re.search(r"الحوائج|قضاء الدين|سعة الرزق|الشفاء|العافية|hajat|hawaij|rizq|shifa|healing", hint):
        return "أدعية الحاجات والشفاء"
    if re.search(r"أعمال ليلة|أعمال يوم|اعمال-شب-|اعمال-روز-|أعمال الجمعة|اعمال-جمعه|ليلة القدر", hint):
        return "الأعمال اليومية والمناسبات"
    return "أدعية عامة"


def _append_mafatih(prepared: list[dict]) -> int:
    if not MAFATIH_PATH.is_file():
        raise SystemExit("Mafatih source JSON is missing. Run tool/prepare_mafatih.py first.")
    data = json.loads(MAFATIH_PATH.read_text(encoding="utf-8"))
    chapters = data.get("chapters") if isinstance(data, dict) else None
    if not isinstance(chapters, list) or not chapters:
        raise SystemExit("Mafatih source must contain a non-empty chapter list.")

    added = 0
    for cidx, chapter in enumerate(chapters):
        if not isinstance(chapter, dict):
            continue
        chapter_title = plain_arabic_text(str(chapter.get("title") or ""))
        for sidx, section in enumerate(chapter.get("sections", [])):
            if not isinstance(section, dict):
                continue
            section_title = plain_arabic_text(str(section.get("title") or ""))
            for aidx, article in enumerate(section.get("articles", [])):
                if not isinstance(article, dict):
                    continue
                href = str(article.get("href") or "")
                title = _mafatih_title(str(article.get("title") or ""), href, section_title, aidx + 1)
                lines = []
                for item in article.get("items", []):
                    if not isinstance(item, dict):
                        continue
                    kind = str(item.get("type") or "").strip().lower()
                    if kind not in {"text", "arabic", "arabictext", "arabic_text"}:
                        continue
                    content = plain_arabic_text(str(item.get("content") or ""))
                    if not content or not is_arabic_recitation(content):
                        continue
                    lines.append({"index": len(lines) + 1, "kind": "arabic", "text": content})
                if not lines:
                    continue
                category = _mafatih_category(cidx, chapter_title, section_title, title, href)
                slug = f"mafatih-c{cidx + 1}-s{sidx + 1}-a{aidx + 1}"
                prepared.append({
                    "slug": slug,
                    "title": title,
                    "alternateName": title,
                    "type": "ziyara" if category == "الزيارات" else "dua",
                    "sourceUrl": MAFATIH_BOOK_URL,
                    "sourceLabel": f"مفاتيح الجنان، {chapter_title}، {section_title}، {title}",
                    "categoryOverride": category,
                    "lines": lines,
                })
                added += 1

    # Sourced solely from the Arabic Mafatih edition's appendix entry on sunset:
    # it is evening-only and is never copied into morning or shared adhkar.
    sunset = {
        "slug": "mafatih-sunset-dua",
        "title": "دعاء عند الغروب",
        "alternateName": "دعاء عند الغروب",
        "type": "dua",
        "sourceUrl": MAFATIH_SUNSET_URL,
        "sourceLabel": "مفاتيح الجنان، الملحق الثاني، العمل عند الغروب",
        "categoryOverride": "أدعية المساء",
        "lines": [{
            "index": 1,
            "kind": "arabic",
            "text": "يا من ختم النبوة بمحمد صلى الله عليه وآله اختم لي في يومي هذا بخير وشهري بخير وسنتي بخير وعمري بخير",
        }],
    }
    prepared.append(sunset)
    added += 1
    return added


def main() -> None:
    index = fetch_json(INDEX_URL)
    entries = index.get("duas") if isinstance(index, dict) else None
    if not isinstance(entries, list) or not entries:
        raise SystemExit("Shia dua source index is empty or has an unexpected shape.")

    prepared = []
    total_arabic_lines = 0
    total_base_records = len(entries)
    slugs_seen = set()
    for record in entries:
        slug = record.get("slug")
        if not isinstance(slug, str) or not slug or slug in slugs_seen:
            raise SystemExit("Invalid or duplicate slug in the Shia dua index.")
        slugs_seen.add(slug)
        raw = fetch_json(f"{BASE}/db/duas/{slug}.json")
        if raw.get("slug") != slug:
            raise SystemExit(f"Slug mismatch for {slug}.")
        lines = raw.get("lines")
        if not isinstance(lines, list) or not lines:
            raise SystemExit(f"Missing line-by-line content for {slug}.")

        normalized_lines = []
        for line in lines:
            if not isinstance(line, dict):
                raise SystemExit(f"Invalid line in {slug}.")
            kind = line.get("kind")
            text = line.get("text")
            if not isinstance(kind, str) or not isinstance(text, str):
                raise SystemExit(f"Missing line type/text in {slug}.")
            if not text.strip() or kind.lower() != "arabic" or not is_arabic_recitation(text):
                continue
            normalized_lines.append({
                "index": line.get("index", len(normalized_lines) + 1),
                "kind": "arabic",
                "text": plain_arabic_text(text),
            })
            total_arabic_lines += 1

        if not normalized_lines:
            continue

        title = plain_arabic_text(str(raw.get("title") or record.get("title") or ""))
        alternate_name = plain_arabic_text(str(raw.get("alternateName") or record.get("alternateName") or ""))
        if not title or not contains_arabic(title) or re.search(r"[A-Za-zپچژگ]", title) or contains_persian_language_markers(title):
            title = ""
        if not alternate_name or not contains_arabic(alternate_name) or re.search(r"[A-Za-zپچژگ]", alternate_name) or contains_persian_language_markers(alternate_name):
            alternate_name = ""

        prepared.append({
            "slug": slug,
            "title": title,
            "alternateName": alternate_name,
            "type": raw.get("type") or "dua",
            "sourceUrl": raw.get("url") or record.get("url") or "",
            "sourceLabel": "مكتبة ثقلين الإلكترونية",
            "lines": normalized_lines,
        })

    base_source_count = len(prepared)
    mafatih_count = _append_mafatih(prepared)
    result = {
        "metadata": {
            "sourceProject": "مكتبة الأدعية والزيارات ومختارات مفاتيح الجنان العربية",
            "sourceIndex": INDEX_URL,
            "mafatihSource": MAFATIH_BOOK_URL,
            "contentSource": "Arabic entries from the Shia library dataset and filtered Mafatih al-Jinan records",
            "license": "CC0 1.0 for the Shia-library dataset and Apache-2.0 for Mafatih source data; see THIRD_PARTY_NOTICES.md.",
            "count": len(prepared),
            "baseSourceCount": base_source_count,
            "mafatihEntryCount": mafatih_count,
            "baseSourceRecordCount": total_base_records,
            "mafatihArabicLineCount": total_arabic_lines,
            "note": "Only vetted Arabic recitation lines are included. Combined sunrise/sunset records remain shared; a separately sourced sunset-only invocation belongs in evening adhkar.",
        },
        "entries": prepared,
    }

    DEST.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix="shia-duas-", suffix=".json", dir=DEST.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(result, handle, ensure_ascii=False, separators=(",", ":"))
            handle.write("\n")
        os.replace(temporary, DEST)
    finally:
        if os.path.exists(temporary):
            os.remove(temporary)

    print(
        f"Prepared merged offline Shia library: {base_source_count} base texts, "
        f"{mafatih_count} Mafatih entries, {len(prepared)} total; "
        f"{total_arabic_lines} Arabic base lines retained"
    )


if __name__ == "__main__":
    main()
