import 'dart:convert';
import 'package:flutter/services.dart';

/// Mafatih Arabic data adapter. This is a content source for the unified
/// dua/ziyara/deeds library, not a standalone user-facing book section.

/// Converts Persian/Urdu keyboard variants commonly present in Arabic
/// editions into standard Arabic letter forms without replacing valid titles.
String normalizeMafatihArabicText(String value) => value
    .replaceAll('ک', 'ك')
    .replaceAll('ی', 'ي')
    .replaceAll('ے', 'ي')
    .replaceAll('ہ', 'ه');

bool containsPersianOnlyLetters(String value) =>
    RegExp(r'[پچژگ]').hasMatch(value);

/// Detect common Persian-language words even when all letters are shared
/// with Arabic and Unicode-range checks alone cannot distinguish the language.
bool containsPersianLanguageMarkers(String value) {
  final normalized = normalizeMafatihArabicText(value);
  final bothForms = '$value $normalized';
  return RegExp(
    r'دعای|دعاي|دعاهای|دعاهاي|روزهای|روزهاي|روزها|هفته|فارسی|فارسي|برای|براي|میباشد|می شود|ميشود|خواهد شد|نمی|نمي|زیارت|زيارت|زیارات|زيارات|مناجات',
  ).hasMatch(bothForms);
}

/// True only for Arabic-script recitation text; translations and romanization
/// are not allowed into the Arabic-only reader.
bool isArabicMafatihRecitation(String value) {
  final normalized = normalizeMafatihArabicText(value);
  return normalized.runes.any((rune) => rune >= 0x0600 && rune <= 0x06FF) &&
      !RegExp(r'[A-Za-z]').hasMatch(normalized) &&
      !containsPersianOnlyLetters(normalized) &&
      !containsPersianLanguageMarkers(value);
}

String _arabicOnlyTitle(Object? value, String fallback) {
  final title = value is String
      ? normalizeMafatihArabicText(value.trim())
      : '';
  return title.isEmpty ||
      containsPersianOnlyLetters(title) ||
      containsPersianLanguageMarkers(value is String ? value : title) ||
      RegExp(r'[A-Za-z]').hasMatch(title)
      ? fallback
      : title;
}

class MafatihItem {
  const MafatihItem({required this.type, required this.content});
  final String type;
  final String content;
  factory MafatihItem.fromJson(Map<String, dynamic> json) => MafatihItem(
    type: json['type'] is String ? json['type'] as String : 'text',
    content: json['content'] is String ? json['content'] as String : '',
  );
}

class MafatihArticle {
  const MafatihArticle({required this.id, required this.title, required this.items, this.href = ''});
  final int id;
  final String title;
  final String href;
  final List<MafatihItem> items;
  factory MafatihArticle.fromJson(Map<String, dynamic> json) => MafatihArticle(
    id: json['id'] is int ? json['id'] as int : 0,
    title: _arabicOnlyTitle(json['title'], 'نص رقم ${json['id'] ?? 'غير مرقم'}'),
    href: json['href'] is String ? json['href'] as String : '',
    items: ((json['items'] as List<dynamic>?) ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>().map(MafatihItem.fromJson).toList(),
  );
}

class MafatihSection {
  const MafatihSection({required this.id, required this.title, required this.articles});
  final int id;
  final String title;
  final List<MafatihArticle> articles;
  factory MafatihSection.fromJson(Map<String, dynamic> json) => MafatihSection(
    id: json['id'] is int ? json['id'] as int : 0,
    title: _arabicOnlyTitle(json['title'], 'قسم رقم ${json['id'] ?? 'غير مرقم'}'),
    articles: ((json['articles'] as List<dynamic>?) ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>().map(MafatihArticle.fromJson).toList(),
  );
}

class MafatihChapter {
  const MafatihChapter({required this.id, required this.title, required this.sections});
  final int id;
  final String title;
  final List<MafatihSection> sections;
  factory MafatihChapter.fromJson(Map<String, dynamic> json) => MafatihChapter(
    id: json['id'] is int ? json['id'] as int : 0,
    title: _arabicOnlyTitle(json['title'], 'الباب ${json['id'] ?? 'غير مرقم'} من مفاتيح الجنان'),
    sections: ((json['sections'] as List<dynamic>?) ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>().map(MafatihSection.fromJson).toList(),
  );
}

class MafatihData {
  const MafatihData({required this.chapters, required this.source});
  final List<MafatihChapter> chapters;
  final String source;
  static Future<MafatihData>? _cache;

