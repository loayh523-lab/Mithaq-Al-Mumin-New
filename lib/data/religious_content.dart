/// Small starter content collection for Mithaq Al-Mumin.
/// Keep quotations short and add a precise source before expanding this file.
class ReligiousText {
  const ReligiousText({
    required this.title,
    required this.text,
    required this.source,
    this.note,
  });

  final String title;
  final String text;
  final String source;
  final String? note;
}

const dailyDhikr = <ReligiousText>[
  ReligiousText(
    title: 'الاستغفار',
    text: 'أستغفر الله ربي وأتوب إليه',
    source: 'صيغة استغفار عامة',
    note: 'صيغة ذكر عامة وليست منسوبة هنا إلى رواية محددة.',
  ),
  ReligiousText(
    title: 'الصلاة على محمد وآل محمد',
    text: 'اللهم صل على محمد وآل محمد',
    source: 'الصلاة على النبي وآله',
    note: 'ذكر عام؛ ستضاف الإحالات التفصيلية عند توثيق مكتبة الروايات.',
  ),
  ReligiousText(
    title: 'التسبيح',
    text: 'سبحان الله والحمد لله ولا إله إلا الله والله أكبر',
    source: 'ذكر عام',
    note: 'صيغة ذكر عامة وليست منسوبة هنا إلى رواية محددة.',
  ),
  ReligiousText(
    title: 'الحوقلة',
    text: 'لا حول ولا قوة إلا بالله العلي العظيم',
    source: 'صيغة ذكر عامة',
    note: 'ذكر عام؛ لا ينسبه التطبيق هنا إلى رواية محددة.',
  ),
  ReligiousText(
    title: 'التهليل',
    text: 'لا إله إلا الله',
    source: 'ذكر عام',
    note: 'ذكر عام، ويمكن تكراره دون تحديد عدد من غير مستند موثق.',
  ),
  ReligiousText(
    title: 'دعاء نبي الله يونس عليه السلام',
    text: 'لا إله إلا أنت سبحانك إني كنت من الظالمين',
    source: 'القرآن الكريم، سورة الأنبياء، الآية 87',
  ),
  ReligiousText(
    title: 'طلب العلم',
    text: 'رب زدني علما',
    source: 'القرآن الكريم، سورة طه، الآية 114',
  ),
  ReligiousText(
    title: 'شرح الصدر وتيسير الأمر',
    text: 'رب اشرح لي صدري ويسر لي أمري',
    source: 'القرآن الكريم، سورة طه، الآيتان 25–26',
  ),
  ReligiousText(
    title: 'التوكل على الله',
    text: 'حسبنا الله ونعم الوكيل',
    source: 'القرآن الكريم، سورة آل عمران، الآية 173',
  ),
  ReligiousText(
    title: 'خير الدنيا والآخرة',
    text: 'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار',
    source: 'القرآن الكريم، سورة البقرة، الآية 201',
  ),
  ReligiousText(
    title: 'دعاء التوبة',
    text: 'ربنا ظلمنا أنفسنا وإن لم تغفر لنا وترحمنا لنكونن من الخاسرين',
    source: 'القرآن الكريم، سورة الأعراف، الآية 23',
  ),
  ReligiousText(
    title: 'الاستعانة بالله',
    text: 'إياك نعبد وإياك نستعين',
    source: 'القرآن الكريم، سورة الفاتحة، الآية 5',
  ),
];

const dailyReflection = ReligiousText(
  title: 'ورد اليوم',
  text: 'اجعل للذكر وقتاً ثابتاً، ولو كان قليلاً، وحافظ عليه بهدوء.',
  source: 'تذكير تحفيزي من إعداد التطبيق',
  note: 'هذه عبارة تذكيرية وليست حديثاً أو آية.',
);
