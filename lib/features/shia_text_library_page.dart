import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mafatih_data.dart';

const _shiaPanel = Color(0xFF10251E);
const _shiaGold = Color(0xFFD9B66D);
const _shiaMuted = Color(0xFF9EB5A9);

class ShiaTextLine {
  const ShiaTextLine({required this.index, required this.kind, required this.text});
  final int index;
  final String kind;
  final String text;
  bool get isArabic => kind.toLowerCase() == 'arabic';
  bool get isTranslation => kind.toLowerCase() == 'translation';
  bool get isPersian =>
      RegExp(r'persian|farsi|\bfa\b|فارسي|فارسی', caseSensitive: false).hasMatch(kind) ||
      RegExp(r'[گچپژ]').hasMatch(text);
  bool get isTransliteration => kind.toLowerCase() == 'transliteration';
  factory ShiaTextLine.fromJson(Map<String, dynamic> json) => ShiaTextLine(
    index: json['index'] is int ? json['index'] as int : 0,
    kind: json['kind'] is String ? json['kind'] as String : 'other',
    text: json['text'] is String ? json['text'] as String : '',
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
    this.sourceLabel = '',
    this.categoryOverride = '',
  });
  final String slug;
  final String title;
  final String alternateName;
  final String type;
  final String sourceUrl;
  final List<ShiaTextLine> lines;
  /// Human-readable source citation, e.g. a book title and the exact source headings.
  final String sourceLabel;
  /// Used for imported book entries whose original section is already verified.
  final String categoryOverride;
  String get displayTitle {
    for (final candidate in <String>[alternateName, title]) {
      final clean = normalizeMafatihArabicText(candidate.trim());
      if (clean.isEmpty) continue;
      if (!clean.runes.any((rune) => rune >= 0x0600 && rune <= 0x06FF)) continue;
      if (RegExp(r'[A-Za-z]').hasMatch(clean)) continue;
      if (containsPersianOnlyLetters(clean) || containsPersianLanguageMarkers(candidate)) continue;
      return clean;
    }
    return _arabicTitleFromSlug(slug, type);
  }
  bool get isSahifa => slug.startsWith('sahifa-sajjadiya-');
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
  bool get isSharedDua {
    final value = '${slug.toLowerCase()} $title $alternateName';
    return RegExp(
      r'morning.{0,24}evening|evening.{0,24}morning|صباح.{0,24}مساء|مساء.{0,24}صباح|صباحاً ومساءً|صباحا ومساء|أذكار مشتركة|both periods',
      caseSensitive: false,
    ).hasMatch(value);
  }
  bool get isMorningDua {
    final value = '${slug.toLowerCase()} $title $alternateName';
    return !isSharedDua &&
        RegExp(r'morning|sabah|asbah|أذكار الصباح|الصباح|الصبح|دعاء الصباح|قبل طلوع الشمس', caseSensitive: false).hasMatch(value);
  }
  bool get isEveningDua {
    final value = '${slug.toLowerCase()} $title $alternateName';
    return !isSharedDua &&
        RegExp(r'evening|masa|amsa|أذكار المساء|المساء|عند الغروب|قبل الغروب|دعاء المساء', caseSensitive: false).hasMatch(value);
  }
  bool get isDailyDeed {
    final value = '${slug.toLowerCase()} $title $alternateName';
    return RegExp(r'daily deeds|أعمال اليوم|أعمال ليلة|أعمال يوم|أعمال الليلة|الأعمال اليومية|العمل اليومي').hasMatch(value);
  }
  bool get isMonthlyDeed {
    final value = '${slug.toLowerCase()} $title $alternateName';
    return RegExp(r'monthly deeds|أعمال الأشهر|أعمال شهر|أعمال الشهر|الأعمال الشهرية').hasMatch(value);
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
    if (categoryOverride.trim().isNotEmpty) return categoryOverride;
    // Keep specific collections and distinct time periods before broad occasion matching.
    if (isZiyara) return 'الزيارات';
    if (isSahifa) return 'الصحيفة السجادية';
    if (isMunajat) return 'المناجيات الخمس عشرة';
    if (isMahdiDua) return 'أدعية صاحب الزمان';
    if (isSharedDua) return 'الأذكار المشتركة';
    if (isMorningDua) return 'أدعية الصباح';
    if (isEveningDua) return 'أدعية المساء';
    if (isDailyDeed) return 'الأعمال اليومية والمناسبات';
    if (isMonthlyDeed) return 'الأعمال الشهرية والمناسبات';
    if (isHajatDua) return 'أدعية الحاجات والشفاء';
    if (isOccasionDua) return 'أدعية الأشهر والمناسبات';
    if (isTaqibat) return 'تعقيبات الصلوات';
    if (isDayDua) return 'أدعية الأيام';
    return 'أدعية عامة';
  }
  String get arabicText => lines.where((line) => line.isArabic).map((line) => line.text).join('\n');

  factory ShiaTextEntry.fromJson(Map<String, dynamic> json) => ShiaTextEntry(
    slug: json['slug'] is String ? json['slug'] as String : '',
    title: json['title'] is String ? json['title'] as String : 'دعاء',
    alternateName: json['alternateName'] is String ? json['alternateName'] as String : '',
    type: json['type'] is String ? json['type'] as String : 'dua',
    sourceUrl: json['sourceUrl'] is String ? json['sourceUrl'] as String : '',
    sourceLabel: json['sourceLabel'] is String ? json['sourceLabel'] as String : '',
    categoryOverride: json['categoryOverride'] is String ? json['categoryOverride'] as String : '',
    lines: ((json['lines'] as List<dynamic>?) ?? const <dynamic>[])
      .whereType<Map<String, dynamic>>().map(ShiaTextLine.fromJson).toList(),
  );
}

