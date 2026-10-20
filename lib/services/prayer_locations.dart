import 'package:geolocator/geolocator.dart';
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

  /// Request and store a fresh GPS fix. Returns null when access or accuracy
  /// is insufficient, allowing the previous city to remain as a fallback.
  static Future<PrayerCity?> acquirePreciseLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 25),
        ),
      );
      if (!position.latitude.isFinite || !position.longitude.isFinite ||
          position.accuracy.isNaN || position.accuracy > 250) return null;
      await saveCurrentLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );
      return PrayerCity(id: 'current_location', name: 'موقعي الحالي',
        latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      return null;
    }
  }

  static Future<double?> currentLocationAccuracy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('prayer_location_accuracy_meters');
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
    await prefs.remove('prayer_location_accuracy_meters');
    await prefs.setString('prayer_city', byId(id).id);
  }

  static Future<void> saveCurrentLocation({
    required double latitude,
    required double longitude,
    double? accuracyMeters,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('prayer_latitude', latitude);
    await prefs.setDouble('prayer_longitude', longitude);
    await prefs.setString('prayer_location_name', 'موقعي الحالي');
    if (accuracyMeters != null) await prefs.setDouble('prayer_location_accuracy_meters', accuracyMeters);
  }
}
