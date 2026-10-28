import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _faithGold = Color(0xFFD9B66D);

const _officialFiqhUrl = 'https://www.leader.ir/ar';
const _officialSistaniFiqhUrl = 'https://www.sistani.org/arabic/qa/';
const _tafsirUrl = 'https://almizan.wilayah.app/';
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

class FaithServicesPage extends StatelessWidget {
  const FaithServicesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('الخدمات الإيمانية')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _faithGold.withValues(alpha: .32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('دليل الخدمات والمصادر', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: _faithGold,
              )),
              SizedBox(height: 8),
              Text(
                'روابط لمصادر خارجية مع أدلة تعمل من داخل التطبيق. الروابط تحتاج الإنترنت؛ لا نعرض النص الخارجي وكأنه مخزّن دون اتصال.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.7),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        _ServiceTile(
          icon: Icons.menu_book_rounded,
          title: 'استفتاءات السيد علي الخامنئي',
          description: 'رابط مباشر إلى الموقع الرسمي لمكتب السيد علي الخامنئي. تُفتح الاستفتاءات عبر الإنترنت، ولا ينشئ التطبيق فتاوى من عنده.',
          actionLabel: 'فتح الاستفتاءات الرسمية',
          onTap: () => openFaithSource(context, _officialFiqhUrl),
        ),
        _ServiceTile(
          icon: Icons.menu_book_rounded,
          title: 'استفتاءات السيد علي السيستاني',
          description: 'رابط مباشر إلى باب الاستفتاءات الرسمي حسب الموضوع. تأكد من مراجعة حكم مرجع تقليدك قبل العمل بأي جواب.',
          actionLabel: 'فتح استفتاءات السيد السيستاني',
          onTap: () => openFaithSource(context, _officialSistaniFiqhUrl),
        ),
        _ServiceTile(
          icon: Icons.auto_stories_rounded,
          title: 'تفسير القرآن الكريم',
          description: 'مكتبة إلكترونية لتفسير الميزان باللغة العربية. هذه نسخة خارجية تحتاج اتصالاً؛ لم نضمّن نص التفسير محلياً ولم نختصره من دون مراجعة.',
          actionLabel: 'فتح تفسير الميزان',
          onTap: () => openFaithSource(context, _tafsirUrl),
        ),
        _ServiceTile(
          icon: Icons.mosque_rounded,
          title: 'دليل مناسك الحج والعمرة',
          description: 'مرجع المناسك المنشور على موقع مكتب السيد القائد. الأحكام التفصيلية تُراجع وفق مرجع التقليد.',
          actionLabel: 'فتح كتاب المناسك',
          onTap: () => openFaithSource(context, _hajjUrl),
        ),
        SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .45)),
          ),
          child: Column(
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
        SizedBox(height: 12),
        Text(
          'تنبيه: المصدر الفقهي الخارجي قد يتضمن أحكاماً خاصة بمرجع معيّن. لا تعتمد جواباً فقهياً إلا بعد التأكد من مطابقته لمرجع تقليدك.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.7, fontSize: 12),
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
    color: Theme.of(context).colorScheme.surface,
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: _faithGold, size: 25),
            SizedBox(width: 10),
            Expanded(child: Text(title, style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 16,
            ))),
          ]),
          SizedBox(height: 8),
          Text(description, style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6,
          )),
          SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onTap,
              icon: Icon(Icons.open_in_new_rounded, size: 18),
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
          color: done ? _faithGold : Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
        SizedBox(width: 9),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 3),
            Text(detail, style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5, fontSize: 12,
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
    appBar: AppBar(title: Text('الاستخارة القرآنية')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _faithGold.withValues(alpha: .3)),
          ),
          child: Text(
            'الاستخارة ليست لعبة ولا أداة لمعرفة الغيب. لا تُستعمل بديلاً عن التفكير أو السؤال أو الاستشارة.',
            style: TextStyle(color: _faithGold, fontSize: 18, height: 1.8, fontWeight: FontWeight.w800),
          ),
        ),
        SizedBox(height: 16),
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
        SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => openFaithSource(context, _officialFiqhUrl),
          icon: Icon(Icons.open_in_new_rounded),
          label: Text('مراجعة المصدر الفقهي الرسمي'),
        ),
        SizedBox(height: 12),
        Text(
          'هذه إرشادات عامة وليست فتوى. راجع النص الرسمي لمرجع تقليدك إذا أردت معرفة الحكم أو الكيفية بالتحديد.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.7, fontSize: 12),
        ),
      ],
    ),
  );
}

class ArbaeenGuidePage extends StatelessWidget {
  const ArbaeenGuidePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('دليل المشاية')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _faithGold.withValues(alpha: .3)),
          ),
          child: Text(
            'قائمة تحضير تعمل دون إنترنت. ليست خريطة طريق، ولا تؤكد مواقع المواكب أو الخدمات.',
            style: TextStyle(color: _faithGold, height: 1.7, fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(height: 12),
        const _GuideStep(number: '١', title: 'قبل الانطلاق', detail: 'تحقق من حالة الطقس وتعليمات الجهات المحلية وخط سير مجموعتك، وأخبر أهلك بخطتك.'),
        const _GuideStep(number: '٢', title: 'الماء والراحة', detail: 'اشرب الماء بانتظام وخذ فترات راحة، ولا تواصل المشي إذا شعرت بدوار أو تعب شديد؛ اطلب مساعدة المشرفين أو الخدمات الطبية.'),
        const _GuideStep(number: '٣', title: 'الهاتف والاتصال', detail: 'اشحن الهاتف وخذ بطارية احتياطية، واحفظ أرقام أفراد مجموعتك ومكان الالتقاء عند الانفصال.'),
        const _GuideStep(number: '٤', title: 'الأغراض الأساسية', detail: 'هوية شخصية، أدوية موصوفة لك إن وجدت، حذاء مريح مجرّب، مستلزمات النظافة، وملابس مناسبة للطقس.'),
        const _GuideStep(number: '٥', title: 'احترام الآخرين', detail: 'اتبع تعليمات المنظمين، حافظ على نظافة الطريق، ولا تدخل مساراً مغلقاً أو مزدحماً.'),
        SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => openFaithSource(context, _officialFiqhUrl),
          icon: Icon(Icons.open_in_new_rounded),
          label: Text('فتح موقع المكتب الرسمي'),
        ),
      ],
    ),
  );
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.number, required this.title, required this.detail});
  final String number;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.surface,
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _faithGold.withValues(alpha: .15),
            child: Text(number, style: TextStyle(
              color: _faithGold, fontWeight: FontWeight.w800,
            )),
          ),
          SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w800)),
              SizedBox(height: 5),
              Text(detail, style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6,
              )),
            ],
          )),
        ],
      ),
    ),
  );
}
