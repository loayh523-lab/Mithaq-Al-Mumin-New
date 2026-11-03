import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/features/shia_text_library_page.dart';

ShiaTextEntry entry({
  required String slug,
  required String title,
  String alternateName = '',
  String type = 'dua',
  String? categoryOverride,
}) => ShiaTextEntry(
  slug: slug,
  title: title,
  alternateName: alternateName,
  type: type,
  sourceUrl: 'https://example.org/source',
  categoryOverride: categoryOverride,
  lines: const <ShiaTextLine>[],
);

void main() {
  group('Six public Arabic library sections', () {
    test('Sahifa and Munajat slugs map to the selection section', () {
      const category = 'الصحيفة السجادية المباركة (نفحات مختارة)';
      expect(entry(slug: 'sahifa-sajjadiya-01', title: 'دعاء التحميد').category, category);
      expect(entry(slug: 'munajat-sahifa-01', title: 'مناجاة التائبين').category, category);
      expect(entry(slug: 'munajat-15', title: 'مناجاة').category, category);
    });
    test('daily source categories merge into one section', () {
      const category = 'الورد اليومي والتعقيبات';
      expect(entry(slug: 'daily-dua-sabah', title: 'دعاء الصباح', categoryOverride: 'الأدعية والأذكار اليومية').category, category);
      expect(entry(slug: 'taqib-after-salaat-01', title: 'تعقيب الصلاة', categoryOverride: 'التعقيبات بعد الصلاة').category, category);
    });
    test('general source category maps to the general or hajat section', () {
      expect(entry(slug: 'general-dua-kumayl', title: 'دعاء كميل', categoryOverride: 'الأدعية العامة وأدعية الفرج وصاحب الزمان').category,
          'الأدعية الكبرى والمناجاة الشريفة');
      expect(entry(slug: 'general-hajat-rizq', title: 'دعاء سعة الرزق', categoryOverride: 'الأدعية العامة وأدعية الفرج وصاحب الزمان').category,
          'أدعية الحوائج، التحصينات والرزق');
    });
    test('occasion and ziyarat source categories map explicitly', () {
      expect(entry(slug: 'occasion-ramadan', title: 'دعاء رمضان', categoryOverride: 'الأعمال والمناسبات').category,
          'أدعية المناسبات والشهور العبادية');
      expect(entry(slug: 'ziyarat-ashura', title: 'زيارة عاشوراء', type: 'ziyarat', categoryOverride: 'الزيارات الشريفة').category,
          'الزيارات الشريفة والمقامات المقدسة');
    });
  });
}
