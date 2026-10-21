import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const _libraryPanel = Color(0xFF10251E);
const _libraryGold = Color(0xFFD9B66D);
const _libraryMuted = Color(0xFF9EB5A9);
const _officialOfficeUrl = 'https://www.leader.ir/ar';

class _FiqhTopic {
  const _FiqhTopic({
    required this.title,
    required this.description,
    required this.searchPhrase,
    required this.icon,
  });

  final String title;
  final String description;
  final String searchPhrase;
  final IconData icon;
}

const _fiqhTopics = <_FiqhTopic>[
  _FiqhTopic(
    title: 'الطهارة والوضوء والغسل',
    description: 'الوضوء، الغسل، التيمم، النجاسات والمطهّرات.',
    searchPhrase: 'أجوبة الاستفتاءات الطهارة الوضوء الغسل',
    icon: Icons.water_drop_outlined,
  ),
  _FiqhTopic(
    title: 'الصلاة',
    description: 'أوقات الصلاة، القراءة، الشكوك، السهو، صلاة المسافر والقضاء.',
    searchPhrase: 'أجوبة الاستفتاءات الصلاة الشكوك صلاة المسافر',
    icon: Icons.mosque_outlined,
  ),
  _FiqhTopic(
    title: 'الصوم وشهر رمضان',
    description: 'النية، المفطرات، القضاء، الكفارة وأحكام السفر في شهر رمضان.',
    searchPhrase: 'أجوبة الاستفتاءات الصوم المفطرات القضاء الكفارة',
    icon: Icons.nights_stay_outlined,
  ),
  _FiqhTopic(
    title: 'الخمس والزكاة والحقوق الشرعية',
    description: 'بداية السنة الخمسية، المؤونة، أرباح المكاسب والحقوق الشرعية.',
    searchPhrase: 'أجوبة الاستفتاءات الخمس أرباح المكاسب المؤونة',
    icon: Icons.account_balance_wallet_outlined,
  ),
  _FiqhTopic(
    title: 'المعاملات والعمل',
    description: 'البيع والشراء، الديون، الإجارة، الوظيفة والتعاملات اليومية.',
    searchPhrase: 'أجوبة الاستفتاءات البيع الشراء الديون الإجارة',
    icon: Icons.storefront_outlined,
  ),
  _FiqhTopic(
    title: 'الأسرة وحقوق الآخرين',
    description: 'أحكام الأسرة، صلة الرحم، حقوق الناس والتعامل الأخلاقي.',
    searchPhrase: 'أجوبة الاستفتاءات الأسرة حقوق الناس صلة الرحم',
    icon: Icons.diversity_3_outlined,
  ),
  _FiqhTopic(
    title: 'الأمر بالمعروف والنهي عن المنكر',
    description: 'الشروط والضوابط الشرعية قبل التدخل في أفعال الآخرين.',
    searchPhrase: 'أجوبة الاستفتاءات الأمر بالمعروف النهي عن المنكر',
    icon: Icons.record_voice_over_outlined,
  ),
  _FiqhTopic(
    title: 'الحج والعمرة',
    description: 'الاستطاعة، الإحرام، الطواف، السعي وبقية المناسك.',
    searchPhrase: 'مناسك الحج والعمرة الاستفتاءات',
    icon: Icons.travel_explore_outlined,
  ),
];

class FiqhTopicsPage extends StatefulWidget {
  const FiqhTopicsPage({super.key});

  @override
  State<FiqhTopicsPage> createState() => _FiqhTopicsPageState();
}

