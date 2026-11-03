import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _shiaGold = Color(0xFFD9B66D);

class ShiaTextLine {
  const ShiaTextLine({
    required this.index,
    required this.kind,
    required this.text,
    this.displayId = '',
  });
  final int index;
  final String kind;
  final String text;
  final String displayId;
  bool get isArabic => kind.toLowerCase() == 'arabic';
  bool get isTranslation => kind.toLowerCase() == 'translation';
  bool get isPersian =>
      RegExp(r'persian|farsi|\bfa\b|\u0641\u0627\u0631\u0633\u064a|\u0641\u0627\u0631\u0633\u06cc', caseSensitive: false).hasMatch(kind) ||
      RegExp(r'[\u067e\u0686\u0698\u06af\u06cc\u06a9\u06d2\u06d3]').hasMatch(text);
  bool get isTransliteration => kind.toLowerCase() == 'transliteration';
  factory ShiaTextLine.fromJson(Map<String, dynamic> json) => ShiaTextLine(
    index: json['index'] is int ? json['index'] as int : 0,
    kind: json['kind'] is String ? json['kind'] as String : 'other',
    text: json['text'] is String ? json['text'] as String : '',
    displayId: json['displayId'] is String
        ? (json['displayId'] as String).trim()
        : '',
  );
}

