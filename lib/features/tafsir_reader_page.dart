import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _tafsirInk = Color(0xFF071713);
const _tafsirPanel = Color(0xFF10251E);
const _tafsirGold = Color(0xFFD9B66D);
const _tafsirMuted = Color(0xFF9EB5A9);
const _alMizanUrl = 'https://almizan.wilayah.app/';

class _TafsirReading {
  const _TafsirReading({
    required this.title,
    required this.reference,
    required this.verse,
    required this.meaning,
  });

  final String title;
  final String reference;
  final String verse;
  final String meaning;
}

const _readings = <_TafsirReading>[
  _TafsirReading(
    title: 'الإخلاص في العبادة والاستعانة',
    reference: 'سورة الفاتحة، الآية 5',
    verse: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
    meaning: 'تجمع الآية أصلين من صلة العبد بربه: أن تكون العبادة لله وحده، وأن يطلب العون منه مع الأخذ بالأسباب المشروعة.',
  ),
  _TafsirReading(
    title: 'الاستعانة بالصبر والصلاة',
    reference: 'سورة البقرة، الآية 153',
    verse: 'يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ إِنَّ اللَّهَ مَعَ الصَّابِرِينَ',
    meaning: 'ترشد الآية المؤمن إلى الثبات وعدم الاستسلام عند الشدائد، وإلى جعل الصلاة وسيلة للاستعانة بالله.',
  ),
  _TafsirReading(
    title: 'الطمأنينة بذكر الله',
    reference: 'سورة الرعد، الآية 28',
    verse: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
    meaning: 'ذكر الله حضورٌ للقلب بمعرفة الله والثقة به وطاعته، وليس مجرد ألفاظ تُقال من دون انتباه أو عمل.',
  ),
  _TafsirReading(
    title: 'طلب زيادة العلم',
    reference: 'سورة طه، الآية 114',
    verse: 'وَقُلْ رَبِّ زِدْنِي عِلْمًا',
    meaning: 'تعلّمنا الآية أن يظل الإنسان طالباً للعلم، وأن يستعين بالله على الفهم النافع والعمل بما يتعلّمه.',
  ),
  _TafsirReading(
    title: 'عدم القنوط من الرحمة',
    reference: 'سورة الزمر، الآية 53',
    verse: 'لَا تَقْنَطُوا مِنْ رَحْمَةِ اللَّهِ',
    meaning: 'تفتح الآية باب الرجوع إلى الله مهما كثرت أخطاء الإنسان، مع التوبة الصادقة وترك الذنب وردّ الحقوق إلى أصحابها.',
  ),
  _TafsirReading(
    title: 'يسرٌ مع العسر',
    reference: 'سورة الشرح، الآيتان 5–6',
    verse: 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا ۝ إِنَّ مَعَ الْعُسْرِ يُسْرًا',
    meaning: 'تدعو الآيتان إلى عدم اليأس عند الشدة، وإلى مواصلة العمل والصبر مع رجاء الفرج من الله.',
  ),
  _TafsirReading(
    title: 'التواضع وحسن الخطاب مع الوالدين',
    reference: 'سورة الإسراء، الآية 23',
    verse: 'وَقُلْ لَهُمَا قَوْلًا كَرِيمًا',
    meaning: 'لا يكفي ترك الإساءة، بل يدخل في البر اختيار الكلام الكريم وإظهار الرحمة والاحترام للوالدين.',
  ),
  _TafsirReading(
    title: 'التعاون على البر',
    reference: 'سورة المائدة، الآية 2',
    verse: 'وَتَعَاوَنُوا عَلَى الْبِرِّ وَالتَّقْوَى',
    meaning: 'توجّه الآية إلى التعاون فيما ينفع ويصلح، وتنهى عن جعل التعاون وسيلة إلى الظلم أو الإثم.',
  ),
  _TafsirReading(
    title: 'العدل والإحسان',
    reference: 'سورة النحل، الآية 90',
    verse: 'إِنَّ اللَّهَ يَأْمُرُ بِالْعَدْلِ وَالْإِحْسَانِ',
    meaning: 'العدل إعطاء الحقوق وعدم الجور، والإحسان بذل الخير وإتقانه. وتجمع الآية بين إقامة الحق وفعل الخير.',
  ),
  _TafsirReading(
    title: 'التثبت من الأخبار',
    reference: 'سورة الحجرات، الآية 6',
    verse: 'فَتَبَيَّنُوا',
    meaning: 'تؤكد الآية ضرورة التحقق قبل التصرف أو نقل الخبر، حتى لا يُظلم إنسان بسبب معلومة غير ثابتة.',
  ),
  _TafsirReading(
    title: 'المشاورة والتوكل',
    reference: 'سورة آل عمران، الآية 159',
    verse: 'وَشَاوِرْهُمْ فِي الْأَمْرِ فَإِذَا عَزَمْتَ فَتَوَكَّلْ عَلَى اللَّهِ',
    meaning: 'تشير الآية إلى قيمة المشاورة ثم اتخاذ القرار بعد النظر، مع التوكل على الله لا الاتكال وترك الأسباب.',
  ),
  _TafsirReading(
    title: 'التعارف وكرامة الإنسان',
    reference: 'سورة الحجرات، الآية 13',
    verse: 'إِنَّ أَكْرَمَكُمْ عِنْدَ اللَّهِ أَتْقَاكُمْ',
    meaning: 'تربط الآية الكرامة عند الله بالتقوى والعمل الصالح، لا بالنسب أو اللون أو الانتماء.',
  ),
];

