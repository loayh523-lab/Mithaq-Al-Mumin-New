import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/features/smart_search_page.dart'
    show normalizeSmartSearchText, stripSmartSearchMarkup;

void main() {
  group('Arabic offline-search normalization', () {
    test('removes diacritics and normalizes Arabic alif variants', () {
      expect(normalizeSmartSearchText('إِسْلَامٌ'), 'اسلام');
      expect(normalizeSmartSearchText('ٱلْحَمْدُ لِلَّهِ'), 'الحمد لله');
      expect(normalizeSmartSearchText('على هدى'), 'علي هدي');
    });

    test('removes tatweel and collapses repeated whitespace', () {
      expect(
        normalizeSmartSearchText('  الرَّحْمَــــنُ   الرَّحِيمُ  '),
        'الرحمن الرحيم',
      );
    });

    test('converts imported markup and common entities to readable text', () {
      expect(
        stripSmartSearchMarkup(
          '<p>زيارة</p><br />السلام&nbsp;عليكم &amp; أهل البيت',
        ),
        'زيارة\nالسلام عليكم & أهل البيت',
      );
      expect(
        stripSmartSearchMarkup('<div>الدعاء</div><li>الفرج</li>'),
        'الدعاء\nالفرج',
      );
    });

    test('preserves plain Arabic content without markup', () {
      expect(
        stripSmartSearchMarkup('السلام عليكم يا أهل بيت النبوة'),
        'السلام عليكم يا أهل بيت النبوة',
      );
    });
  });
}