class ShiaTextEntry {
  const ShiaTextEntry({
    required this.slug,
    required this.title,
    required this.alternateName,
    required this.type,
    required this.sourceUrl,
    required this.lines,
    this.sourceReference = '',
    this.categoryOverride,
    this.omittedSourceInstructionCount = 0,
  });
  final String slug;
  final String title;
  final String alternateName;
  final String type;
  final String sourceUrl;
  final String sourceReference;
  final String? categoryOverride;
  final int omittedSourceInstructionCount;
  final List<ShiaTextLine> lines;
  String get displayTitle {
    final candidate = alternateName.trim().isNotEmpty
        ? alternateName.trim()
        : title.trim();
    final genericTaqibTitle = slug.startsWith('taqib-after-salaat-') &&
        (candidate == 'تعقيبات الصلاة' ||
            candidate.contains('دعاء التعقيب بعد الصلاة') ||
            candidate.contains('تعقيب بعد الصلاة') ||
            candidate.contains('تعقيب الصلاة'));
    if (!genericTaqibTitle) return candidate;

    final arabicLines = lines
        .where((line) => line.isArabic && line.text.trim().isNotEmpty)
        .map((line) => line.text.trim())
        .toList();
    String normalizeForTitle(String value) {
      final compact = StringBuffer();
      for (final rune in value.runes) {
        if ((rune >= 0x064B && rune <= 0x065F) ||
            rune == 0x0670 ||
            rune == 0x0640 ||
            rune == 0x0020) {
          continue;
        }
        compact.writeCharCode(rune);
      }
      return compact.toString().replaceAll('ٱ', 'ا');
    }
    // Imported entries sometimes store an entire dua as one line beginning
    // with the same basmala/salawat. Strip that boilerplate before deriving a
    // readable title, otherwise five different texts all appear with one title.
    String meaningfulPrefix(String line) {
      var value = line
          .trim()
          .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');
      const commonOpeners = [
        'بسم الله الرحمن الرحيم',
        'بسم الله',
        'أعوذ بالله من الشيطان الرجيم',
        'اللهم صل على محمد وآل محمد',
        'اللهم صل على محمد و آل محمد',
        'اللهم صل على محمد',
        'و آل محمد',
        'وآل محمد',
      ];
      var changed = true;
      while (changed) {
        changed = false;
        for (final opener in commonOpeners) {
          if (value.startsWith(opener)) {
            value = value.substring(opener.length).trimLeft();
            changed = true;
          }
        }
      }
      return value;
    }

    final candidates = arabicLines
        .map(meaningfulPrefix)
        // Ignore a leftover connective or short salawat fragment, and choose
        // the first genuinely descriptive phrase from the complete entry.
        .where((line) => normalizeForTitle(line)
            .replaceAll(RegExp(r'\s+'), '')
            .runes.length >= 12)
        .toList();
    final sourceLine = candidates.isNotEmpty
        ? candidates.first
        : (arabicLines.isNotEmpty ? arabicLines.first : '');
    if (sourceLine.isEmpty) return 'تعقيب بعد الصلاة';

    final runes = sourceLine.runes.toList();
    final preview = runes.length <= 42
        ? sourceLine
        : '${String.fromCharCodes(runes.take(42)).trimRight()}…';
    return 'تعقيب بعد الصلاة — $preview';
  }
  bool get isSahifa =>
      categoryOverride == 'الصحيفة السجادية المباركة (نفحات مختارة)' ||
      categoryOverride == 'الصحيفة السجادية والمناجيات' ||
      slug.startsWith('selected-sahifa-') ||
      slug.startsWith('sahifa-sajjadiya-') ||
      slug.startsWith('munajat-sahifa-') ||
      slug.startsWith('munajat-');
  bool get isDayDua =>
      RegExp(r'(sunday|monday|tuesday|wednesday|thursday|friday|saturday)', caseSensitive: false).hasMatch(slug) ||
      RegExp(r'دعاء يوم|أدعية يوم|دعاء الأحد|دعاء الاثنين|دعاء الثلاثاء|دعاء الأربعاء|دعاء الخميس|دعاء الجمعة|دعاء السبت').hasMatch('$title $alternateName');
  bool get isZiyara =>
      slug.toLowerCase().contains('ziyarat') ||
      title.contains('زيارة') ||
      alternateName.contains('زيارة');
  bool get isTaqibat =>
      slug.toLowerCase().contains('taqib') ||
      title.contains('تعقيب') ||
      alternateName.contains('تعقيب');
  bool get isMunajat =>
      slug.toLowerCase().contains('munajat') ||
      title.contains('مناجاة') ||
      alternateName.contains('مناجاة');
  bool get isMahdiDua {
    final value = '${slug.toLowerCase()} $title $alternateName';
    return RegExp(r'mahdi|hujja|hujjah|sahib.al.zaman|imam.al.zaman|istighatha|ghayba|ghaib|nudba|al.ahd|faraj|صاحب الزمان|الإمام المهدي|الامام المهدي|الحجة|اللهم كن لوليك|دعاء العهد|دعاء الندبة|الاستغاثة بالحجة', caseSensitive: false).hasMatch(value);
  }
  bool get isMorningEveningDua {
    final value = '${slug.toLowerCase()} $title $alternateName';
    return RegExp(r'morning|evening|sabah|masa|asbah|amsa|adhkar|أذكار|الصباح|المساء|دعاء الصباح|دعاء المساء', caseSensitive: false).hasMatch(value);
  }
  bool get isHajatDua {
    final value = '${slug.toLowerCase()} $title $alternateName';
    return RegExp(r'hajat|hawaij|rizq|shifa|healing|tawfiq|success|الكرب|الحوائج|قضاء الدين|سعة الرزق|الشفاء|العافية|طلب العلم|تفريج الهم|الحزن').hasMatch(value);
  }
  bool get isOccasionDua {
    final value = '${slug.toLowerCase()} $title $alternateName';
    return RegExp(r'eid|ramadan|arafah|mubahala|mubahilah|laylat|rajab|shaaban|dhul.hijja|dhul.qadah|مناسبة|العيد|رمضان|عرفة|مباهلة|رجب|شعبان|ذي الحجة|ذي القعدة|ليلة القدر').hasMatch(value);
  }
  String get category {
    const validCategories = <String>{
      'الورد اليومي والتعقيبات',
      'الأدعية الكبرى والمناجاة الشريفة',
      'أدعية المناسبات والشهور العبادية',
      'الصحيفة السجادية المباركة (نفحات مختارة)',
      'أدعية الحوائج، التحصينات والرزق',
      'الزيارات الشريفة والمقامات المقدسة',
    };
    final fixed = categoryOverride;
    if (fixed != null && validCategories.contains(fixed)) return fixed;
    if (isSahifa) return 'الصحيفة السجادية المباركة (نفحات مختارة)';
    if (fixed == 'الزيارات الشريفة' || isZiyara) {
      return 'الزيارات الشريفة والمقامات المقدسة';
    }
    if (fixed == 'الأعمال والمناسبات' || isOccasionDua) {
      return 'أدعية المناسبات والشهور العبادية';
    }
    if (fixed == 'الأدعية والأذكار اليومية' ||
        fixed == 'التعقيبات بعد الصلاة' ||
        isTaqibat ||
        isDayDua ||
        isMorningEveningDua) {
      return 'الورد اليومي والتعقيبات';
    }
    if (fixed == 'الأدعية العامة وأدعية الفرج وصاحب الزمان') {
      return isHajatDua
          ? 'أدعية الحوائج، التحصينات والرزق'
          : 'الأدعية الكبرى والمناجاة الشريفة';
    }
    if (isHajatDua) return 'أدعية الحوائج، التحصينات والرزق';
    return 'الأدعية الكبرى والمناجاة الشريفة';
  }
  String get arabicText => lines.where((line) => line.isArabic).map((line) => line.text).join('\n');