String _arabicTitleFromSlug(String slug, String type) {
  final value = slug.toLowerCase().replaceAll('_', '-');
  if (value.contains('ziyarat-ashura') || value.contains('ziyarah-ashura')) return 'زيارة عاشوراء';
  if (value.contains('ziyarat-arba') || value.contains('ziyarah-arba')) return 'زيارة الأربعين';
  if (value.contains('ziyarat-warith') || value.contains('ziyarah-warith')) return 'زيارة وارث';
  if (value.contains('ziyarat-amin-allah') || value.contains('ziyarah-amin-allah')) return 'زيارة أمين الله';
  if (value.contains('dua-kumayl') || value.contains('du-a-kumayl')) return 'دعاء كميل';
  if (value.contains('dua-sabah') || value.contains('du-a-sabah')) return 'دعاء الصباح';
  if (value.contains('dua-nudba') || value.contains('du-a-nudba')) return 'دعاء الندبة';
  if (value.contains('dua-al-ahd') || value.contains('du-a-al-ahd')) return 'دعاء العهد';
  if (value.contains('dua-iftitah') || value.contains('du-a-iftitah')) return 'دعاء الافتتاح';
  if (value.contains('dua-tawassul') || value.contains('du-a-tawassul')) return 'دعاء التوسل';
  if (value.startsWith('sahifa-sajjadiya-')) {
    final number = int.tryParse(value.split('-').last);
    return number == null ? 'الصحيفة السجادية' : 'الصحيفة السجادية — الدعاء رقم $number';
  }
  if (value.contains('ziyarat') || value.contains('ziyarah') || type.toLowerCase().contains('ziyara')) return 'زيارة';
  if (value.contains('sahifa')) return 'الصحيفة السجادية';
  return 'دعاء';
}

class ShiaTextData {
  const ShiaTextData({required this.entries, required this.sourceProject, required this.license});
  final List<ShiaTextEntry> entries;
  final String sourceProject;
  final String license;
  static Future<ShiaTextData>? _cache;
  static Future<ShiaTextData> load() => _cache ??= _load();