  static Future<MafatihData> load() => _cache ??= _load();
  static Future<MafatihData> _load() async {
    final raw = await rootBundle.loadString('assets/mafatih/mafatih.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final rawChapters = decoded['chapters'] as List<dynamic>;
    final chapters = rawChapters.whereType<Map<String, dynamic>>().map(MafatihChapter.fromJson).toList();
    if (chapters.isEmpty) throw const FormatException('Mafatih library is empty.');
    final metadata = decoded['metadata'] as Map<String, dynamic>? ?? const {};
    final source = metadata['upstream_project'] is String
        ? metadata['upstream_project'] as String
        : 'aminpaydar/Mafatih';
    return MafatihData(chapters: chapters, source: source);
  }
}

String mafatihCategoryFor(String value) {
  final text = _normalizeTitle(value);

  // Keep visits, Sahifa and special supplication collections ahead of broad matches.
  if (RegExp(r'زيارة|زيارات|ziyarat|ziyarah').hasMatch(text)) return 'الزيارات';
  if (RegExp(r'الصحيفة السجادية|صحيفة سجادية|sahifa sajjadiya').hasMatch(text)) return 'الصحيفة السجادية';
  if (RegExp(r'مناجاة|munajat').hasMatch(text)) return 'المناجيات الخمس عشرة';
  if (RegExp(r'الإمام المهدي|الامام المهدي|صاحب الزمان|الحجة|دعاء العهد|دعاء الندبة|الاستغاثة بالحجة|دعاء الفرج|mahdi|sahib al zaman|nudba|faraj|ghayba').hasMatch(text)) return 'أدعية صاحب الزمان';

  // Texts explicitly prescribed for both periods live in their own catalogue.
  if (RegExp(r'الصباح.{0,18}المساء|المساء.{0,18}الصباح|صباحاً ومساءً|صباحا ومساء|صباحاً ومساء|صباحا ومساءً|صباحا ومساءا|طلوع الشمس.{0,28}غروب الشمس|غروب الشمس.{0,28}طلوع الشمس|عند طلوع الشمس.{0,28}عند غروب الشمس|عند غروب الشمس.{0,28}عند طلوع الشمس|morning.{0,18}evening|evening.{0,18}morning').hasMatch(text)) return 'أذكار مشتركة';
  if (RegExp(r'أذكار الصباح|دعاء الصباح|الصباح|الصبح|الفجر|قبل طلوع الشمس|عند طلوع الشمس|بعد طلوع الشمس|تعقيب الصبح|صلاة الصبح|sabah|morning|sunrise').hasMatch(text)) return 'أدعية الصباح';
  if (RegExp(r'أذكار المساء|دعاء المساء|المساء|عشية|الغروب|قبل غروب الشمس|عند غروب الشمس|بعد الغروب|صلاة المغرب|تعقيب المغرب|masa|evening|sunset').hasMatch(text)) return 'أدعية المساء';

  if (RegExp(r'تعقيبات|تعقيب الصلاة|تعقيب الفجر|تعقيب الظهر|تعقيب العصر|تعقيب المغرب|تعقيب العشاء|taqibat').hasMatch(text)) return 'تعقيبات';
  if (RegExp(r'دعاء الأحد|دعاء الاثنين|دعاء الثلاثاء|دعاء الأربعاء|دعاء الخميس|دعاء الجمعة|دعاء السبت|دعوات أيام الأسبوع|sunday|monday|tuesday|wednesday|thursday|friday|saturday').hasMatch(text)) return 'أدعية الأيام';
  if (RegExp(r'أعمال.{0,22}(اليوم|ليلة|يوم)|اعمال.{0,22}(اليوم|ليلة|يوم)|عمل ليلة|عمل يوم|الأعمال اليومية|الاعمال اليومية|acts of|amal').hasMatch(text)) return 'الأعمال اليومية والمناسبات';
  if (RegExp(r'أعمال.{0,25}(الشهر|الأشهر|أشهر|الشهور|اشهر|رجب|رمضان|شعبان)|اعمال.{0,25}(الشهر|الأشهر|أشهر|الشهور|اشهر|رجب|رمضان|شعبان)|عمل شهر|أعمال الأشهر|الاعمال الشهرية').hasMatch(text)) return 'الأعمال الشهرية والمناسبات';
  if (RegExp(r'رمضان|رجب|شعبان|ذي الحجة|ذي القعدة|شوال|محرم|صفر|ليلة القدر|عرفة|العيد|مباهلة|ramadan|rajab|shaaban|arafah|eid|mubahala').hasMatch(text)) return 'أدعية الأشهر والمناسبات';
  if (RegExp(r'الشفاء|العافية|الرزق|قضاء الدين|تفريج الهم|الكرب|الحوائج|المرض|المريض|shifa|rizq|hajat|hawaij').hasMatch(text)) return 'أدعية الحاجات والشفاء';
  return 'أدعية عامة';
}

String _normalizeTitle(String value) => value
  .toLowerCase()
  .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
  .replaceAll(RegExp('[أإآٱ]'), 'ا')
  .replaceAll('ى', 'ي')
  .replaceAll('ک', 'ك')
  .replaceAll('ی', 'ي')
  .replaceAll('ے', 'ي')
  .replaceAll('ہ', 'ه');

String plainMafatihText(String value) => value
  .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
  .replaceAll(RegExp(r'</(p|div|li|h[1-6])\s*>', caseSensitive: false), '\n\n')
  .replaceAll(RegExp(r'<[^>]*>'), '')
  .replaceAll('&nbsp;', ' ')
  .replaceAll('&amp;', '&')
  .replaceAll('&quot;', '"')
  .replaceAll('&#39;', "'")
  .replaceAll('&lt;', '<')
  .replaceAll('&gt;', '>')
  .replaceAll('ک', 'ك')
  .replaceAll('ی', 'ي')
  .replaceAll('ے', 'ي')
  .replaceAll('ہ', 'ه')
  .trim();
