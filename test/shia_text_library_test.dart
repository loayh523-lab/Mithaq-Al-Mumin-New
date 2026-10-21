import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/features/shia_text_library_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Arabic dua and ziyara library merges source-linked Mafatih records', () async {
    final data = await ShiaTextData.load();

    expect(data.entries, isNotEmpty);
    expect(data.entries.any((entry) => entry.category == 'الزيارات'), isTrue);
    expect(data.entries.any((entry) => entry.category == 'أدعية الصباح'), isTrue);
    expect(data.entries.any((entry) => entry.category == 'أدعية المساء'), isTrue);
    expect(data.entries.any((entry) => entry.category == 'الأذكار المشتركة'), isTrue);
    expect(data.entries.any((entry) => entry.category == 'تعقيبات الصلوات'), isTrue);
    expect(data.entries.any((entry) => entry.category == 'أدعية الأيام'), isTrue);
    expect(data.entries.any((entry) => entry.category == 'الأعمال اليومية والمناسبات'), isTrue);
    expect(data.entries.any((entry) => entry.category == 'الأعمال الشهرية والمناسبات'), isTrue);
    expect(data.entries.any((entry) => entry.category == 'أدعية صاحب الزمان'), isTrue);
    expect(data.entries.any((entry) => entry.isSahifa), isTrue);
    expect(data.entries.every((entry) => entry.arabicText.trim().isNotEmpty), isTrue);

    final mafatihEntries = data.entries
        .where((entry) => entry.sourceLabel.startsWith('مفاتيح الجنان،'))
        .toList(growable: false);
    expect(mafatihEntries, isNotEmpty);
    expect(mafatihEntries.any((entry) => entry.category == 'الزيارات'), isTrue);
    expect(mafatihEntries.any((entry) => entry.category == 'الأعمال الشهرية والمناسبات'), isTrue);
    expect(mafatihEntries.any((entry) => entry.category == 'تعقيبات الصلوات'), isTrue);

    final sunset = data.entries.singleWhere((entry) => entry.slug == 'mafatih-sunset-dua');
    expect(sunset.displayTitle, 'دعاء عند الغروب');
    expect(sunset.category, 'أدعية المساء');
    expect(sunset.sourceLabel, 'مفاتيح الجنان، الملحق الثاني، العمل عند الغروب');
    expect(sunset.sourceUrl, contains('page=757'));
    expect(sunset.arabicText, contains('يا من ختم النبوة بمحمد'));

    for (final entry in data.entries) {
      expect(entry.sourceUrl, isNotEmpty, reason: 'Missing source URL');
      if (entry.sourceLabel.startsWith('مفاتيح الجنان،')) {
        expect(entry.categoryOverride, isNotEmpty, reason: 'Missing Mafatih category override');
        expect(entry.sourceUrl, contains('lib.rafed.net'), reason: 'Mafatih citation must link to the Arabic edition');
      } else {
        expect(entry.sourceLabel, 'مكتبة ثقلين الإلكترونية', reason: 'Base source attribution mismatch');
      }
      expect(
        RegExp(r'[A-Za-zپچژگ]').hasMatch(entry.displayTitle),
        isFalse,
        reason: 'Entry title is not Arabic-only',
      );
      expect(
        containsPersianLanguageMarkers(entry.displayTitle),
        isFalse,
        reason: 'Persian-language title marker found',
      );
      expect(
        RegExp(r'[پچژگ]').hasMatch(entry.sourceLabel),
        isFalse,
        reason: 'Persian-script source label found',
      );
      for (final line in entry.lines.where((line) => line.isArabic)) {
        expect(
          RegExp(r'[پچژگ]').hasMatch(line.text),
          isFalse,
          reason: 'Persian-script character found in Arabic content',
        );
        expect(
          containsPersianLanguageMarkers(line.text),
          isFalse,
          reason: 'Persian-language marker found in Arabic content',
        );
      }
    }
  });

  test('Sahifa texts remain in the full collection and appear in relevant topical sections', () {
    const friday = ShiaTextEntry(
      slug: 'sahifa-sajjadiya-the-supplication-for-friday',
      title: 'دعاء يوم الجمعة',
      alternateName: 'دعاء يوم الجمعة',
      type: 'dua',
      sourceUrl: 'https://thaqalayn.net/duas/sahifa-sajjadiya-the-supplication-for-friday',
      sourceLabel: 'مكتبة ثقلين الإلكترونية',
      lines: <ShiaTextLine>[
        ShiaTextLine(index: 1, kind: 'arabic', text: 'اللهم صل على محمد وآل محمد'),
      ],
    );
    const ramadan = ShiaTextEntry(
      slug: 'sahifa-sajjadiya-for-the-coming-of-the-month-of-ramadan',
      title: 'دعاؤه لدخول شهر رمضان',
      alternateName: 'دعاؤه لدخول شهر رمضان',
      type: 'dua',
      sourceUrl: 'https://thaqalayn.net/duas/sahifa-sajjadiya-for-the-coming-of-the-month-of-ramadan',
      sourceLabel: 'مكتبة ثقلين الإلكترونية',
      lines: <ShiaTextLine>[
        ShiaTextLine(index: 1, kind: 'arabic', text: 'اللهم صل على محمد وآل محمد'),
      ],
    );
    const hajat = ShiaTextEntry(
      slug: 'sahifa-sajjadiya-his-supplication-in-seeking-needs-from-god',
      title: 'دعاؤه في طلب الحوائج إلى الله',
      alternateName: 'دعاؤه في طلب الحوائج إلى الله',
      type: 'dua',
      sourceUrl: 'https://thaqalayn.net/duas/sahifa-sajjadiya-his-supplication-in-seeking-needs-from-god',
      sourceLabel: 'مكتبة ثقلين الإلكترونية',
      lines: <ShiaTextLine>[
        ShiaTextLine(index: 1, kind: 'arabic', text: 'اللهم صل على محمد وآل محمد'),
      ],
    );

    expect(friday.categories, contains('الصحيفة السجادية'));
    expect(friday.categories, contains('أدعية الأيام'));
    expect(ramadan.categories, contains('الصحيفة السجادية'));
    expect(ramadan.categories, contains('الأعمال الشهرية والمناسبات'));
    expect(hajat.categories, contains('الصحيفة السجادية'));
    expect(hajat.categories, contains('أدعية الحاجات والشفاء'));
  });

  test('morning-only, shared, and sunset-only invocations stay distinct', () {
    const morning = ShiaTextEntry(
      slug: 'dua-sabah',
      title: 'دعاء الصباح',
      alternateName: 'دعاء الصباح',
      type: 'dua',
      sourceUrl: '',
      lines: <ShiaTextLine>[
        ShiaTextLine(index: 1, kind: 'arabic', text: 'بسم الله الرحمن الرحيم'),
      ],
    );
    const combined = ShiaTextEntry(
      slug: 'sahifa-sajjadiya-his-supplication-in-the-morning-and-evening',
      title: 'دعاؤه عند الصباح والمساء',
      alternateName: 'دعاؤه عند الصباح والمساء',
      type: 'dua',
      sourceUrl: '',
      lines: <ShiaTextLine>[
        ShiaTextLine(index: 1, kind: 'arabic', text: 'بسم الله الرحمن الرحيم'),
      ],
    );
    const sunset = ShiaTextEntry(
      slug: 'mafatih-sunset-dua',
      title: 'دعاء عند الغروب',
      alternateName: 'دعاء عند الغروب',
      type: 'dua',
      sourceUrl: 'https://lib.rafed.net/view.php?b_id=1731&page=757&type=c_fbook',
      sourceLabel: 'مفاتيح الجنان، الملحق الثاني، العمل عند الغروب',
      categoryOverride: 'أدعية المساء',
      lines: <ShiaTextLine>[
        ShiaTextLine(index: 1, kind: 'arabic', text: 'يا من ختم النبوة بمحمد صلى الله عليه وآله اختم لي في يومي هذا بخير وشهري بخير وسنتي بخير وعمري بخير'),
      ],
    );

    expect(morning.category, 'أدعية الصباح');
    expect(combined.category, 'الأذكار المشتركة');
    expect(combined.category, isNot('أدعية الصباح'));
    expect(combined.category, isNot('أدعية المساء'));
    expect(sunset.category, 'أدعية المساء');
    expect(sunset.category, isNot('أدعية الصباح'));
  });
}
