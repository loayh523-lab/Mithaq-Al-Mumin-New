import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _dhikrGold = Color(0xFFD9B66D);
const _dhikrSourceUrl = 'https://tableegh.imamali.net/?id=3117';

class _DhikrItem {
  const _DhikrItem({
    required this.id,
    required this.category,
    required this.title,
    required this.text,
    required this.target,
    required this.source,
    this.eveningText,
  });

  final String id;
  final String category;
  final String title;
  final String text;
  final int? target;
  final String source;
  final String? eveningText;

  String textFor(int period) => period == 1 ? (eveningText ?? text) : text;
}

class DhikrFortressPage extends StatefulWidget {
  const DhikrFortressPage({super.key});
  @override
  State<DhikrFortressPage> createState() => _DhikrFortressPageState();
}

class _DhikrFortressPageState extends State<DhikrFortressPage> {
  static const _items = <_DhikrItem>[
    _DhikrItem(
      id: 'shield-prayer',
      category: 'المناجاة',
      title: 'دعاء الدرع الحصينة',
      text: 'اللهم اجعلني في درعك الحصينة التي تجعل فيها من تريد',
      target: 3,
      source: 'ثلاث مرات صباحاً ومساءً. الكافي، ج 2، ص 534؛ وسائل الشيعة، ج 7، ص 229؛ بحار الأنوار، ج 83، ص 296.',
    ),
    _DhikrItem(
      id: 'salawat-prophetic',
      category: 'المناجاة',
      title: 'الصلاة على النبي وآله',
      text: 'اللهم صل على محمد وآل محمد في الأولين، وصل على محمد وآل محمد في الآخرين، وصل على محمد وآل محمد في الملأ الأعلى، وصل على محمد وآل محمد في المرسلين. اللهم أعط محمداً الوسيلة والشرف والفضيلة والدرجة الكبيرة. اللهم إني آمنت بمحمد ولم أره، فلا تحرمني يوم القيامة رؤيته، وارزقني صحبته وتوفني على ملته، واسقني من حوضه مشرباً روياً سائغاً هنيئاً لا أظمأ بعده أبداً، إنك على كل شيء قدير. اللهم كما آمنت بمحمد ولم أره، فعرفني في الجنان وجهه. اللهم بلغ روح محمد عني تحية كثيرة وسلاماً.',
      target: 3,
      source: 'وردت ثلاث مرات غدوة وعشية. ثواب الأعمال للشيخ الصدوق، ص 157؛ بحار الأنوار، ج 91، ص 59.',
    ),
    _DhikrItem(
      id: 'mutaqallib',
      category: 'المناجاة',
      title: 'دعاء تثبيت القلب',
      text: 'اللهم مقلب القلوب والأبصار، ثبت قلبي على دينك، ولا تزغ قلبي بعد إذ هديتني، وهب لي من لدنك رحمة إنك أنت الوهاب، وأجرني من النار برحمتك. اللهم امدد لي في عمري، وأوسع علي من رزقي، وانشر علي من رحمتك، وإن كنت عندك في أم الكتاب شقياً فاجعلني سعيداً، فإنك تمحو ما تشاء وتثبت وعندك أم الكتاب.',
      target: 3,
      source: 'ورد ثلاث مرات عند الصباح والمساء. الكافي، ج 2، ص 525.',
    ),
    _DhikrItem(
      id: 'allah-allah',
      category: 'التسبيحات',
      title: 'ذكر التوحيد',
      text: 'الله الله الله ربي الرحمن الرحيم، لا أشرك به شيئاً',
      target: null,
      source: 'الكافي، ج 2، ص 534. ورد أن يقال صباحاً ومساءً، والنقل المذكور لا يحدد عدداً؛ العداد هنا للتتبع فقط.',
    ),
    _DhikrItem(
      id: 'la-yadurru',
      category: 'العوذات',
      title: 'بسم الله الذي لا يضر',
      text: 'بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم',
      target: 3,
      source: 'ثلاث مرات صباحاً ومساءً. بحار الأنوار، ج 83، ص 300.',
    ),
    _DhikrItem(
      id: 'la-hawla',
      category: 'التسبيحات',
      title: 'لا حول ولا قوة إلا بالله',
      text: 'لا حول ولا قوة إلا بالله العلي العظيم',
      target: 10,
      source: 'عشر مرات صباحاً وعشر مرات مساءً. بحار الأنوار، ج 83، ص 161. وذكر المصدر أيضاً قولها قبل النوم.',
    ),
    _DhikrItem(
      id: 'maqalid',
      category: 'التسبيحات',
      title: 'دعاء المقاليد',
      text: 'لا إله إلا الله، والله أكبر، سبحان الله، والحمد لله، أستغفر الله، ولا حول ولا قوة إلا بالله، هو الأول والآخر، والظاهر والباطن، له الملك وله الحمد، يحيي ويميت وهو حي لا يموت، بيده الخير وهو على كل شيء قدير',
      target: 10,
      source: 'عشر مرات صباحاً وعشر مرات مساءً؛ منقول في المصدر عن بحار الأنوار ضمن أذكار الصباح والمساء.',
    ),
    _DhikrItem(
      id: 'nimat',
      category: 'العوذات',
      title: 'دعاء النعمة والعافية والستر',
      text: 'اللهم إني أصبحت في نعمة منك وعافية وستر، فصل على محمد وآل محمد، وأتمم علي نعمتك وعافيتك وسترك',
      eveningText: 'اللهم إني أمسيت في نعمة منك وعافية وستر، فصل على محمد وآل محمد، وأتمم علي نعمتك وعافيتك وسترك',
      target: 3,
      source: 'ثلاث مرات صباحاً ومساءً. بحار الأنوار، ج 83، ص 283.',
    ),
  ];

