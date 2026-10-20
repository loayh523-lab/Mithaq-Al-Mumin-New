import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../services/prayer_locations.dart';

const _qiblaGold = Color(0xFFD9B66D);
const _qiblaPanel = Color(0xFF10251E);
const _qiblaMuted = Color(0xFF9EB5A9);

/// Live compass direction for the configured approximate Qal'at Sukar location.
class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});
  @override State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  static const double _kaabaLat = 21.4225;
  static const double _kaabaLon = 39.8262;
  PrayerCity _city = PrayerLocations.cities.first;
  bool _gpsBusy = false;
  double? _gpsAccuracy;
  String? _locationMessage;

  @override void initState() { super.initState(); _loadCity(); }

  Future<void> _loadCity() async {
    try {
      final selected = await PrayerLocations.load();
      if (!mounted) return;
      setState(() => _city = selected);
      if (selected.id == 'current_location') {
        _gpsAccuracy = await PrayerLocations.currentLocationAccuracy();
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _refreshLocation() async {
    setState(() { _gpsBusy = true; _locationMessage = null; });
    final precise = await PrayerLocations.acquirePreciseLocation();
    if (!mounted) return;
    if (precise == null) {
      setState(() => _locationMessage = 'تعذّر تحديد GPS دقيق. فعّل الموقع واسمح للتطبيق بالوصول إليه.');
    } else {
      final accuracy = await PrayerLocations.currentLocationAccuracy();
      if (!mounted) return;
      setState(() {
        _city = precise;
        _gpsAccuracy = accuracy;
        _locationMessage = accuracy == null ? 'تم تحديث الموقع من GPS.' : 'دقة الموقع المعلنة من الجهاز نحو ${accuracy.round()} متر.';
      });
    }
    if (mounted) setState(() => _gpsBusy = false);
  }

  double get _bearing {
    const r = math.pi / 180;
    final lat1 = _city.latitude * r, lat2 = _kaabaLat * r;
    final dLon = (_kaabaLon - _city.longitude) * r;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) / r + 360) % 360;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('اتجاه القبلة'),
      actions: [
        IconButton(
          tooltip: 'تحديث الموقع الدقيق',
          onPressed: _gpsBusy ? null : _refreshLocation,
          icon: _gpsBusy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.my_location_rounded),
        ),
      ],
    ),
    body: StreamBuilder<CompassEvent?>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        final heading = snapshot.data?.heading;
        if (heading == null) {
          return const Center(child: Padding(padding: EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.explore_off_outlined, size: 58, color: _qiblaGold), SizedBox(height: 14),
            Text('البوصلة غير متاحة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), SizedBox(height: 8),
            Text('تأكد أن جهازك يحتوي على حساس بوصلة، وابتعد عن المغناطيس والأغطية المغناطيسية. جرّب تحريك الهاتف بشكل رقم 8 لمعايرة الحساس.', textAlign: TextAlign.center, style: TextStyle(color: _qiblaMuted, height: 1.6)),
          ])));
        }
        return ListView(padding: const EdgeInsets.all(24), children: [
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: _qiblaPanel, borderRadius: BorderRadius.circular(28), border: Border.all(color: _qiblaGold.withValues(alpha: .3))), child: Column(children: [
            const Text('اتجاه الكعبة المشرفة', style: TextStyle(color: _qiblaMuted)), const SizedBox(height: 6),
            Text('${_bearing.round()}° من الشمال', style: const TextStyle(color: _qiblaGold, fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 28),
            SizedBox(
              width: 250,
              height: 250,
              child: Transform.rotate(
                angle: -heading * math.pi / 180,
                child: Stack(alignment: Alignment.center, children: [
                  Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _qiblaGold.withValues(alpha: .5), width: 2))),
                  const Positioned(top: 12, child: Text('N', style: TextStyle(color: _qiblaMuted, fontWeight: FontWeight.bold))),
                  const Positioned(bottom: 12, child: Text('S', style: TextStyle(color: _qiblaMuted))),
                  const Positioned(left: 12, child: Text('W', style: TextStyle(color: _qiblaMuted))),
                  const Positioned(right: 12, child: Text('E', style: TextStyle(color: _qiblaMuted))),
                  Transform.rotate(angle: _bearing * math.pi / 180, child: const Icon(Icons.navigation_rounded, size: 120, color: _qiblaGold)),
                  Container(width: 16, height: 16, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                ]),
              ),
            ),
            const SizedBox(height: 20), Text('اتجاه الهاتف: ${heading.round()}°', style: const TextStyle(color: _qiblaMuted)),
          ])),
          const SizedBox(height: 18),
          Text(
            'الموقع المعتمد: ${_city.name} — ${_city.id == 'current_location' ? 'GPS من الجهاز' : 'إحداثيات مدينة تقريبية'}${_gpsAccuracy == null ? '' : ' (دقة GPS نحو ${_gpsAccuracy!.round()} م)'}. حرّك الهاتف بعيداً عن المعادن والمغناطيس وعاير الحساس. قد يختلف الشمال المغناطيسي عن الشمال الجغرافي ببضع درجات.',
            style: const TextStyle(color: _qiblaMuted, height: 1.6, fontSize: 12),
          ),
          if (_locationMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_locationMessage!, style: const TextStyle(color: _qiblaGold, height: 1.5)),
            ),
        ]);
      },
    ),
  );
}
