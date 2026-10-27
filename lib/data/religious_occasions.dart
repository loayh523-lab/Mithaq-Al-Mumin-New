/// Local data for Shi'a religious occasions shown by the approximate tabular Hijri calendar.
///
/// Dates are calendar conventions, not proof of local moon sighting. Entries with
/// variant narrations state that qualification explicitly; verify primary sources
/// before attaching specific devotional acts or treating a date as definitive.
enum ReligiousOccasionKind { historical, birth, martyrdom, eid, ziyara, devotional }

class ReligiousOccasion {
  const ReligiousOccasion({
    required this.hijriDay,
    required this.hijriMonth,
    required this.title,
    required this.kind,
    this.qualification,
    this.sourceLabel,
    this.sourceUrl,
  });

  final int hijriDay;
  final int hijriMonth;
  final String title;
  final ReligiousOccasionKind kind;
  final String? qualification;
  final String? sourceLabel;
  final String? sourceUrl;

  String get displayTitle =>
      qualification == null ? title : '$title — $qualification';

  String get kindLabel => switch (kind) {
        ReligiousOccasionKind.historical => 'حدث تاريخي',
        ReligiousOccasionKind.birth => 'ولادة',
        ReligiousOccasionKind.martyrdom => 'شهادة أو وفاة',
        ReligiousOccasionKind.eid => 'عيد',
        ReligiousOccasionKind.ziyara => 'زيارة',
        ReligiousOccasionKind.devotional => 'مناسبة وأعمال',
      };
}

