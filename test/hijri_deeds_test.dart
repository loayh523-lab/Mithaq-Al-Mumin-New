import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/features/good_deeds_page.dart'
    show seasonalDeedIdsForHijriDate;
import 'package:mithaq_al_mumin/features/prayer_calendar_page.dart'
    show hijriDateParts;

void main() {
  test('Hijri date helper preserves the app calendar correction', () {
    final base = hijriDateParts(DateTime(2026, 10, 20));
    expect(base.day, 8);
    expect(base.month, 5);
    expect(base.year, 1448);

    final corrected = hijriDateParts(
      DateTime(2026, 10, 20),
      correction: 1,
    );
    expect(corrected.day, 9);
    expect(corrected.month, 5);
    expect(corrected.year, 1448);
  });

  test('seasonal deeds appear throughout Rajab, Shaaban and Ramadan', () {
    expect(
      seasonalDeedIdsForHijriDate(month: 7, day: 12),
      contains('rajab-acts'),
    );
    expect(
      seasonalDeedIdsForHijriDate(month: 8, day: 1),
      contains('shaban-acts'),
    );
    expect(
      seasonalDeedIdsForHijriDate(month: 9, day: 27),
      contains('ramadan-acts'),
    );
  });

  test('special Shia occasions are shown only on their tabular dates', () {
    expect(
      seasonalDeedIdsForHijriDate(month: 1, day: 10),
      contains('ashura-acts'),
    );
    expect(
      seasonalDeedIdsForHijriDate(month: 2, day: 20),
      contains('arbaeen-ziyara'),
    );
    expect(
      seasonalDeedIdsForHijriDate(month: 10, day: 1),
      contains('eid-fitr-acts'),
    );
    expect(
      seasonalDeedIdsForHijriDate(month: 12, day: 9),
      contains('arafah-acts'),
    );
    expect(
      seasonalDeedIdsForHijriDate(month: 12, day: 10),
      contains('eid-adha-acts'),
    );
    expect(
      seasonalDeedIdsForHijriDate(month: 12, day: 18),
      contains('ghadir-acts'),
    );
    expect(
      seasonalDeedIdsForHijriDate(month: 1, day: 9),
      isNot(contains('ashura-acts')),
    );
    expect(
      seasonalDeedIdsForHijriDate(month: 5, day: 8),
      isEmpty,
    );
  });
}