  factory ShiaTextEntry.fromJson(Map<String, dynamic> json) => ShiaTextEntry(
    slug: json['slug'] is String ? json['slug'] as String : '',
    title: json['title'] is String ? json['title'] as String : 'دعاء',
    alternateName: json['alternateName'] is String ? json['alternateName'] as String : '',
    type: json['type'] is String ? json['type'] as String : 'dua',
    sourceUrl: json['sourceUrl'] is String ? json['sourceUrl'] as String : '',
    sourceReference: json['sourceReference'] is String
        ? json['sourceReference'] as String
        : '',
    categoryOverride: json['category'] is String ? json['category'] as String : null,
    omittedSourceInstructionCount:
        json['omittedSourceInstructionCount'] is int
            ? json['omittedSourceInstructionCount'] as int
            : 0,
    lines: ((json['lines'] as List<dynamic>?) ?? const <dynamic>[])
      .whereType<Map<String, dynamic>>().map(ShiaTextLine.fromJson).toList(),
  );
}

class ShiaTextData {
  const ShiaTextData({required this.entries, required this.sourceProject, required this.license});
  final List<ShiaTextEntry> entries;
  final String sourceProject;
  final String license;
  static Future<ShiaTextData>? _cache;
  static Future<ShiaTextData>? _coreCache;
  static Future<ShiaTextData>? _sahifaCache;

  static Future<ShiaTextData> loadCore() => _coreCache ??= _loadAsset(
    'assets/shia_duas/shia_duas.json',
    expectedCount: 110,
  );

  static Future<ShiaTextData> load() => _cache ??= _loadCombined();

  static Future<ShiaTextData> _loadCombined() async => await loadCore();

  /// The source manifest preserves 76 Sahifa/Munajat records, but the owner's
  /// approved 20-item selection has not been identified by stable slugs yet.
  /// Do not guess which texts are approved or publish all 76 as a substitute.
  static Future<ShiaTextData> loadSahifa() => _sahifaCache ??= loadCore().then(
        (data) => ShiaTextData(
          entries: const <ShiaTextEntry>[],
          sourceProject: data.sourceProject,
          license: data.license,
        ),
      );

