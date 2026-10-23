import 'package:flutter/material.dart';

const _namesGold = Color(0xFFD9B66D);

class NamesOfAllahPage extends StatefulWidget {
  const NamesOfAllahPage({super.key});
  @override State<NamesOfAllahPage> createState() => _NamesOfAllahPageState();
}

class _NamesOfAllahPageState extends State<NamesOfAllahPage> {
  final TextEditingController _search = TextEditingController();

  static const _names = <(String, String)>[
    ('الله', 'المعبود بحق، الجامع لصفات الكمال'),
    ('الرحمن', 'واسع الرحمة لجميع خلقه'),
    ('الرحيم', 'كثير الرحمة بعباده'),
    ('الملك', 'المالك المتصرف في خلقه'),
    ('القدوس', 'المنزّه عن كل نقص'),
    ('السلام', 'السالم من النقص، وواهب السلام'),
    ('المؤمن', 'المؤمّن لعباده من الظلم'),
    ('المهيمن', 'الرقيب الحافظ على خلقه'),
    ('العزيز', 'الغالب الذي لا يُغلب'),
    ('الجبار', 'الذي تنفذ مشيئته ويجبر الضعف'),
    ('المتكبر', 'المتعالي عن صفات الخلق'),
    ('الخالق', 'الذي أوجد الخلق'),
    ('البارئ', 'الذي أنشأ الخلق وأوجدهم'),
    ('المصور', 'الذي أعطى كل مخلوق صورته'),
    ('الغفار', 'كثير المغفرة لمن تاب'),
    ('القهار', 'الغالب لكل شيء'),
    ('الوهاب', 'كثير العطاء بلا عوض'),
    ('الرزاق', 'الذي يرزق خلقه'),
    ('الفتاح', 'الذي يفتح أبواب الخير ويحكم بالحق'),
    ('العليم', 'المحيط علماً بكل شيء'),
    ('القابض', 'الذي يقبض بحكمته'),
    ('الباسط', 'الذي يبسط فضله ورزقه'),
    ('الخافض', 'الذي يخفض بحكمته'),
    ('الرافع', 'الذي يرفع من يشاء بفضله'),
    ('المعز', 'الذي يمنح العزة'),
    ('المذل', 'الذي يذل من يشاء بعدله'),
    ('السميع', 'الذي يسمع كل شيء'),
    ('البصير', 'الذي لا يخفى عليه شيء'),
    ('الحكم', 'الحاكم بالحق'),
    ('العدل', 'المنزّه عن الظلم'),
    ('اللطيف', 'الرفيق بعباده، العالم بدقائق الأمور'),
    ('الخبير', 'العالم ببواطن الأمور'),
    ('الحليم', 'الذي لا يعاجل بالعقوبة'),
    ('العظيم', 'صاحب العظمة والكمال'),
    ('الغفور', 'الذي يستر الذنب ويغفره'),
    ('الشكور', 'الذي يثيب على القليل كثيراً'),
    ('العلي', 'المتعالي في كماله'),
    ('الكبير', 'الذي كل شيء دونه'),
    ('الحفيظ', 'الحافظ لكل شيء'),
    ('المقيت', 'المتكفّل بأقوات الخلق'),
    ('الحسيب', 'الكافي والمحاسب لعباده'),
    ('الجليل', 'العظيم القدر'),
    ('الكريم', 'الواسع الخير والعطاء'),
    ('الرقيب', 'المطّلع الذي لا يغيب عنه شيء'),
    ('المجيب', 'الذي يجيب دعاء من يشاء'),
    ('الواسع', 'الذي وسع علمه ورحمته كل شيء'),
    ('الحكيم', 'الذي يضع الأمور مواضعها'),
    ('الودود', 'المحب لعباده الصالحين'),
    ('المجيد', 'العظيم كثير الإحسان'),
    ('الباعث', 'الذي يبعث الخلق بعد الموت'),
    ('الشهيد', 'الحاضر الذي لا يغيب عنه شيء'),
    ('الحق', 'الثابت الذي لا شك فيه'),
    ('الوكيل', 'الكافي لمن توكل عليه'),
    ('القوي', 'صاحب القوة التامة'),
    ('المتين', 'الشديد القوة الذي لا يضعف'),
    ('الولي', 'الناصر والمتولي لشؤون عباده'),
    ('الحميد', 'المستحق للحمد'),
    ('المحصي', 'الذي أحاط بكل شيء عدداً وعلماً'),
    ('المبدئ', 'الذي يبدأ الخلق'),
    ('المعيد', 'الذي يعيد الخلق بعد الموت'),
    ('المحيي', 'الذي يهب الحياة'),
    ('المميت', 'الذي يقدّر الموت'),
    ('الحي', 'الذي له الحياة الكاملة التي لا تزول'),
    ('القيوم', 'القائم بنفسه والقائم على كل شيء'),
    ('الواجد', 'الذي لا يعجزه شيء'),
    ('الماجد', 'الكريم العظيم ذو المجد'),
    ('الواحد', 'المنفرد في ذاته وصفاته'),
    ('الصمد', 'المقصود في الحوائج'),
    ('القادر', 'الذي لا يعجزه شيء'),
    ('المقتدر', 'تام القدرة'),
    ('المقدم', 'الذي يقدم من يشاء بحكمته'),
    ('المؤخر', 'الذي يؤخر من يشاء بحكمته'),
    ('الأول', 'الذي ليس قبله شيء'),
    ('الآخر', 'الذي ليس بعده شيء'),
    ('الظاهر', 'الذي ظهرت دلائل وجوده وقهره'),
    ('الباطن', 'الذي لا تحيط به الأبصار ولا تدركه الأوهام'),
    ('الوالي', 'المتولي لتدبير الخلق'),
    ('المتعالي', 'المنزّه عن صفات النقص'),
    ('البر', 'كثير الإحسان واللطف'),
    ('التواب', 'الذي يقبل التوبة مراراً'),
    ('المنتقم', 'الذي يجازي على الظلم بحكمته وعدله'),
    ('العفو', 'الذي يمحو الذنوب ويتجاوز عنها'),
    ('الرؤوف', 'شديد الرأفة بعباده'),
    ('مالك الملك', 'مالك السلطان كله'),
    ('ذو الجلال والإكرام', 'صاحب العظمة والإحسان'),
    ('المقسط', 'العادل الذي ينصف المظلوم'),
    ('الجامع', 'الذي يجمع الخلق ليوم الحساب'),
    ('الغني', 'المستغني عن كل شيء'),
    ('المغني', 'الذي يغني من يشاء بفضله'),
    ('المانع', 'الذي يمنع بحكمته'),
    ('الضار', 'لا يقع شيء إلا بإذنه وحكمته'),
    ('النافع', 'بيده النفع كله'),
    ('النور', 'هادي أهل السماوات والأرض'),
    ('الهادي', 'الذي يهدي من يشاء إلى صراطه'),
    ('البديع', 'الذي أبدع الخلق بلا مثال سابق'),
    ('الباقي', 'الذي لا يفنى'),
    ('الوارث', 'الباقي بعد فناء الخلق، وإليه يرجع كل شيء'),
    ('الرشيد', 'الذي يرشد إلى الصواب'),
    ('الصبور', 'الذي لا يعاجل العصاة بالعقوبة'),
  ];

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim();
    final filtered = List.generate(_names.length, (i) => (number: i + 1, name: _names[i].$1, meaning: _names[i].$2))
      .where((item) => query.isEmpty || item.name.contains(query) || item.meaning.contains(query))
      .toList();
    return Scaffold(
      appBar: AppBar(title: Text('أسماء الله الحسنى')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: _namesGold.withValues(alpha: .3))),
            child: Text('قائمة مشهورة لأسماء الله الحسنى ومعانٍ موجزة للتدبّر. قد تختلف طريقة تعداد الأسماء وترتيبها بين المصادر.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.7)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ابحث عن اسم أو معنى...',
              prefixIcon: Icon(Icons.search_rounded),
              filled: true, fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = filtered[index];
              return Card(
                color: Theme.of(context).colorScheme.surface,
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: _namesGold.withValues(alpha: .15), child: Text(item.number.toString(), style: TextStyle(color: _namesGold, fontSize: 12))),
                  title: Text(item.name, style: TextStyle(color: _namesGold, fontSize: 20, fontWeight: FontWeight.w800)),
                  subtitle: Text(item.meaning, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6)),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