class TafsirReaderPage extends StatefulWidget {
  const TafsirReaderPage({super.key});

  @override
  State<TafsirReaderPage> createState() => _TafsirReaderPageState();
}

class _TafsirReaderPageState extends State<TafsirReaderPage> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openFullTafsir() async {
    final uri = Uri.parse(_alMizanUrl);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح المصدر الكامل. تحقق من اتصال الإنترنت.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح المصدر الكامل.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim();
    final visible = _readings.where((item) =>
      query.isEmpty ||
      item.title.contains(query) ||
      item.reference.contains(query) ||
      item.verse.contains(query) ||
      item.meaning.contains(query)
    ).toList(growable: false);

    return Scaffold(
      backgroundColor: _tafsirInk,
      appBar: AppBar(title: const Text('التفسير والتدبر')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: _tafsirPanel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _tafsirGold.withValues(alpha: .32)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'قراءات قرآنية داخل التطبيق',
                  style: TextStyle(color: _tafsirGold, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text(
                  'تضم هذه الصفحة معاني إجمالية موجزة للتدبر، بصياغة مبسطة وليست نقلاً حرفياً عن تفسير الميزان أو بديلاً عن التفسير العلمي المعتمد. أُبقي رابط المصدر الكامل خياراً إضافياً.',
                  style: TextStyle(color: _tafsirMuted, height: 1.75),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'ابحث في الآيات والمعاني...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: _tafsirPanel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final item in visible)
            Card(
              color: _tafsirPanel,
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(color: _tafsirGold, fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text(item.reference, style: const TextStyle(color: _tafsirMuted, fontSize: 12)),
                    const SizedBox(height: 12),
                    SelectableText(
                      item.verse,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 21, height: 2),
                    ),
                    const Divider(color: Color(0x334A7562), height: 22),
                    const Text('المعنى الإجمالي', style: TextStyle(color: _tafsirGold, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(item.meaning, style: const TextStyle(color: _tafsirMuted, height: 1.8)),
                  ],
                ),
              ),
            ),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('ما لقينا نتيجة مطابقة لهذا البحث.')),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openFullTafsir,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('فتح تفسير الميزان الكامل'),
          ),
        ],
      ),
    );
  }
}