  final Map<String, int> _counts = <String, int>{};
  bool _loading = true;
  int _period = 0;
  String _selectedCategory = 'الكل';
  static const _categoryNames = ['الكل', 'التسبيحات', 'المناجاة', 'العوذات'];

  String get _periodName => _period == 0 ? 'صباح' : 'مساء';
  List<_DhikrItem> get _visibleItems => _items.where((item) => _selectedCategory == 'الكل' || item.category == _selectedCategory).toList();

  String _key(String id) {
    final now = DateTime.now();
    final day = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'fortress_v3_${_periodName}_${day}_$id';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        for (final item in _visibleItems) {
          _counts[item.id] = (prefs.getInt(_key(item.id)) ?? 0);
          if (item.target != null) {
            _counts[item.id] = _counts[item.id]!.clamp(0, item.target!);
          }
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setPeriod(int period) async {
    setState(() {
      _period = period;
      _loading = true;
      _counts.clear();
    });
    await _load();
  }

  Future<void> _increment(_DhikrItem item) async {
    final current = _counts[item.id] ?? 0;
    if (item.target != null && current >= item.target!) return;
    final next = current + 1;
    HapticFeedback.lightImpact();
    setState(() => _counts[item.id] = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key(item.id), next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ عدّاد الذكر')),
        );
      }
    }
  }

  Future<void> _reset(_DhikrItem item) async {
    setState(() => _counts[item.id] = 0);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key(item.id), 0);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر تصفير عدّاد الذكر')),
        );
      }
    }
  }

  final TextEditingController _searchController = TextEditingController();

  Future<void> _openSource() async {
    try {
      final opened = await launchUrl(Uri.parse(_dhikrSourceUrl), mode: LaunchMode.externalApplication);
      if (!opened && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر فتح مصدر الأذكار.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر فتح مصدر الأذكار.')));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _visibleItems.where((item) {
      return query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.textFor(_period).toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('حصن الأذكار'),
        actions: [
          IconButton(
            tooltip: 'المفضلة قريباً',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('يمكنك حفظ الأذكار المهمة ضمن المفضلة بعد تفعيل هذه الميزة.')),
            ),
            icon: const Icon(Icons.bookmark_border_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            controller: _searchController,
            textDirection: TextDirection.rtl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ابحث عن الأذكار',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: 'مسح البحث',
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.mic_none_rounded),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'الأذكار المخصصة باليوم',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('أذكار الصباح'), icon: Icon(Icons.wb_sunny_outlined)),
              ButtonSegment(value: 1, label: Text('أذكار المساء'), icon: Icon(Icons.nights_stay_outlined)),
            ],
            selected: {_period},
            onSelectionChanged: (selected) => _setPeriod(selected.first),
          ),
          const SizedBox(height: 20),
          Text(
            'أقسام الأذكار',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in _categoryNames)
                ChoiceChip(
                  label: Text(category == 'الكل' ? 'كل الأذكار' : category + ' (' + _items.where((item) => item.category == category).length.toString() + ')'),
                  selected: _selectedCategory == category,
                  onSelected: (_) => setState(() => _selectedCategory = category),
                  avatar: Icon(category == 'التسبيحات' ? Icons.fingerprint_rounded : category == 'المناجاة' ? Icons.volunteer_activism_rounded : category == 'العوذات' ? Icons.shield_moon_rounded : Icons.grid_view_rounded, size: 18, color: _dhikrGold),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('ما لقينا ذكر يطابق بحثك.', style: theme.textTheme.bodyLarge)),
            )
          else
            ...filtered.map((item) {
              final count = _counts[item.id] ?? 0;
              final target = item.target;
              final complete = target != null && count >= target;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _dhikrGold.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      complete ? Icons.check_circle_rounded : Icons.autorenew_rounded,
                      color: _dhikrGold,
                    ),
                  ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(target == null ? 'عداد مفتوح' : (complete ? 'اكتمل الورد' : '$count من $target')),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        item.textFor(_period),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.titleMedium?.copyWith(height: 1.9),
                      ),
                    ),
                    if (target != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (count / target).clamp(0, 1).toDouble(),
                          minHeight: 6,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('المصدر: ${item.source}', style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: _openSource,
                        icon: const Icon(Icons.open_in_new_rounded, size: 17),
                        label: const Text('فتح مصدر الأذكار'),
                        style: TextButton.styleFrom(foregroundColor: _dhikrGold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: complete || _loading ? null : () => _increment(item),
                            icon: const Icon(Icons.touch_app_rounded),
                            label: const Text('تسبيح'),
                          ),
                        ),
                        IconButton(
                          tooltip: 'إعادة العداد',
                          onPressed: _loading ? null : () => _reset(item),
                          icon: const Icon(Icons.restart_alt_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 8),
          Text(
            'تنبيه: تُعرض الأعداد كما وردت في المصدر عند توفرها، والعداد المفتوح للتتبع فقط وليس تحديداً لحكم شرعي.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