  static Future<ShiaTextData> _loadAsset(
    String assetPath, {
    required int expectedCount,
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final rawEntries = decoded['entries'] as List<dynamic>;
    final entries = rawEntries.whereType<Map<String, dynamic>>()
        .map(ShiaTextEntry.fromJson).toList();
    if (entries.length != expectedCount) {
      throw FormatException(
        'Expected exactly $expectedCount texts in $assetPath; found ${entries.length}.',
      );
    }
    final slugs = entries.map((entry) => entry.slug).toSet();
    if (slugs.length != expectedCount || entries.any((entry) => entry.slug.isEmpty)) {
      throw const FormatException(
        'The religious text collection contains duplicate or empty identifiers.',
      );
    }
    const validCategories = <String>{
      'الورد اليومي والتعقيبات',
      'الأدعية الكبرى والمناجاة الشريفة',
      'أدعية المناسبات والشهور العبادية',
      'الصحيفة السجادية المباركة (نفحات مختارة)',
      'أدعية الحوائج، التحصينات والرزق',
      'الزيارات الشريفة والمقامات المقدسة',
      'الأدعية والأذكار اليومية',
      'التعقيبات بعد الصلاة',
      'الأدعية العامة وأدعية الفرج وصاحب الزمان',
      'الأعمال والمناسبات',
      'الزيارات الشريفة',
    };
    if (entries.any((entry) => entry.categoryOverride == null ||
        !validCategories.contains(entry.categoryOverride))) {
      throw const FormatException(
        'A religious text is missing a valid fixed category.',
      );
    }
    if (entries.any((entry) => entry.title.trim().isEmpty ||
        entry.sourceUrl.trim().isEmpty ||
        entry.sourceReference.trim().isEmpty ||
        entry.lines.isEmpty || entry.arabicText.trim().isEmpty)) {
      throw const FormatException(
        'The religious text collection contains an entry without a title, source, or Arabic text.',
      );
    }
    final signatures = <String>{};
    for (final entry in entries) {
      final signature = entry.arabicText
          .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640\s،؛,.!?؟:…()\-]'), '')
          .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
          .replaceAll('ى', 'ي');
      if (!signatures.add(signature)) {
        throw const FormatException(
          'The religious text collection contains duplicate Arabic texts.',
        );
      }
    }
    final metadata = decoded['metadata'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return ShiaTextData(
      entries: List<ShiaTextEntry>.unmodifiable(entries),
      sourceProject: metadata['sourceProject'] is String
          ? metadata['sourceProject'] as String
          : 'مكتبة الأدعية الشيعية',
      license: metadata['license'] is String
          ? metadata['license'] as String
          : 'المصادر موضحة لكل نص',
    );
  }
}

class ShiaTextLibraryPage extends StatefulWidget {
  const ShiaTextLibraryPage({
    super.key,
    this.initialCategory,
    this.sahifaOnly = false,
    this.dataFuture,
  });
  final String? initialCategory;
  final bool sahifaOnly;

  /// Allows deterministic UI tests to inject already loaded offline content.
  /// Regular app navigation leaves this unset and uses the bundled asset loaders.
  final Future<ShiaTextData>? dataFuture;

