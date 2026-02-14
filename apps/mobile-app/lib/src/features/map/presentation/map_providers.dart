import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../data/trace_repository.dart';

final mapCenterProvider = StateProvider<LatLng>((ref) {
  return const LatLng(35.6895, 139.6917); // Default Tokyo
});

final userLocationProvider = FutureProvider<Position>((ref) async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception('Location permissions are permanently denied, we cannot request permissions.');
  }

  return await Geolocator.getCurrentPosition();
});

final nearbyTracesProvider = FutureProvider<List<dynamic>>((ref) async {
  final center = ref.watch(mapCenterProvider);
  final repo = ref.read(traceRepositoryProvider);
  // Fetch slightly larger radius for map view
  return repo.getNearby(center.latitude, center.longitude, radius: 1000); 
});
