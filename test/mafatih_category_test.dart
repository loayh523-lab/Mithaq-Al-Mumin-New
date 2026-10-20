import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/features/mafatih_library_page.dart';

void main() {
  group('Arabic Mafatih categories', () {
    test('morning and evening supplications are separate', () {
      expect(mafatihCategoryFor('دعاء الصباح لأمير المؤمنين'), 'أدعية الصباح');
      expect(mafatihCategoryFor('دعاء المساء'), 'أدعية المساء');
    });

    test('texts explicitly prescribed for both periods have their own category', () {
      expect(mafatihCategoryFor('أذكار ودعوات تقرأ صباحاً ومساءً'), 'أذكار مشتركة');
    });

    test('visits and daily/monthly deeds are not buried among general supplications', () {
      expect(mafatihCategoryFor('زيارة عاشوراء'), 'الزيارات');
      expect(mafatihCategoryFor('أعمال ليلة الجمعة'), 'الأعمال اليومية والمناسبات');
      expect(mafatihCategoryFor('أعمال أشهر السنة الهجرية'), 'الأعمال الشهرية والمناسبات');
      expect(mafatihCategoryFor('دعاء كميل'), 'أدعية عامة');
    });
  });
}
