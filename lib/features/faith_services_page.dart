import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'faith_library_pages.dart';
import 'tafsir_reader_page.dart';

const _faithPanel = Color(0xFF10251E);
const _faithGold = Color(0xFFD9B66D);
const _faithMuted = Color(0xFF9EB5A9);

const _officialFiqhUrl = 'https://www.leader.ir/ar';
const _hajjUrl = 'https://www.leader.ir/ar/book/240/%D9%85%D9%86%D8%A7%D8%B3%D9%83-%D8%A7%D9%84%D8%AD%D8%AC';

Future<void> openFaithSource(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('الرابط غير صالح')),
    );
    return;
  }
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح الرابط. تحقق من اتصال الإنترنت.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح المصدر الخارجي.')),
      );
    }
  }
}

const _sistaniIstiftaatUrl = 'https://www.sistani.org/arabic/qa/';

/// Separate, source-linked gateways: answers are opened on each marja's own
/// official site and are never mixed or paraphrased as one shared ruling.
class IstiftaatPage extends StatelessWidget {
  const IstiftaatPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('استفتاءات المراجع')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _faithPanel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _faithGold.withValues(alpha: .32)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اختر مرجع التقليد', style: TextStyle(
                color: _faithGold, fontSize: 21, fontWeight: FontWeight.w900,
              )),
              SizedBox(height: 8),
              Text(
                'كل خيار يفتح الاستفتاءات في الموقع الرسمي لمكتب المرجع نفسه. الأجوبة خارجية وتحتاج الإنترنت؛ لا يخلط التطبيق بين فتاوى المراجع.',
                style: TextStyle(color: _faithMuted, height: 1.7),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ServiceTile(
          icon: Icons.account_balance_outlined,
          title: 'استفتاءات السيد علي الخامنئي',
          description: 'افتح الموقع الرسمي لمكتب السيد القائد للوصول إلى المسائل والأجوبة الفقهية.',
          actionLabel: 'فتح استفتاءات السيد الخامنئي',
          onTap: () => openFaithSource(context, _officialFiqhUrl),
        ),
        _ServiceTile(
          icon: Icons.menu_book_outlined,
          title: 'استفتاءات السيد السيستاني',
          description: 'افتح قسم الاستفتاءات المنشور على الموقع الرسمي لمكتب السيد السيستاني.',
          actionLabel: 'فتح استفتاءات السيد السيستاني',
          onTap: () => openFaithSource(context, _sistaniIstiftaatUrl),
        ),
      ],
    ),
  );
}

