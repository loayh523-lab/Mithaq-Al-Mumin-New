import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/data/religious_content.dart';

void main() {
  group('Daily devotional content', () {
    test('includes the core items requested for Ward Al-Yawm', () {
      final titles = dailyDhikr.map((item) => item.title).toSet();

      expect(titles, contains('الاستغفار'));
      expect(titles, contains('الحوقلة'));
      expect(titles, contains('الصلاة الإبراهيمية'));
      expect(titles, contains('دعاء نبي الله يونس عليه السلام'));
    });

    test('daily items have unique titles and non-empty text/source', () {
      final titles = dailyDhikr.map((item) => item.title).toList();

      expect(titles.toSet().length, titles.length);
      for (final item in dailyDhikr) {
        expect(item.title.trim(), isNotEmpty);
        expect(item.text.trim(), isNotEmpty, reason: item.title);
        expect(item.source.trim(), isNotEmpty, reason: item.title);
      }
    });

    test('the collection contains no obvious Persian-only script markers', () {
      final persianOnlyLetters = RegExp(r'[پچژگ]');
      for (final item in dailyDhikr) {
        expect(persianOnlyLetters.hasMatch(item.title), isFalse,
            reason: item.title);
        expect(persianOnlyLetters.hasMatch(item.text), isFalse,
            reason: item.title);
        expect(persianOnlyLetters.hasMatch(item.source), isFalse,
            reason: item.title);
      }
    });
  });
}
