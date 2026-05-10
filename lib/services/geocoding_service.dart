import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  static Future<LatLng?> geocode(String address) async {
    if (address.trim().isEmpty) return null;
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': '$address, Philippines',
        'format': 'json',
        'limit': '1',
        'countrycodes': 'ph',
      });
      final response = await http
          .get(uri, headers: {
            'User-Agent': 'VaronApp/1.0',
            'Accept-Language': 'en',
          })
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as List;
      if (data.isEmpty) return null;

      final lat = double.tryParse(data[0]['lat'] as String? ?? '');
      final lon = double.tryParse(data[0]['lon'] as String? ?? '');
      if (lat == null || lon == null) return null;
      return LatLng(lat, lon);
    } catch (_) {
      return null;
    }
  }
}