class FaithServicesPage extends StatelessWidget {
  const FaithServicesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الخدمات الإيمانية')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _faithPanel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _faithGold.withValues(alpha: .32)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('دليل الخدمات والمصادر', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: _faithGold,
              )),
              SizedBox(height: 8),
              Text(
                'روابط لمصادر خارجية مع أدلة تعمل من داخل التطبيق. الروابط تحتاج الإنترنت؛ لا نعرض النص الخارجي وكأنه مخزّن دون اتصال.',
                style: TextStyle(color: _faithMuted, height: 1.7),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ServiceTile(
          icon: Icons.menu_book_rounded,
          title: 'فقه المؤمن — المسائل الشرعية',
          description: 'فهرس لأبواب الطهارة والصلاة والصوم والخمس والمعاملات، مع عبارات بحث قابلة للنسخ للوصول إلى المصدر الرسمي. الفتاوى نفسها غير محفوظة دون إنترنت.',
          actionLabel: 'تصفح أبواب المسائل',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Directionality(
              textDirection: TextDirection.rtl,
              child: FiqhTopicsPage(),
            ),
          )),
        ),
        _ServiceTile(
          icon: Icons.auto_stories_rounded,
          title: 'تفسير القرآن الكريم',
          description: 'قراءات ومعانٍ إجمالية موجزة داخل التطبيق، مع إمكانية فتح تفسير الميزان الكامل من المصدر الخارجي.',
          actionLabel: 'قراءة التفسير داخل التطبيق',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Directionality(
              textDirection: TextDirection.rtl,
              child: TafsirReaderPage(),
            ),
          )),
        ),
        _ServiceTile(
          icon: Icons.explore_rounded,
          title: 'الاستخارة القرآنية — إرشاد شرعي',
          description: 'إرشادات قبل الاستخارة، من دون توليد نتيجة عشوائية أو الادعاء بمعرفة الغيب.',
          actionLabel: 'قراءة الإرشادات',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Directionality(
              textDirection: TextDirection.rtl,
              child: IstikharaGuidePage(),
            ),
          )),
        ),
        _ServiceTile(
          icon: Icons.mosque_rounded,
          title: 'دليل مناسك الحج والعمرة',
          description: 'مرجع المناسك المنشور على موقع مكتب السيد القائد. الأحكام التفصيلية تُراجع وفق مرجع التقليد.',
          actionLabel: 'فتح كتاب المناسك',
          onTap: () => openFaithSource(context, _hajjUrl),
        ),
        _ServiceTile(
          icon: Icons.directions_walk_rounded,
          title: 'دليل المشاية وزوار الأربعين',
          description: 'قائمة تحضير وتذكير محلية. الخريطة الحية ومسارات الخدمات الدقيقة غير مضمّنة حالياً.',
          actionLabel: 'فتح دليل الاستعداد',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Directionality(
              textDirection: TextDirection.rtl,
              child: ArbaeenGuidePage(),
            ),
          )),
        ),
        _ServiceTile(
          icon: Icons.format_quote_rounded,
          title: 'نهج البلاغة والحِكم',
          description: 'مختارات من حكم أمير المؤمنين علي عليه السلام باللغة العربية، مع معانٍ مبسطة وروابط للمصادر. هذه مختارات وليست النسخة الكاملة من الكتاب.',
          actionLabel: 'قراءة الحكم',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Directionality(
              textDirection: TextDirection.rtl,
              child: NahjAlBalaghaPage(),
            ),
          )),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _faithPanel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ما يحتاج مرحلة تنفيذ أخرى', style: TextStyle(
                color: _faithGold, fontWeight: FontWeight.w800, fontSize: 17,
              )),
              SizedBox(height: 9),
              _StatusLine(
                title: 'الختمة الشخصية',
                detail: 'موجودة وتحفظ التقدم محلياً؛ الختمة الجماعية المتزامنة تحتاج حسابات وخادماً وقاعدة بيانات.',
                done: true,
              ),
              _StatusLine(
                title: 'الصوتيات الخلفية ومكتبة المرئيات',
                detail: 'المتوفر حالياً معاينة تسجيل الأذان. المكتبة المتكاملة تحتاج ملفات موثقة الترخيص ومشغل خلفية واختبارات جهاز.',
                done: false,
              ),
              _StatusLine(
                title: 'تعيين نغمة رنين للهاتف',
                detail: 'ليس مفعّلاً. يحتاج تكاملاً خاصاً مع أندرويد وأذونات النظام، ويختلف حسب إصدار الجهاز.',
                done: false,
              ),
              _StatusLine(
                title: 'الخرائط للعمل دون إنترنت',
                detail: 'غير متوفرة حالياً؛ لا نعطي مساراً أو موقع خدمة على أنه مؤكد بلا بيانات خرائط فعلية.',
                done: false,
              ),
              _StatusLine(
                title: 'تفسير كامل دون إنترنت',
                detail: 'غير مضمّن. نحتاج نصاً عربياً موثوقاً مع ترخيص استخدام واضح ومراجعة قبل إدراجه.',
                done: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'تنبيه: المصدر الفقهي الخارجي قد يتضمن أحكاماً خاصة بمرجع معيّن. لا تعتمد جواباً فقهياً إلا بعد التأكد من مطابقته لمرجع تقليدك.',
          style: TextStyle(color: _faithMuted, height: 1.7, fontSize: 12),
        ),
      ],
    ),
  );
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: _faithPanel,
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: _faithGold, size: 25),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 16,
            ))),
          ]),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(
            color: _faithMuted, height: 1.6,
          )),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.title, required this.detail, required this.done});
  final String title;
  final String detail;
  final bool done;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          done ? Icons.check_circle_outline_rounded : Icons.pending_outlined,
          color: done ? _faithGold : _faithMuted,
          size: 20,
        ),
        const SizedBox(width: 9),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(detail, style: const TextStyle(
              color: _faithMuted, height: 1.5, fontSize: 12,
            )),
          ],
        )),
      ],
    ),
  );
}

class IstikharaGuidePage extends StatelessWidget {
  const IstikharaGuidePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الاستخارة القرآنية')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _faithPanel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _faithGold.withValues(alpha: .3)),
          ),
          child: const Text(
            'الاستخارة ليست لعبة ولا أداة لمعرفة الغيب. لا تُستعمل بديلاً عن التفكير أو السؤال أو الاستشارة.',
            style: TextStyle(color: _faithGold, fontSize: 18, height: 1.8, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 16),
        const _GuideStep(
          number: '١',
          title: 'فكّر في الموضوع',
          detail: 'اجمع المعلومات اللازمة وحدّد الخيارات وآثار كل خيار قبل اتخاذ القرار.',
        ),
        const _GuideStep(
          number: '٢',
          title: 'استشر أهل الخبرة والثقة',
          detail: 'اسأل أصحاب الخبرة المناسبة. لا تجعل الاستخارة بديلاً عن المشورة، خصوصاً في القرارات المصيرية.',
        ),
        const _GuideStep(
          number: '٣',
          title: 'إذا بقي التحيّر',
          detail: 'ارجع إلى أحكام مرجع تقليدك بشأن الاستخارة وطريقتها. لا تستخدم التطبيق لتوليد حكم أو نتيجة عشوائية من عنده.',
        ),
        const _GuideStep(
          number: '٤',
          title: 'لا تعتبرها كشفاً للغيب',
          detail: 'لا يزعم التطبيق أن آية بعينها تتنبأ بالمستقبل أو تضمن نتيجة القرار.',
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => openFaithSource(context, _officialFiqhUrl),
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('مراجعة المصدر الفقهي الرسمي'),
        ),
        const SizedBox(height: 12),
        const Text(
          'هذه إرشادات عامة وليست فتوى. راجع النص الرسمي لمرجع تقليدك إذا أردت معرفة الحكم أو الكيفية بالتحديد.',
          style: TextStyle(color: _faithMuted, height: 1.7, fontSize: 12),
        ),
      ],
    ),
  );
}

