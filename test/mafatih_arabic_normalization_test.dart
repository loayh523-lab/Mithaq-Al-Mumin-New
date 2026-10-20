import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/data/mafatih_data.dart';

void main() {
  group('Arabic-only Mafatih normalization', () {
    test('normalizes Persian-form kaf and yeh in Arabic titles', () {
      expect(normalizeMafatihArabicText('کسی'), 'كسي');
      expect(
        normalizeMafatihArabicText('دعايی برای رزق'),
        'دعايي براي رزق',
      );
    });

    test('does not mistake Arabic kaf and yeh variants for Persian text', () {
      expect(containsPersianOnlyLetters('باب الصلاة والذكر'), isFalse);
      expect(containsPersianOnlyLetters('الدعاء'), isFalse);
    });


    test('rejects transliteration and English text from the Arabic-only reader', () {
      expect(isArabicMafatihRecitation('اللهم صل على محمد وآل محمد'), isTrue);
      expect(isArabicMafatihRecitation('Allahumma salli ala Muhammad'), isFalse);
      expect(isArabicMafatihRecitation('English translation'), isFalse);
      expect(isArabicMafatihRecitation('دعاء به واژه'), isFalse);
    });

    test('detects common Persian words even when the letters are shared with Arabic', () {
      expect(containsPersianLanguageMarkers('دعای روزهای هفته'), isTrue);
      expect(containsPersianLanguageMarkers('دعاء الصباح'), isFalse);
      expect(isArabicMafatihRecitation('دعای روزهای هفته'), isFalse);
    });

    test('detects distinctively Persian letters so Persian translations are omitted', () {
      expect(containsPersianOnlyLetters('گل و چهره'), isTrue);
    });
  });
}
