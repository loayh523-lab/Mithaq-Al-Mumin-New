import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/religious_occasions.dart';
import 'prayer_calendar_page.dart';

const _occasionGold = Color(0xFFD9B66D);

class ReligiousOccasionsPage extends StatefulWidget {
  const ReligiousOccasionsPage({super.key});

  @override
  State<ReligiousOccasionsPage> createState() => _ReligiousOccasionsPageState();
}

class _ReligiousOccasionsPageState extends State<ReligiousOccasionsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  ReligiousOccasionKind? _kind;
  int _hijriCorrection = 0;
  late DateTime _today;
  Map<String, DateTime> _nextDates = <String, DateTime>{};

  @override
  void initState() {
    super.initState();
    _today = DateUtils.dateOnly(DateTime.now());
    _rebuildNextDates();
    _loadHijriCorrection();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHijriCorrection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _hijriCorrection = prefs.getInt('hijri_correction') ?? 0;
        _rebuildNextDates();
      });
    } catch (_) {
      // The page still works with the default civil-calendar estimate.
    }
  }

  String _dateKey(int day, int month) => '$month-$day';

  void _rebuildNextDates() {
    final wantedDates = shiaReligiousOccasions
        .map((occasion) => _dateKey(occasion.hijriDay, occasion.hijriMonth))
        .toSet();
    final nextDates = <String, DateTime>{};

    // Scan the calendar once, not once per event on every rebuild.
    for (var offset = 0; offset <= 400; offset++) {
      final candidate = _today.add(Duration(days: offset));
      final hijri = hijriDateParts(candidate, correction: _hijriCorrection);
      final key = _dateKey(hijri.day, hijri.month);
      if (wantedDates.contains(key)) {
        nextDates.putIfAbsent(key, () => candidate);
      }
      if (nextDates.length == wantedDates.length) break;
    }
    _nextDates = nextDates;
  }

  DateTime? _nextGregorianDate(ReligiousOccasion occasion) =>
      _nextDates[_dateKey(occasion.hijriDay, occasion.hijriMonth)];

  List<({ReligiousOccasion occasion, DateTime? date})> get _visibleOccasions {
    final query = _normalize(_query);
    final filtered = shiaReligiousOccasions.where((occasion) {
      if (_kind != null && occasion.kind != _kind) return false;
      if (query.isEmpty) return true;
      final searchable = _normalize(
        '${occasion.title} ${occasion.qualification ?? ''} '
        '${occasion.kindLabel} ${_monthName(occasion.hijriMonth)} '
        '${occasion.hijriDay}',
      );
      return searchable.contains(query);
    }).map((occasion) => (
          occasion: occasion,
          date: _nextGregorianDate(occasion),
        )).toList();

    filtered.sort((a, b) {
      if (a.date != null && b.date != null) return a.date!.compareTo(b.date!);
      if (a.date != null) return -1;
      if (b.date != null) return 1;
      final monthCompare =
          a.occasion.hijriMonth.compareTo(b.occasion.hijriMonth);
      return monthCompare != 0
          ? monthCompare
          : a.occasion.hijriDay.compareTo(b.occasion.hijriDay);
    });
    return filtered;
  }

  String _normalize(String value) => value
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();

  String _monthName(int month) => const [
        'محرم',
        'صفر',
        'ربيع الأول',
        'ربيع الآخر',
        'جمادى الأولى',
        'جمادى الآخرة',
        'رجب',
        'شعبان',
        'رمضان',
        'شوال',
        'ذو القعدة',
        'ذو الحجة',
      ][month - 1];

  String _gregorianLabel(DateTime? date) {
    if (date == null) return 'لم يتحدد المقابل الحسابي';
    const months = [
      'كانون الثاني',
      'شباط',
      'آذار',
      'نيسان',
      'أيار',
      'حزيران',
      'تموز',
      'آب',
      'أيلول',
      'تشرين الأول',
      'تشرين الثاني',
      'كانون الأول',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} م';
  }

  String _arabicDigits(int value) => value.toString().replaceAllMapped(
        RegExp(r'[0-9]'),
        (match) => '٠١٢٣٤٥٦٧٨٩'[int.parse(match.group(0)!)],
      );

  void _showDetails(
    ReligiousOccasion occasion,
    DateTime? estimatedDate,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              6,
              20,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    occasion.title,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.event_outlined, size: 17),
                        label: Text(
                          '${_arabicDigits(occasion.hijriDay)} '
                          '${_monthName(occasion.hijriMonth)} هـ',
                        ),
                      ),
                      Chip(
                        avatar: const Icon(
                          Icons.category_outlined,
                          size: 17,
                        ),
                        label: Text(occasion.kindLabel),
                      ),
                    ],
                  ),
                  if (occasion.qualification != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      occasion.qualification!,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 16,
                        height: 1.7,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month_rounded),
                    title: const Text('التاريخ الميلادي الحسابي المتوقع'),
                    subtitle: Text(_gregorianLabel(estimatedDate)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'التاريخ الهجري هنا حسابي للتقويم فقط، وقد يختلف يومًا عن إعلان ثبوت الهلال في العراق. بعض المناسبات لها روايات متعددة؛ لذلك عُرضت صفة الرواية بوضوح ولا يُعرض التاريخ الحسابي باعتباره إثباتًا شرعيًا.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.65,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final occasions = _visibleOccasions;
    return Scaffold(
      appBar: AppBar(title: const Text('المناسبات الدينية')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: scheme.secondary.withValues(alpha: .24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      color: scheme.secondary,
                      size: 26,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'مناسبات أهل البيت عليهم السلام',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  'ابحث بالاسم أو الشهر، أو صفِّ المناسبات حسب نوعها.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    height: 1.55,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن مناسبة أو معصوم...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'مسح البحث',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest.withValues(
                      alpha: .38,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'تصنيف المناسبات',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _kindChip('الكل', null),
              for (final kind in ReligiousOccasionKind.values)
                _kindChip(_labelForKind(kind), kind),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  _query.isEmpty && _kind == null
                      ? 'الأقرب بحسب التقويم الحسابي'
                      : 'نتائج البحث',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${_arabicDigits(occasions.length)} مناسبة',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (occasions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 34,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ما لقينا مناسبة بهالبحث',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'غيّر كلمة البحث أو اختر تصنيفًا آخر.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            for (final item in occasions) _occasionTile(item, scheme),
          const SizedBox(height: 10),
          Text(
            'ملاحظة: المقابل الميلادي تقديري وفق التقويم الهجري الجدولي وتصحيح التاريخ المحفوظ في الإعدادات، وليس إعلانًا رسميًا لثبوت الهلال.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kindChip(String label, ReligiousOccasionKind? kind) {
    final selected = _kind == kind;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _kind = kind),
      selectedColor: _occasionGold.withValues(alpha: .24),
      labelStyle: TextStyle(
        color: selected
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected
            ? _occasionGold.withValues(alpha: .8)
            : Theme.of(context).colorScheme.outlineVariant,
      ),
      showCheckmark: false,
    );
  }

  String _labelForKind(ReligiousOccasionKind kind) => switch (kind) {
        ReligiousOccasionKind.historical => 'أحداث تاريخية',
        ReligiousOccasionKind.birth => 'ولادات',
        ReligiousOccasionKind.martyrdom => 'شهادات ووفيات',
        ReligiousOccasionKind.eid => 'أعياد',
        ReligiousOccasionKind.ziyara => 'زيارات',
        ReligiousOccasionKind.devotional => 'مناسبات وأعمال',
      };

  Widget _occasionTile(
    ({ReligiousOccasion occasion, DateTime? date}) item,
    ColorScheme scheme,
  ) {
    final occasion = item.occasion;
    return Card(
      color: scheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: .55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(occasion, item.date),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 54),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _occasionGold.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  children: [
                    Text(
                      _arabicDigits(occasion.hijriDay),
                      style: TextStyle(
                        color: scheme.secondary,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _monthName(occasion.hijriMonth),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 9,
                        height: 1.35,
                      ),
                    ),
                    const Text('هـ', style: TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      occasion.title,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.55,
                      ),
                    ),
                    if (occasion.qualification != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        occasion.qualification!,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: scheme.secondary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _gregorianLabel(item.date),
                            style: TextStyle(
                              color: scheme.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                Icons.chevron_left_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