/// Maintained separately from widgets so dates can be searched, audited and tested.
const List<ReligiousOccasion> shiaReligiousOccasions = [
  ReligiousOccasion(hijriDay: 1, hijriMonth: 1, title: 'بداية السنة الهجرية', kind: ReligiousOccasionKind.historical),
  ReligiousOccasion(hijriDay: 2, hijriMonth: 1, title: 'ذكرى ورود الإمام الحسين عليه السلام أرض كربلاء', kind: ReligiousOccasionKind.historical, qualification: 'في بعض التقاويم'),
  ReligiousOccasion(hijriDay: 7, hijriMonth: 1, title: 'ذكرى منع الماء عن الإمام الحسين عليه السلام وأهل بيته وأصحابه', kind: ReligiousOccasionKind.historical, qualification: 'مشهور في المجالس'),
  ReligiousOccasion(hijriDay: 9, hijriMonth: 1, title: 'تاسوعاء — من أيام الحزن على الإمام الحسين عليه السلام', kind: ReligiousOccasionKind.historical),
  ReligiousOccasion(hijriDay: 10, hijriMonth: 1, title: 'يوم عاشوراء — ذكرى استشهاد الإمام الحسين عليه السلام وأهل بيته وأصحابه', kind: ReligiousOccasionKind.martyrdom),
  ReligiousOccasion(hijriDay: 13, hijriMonth: 5, title: 'شهادة السيدة فاطمة الزهراء عليها السلام', kind: ReligiousOccasionKind.martyrdom, qualification: 'الرواية الأولى: خمسة وسبعون يوماً بعد وفاة النبي صلى الله عليه وآله', sourceLabel: 'Al-Islam.org — After Her Death', sourceUrl: 'https://al-islam.org/fatimah-al-zahra-cradle-grave-sayyid-muhammad-kadhim-al-qazwini/chapter-20-after-her-death'),
  ReligiousOccasion(hijriDay: 3, hijriMonth: 6, title: 'شهادة السيدة فاطمة الزهراء عليها السلام', kind: ReligiousOccasionKind.martyrdom, qualification: 'الرواية الثانية: خمسة وتسعون يوماً بعد وفاة النبي صلى الله عليه وآله', sourceLabel: 'Al-Islam.org — After Her Death', sourceUrl: 'https://al-islam.org/fatimah-al-zahra-cradle-grave-sayyid-muhammad-kadhim-al-qazwini/chapter-20-after-her-death'),
  ReligiousOccasion(hijriDay: 20, hijriMonth: 2, title: 'زيارة الأربعين للإمام الحسين عليه السلام', kind: ReligiousOccasionKind.ziyara),
  ReligiousOccasion(hijriDay: 25, hijriMonth: 1, title: 'ذكرى استشهاد الإمام زين العابدين عليه السلام', kind: ReligiousOccasionKind.martyrdom, qualification: 'على رواية مشهورة'),
  ReligiousOccasion(hijriDay: 7, hijriMonth: 2, title: 'ذكرى استشهاد الإمام الحسن المجتبى عليه السلام', kind: ReligiousOccasionKind.martyrdom, qualification: 'على رواية مشهورة'),
  ReligiousOccasion(hijriDay: 29, hijriMonth: 2, title: 'ذكرى استشهاد الإمام علي بن موسى الرضا عليه السلام', kind: ReligiousOccasionKind.martyrdom, qualification: 'على رواية'),
  ReligiousOccasion(hijriDay: 8, hijriMonth: 3, title: 'ذكرى استشهاد الإمام الحسن العسكري عليه السلام', kind: ReligiousOccasionKind.martyrdom),
  ReligiousOccasion(hijriDay: 9, hijriMonth: 3, title: 'بداية إمامة الإمام المهدي عجل الله فرجه', kind: ReligiousOccasionKind.historical, qualification: 'في التقويم المشهور'),
  ReligiousOccasion(hijriDay: 17, hijriMonth: 3, title: 'ذكرى مولد النبي محمد صلى الله عليه وآله والإمام جعفر الصادق عليه السلام', kind: ReligiousOccasionKind.birth, qualification: 'المشهور'),
  ReligiousOccasion(hijriDay: 10, hijriMonth: 4, title: 'ذكرى وفاة السيدة فاطمة المعصومة عليها السلام', kind: ReligiousOccasionKind.martyrdom, qualification: 'على رواية'),
  ReligiousOccasion(hijriDay: 5, hijriMonth: 5, title: 'ذكرى ولادة السيدة زينب عليها السلام', kind: ReligiousOccasionKind.birth, qualification: 'المشهور'),
  ReligiousOccasion(hijriDay: 13, hijriMonth: 6, title: 'ذكرى وفاة أم البنين عليها السلام', kind: ReligiousOccasionKind.martyrdom, qualification: 'مشهورة في بعض التقويمات'),
  ReligiousOccasion(hijriDay: 3, hijriMonth: 7, title: 'ذكرى استشهاد الإمام علي الهادي عليه السلام', kind: ReligiousOccasionKind.martyrdom),
  ReligiousOccasion(hijriDay: 13, hijriMonth: 7, title: 'ذكرى ولادة أمير المؤمنين الإمام علي عليه السلام', kind: ReligiousOccasionKind.birth),
  ReligiousOccasion(hijriDay: 25, hijriMonth: 7, title: 'ذكرى استشهاد الإمام موسى الكاظم عليه السلام', kind: ReligiousOccasionKind.martyrdom, qualification: 'على رواية مشهورة'),
  ReligiousOccasion(hijriDay: 27, hijriMonth: 7, title: 'عيد المبعث النبوي الشريف', kind: ReligiousOccasionKind.eid),
  ReligiousOccasion(hijriDay: 3, hijriMonth: 8, title: 'ذكرى ولادة الإمام الحسين عليه السلام', kind: ReligiousOccasionKind.birth),
  ReligiousOccasion(hijriDay: 4, hijriMonth: 8, title: 'ذكرى ولادة أبي الفضل العباس عليه السلام', kind: ReligiousOccasionKind.birth, qualification: 'المشهور'),
  ReligiousOccasion(hijriDay: 5, hijriMonth: 8, title: 'ذكرى ولادة الإمام زين العابدين عليه السلام', kind: ReligiousOccasionKind.birth),
  ReligiousOccasion(hijriDay: 15, hijriMonth: 8, title: 'ذكرى ولادة الإمام المهدي عجل الله فرجه', kind: ReligiousOccasionKind.birth),
  ReligiousOccasion(hijriDay: 10, hijriMonth: 9, title: 'ذكرى وفاة السيدة خديجة عليها السلام', kind: ReligiousOccasionKind.martyrdom, qualification: 'على رواية'),
  ReligiousOccasion(hijriDay: 15, hijriMonth: 9, title: 'ذكرى ولادة الإمام الحسن المجتبى عليه السلام', kind: ReligiousOccasionKind.birth),
  ReligiousOccasion(hijriDay: 19, hijriMonth: 9, title: 'ليلة جرح أمير المؤمنين الإمام علي عليه السلام — من ليالي القدر', kind: ReligiousOccasionKind.historical),
  ReligiousOccasion(hijriDay: 21, hijriMonth: 9, title: 'ذكرى استشهاد أمير المؤمنين الإمام علي عليه السلام — من ليالي القدر', kind: ReligiousOccasionKind.martyrdom),
  ReligiousOccasion(hijriDay: 23, hijriMonth: 9, title: 'ليلة القدر المباركة بحسب رواية مشهورة', kind: ReligiousOccasionKind.devotional),
  ReligiousOccasion(hijriDay: 1, hijriMonth: 10, title: 'عيد الفطر المبارك', kind: ReligiousOccasionKind.eid),
  ReligiousOccasion(hijriDay: 25, hijriMonth: 10, title: 'ذكرى استشهاد الإمام جعفر الصادق عليه السلام', kind: ReligiousOccasionKind.martyrdom, qualification: 'المشهور عند كثير من الشيعة'),
  ReligiousOccasion(hijriDay: 1, hijriMonth: 11, title: 'ذكرى ولادة السيدة فاطمة المعصومة عليها السلام', kind: ReligiousOccasionKind.birth),
  ReligiousOccasion(hijriDay: 11, hijriMonth: 11, title: 'ذكرى ولادة الإمام علي بن موسى الرضا عليه السلام', kind: ReligiousOccasionKind.birth),
  ReligiousOccasion(hijriDay: 25, hijriMonth: 11, title: 'يوم دحو الأرض', kind: ReligiousOccasionKind.devotional, qualification: 'من الأعمال المذكورة في كتب الأدعية'),
  ReligiousOccasion(hijriDay: 1, hijriMonth: 12, title: 'ذكرى زواج أمير المؤمنين الإمام علي والسيدة فاطمة الزهراء عليهما السلام', kind: ReligiousOccasionKind.historical, qualification: 'المشهور'),
  ReligiousOccasion(hijriDay: 7, hijriMonth: 12, title: 'ذكرى استشهاد الإمام محمد الباقر عليه السلام', kind: ReligiousOccasionKind.martyrdom, qualification: 'على رواية مشهورة'),
  ReligiousOccasion(hijriDay: 9, hijriMonth: 12, title: 'يوم عرفة، وذكرى شهادة مسلم بن عقيل عليه السلام', kind: ReligiousOccasionKind.devotional, qualification: 'في التقويم المشهور'),
  ReligiousOccasion(hijriDay: 10, hijriMonth: 12, title: 'عيد الأضحى المبارك', kind: ReligiousOccasionKind.eid),
  ReligiousOccasion(hijriDay: 15, hijriMonth: 12, title: 'ذكرى ولادة الإمام علي الهادي عليه السلام', kind: ReligiousOccasionKind.birth),
  ReligiousOccasion(hijriDay: 18, hijriMonth: 12, title: 'عيد الغدير الأغر', kind: ReligiousOccasionKind.eid),
  ReligiousOccasion(hijriDay: 24, hijriMonth: 12, title: 'يوم المباهلة', kind: ReligiousOccasionKind.historical),
  ReligiousOccasion(hijriDay: 25, hijriMonth: 12, title: 'نزول سورة هل أتى في شأن أهل البيت عليهم السلام', kind: ReligiousOccasionKind.historical, qualification: 'يُذكر في بعض كتب المناسبات'),
];

List<ReligiousOccasion> religiousOccasionsForHijriDate(int day, int month) =>
    List<ReligiousOccasion>.unmodifiable(
      shiaReligiousOccasions.where(
        (occasion) =>
            occasion.hijriDay == day && occasion.hijriMonth == month,
      ),
    );

List<ReligiousOccasion> religiousOccasionsForHijriMonth(int month) =>
    List<ReligiousOccasion>.unmodifiable(
      shiaReligiousOccasions.where((occasion) => occasion.hijriMonth == month),
    );
