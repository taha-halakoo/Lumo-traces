import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

final featureFlagsProvider = FutureProvider<Map<String, bool>>((ref) async {
  final client = ref.read(apiClientProvider);
  try {
    final response = await client.get('/meta/flags');
    return Map<String, bool>.from(response.data);
  } catch (e) {
    return {}; 
  }
});