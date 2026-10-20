import 'package:shared_preferences/shared_preferences.dart';

class PrayerCity {
  const PrayerCity({required this.id, required this.name, required this.latitude, required this.longitude});
  final String id;
  final String name;
  final double latitude;
  final double longitude;
}

class PrayerLocations {
  static const cities = <PrayerCity>[
    PrayerCity(id: 'qalat_sukar', name: 'قلعة سكر', latitude: 31.85, longitude: 46.07),
    PrayerCity(id: 'nasiriyah', name: 'الناصرية', latitude: 31.05, longitude: 46.26),
    PrayerCity(id: 'baghdad', name: 'بغداد', latitude: 33.3152, longitude: 44.3661),
    PrayerCity(id: 'najaf', name: 'النجف الأشرف', latitude: 32.025, longitude: 44.335),
    PrayerCity(id: 'karbala', name: 'كربلاء المقدسة', latitude: 32.616, longitude: 44.025),
    PrayerCity(id: 'basra', name: 'البصرة', latitude: 30.5085, longitude: 47.7804),
    PrayerCity(id: 'kufa', name: 'الكوفة', latitude: 32.0303, longitude: 44.4036),
    PrayerCity(id: 'amarah', name: 'العمارة', latitude: 31.8359, longitude: 47.1448),
  ];

  static PrayerCity byId(String? id) {
    for (final city in cities) {
      if (city.id == id) return city;
    }
    return cities.first;
  }

  static Future<PrayerCity> load() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble('prayer_latitude');
    final longitude = prefs.getDouble('prayer_longitude');
    if (latitude != null && longitude != null) {
      return PrayerCity(
        id: 'current_location',
        name: prefs.getString('prayer_location_name') ?? 'موقعي الحالي',
        latitude: latitude,
        longitude: longitude,
      );
    }
    return byId(prefs.getString('prayer_city'));
  }

  static Future<void> save(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('prayer_latitude');
    await prefs.remove('prayer_longitude');
    await prefs.remove('prayer_location_name');
    await prefs.setString('prayer_city', byId(id).id);
  }

  static Future<void> saveCurrentLocation({
    required double latitude,
    required double longitude,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('prayer_latitude', latitude);
    await prefs.setDouble('prayer_longitude', longitude);
    await prefs.setString('prayer_location_name', 'موقعي الحالي');
  }
}
