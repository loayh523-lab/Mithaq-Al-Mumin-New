import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mithaq_al_mumin/features/settings_page.dart';
import 'package:mithaq_al_mumin/services/prayer_locations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Iraq administrative data contains the full attributed hierarchy', () async {
    final divisions = await PrayerLocations.administrativeDivisions();
    final raw = await rootBundle.loadString(PrayerLocations.administrativeAsset);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final metadata = decoded['metadata'] as Map<String, dynamic>;

    expect(PrayerLocations.governoratesFrom(divisions), hasLength(18));
    expect(
      divisions.where((item) => item.level == 2),
      hasLength(101),
    );
    expect(
      divisions.where((item) => item.level == 3),
      hasLength(294),
    );
    expect(divisions.map((item) => item.id).toSet(), hasLength(413));
    expect(metadata['license'], 'CC-BY-4.0');
    expect(metadata['sourceCommit'], '098a1a49a16d5ab47fe63333ca9fa49970dc6e92');
    expect(metadata['attribution'], contains('Open Admin Data'));

    for (final division in divisions) {
      expect(division.name.trim(), isNotEmpty);
      expect(division.latitude, inInclusiveRange(29, 38));
      expect(division.longitude, inInclusiveRange(38, 49));
      expect(division.governorateName.trim(), isNotEmpty);
      if (division.level > 1) {
        expect(
          PrayerLocations.divisionById(divisions, division.parentId),
          isNotNull,
          reason: 'Missing parent for ${division.id} (${division.name})',
        );
      }
    }
  });

  test('governorate, district and subdistrict filters retain parent relationships', () async {
    final divisions = await PrayerLocations.administrativeDivisions();
    final dhiQar = PrayerLocations.divisionById(divisions, 'IQG17');
    expect(dhiQar, isNotNull);
    expect(dhiQar!.name, 'ذي قار');

    final districts = PrayerLocations.districtsFrom(divisions, dhiQar.id);
    expect(districts, hasLength(5));
    expect(districts.every((item) => item.governorateId == dhiQar.id), isTrue);

    const rifaiId = 'IQG17Q02';
    final rifai = PrayerLocations.divisionById(divisions, rifaiId);
    expect(rifai?.name, 'الرفاعي');
    final subdistricts = PrayerLocations.subdistrictsFrom(divisions, rifaiId);
    expect(subdistricts, hasLength(4));

    final qalatSukar = subdistricts.singleWhere((item) => item.name == 'قلعة السكر');
    expect(qalatSukar.id, 'IQG17Q02N04');
    expect(qalatSukar.governorateName, 'ذي قار');
    expect(qalatSukar.districtName, 'الرفاعي');
    expect(qalatSukar.latitude, 31.836);
    expect(qalatSukar.longitude, 46.073);
  });

  test('a selected administrative place is restored for prayer calculations', () async {
    final divisions = await PrayerLocations.administrativeDivisions();
    final qalatSukar = PrayerLocations.divisionById(divisions, 'IQG17Q02N04');
    expect(qalatSukar, isNotNull);

    await PrayerLocations.savePlace(qalatSukar!);
    final restored = await PrayerLocations.load();

    expect(restored.id, qalatSukar.id);
    expect(restored.latitude, qalatSukar.latitude);
    expect(restored.longitude, qalatSukar.longitude);
    expect(restored.administrativeLabel, contains('قلعة السكر'));
    expect(restored.administrativeLabel, contains('الرفاعي'));
    expect(restored.administrativeLabel, contains('ذي قار'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('prayer_place_id'), qalatSukar.id);
    expect(prefs.getString('prayer_city'), isNull);
  });

  test('GPS coordinates take precedence over a previously saved administrative place', () async {
    final divisions = await PrayerLocations.administrativeDivisions();
    final place = PrayerLocations.divisionById(divisions, 'IQG17Q02N04')!;
    await PrayerLocations.savePlace(place);
    await PrayerLocations.saveCurrentLocation(
      latitude: 34.2,
      longitude: 44.1,
      accuracyMeters: 18,
    );

    final restored = await PrayerLocations.load();
    expect(restored.id, 'current_location');
    expect(restored.latitude, 34.2);
    expect(restored.longitude, 44.1);
  });

  testWidgets('settings cascade from governorate to subdistrict and save its coordinates', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: SettingsPage(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('المحافظة'), findsOneWidget);
    expect(find.text('القضاء'), findsOneWidget);
    expect(find.text('الناحية / مركز القضاء'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('prayer-governorate-IQG17')),
    );
    await tester.tap(
      find.byKey(const ValueKey('prayer-governorate-IQG17')),
    );
    await tester.pumpAndSettle();
    expect(find.text('بابل'), findsOneWidget);
    await tester.tap(find.text('بابل').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('prayer-district-none')),
    );
    await tester.tap(find.byKey(const ValueKey('prayer-district-none')));
    await tester.pumpAndSettle();
    expect(find.text('الحلة'), findsOneWidget);
    await tester.tap(find.text('الحلة').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey(
        'prayer-subdistrict-IQG07Q02-__district_center__',
      )),
    );
    await tester.tap(find.byKey(const ValueKey(
      'prayer-subdistrict-IQG07Q02-__district_center__',
    )));
    await tester.pumpAndSettle();
    expect(find.text('ابي غرق'), findsOneWidget);
    await tester.tap(find.text('ابي غرق').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('حفظ موقع الحساب'));
    await tester.tap(find.text('حفظ موقع الحساب'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('prayer_place_id'), 'IQG07Q02N02');
    final restored = await PrayerLocations.load();
    expect(restored.name, 'ابي غرق');
    expect(restored.governorateName, 'بابل');
    expect(restored.districtName, 'الحلة');
    expect(tester.takeException(), isNull);
  });
}
