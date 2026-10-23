import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/features/shia_text_library_page.dart';

ShiaTextEntry entry({
  required String slug,
  required String title,
  String alternateName = '',
  String type = 'dua',
}) => ShiaTextEntry(
  slug: slug,
  title: title,
  alternateName: alternateName,
  type: type,
  sourceUrl: 'https://example.org/source',
  lines: const <ShiaTextLine>[],
);

void main() {
  group('Five agreed Arabic supplication sections', () {
    test('Sahifa and munajat share one section', () {
      expect(entry(slug: 'sahifa-sajjadiya-01', title: 'دعاء التحميد').category,
          'الصحيفة السجادية والمناجيات');
      expect(entry(slug: 'munajat-al-tawibin', title: 'مناجاة التائبين').category,
          'الصحيفة السجادية والمناجيات');
    });

    test('daily prayers and taqibat have separate clear sections', () {
      expect(entry(slug: 'dua-morning', title: 'دعاء الصباح').category,
          'الأدعية والأذكار اليومية');
      expect(entry(slug: 'taqib-prayer', title: 'تعقيب الصلاة').category,
          'التعقيبات بعد الصلاة');
      expect(entry(slug: 'dua-friday', title: 'دعاء يوم الجمعة').category,
          'الأدعية والأذكار اليومية');
      expect(entry(slug: 'taqib-after-salaat-01', title: 'تعقيب بعد الصلاة').category,
          'التعقيبات بعد الصلاة');
    });

    test('general and Mahdi-related prayers share one section', () {
      expect(entry(slug: 'dua-kumayl', title: 'دعاء كميل').category,
          'الأدعية العامة وأدعية الفرج وصاحب الزمان');
      expect(entry(slug: 'dua-al-ahd', title: 'دعاء العهد').category,
          'الأدعية العامة وأدعية الفرج وصاحب الزمان');
    });

    test('occasions and ziyarat have their own sections', () {
      expect(entry(slug: 'dua-ramadan', title: 'دعاء رمضان').category,
          'الأعمال والمناسبات');
      expect(entry(slug: 'ziyarat-ashura', title: 'زيارة عاشوراء', type: 'ziyarat').category,
          'الزيارات الشريفة');
    });

    test('each entry maps to one section only', () {
      final samples = <ShiaTextEntry>[
        entry(slug: 'sahifa-sajjadiya-01', title: 'دعاء التحميد'),
        entry(slug: 'dua-morning', title: 'دعاء الصباح'),
        entry(slug: 'dua-kumayl', title: 'دعاء كميل'),
        entry(slug: 'dua-ramadan', title: 'دعاء رمضان'),
        entry(slug: 'ziyarat-ashura', title: 'زيارة عاشوراء', type: 'ziyarat'),
      ];
      expect(samples.map((item) => item.category).toSet().length, samples.length);
    });
  });
}
