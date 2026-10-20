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
  })
  test('generated Arabic library has non-empty morning, evening, ziyara and deeds lists', () async {
    final data = await MafatihData.load();
    final counts = <String, int>{};

    for (final chapter in data.chapters) {
      for (final section in chapter.sections) {
        for (final article in section.articles) {
          final contentHead = article.items
              .map((item) => plainMafatihText(item.content))
              .where((value) => value.isNotEmpty)
              .take(3)
              .join(' ');
          final searchable = '${chapter.title} ${section.title} ${article.title} $contentHead';
          final category = mafatihCategoryFor(searchable);
          counts[category] = (counts[category] ?? 0) + 1;

          expect(article.title, isNot(contains(RegExp(r'[A-Za-zپچژگ]'))));
          expect(section.title, isNot(contains(RegExp(r'[A-Za-zپچژگ]'))));
          expect(chapter.title, isNot(contains(RegExp(r'[A-Za-zپچژگ]'))));
          expect(article.items, isNotEmpty);
        }
      }
    }

    expect(counts['أدعية الصباح'] ?? 0, greaterThan(0));
    expect(counts['أدعية المساء'] ?? 0, greaterThan(0));
    expect(counts['الزيارات'] ?? 0, greaterThan(0));
    expect(counts['الأعمال اليومية والمناسبات'] ?? 0, greaterThan(0));
  });
;
}
