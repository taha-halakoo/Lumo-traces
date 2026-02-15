import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../profile/data/user_repository.dart';
import '../../map/presentation/map_providers.dart';

final explorerFilterProvider = StateProvider<String>((ref) => 'All');
final explorerSearchProvider = StateProvider<String>((ref) => '');

final discoveryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  double? lat, long;
  try {
    final position = await ref.watch(userLocationProvider.future);
    lat = position.latitude;
    long = position.longitude;
  } catch (_) {
    // If location fails, we can either throw or fetch generic discovery.
    // For now, let's fetch generic.
  }
  
  return ref.read(userRepositoryProvider).getDiscovery(lat: lat, long: long);
});

final explorerTracesProvider = FutureProvider<List<dynamic>>((ref) async {
  final discovery = await ref.watch(discoveryProvider.future);
  final filter = ref.watch(explorerFilterProvider);
  final search = ref.watch(explorerSearchProvider).toLowerCase();
  
  List<dynamic> list = discovery['traces'] ?? [];

  if (filter != 'All') {
    list = list.where((t) => (t['type'] as String).toLowerCase() == filter.toLowerCase()).toList();
  }

  if (search.isNotEmpty) {
    list = list.where((t) => 
      (t['content_text'] as String).toLowerCase().contains(search) ||
      (t['profiles']?['username'] as String).toLowerCase().contains(search)
    ).toList();
  }

  return list;
});

final userRecommendationsProvider = FutureProvider<List<dynamic>>((ref) async {
  final discovery = await ref.watch(discoveryProvider.future);
  return discovery['recommendations'] ?? [];
});