  @override
  State<ShiaTextLibraryPage> createState() => _ShiaTextLibraryPageState();
}

class _ShiaTextLibraryPageState extends State<ShiaTextLibraryPage> {
  Widget _categoryCard(BuildContext context, String category, int count) {
    final theme = Theme.of(context);
    IconData icon;
    String description;
    if (category == 'الورد اليومي والتعقيبات') {
      icon = Icons.wb_sunny_rounded;
      description = 'أوراد اليوم وأذكار الصلاة';
    } else if (category == 'الأدعية الكبرى والمناجاة الشريفة') {
      icon = Icons.volunteer_activism_rounded;
      description = 'الأدعية الجامعة والمناجاة المأثورة';
    } else if (category == 'أدعية المناسبات والشهور العبادية') {
      icon = Icons.calendar_month_rounded;
      description = 'أعمال الشهور والمناسبات الدينية';
    } else if (category == 'الصحيفة السجادية المباركة (نفحات مختارة)') {
      icon = Icons.menu_book_rounded;
      description = 'تظهر المختارات بعد تثبيت العناوين المعتمدة';
    } else if (category == 'أدعية الحوائج، التحصينات والرزق') {
      icon = Icons.shield_moon_rounded;
      description = 'أدعية قرآنية ومأثورة للحوائج';
    } else {
      icon = Icons.mosque_rounded;
      description = 'الزيارات والمقامات مع مرجع كل نص';
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: count == 0 ? null : () => setState(() => _category = category),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _shiaGold.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: _shiaGold, size: 24),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                category,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  height: 1.2,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                count == 0 &&
                        category == 'الصحيفة السجادية المباركة (نفحات مختارة)'
                    ? 'بانتظار اعتماد المختارات'
                    : count == 0
                        ? 'لا توجد مواد مختارة حالياً'
                        : '$count نصاً',
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  final _controller = TextEditingController();
  late Future<ShiaTextData> _future;
  late bool _sahifaOnly;
  String _query = '';
  String _category = 'كل النصوص';
  static const _categories = [
    'كل النصوص',
    'الورد اليومي والتعقيبات',
    'الأدعية الكبرى والمناجاة الشريفة',
    'أدعية المناسبات والشهور العبادية',
    'الصحيفة السجادية المباركة (نفحات مختارة)',
    'أدعية الحوائج، التحصينات والرزق',
    'الزيارات الشريفة والمقامات المقدسة',
  ];
  @override void initState() {
    super.initState();
    _sahifaOnly = widget.sahifaOnly;
    const categoryAliases = <String, String>{
      'الصحيفة السجادية والمناجيات': 'الصحيفة السجادية المباركة (نفحات مختارة)',
      'الأدعية والأذكار اليومية': 'الورد اليومي والتعقيبات',
      'التعقيبات بعد الصلاة': 'الورد اليومي والتعقيبات',
      'الأدعية العامة والفرج وصاحب الزمان': 'الأدعية الكبرى والمناجاة الشريفة',
      'الأدعية العامة وأدعية الفرج وصاحب الزمان': 'الأدعية الكبرى والمناجاة الشريفة',
      'الأعمال والمناسبات': 'أدعية المناسبات والشهور العبادية',
      'الزيارات الشريفة': 'الزيارات الشريفة والمقامات المقدسة',
    };
    final requestedCategory = widget.initialCategory;
    final mappedCategory = requestedCategory == null
        ? null
        : (categoryAliases[requestedCategory] ?? requestedCategory);
    _category = _sahifaOnly
        ? 'الصحيفة السجادية المباركة (نفحات مختارة)'
        : (_categories.contains(mappedCategory) ? mappedCategory! : _categories.first);
    _future = widget.dataFuture ??
        (_sahifaOnly ? ShiaTextData.loadSahifa() : ShiaTextData.load());
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }

  void _submitSearch() => setState(() => _query = _normalize(_controller.text.trim()));

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_sahifaOnly ? 'الصحيفة السجادية المباركة (نفحات مختارة)' : 'الأدعية والزيارات')),
    body: FutureBuilder<ShiaTextData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _shiaError(context, () {
            setState(() {
              if (_sahifaOnly) {
                ShiaTextData._sahifaCache = null;
                ShiaTextData._cache = null;
                ShiaTextData._coreCache = null;
                _future = ShiaTextData.loadSahifa();
              } else {
                ShiaTextData._cache = null;
                ShiaTextData._coreCache = null;
                ShiaTextData._sahifaCache = null;
                _future = ShiaTextData.load();
              }
            });
          });
        }
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: _shiaGold));
        }
        final data = snapshot.data!;
        final filtered = data.entries.where((entry) {
          if (_category != 'كل النصوص' && entry.category != _category) return false;
          if (_query.isEmpty) return true;
          final header = _normalize('${entry.displayTitle} ${entry.title} ${entry.slug}');
          return header.contains(_query) ||
              entry.lines.where((line) => line.isArabic).any((line) => _normalize(line.text).contains(_query));
        }).toList();
        final showCategoryOverview = !_sahifaOnly && _category == 'كل النصوص' && _query.isEmpty;
        return Column(children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _shiaGold.withValues(alpha: .28)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('مكتبة الأدعية والزيارات', style: TextStyle(color: _shiaGold, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                _sahifaOnly
                    ? (data.entries.isEmpty
                        ? 'لم تُعتمد قائمة العشرين المختارة بعد'
                        : '${data.entries.length} نصاً من الصحيفة السجادية والمناجيات')
                    : '${data.entries.length} نصاً في الأقسام المنشورة',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 6),
              Text(
                _sahifaOnly
                    ? 'لم تُنشر نصوص الصحيفة قبل تثبيت معرفات العشرين المختارة. بقيت سجلات المصدر محفوظة للمراجعة.'
                    : 'تصفح الأقسام المنشورة، مع مرجع النص بجانب محتواه. قسم الصحيفة ينتظر اعتماد المختارات.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11, height: 1.5),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submitSearch(),
              decoration: InputDecoration(
                hintText: 'ابحث بعنوان أو عبارة عربية...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(onPressed: _submitSearch, icon: const Icon(Icons.arrow_forward_rounded)),
                filled: true, fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            child: Row(children: [
              ...(_sahifaOnly ? const <String>['الصحيفة السجادية المباركة (نفحات مختارة)'] : _categories)
            ].map((choice) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(
                  choice == 'كل النصوص'
                      ? 'كل النصوص (${data.entries.length})'
                      : '$choice (${data.entries.where((entry) => entry.category == choice).length})',
                ),
                selected: _category == choice,
                onSelected: (_) => setState(() => _category = choice),
              ),
            )).toList()),
          ),
          Expanded(
            child: showCategoryOverview
                ? GridView.count(
                    padding: const EdgeInsets.all(14),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: .74,
                    children: [
                      for (final category in _categories.skip(1))
                        _categoryCard(
                          context,
                          category,
                          data.entries.where((entry) => entry.category == category).length,
                        ),
                    ],
                  )
                : filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(
                              _sahifaOnly
                                  ? 'قائمة العشرين المختارة من الصحيفة السجادية بانتظار تثبيت العناوين والمعرفات المعتمدة.'
                                  : 'ماكو نصوص ضمن هذا القسم في مصدر الأدعية الحالي.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'جرّب البحث باسم الدعاء أو اختر قسماً آخر من الأقسام المعروضة.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12, height: 1.6),
                            ),
                          ]),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          final arabicLineCount = entry.lines.where((line) => line.isArabic).length;
                          return Card(
                            color: Theme.of(context).colorScheme.surface,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _shiaGold.withValues(alpha: .15),
                                child: Icon(entry.isSahifa ? Icons.menu_book_rounded : Icons.auto_awesome_rounded, color: _shiaGold),
                              ),
                              title: Text(entry.displayTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${entry.isSahifa ? 'الصحيفة السجادية' : 'دعاء / زيارة'} • $arabicLineCount أسطر عربية', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              trailing: const Icon(Icons.chevron_left_rounded, color: _shiaGold),
                              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                                builder: (_) => Directionality(textDirection: TextDirection.rtl, child: ShiaTextReaderPage(entry: entry)),
                              )),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Text('المصدر: ${data.sourceProject} • ${data.license}', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10)),
          ),
        ]);
      },
    ),
  );
}