class ArbaeenGuidePage extends StatefulWidget {
  const ArbaeenGuidePage({super.key});

  @override
  State<ArbaeenGuidePage> createState() => _ArbaeenGuidePageState();
}

class _ArbaeenGuidePageState extends State<ArbaeenGuidePage> {
  static const _storageKey = 'mithaq_arbaeen_preparation_checked_v1';
  static const _items = <({String title, String detail})>[
    (title: 'تأكيد خط السير ونقطة الالتقاء', detail: 'اتفق مع المجموعة على مسارها ومكان واضح للاجتماع عند الانفصال.'),
    (title: 'إبلاغ الأهل بالخطة', detail: 'شارك وقت الانطلاق وخط السير التقريبي ووسيلة التواصل.'),
    (title: 'الهاتف والاتصال', detail: 'اشحن الهاتف وخذ بطارية احتياطية واحفظ الأرقام المهمة.'),
    (title: 'الماء والراحة', detail: 'خطط للاستراحة واشرب الماء بانتظام، واطلب المساعدة عند الدوار أو التعب الشديد.'),
    (title: 'الأغراض الأساسية', detail: 'هوية، مستلزمات النظافة، حذاء مريح وملابس تناسب الطقس.'),
    (title: 'الأدوية اللازمة', detail: 'خذ أدويتك الموصوفة إن وجدت واحفظها بطريقة مناسبة.'),
    (title: 'متابعة التعليمات المحلية', detail: 'تحقق من حالة الطقس والتنبيهات والتعليمات الرسمية قبل التحرك.'),
    (title: 'احترام الطريق والآخرين', detail: 'حافظ على النظافة واتبع توجيهات المنظمين وتجنب المسارات المغلقة.'),
  ];

  Set<String> _checked = <String>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_storageKey) ?? const <String>[];
    if (!mounted) return;
    setState(() {
      _checked = saved.toSet();
      _loading = false;
    });
  }

  Future<void> _toggle(String title, bool checked) async {
    final next = Set<String>.from(_checked);
    if (checked) {
      next.add(title);
    } else {
      next.remove(title);
    }
    setState(() => _checked = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, next.toList()..sort());
  }

  @override
  Widget build(BuildContext context) {
    final completed = _items.where((item) => _checked.contains(item.title)).length;
    return Scaffold(
      appBar: AppBar(title: const Text('دليل المشاية')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _faithPanel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _faithGold.withValues(alpha: .3)),
            ),
            child: const Text(
              'قائمة تحضير تعمل دون إنترنت وتحفظ علامات الإنجاز على جهازك. ليست خريطة طريق، ولا تؤكد مواقع المواكب أو الخدمات.',
              style: TextStyle(color: _faithGold, height: 1.7, fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Text('قائمة الاستعداد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              Text('$completed من ${_items.length}', style: const TextStyle(color: _faithGold, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _items.isEmpty ? 0 : completed / _items.length,
            minHeight: 6,
            borderRadius: BorderRadius.circular(6),
            backgroundColor: _faithMuted.withValues(alpha: .16),
            color: _faithGold,
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ))
          else
            for (final item in _items)
              Card(
                color: _faithPanel,
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  value: _checked.contains(item.title),
                  onChanged: (value) => _toggle(item.title, value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: _faithGold,
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(item.detail, style: const TextStyle(color: _faithMuted, height: 1.5)),
                  ),
                ),
              ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading || _checked.isEmpty
                ? null
                : () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove(_storageKey);
                    if (mounted) setState(() => _checked = <String>{});
                  },
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('إعادة تعيين القائمة'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => openFaithSource(context, _officialFiqhUrl),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('فتح موقع المكتب الرسمي'),
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.number, required this.title, required this.detail});
  final String number;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Card(
    color: _faithPanel,
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _faithGold.withValues(alpha: .15),
            child: Text(number, style: const TextStyle(
              color: _faithGold, fontWeight: FontWeight.w800,
            )),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(detail, style: const TextStyle(
                color: _faithMuted, height: 1.6,
              )),
            ],
          )),
        ],
      ),
    ),
  );
}
