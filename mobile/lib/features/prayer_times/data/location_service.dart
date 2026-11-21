import 'package:geolocator/geolocator.dart';

class City {
  final String bn, en;
  final double lat, lng;
  const City(this.bn, this.en, this.lat, this.lng);
}

const cities = <City>[
  City('ঢাকা', 'Dhaka', 23.8103, 90.4125),
  City('চট্টগ্রাম', 'Chattogram', 22.3569, 91.7832),
  City('ফেনী', 'Feni', 23.0159, 91.3976),
  City('কুমিল্লা', 'Cumilla', 23.4607, 91.1809),
  City('সিলেট', 'Sylhet', 24.8949, 91.8687),
  City('রাজশাহী', 'Rajshahi', 24.3745, 88.6042),
  City('খুলনা', 'Khulna', 22.8456, 89.5403),
  City('বরিশাল', 'Barishal', 22.7010, 90.3535),
  City('রংপুর', 'Rangpur', 25.7439, 89.2752),
  City('ময়মনসিংহ', 'Mymensingh', 24.7471, 90.4203),
  City("কক্সবাজার", "Cox's Bazar", 21.4272, 92.0058),
  City('মক্কা', 'Makkah', 21.3891, 39.8579),
  City('মদিনা', 'Madinah', 24.4672, 39.6024),
  City('দুবাই', 'Dubai', 25.2048, 55.2708),
  City('কুয়ালালামপুর', 'Kuala Lumpur', 3.1390, 101.6869),
  City('লন্ডন', 'London', 51.5074, -0.1278),
  City('নিউ ইয়র্ক', 'New York', 40.7128, -74.0060),
];

class LocationService {
  /// Returns null if permission is denied or services are off.
  static Future<Position?> detect() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
    try {
      return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low));
    } catch (_) {
      return null;
    }
  }
}
