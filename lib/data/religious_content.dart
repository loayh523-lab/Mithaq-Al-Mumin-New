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
  ),
];

const dailyReflection = ReligiousText(
  title: 'ورد اليوم',
  text: 'اجعل للذكر وقتاً ثابتاً، ولو كان قليلاً، وحافظ عليه بهدوء.',
  source: 'تذكير تحفيزي من إعداد التطبيق',
  note: 'هذه عبارة تذكيرية وليست حديثاً أو آية.',
);
