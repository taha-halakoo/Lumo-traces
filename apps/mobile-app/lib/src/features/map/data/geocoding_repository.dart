import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

final geocodingRepositoryProvider = Provider<GeocodingRepository>((ref) => GeocodingRepository());

class GeocodingRepository {
  final Dio _dio = Dio();

  // Search for places using OSM Nominatim (Free, no key required for low volume)
  // In production, we'd wrap this in our backend or use a paid service like Mapbox/Google.
  Future<List<PlaceResult>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': 5,
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((item) => PlaceResult.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      // Fail silently for search suggestions
      return [];
    }
  }
}

class PlaceResult {
  final String displayName;
  final LatLng location;
  final String type; // e.g., "city", "restaurant"

  PlaceResult({required this.displayName, required this.location, required this.type});

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      displayName: json['display_name'] ?? 'Unknown Place',
      location: LatLng(
        double.parse(json['lat']),
        double.parse(json['lon']),
      ),
      type: json['type'] ?? 'place',
    );
  }
}