class ShiaTextReaderPage extends StatefulWidget {
  const ShiaTextReaderPage({super.key, required this.entry});
  final ShiaTextEntry entry;
  @override State<ShiaTextReaderPage> createState() => _ShiaTextReaderPageState();
}

class _ShiaTextReaderPageState extends State<ShiaTextReaderPage> {
  double _fontSize = 23;
  bool _focusMode = false;
  bool _isFavorite = false;
  bool _favoriteLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final slugs = prefs.getStringList('favorite_shia_text_slugs') ??
          const <String>[];
      if (!mounted) return;
      setState(() {
        _isFavorite = slugs.contains(widget.entry.slug);
        _favoriteLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _favoriteLoaded = true);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final slugs = (prefs.getStringList('favorite_shia_text_slugs') ??
              const <String>[])
          .toSet();
      final removing = slugs.contains(widget.entry.slug);
      if (removing) {
        slugs.remove(widget.entry.slug);
      } else {
        slugs.add(widget.entry.slug);
      }
      await prefs.setStringList(
        'favorite_shia_text_slugs',
        slugs.toList()..sort(),
      );
      if (!mounted) return;
      setState(() => _isFavorite = !removing);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(removing
              ? 'أُزيل النص من المفضلة'
              : 'أُضيف النص إلى المفضلة المباركة'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ المفضلة على الجهاز')),
        );
      }
    }
  }

  Future<void> _toggleFocusMode() async {
    final next = !_focusMode;
    setState(() => _focusMode = next);
    await SystemChrome.setEnabledSystemUIMode(
      next ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  @override
  void dispose() {
    if (_focusMode) SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  List<ShiaTextLine> get _visibleLines => widget.entry.lines
      .where((line) => line.isArabic && !_containsPersianOnlyText(line.text))
      .toList();

  bool _containsPersianOnlyText(String value) =>
      RegExp(r'[\u067e\u0686\u0698\u06af\u06cc\u06a9\u06d2\u06d3]').hasMatch(value) ||
      RegExp(r'\u062f\u0639\u0627\u06cc|\u0631\u0648\u0632\u0647\u0627\u06cc|\u0647\u0641\u062a\u0647|\u0641\u0627\u0631\u0633\u06cc|\u0628\u0631\u0627\u06cc|\u0645\u06cc\u0628\u0627\u0634\u062f|\u0645\u06cc \u0634\u0648\u062f|\u062e\u0648\u0627\u0647\u062f \u0634\u062f|\u0646\u0645\u06cc', caseSensitive: false).hasMatch(value);

  @override Widget build(BuildContext context) {
    final lines = _visibleLines;
    final allText = lines.map((line) => line.text).join('\n');
    return Scaffold(
      appBar: _focusMode ? null : AppBar(
        title: Text(widget.entry.displayTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: _isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
            onPressed: _favoriteLoaded ? _toggleFavorite : null,
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: _isFavorite ? _shiaGold : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            tooltip: 'وضع القراءة الخاشعة',
            onPressed: _toggleFocusMode,
            icon: const Icon(Icons.center_focus_strong_rounded),
          ),
          IconButton(
          tooltip: 'نسخ النص الظاهر',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: allText));
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص الظاهر')));
          },
          icon: const Icon(Icons.copy_rounded),
        )],
      ),
      floatingActionButton: _focusMode
        ? FloatingActionButton.small(onPressed: _toggleFocusMode, tooltip: 'إنهاء وضع القراءة الخاشعة', child: const Icon(Icons.close_rounded))
        : null,
      body: Column(children: [
        if (!_focusMode) Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          child: Column(children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('النص العربي', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            ),
            Row(children: [
              const Icon(Icons.text_fields_rounded, color: _shiaGold),
              Expanded(child: Slider(value: _fontSize, min: 16, max: 34, divisions: 9, label: _fontSize.round().toString(), onChanged: (v) => setState(() => _fontSize = v), activeColor: _shiaGold)),
              Text('${_fontSize.round()}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ]),
        ),
        Expanded(child: lines.isEmpty
          ? Center(child: Text('لا توجد أسطر ضمن هذا الخيار.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: _shiaGold.withValues(alpha: .28))),
                  child: Text(widget.entry.displayTitle, textAlign: TextAlign.center, style: const TextStyle(color: _shiaGold, fontSize: 22, fontWeight: FontWeight.w800, height: 1.6)),
                ),
                if (widget.entry.omittedSourceInstructionCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'ملاحظة تحريرية: تحتوي بيانات المصدر على ${widget.entry.omittedSourceInstructionCount} أسطر إرشادية غير عربية لم تُعرض هنا؛ هذه الصفحة تعرض الأسطر العربية فقط.',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        height: 1.6,
                      ),
                    ),
                  ),
                ...lines.map((line) {
                  final arabic = line.isArabic;
                  final persian = line.isPersian;
                  final rtl = arabic || persian;
                  final translation = line.isTranslation;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (line.displayId.isNotEmpty)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 7, top: 8),
                            child: Text(
                              line.displayId,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        Expanded(
                          child: SelectableText(
                            line.text,
                            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                            textAlign: rtl ? TextAlign.justify : TextAlign.start,
                            style: TextStyle(
                              fontSize: rtl ? _fontSize : _fontSize * .75,
                              height: rtl ? 2.0 : 1.6,
                              color: translation ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(color: Color(0x334A7562)),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _shiaGold.withValues(alpha: .22)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.sourceReference.trim().isNotEmpty
                            ? 'الإحالة المسجلة في بيانات النص: ${widget.entry.sourceReference}'
                            : 'لا توجد إحالة نصية مسجلة في بيانات هذا النص',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.7,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'هذه إحالة واردة في مجموعة البيانات، وليست بحد ذاتها مقابلة مستقلة على طبعة أصلية أو حكماً على صحة نسبة النص.',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.6,
                          fontSize: 11,
                        ),
                      ),
                      if (widget.entry.sourceUrl.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SelectableText(
                          'مصدر البيانات الإلكتروني: ${widget.entry.sourceUrl}',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 10,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            )),
      ]),
    );
  }
}

String _normalize(String value) => value
  .toLowerCase()
  .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
  .replaceAll(RegExp('[أإآٱ]'), 'ا')
  .replaceAll('ى', 'ي');

Widget _shiaError(BuildContext context, VoidCallback retry) => Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, color: _shiaGold, size: 42),
      const SizedBox(height: 12),
      Text('ما قدرنا نحمّل مكتبة الأدعية', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('قد يكون ملف المحتوى غير موجود في هذه النسخة. أعد المحاولة أو ثبّت نسخة مبنية بملفات البيانات.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6)),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: retry, icon: const Icon(Icons.refresh_rounded), label: Text('إعادة المحاولة')),
    ]),
  ),
);