class _FiqhTopicsPageState extends State<FiqhTopicsPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openOfficialOffice() async {
    try {
      final opened = await launchUrl(
        Uri.parse(_officialOfficeUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح موقع المكتب. تحقق من الإنترنت.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح موقع المكتب.')),
        );
      }
    }
  }

  Future<void> _copySearchPhrase(String phrase) async {
    await Clipboard.setData(ClipboardData(text: phrase));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نُسخت عبارة البحث. افتح المصدر الرسمي وابحث بها.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim();
    final visibleTopics = _fiqhTopics.where((topic) {
      if (query.isEmpty) return true;
      return '${topic.title} ${topic.description} ${topic.searchPhrase}'
          .toLowerCase()
          .contains(query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('المسائل الشرعية')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
        children: [
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: _libraryPanel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _libraryGold.withValues(alpha: .32)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دليل أبواب الفقه',
                  style: TextStyle(
                    color: _libraryGold,
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'هذا فهرس يساعدك على تحديد موضوع المسألة، وليس موسوعة فتاوى محفوظة دون إنترنت. افتح المصدر الرسمي لمكتب السيد علي الخامنئي، ثم طابق الجواب مع مرجع تقليدك قبل العمل به.',
                  style: TextStyle(color: _libraryMuted, height: 1.7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ابحث عن باب فقهي...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: _libraryPanel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final topic in visibleTopics)
            Card(
              color: _libraryPanel,
              margin: const EdgeInsets.only(bottom: 9),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(topic.icon, color: _libraryGold, size: 25),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            topic.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      topic.description,
                      style: const TextStyle(
                        color: _libraryMuted,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _copySearchPhrase(topic.searchPhrase),
                          icon: const Icon(Icons.copy_rounded, size: 17),
                          label: const Text('نسخ عبارة البحث'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _openOfficialOffice,
                          icon: const Icon(Icons.open_in_new_rounded, size: 17),
                          label: const Text('المصدر الرسمي'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (visibleTopics.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('ما لقينا باباً مطابقاً لبحثك.'),
              ),
            ),
        ],
      ),
    );
  }
}

class NahjEntry {
  const NahjEntry({
    required this.id,
    required this.category,
    required this.number,
    required this.title,
    required this.text,
  });

  final int id;
  final int category;
  final String number;
  final String title;
  final String text;

  String get categoryLabel => switch (category) {
    1 => 'خطب',
    2 => 'رسائل',
    3 => 'حِكم',
    _ => 'نص',
  };

  factory NahjEntry.fromJson(Map<String, dynamic> json) => NahjEntry(
    id: json['id'] is int ? json['id'] as int : 0,
    category: json['category'] is int ? json['category'] as int : 0,
    number: json['number'] is String ? json['number'] as String : '',
    title: json['title'] is String ? json['title'] as String : '',
    text: json['text'] is String ? json['text'] as String : '',
  );
}

class NahjData {
  static Future<List<NahjEntry>> load() async {
    final raw = await rootBundle.loadString('assets/nahj/nahj.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final rawEntries = decoded['entries'] as List<dynamic>;
    final entries = rawEntries
        .whereType<Map<String, dynamic>>()
        .map(NahjEntry.fromJson)
        .where((entry) => entry.text.trim().isNotEmpty)
        .toList(growable: false);
    if (entries.length < 500) {
      throw FormatException('The offline Nahj catalogue appears incomplete: ${entries.length} entries.');
    }
    return entries;
  }
}

const _nahjCategoryOptions = <({int value, String label})>[
  (value: 0, label: 'الكتاب كله'),
  (value: 1, label: 'الخطب'),
  (value: 2, label: 'الرسائل'),
  (value: 3, label: 'الحِكم'),
];

String _nahjSearchKey(String value) => value
    .toLowerCase()
    .replaceAll('أ', 'ا')
    .replaceAll('إ', 'ا')
    .replaceAll('آ', 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
    .trim();

class NahjAlBalaghaPage extends StatefulWidget {
  const NahjAlBalaghaPage({super.key});

  @override
  State<NahjAlBalaghaPage> createState() => _NahjAlBalaghaPageState();
}

class _NahjAlBalaghaPageState extends State<NahjAlBalaghaPage> {
  final TextEditingController _search = TextEditingController();
  late Future<List<NahjEntry>> _future;
  int _category = 0;

  @override
  void initState() {
    super.initState();
    _future = NahjData.load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() => _future = NahjData.load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('نهج البلاغة'),
      actions: [
        IconButton(
          tooltip: 'إعادة تحميل المكتبة',
          onPressed: _retry,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: FutureBuilder<List<NahjEntry>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book_outlined, size: 44, color: _libraryGold),
                  const SizedBox(height: 12),
                  const Text(
                    'تعذّر تحميل مكتبة نهج البلاغة داخل التطبيق.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'أعد المحاولة بعد تحديث بيانات التطبيق.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _libraryMuted, height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _libraryGold));
        }

        final allEntries = snapshot.data!;
        final query = _nahjSearchKey(_search.text);
        final visible = allEntries.where((entry) {
          if (_category != 0 && entry.category != _category) return false;
          if (query.isEmpty) return true;
          return _nahjSearchKey(entry.title).contains(query) ||
              _nahjSearchKey(entry.number).contains(query) ||
              _nahjSearchKey(entry.text).contains(query);
        }).toList(growable: false);

        final sermonCount = allEntries.where((entry) => entry.category == 1).length;
        final letterCount = allEntries.where((entry) => entry.category == 2).length;
        final wisdomCount = allEntries.where((entry) => entry.category == 3).length;

        return Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _libraryPanel,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: _libraryGold.withValues(alpha: .3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'مكتبة نهج البلاغة',
                    style: TextStyle(color: _libraryGold, fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'نصوص عربية داخل التطبيق، مع فهرسة وبحث في الخطب والرسائل والحِكم.',
                    style: const TextStyle(color: _libraryMuted, height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _NahjCountChip(label: 'الخطب', count: sermonCount),
                      _NahjCountChip(label: 'الرسائل', count: letterCount),
                      _NahjCountChip(label: 'الحِكم', count: wisdomCount),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'ابحث في نصوص نهج البلاغة...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: _libraryPanel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  for (final option in _nahjCategoryOptions)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text(option.label),
                        selected: _category == option.value,
                        onSelected: (_) => setState(() => _category = option.value),
                        selectedColor: _libraryGold.withValues(alpha: .18),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'نتائج البحث: ${visible.length}',
                  style: const TextStyle(color: _libraryMuted, fontSize: 12),
                ),
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? const Center(child: Text('ما لقينا نصاً مطابقاً لهذا البحث.'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = visible[index];
                        final preview = entry.text.replaceAll(RegExp(r'\s+'), ' ').trim();
                        final shortPreview = preview.length > 180 ? '${preview.substring(0, 180)}…' : preview;
                        return Card(
                          color: _libraryPanel,
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: NahjEntryPage(entry: entry),
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.title.isEmpty ? '${entry.categoryLabel} ${entry.number}' : entry.title,
                                          style: const TextStyle(color: _libraryGold, fontWeight: FontWeight.w800, fontSize: 16, height: 1.6),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _libraryGold.withValues(alpha: .12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${entry.categoryLabel} ${entry.number}',
                                          style: const TextStyle(color: _libraryGold, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    shortPreview,
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(color: Colors.white, height: 1.75),
                                  ),
                                  const SizedBox(height: 8),
                                  const Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Icon(Icons.chevron_left_rounded, color: _libraryMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'المصدر: بيانات ثقالين المفتوحة بترخيص CC0-1.0. قد يختلف الترقيم بين الطبعات.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _libraryMuted, fontSize: 10, height: 1.5),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _NahjCountChip extends StatelessWidget {
  const _NahjCountChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      '$label: $count',
      style: const TextStyle(color: _libraryMuted, fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}

class NahjEntryPage extends StatelessWidget {
  const NahjEntryPage({super.key, required this.entry});

  final NahjEntry entry;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(
      text: '${entry.title} — ${entry.categoryLabel} ${entry.number}\n\n${entry.text}',
    ));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ النص')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${entry.categoryLabel} ${entry.number}'),
      actions: [
        IconButton(
          tooltip: 'نسخ النص',
          onPressed: () => _copy(context),
          icon: const Icon(Icons.copy_rounded, color: _libraryGold),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _libraryPanel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _libraryGold.withValues(alpha: .28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title.isEmpty ? '${entry.categoryLabel} ${entry.number}' : entry.title,
                style: const TextStyle(color: _libraryGold, fontWeight: FontWeight.w800, fontSize: 19, height: 1.7),
              ),
              const SizedBox(height: 8),
              Text(
                '${entry.categoryLabel} ${entry.number}',
                style: const TextStyle(color: _libraryMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SelectableText(
          entry.text,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
          style: const TextStyle(fontSize: 20, height: 2.0, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(
            onPressed: () => _copy(context),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('نسخ النص كاملاً'),
          ),
        ),
      ],
    ),
  );
}