  static Future<ShiaTextData> _load() async {
    final raw = await rootBundle.loadString('assets/shia_duas/shia_duas.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final rawEntries = decoded['entries'] as List<dynamic>;
    final entries = rawEntries
        .whereType<Map<String, dynamic>>()
        .map(ShiaTextEntry.fromJson)
        .where((entry) => entry.lines.any(
              (line) => line.isArabic && line.text.trim().isNotEmpty,
            ))
        .toList(growable: false);

    if (entries.isEmpty) {
      throw const FormatException('The bundled Arabic dua/ziyara library is empty.');
    }

    final metadata = decoded['metadata'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return ShiaTextData(
      entries: entries,
      sourceProject: metadata['sourceProject'] is String
          ? metadata['sourceProject'] as String
          : 'مكتبة الأدعية والزيارات العربية',
      license: metadata['license'] is String
          ? metadata['license'] as String
          : 'تختلف الرخص بحسب مصدر كل نص',
    );
  }
}

class ShiaTextLibraryPage extends StatefulWidget {
  const ShiaTextLibraryPage({super.key, this.initialCategory});
  final String? initialCategory;
  @override State<ShiaTextLibraryPage> createState() => _ShiaTextLibraryPageState();
}

class _ShiaTextLibraryPageState extends State<ShiaTextLibraryPage> {
  final _controller = TextEditingController();
  late Future<ShiaTextData> _future;
  String _query = '';
  String _category = 'أدعية عامة';
  static const _categories = [
    'أدعية عامة',
    'أدعية صاحب الزمان',
    'أدعية الصباح',
    'أدعية المساء',
    'الأذكار المشتركة',
    'أدعية الحاجات والشفاء',
    'تعقيبات الصلوات',
    'أدعية الأيام',
    'الأعمال اليومية والمناسبات',
    'الأعمال الشهرية والمناسبات',
    'أدعية الأشهر والمناسبات',
    'الزيارات',
    'الصحيفة السجادية',
    'المناجيات الخمس عشرة',
  ];

  @override void initState() {
    super.initState();
    _category = widget.initialCategory ?? 'أدعية عامة';
    _future = ShiaTextData.load();
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }

  void _submitSearch() => setState(() => _query = _normalize(_controller.text.trim()));

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الأدعية والزيارات')),
    body: FutureBuilder<ShiaTextData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _shiaError(() {
            setState(() { ShiaTextData._cache = null; _future = ShiaTextData.load(); });
          });
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _shiaGold));
        }
        final data = snapshot.data!;
        // Only show categories that actually contain readable Arabic entries.
        final availableCategories = _categories
            .where((category) => data.entries.any((entry) => entry.category == category))
            .toList(growable: false);
        final activeCategory = availableCategories.contains(_category)
            ? _category
            : (availableCategories.isNotEmpty ? availableCategories.first : 'أدعية عامة');
        final filtered = data.entries.where((entry) {
          if (entry.category != activeCategory) return false;
          if (_query.isEmpty) return true;
          final header = _normalize('${entry.displayTitle} ${entry.title} ${entry.slug}');
          return header.contains(_query) ||
              entry.lines.where((line) => line.isArabic).any((line) => _normalize(line.text).contains(_query));
        }).toList();
        final sahifaCount = data.entries.where((entry) => entry.isSahifa).length;
        return Column(children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _shiaPanel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _shiaGold.withValues(alpha: .28)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('نصوص شيعية للقراءة دون إنترنت', style: TextStyle(color: _shiaGold, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('${data.entries.length} نصاً • منها $sahifaCount من الصحيفة السجادية', style: const TextStyle(color: _shiaMuted)),
              const SizedBox(height: 6),
              const Text('المكتبة مصنفة حسب نوع الدعاء والزيارة والعمل، ويظهر مصدر كل نص بوضوح في صفحة القراءة. قد تختلف العناوين أو الروايات بين الطبعات؛ العرض هنا عربي فقط.', style: TextStyle(color: _shiaMuted, fontSize: 11, height: 1.5)),
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
                filled: true, fillColor: _shiaPanel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            child: Row(children: [
              ...availableCategories
            ].map((choice) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(label: Text(choice), selected: activeCategory == choice, onSelected: (_) => setState(() => _category = choice)),
            )).toList()),
          ),
          Expanded(
            child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text(
                        'ماكو نصوص ضمن هذا القسم في مصدر الأدعية الحالي.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _shiaMuted, height: 1.6),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => setState(() {
                          _category = 'أدعية عامة';
                          _query = '';
                          _controller.clear();
                        }),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('عرض الأدعية العامة'),
                      ),
                    ]),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16), itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    final arabicLineCount = entry.lines.where((line) => line.isArabic).length;
                    return Card(
                      color: _shiaPanel,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _shiaGold.withValues(alpha: .15),
                          child: Icon(entry.isSahifa ? Icons.menu_book_rounded : Icons.auto_awesome_rounded, color: _shiaGold),
                        ),
                        title: Text(entry.displayTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${entry.isSahifa ? 'الصحيفة السجادية' : 'دعاء / زيارة'} • $arabicLineCount أسطر عربية', style: const TextStyle(color: _shiaMuted)),
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
            child: Text('المصدر: ${data.sourceProject} • ${data.license}', textAlign: TextAlign.center, style: const TextStyle(color: _shiaMuted, fontSize: 10)),
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

  List<ShiaTextLine> get _visibleLines =>
      widget.entry.lines.where((line) => line.isArabic && line.text.trim().isNotEmpty).toList(growable: false);

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
              color: _isFavorite ? _shiaGold : _shiaMuted,
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
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'عرض النص العربي فقط',
                style: TextStyle(color: _shiaMuted, fontSize: 12),
              ),
            ),
            Row(children: [
              const Icon(Icons.text_fields_rounded, color: _shiaGold),
              Expanded(child: Slider(value: _fontSize, min: 16, max: 34, divisions: 9, label: _fontSize.round().toString(), onChanged: (v) => setState(() => _fontSize = v), activeColor: _shiaGold)),
              Text('${_fontSize.round()}', style: const TextStyle(color: _shiaMuted)),
            ]),
          ]),
        ),
        Expanded(child: lines.isEmpty
          ? const Center(child: Text('لا توجد أسطر ضمن هذا الخيار.', style: TextStyle(color: _shiaMuted)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _shiaPanel, borderRadius: BorderRadius.circular(18), border: Border.all(color: _shiaGold.withValues(alpha: .28))),
                  child: Text(widget.entry.displayTitle, textAlign: TextAlign.center, style: const TextStyle(color: _shiaGold, fontSize: 22, fontWeight: FontWeight.w800, height: 1.6)),
                ),
                ...lines.map((line) {
                  final arabic = line.isArabic;
                  final persian = line.isPersian;
                  final rtl = arabic || persian;
                  final translation = line.isTranslation;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SelectableText(
                      line.text,
                      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                      textAlign: rtl ? TextAlign.justify : TextAlign.start,
                      style: TextStyle(
                        fontSize: rtl ? _fontSize : _fontSize * .75,
                        height: rtl ? 2.0 : 1.6,
                        color: rtl ? Colors.white : (translation ? _shiaMuted : Colors.white70),
                      ),
                    ),
                  );
                }),
                const Divider(color: Color(0x334A7562)),
                const Text('النص المعروض عربي فقط. قد تختلف الضبطات أو ترتيب الفقرات بين الطبعات.', style: TextStyle(color: _shiaMuted, height: 1.7, fontSize: 11)),
                if (widget.entry.sourceLabel.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SelectableText('المصدر: ${widget.entry.sourceLabel}', textDirection: TextDirection.rtl, style: const TextStyle(color: _shiaGold, fontSize: 11, height: 1.6)),
                ],
                if (widget.entry.sourceUrl.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SelectableText('رابط المصدر: ${widget.entry.sourceUrl}', textDirection: TextDirection.ltr, style: const TextStyle(color: _shiaMuted, fontSize: 10)),
                ],
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

Widget _shiaError(VoidCallback retry) => Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, color: _shiaGold, size: 42),
      const SizedBox(height: 12),
      const Text('ما قدرنا نحمّل مكتبة الأدعية', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('قد يكون ملف المحتوى غير موجود في هذه النسخة. أعد المحاولة أو ثبّت نسخة مبنية بملفات البيانات.', textAlign: TextAlign.center, style: TextStyle(color: _shiaMuted, height: 1.6)),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: retry, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة')),
    ]),
  ),
);
