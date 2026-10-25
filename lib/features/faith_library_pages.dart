import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final scheme = Theme.of(context).colorScheme;
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
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.secondary.withValues(alpha: .32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دليل أبواب الفقه',
                  style: TextStyle(
                    color: scheme.secondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'هذا فهرس يساعدك على تحديد موضوع المسألة، وليس موسوعة فتاوى محفوظة دون إنترنت. افتح المصدر الرسمي لمكتب السيد علي الخامنئي، ثم طابق الجواب مع مرجع تقليدك قبل العمل به.',
                  style: TextStyle(color: scheme.onSurfaceVariant, height: 1.7),
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
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: .45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final topic in visibleTopics)
            Card(
              color: scheme.surface,
              margin: const EdgeInsets.only(bottom: 9),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(topic.icon, color: scheme.secondary, size: 25),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            topic.title,
                            style: TextStyle(
                              color: scheme.onSurface,
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
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
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
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'ما لقينا باباً مطابقاً لبحثك.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
        ],
      ),
    );
  }

}

class _NahjWisdom {
  const _NahjWisdom({
    required this.text,
    required this.meaning,
    required this.sourceUrl,
  });

  final String text;
  final String meaning;
  final String sourceUrl;
}

const _nahjWisdoms = <_NahjWisdom>[
  _NahjWisdom(
    text: 'قِيمَةُ كُلِّ امْرِئٍ مَا يُحْسِنُهُ',
    meaning: 'قيمة الإنسان فيما يتقنه من علم وعمل وخُلُق، لا في اسمه أو ماله وحدهما.',
    sourceUrl: 'https://www.inahj.org/shortresearchwisdomstring/3061',
  ),
  _NahjWisdom(
    text: 'النَّاسُ أَعْدَاءُ مَا جَهِلُوا',
    meaning: 'قد يدفع الجهل إلى رفض ما لا نفهمه؛ لذلك نتعلّم ونتثبّت قبل إصدار الأحكام.',
    sourceUrl: 'https://inahj.org/3387',
  ),
  _NahjWisdom(
    text: 'لِسَانُ العَاقِلِ وَرَاءَ قَلْبِهِ، وَقَلْبُ الأَحْمَقِ وَرَاءَ لِسَانِهِ',
    meaning: 'العاقل يفكّر قبل أن يتكلم، ولا يترك لسانه يسبقه إلى كلام يندم عليه.',
    sourceUrl: 'https://inahj.org/2636',
  ),
  _NahjWisdom(
    text: 'إِذَا تَمَّ العَقْلُ نَقَصَ الكَلَامُ',
    meaning: 'ليس المقصود الصمت دائماً، بل أن يكون الكلام بقدر الحاجة والفائدة.',
    sourceUrl: 'https://inahj.org/2977',
  ),
  _NahjWisdom(
    text: 'فَقْدُ الأَحِبَّةِ غُرْبَةٌ',
    meaning: 'فقد الأحبة يجعل الإنسان يشعر بالوحشة حتى لو كان بين الناس.',
    sourceUrl: 'https://inahj.org/impact/695',
  ),
  _NahjWisdom(
    text: 'الكَلَامُ فِي وَثَاقِكَ مَا لَمْ تَتَكَلَّمْ بِهِ، فَإِذَا تَكَلَّمْتَ بِهِ صِرْتَ فِي وَثَاقِهِ',
    meaning: 'قبل الكلام تملك اختيارك، وبعده تتحمّل مسؤوليته وآثاره.',
    sourceUrl: 'https://inahj.org/1089',
  ),
  _NahjWisdom(
    text: 'لَا مَالَ أَعْوَدُ مِنَ العَقْلِ، وَلَا مِيرَاثَ كَالأَدَبِ',
    meaning: 'العقل والأدب زاد يبقى مع الإنسان وينفعه أكثر من المال العابر.',
    sourceUrl: 'https://www.inahj.org/articlesandresearch/2071',
  ),
  _NahjWisdom(
    text: 'مَا رَأَيْتُ ظَالِمًا أَشْبَهَ بِمَظْلُومٍ مِنَ الحَاسِدِ',
    meaning: 'الحسد يؤذي صاحبه قبل أن يؤذي غيره، فلا تجعل نجاح الآخرين سبباً للحقد.',
    sourceUrl: 'https://inahj.org/559',
  ),
];

class NahjAlBalaghaPage extends StatefulWidget {
  const NahjAlBalaghaPage({super.key});

  @override
  State<NahjAlBalaghaPage> createState() => _NahjAlBalaghaPageState();
}

class _NahjAlBalaghaPageState extends State<NahjAlBalaghaPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openSource(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح المصدر.')),
        );
      }
    }
  }

  Future<void> _copyWisdom(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ الحكمة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = _search.text.trim().toLowerCase();
    final visible = _nahjWisdoms.where((item) =>
        query.isEmpty ||
        item.text.toLowerCase().contains(query) ||
        item.meaning.toLowerCase().contains(query)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('نهج البلاغة والحِكم')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
        children: [
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.secondary.withValues(alpha: .32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مختارات من الحكم',
                  style: TextStyle(
                    color: scheme.secondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'المتوفر دون إنترنت هنا ثماني حكم مختارة مع شرح مبسّط، وليس النص الكامل لنهج البلاغة. افتح المصدر الخارجي لقراءة الخطب والرسائل والحِكم كاملة؛ يحتاج ذلك إلى الإنترنت.',
                  style: TextStyle(color: scheme.onSurfaceVariant, height: 1.7),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _openSource('https://arabic.balaghah.net/'),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('فتح نهج البلاغة الكامل عبر المصدر الخارجي'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ابحث في الحكم ومعانيها...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: .45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < visible.length; i++)
            Card(
              color: scheme.surface,
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: scheme.secondary.withValues(alpha: .15),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: scheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            visible[i].text,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 21,
                              height: 1.9,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      visible[i].meaning,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: () => _copyWisdom(visible[i].text),
                          icon: const Icon(Icons.copy_rounded, size: 17),
                          label: const Text('نسخ الحكمة'),
                        ),
                        TextButton.icon(
                          onPressed: () => _openSource(visible[i].sourceUrl),
                          icon: const Icon(Icons.source_outlined, size: 17),
                          label: const Text('مصدر النص'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'ما لقينا حكمة مطابقة.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
        ],
      ),
    );
  }

}
