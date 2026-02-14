import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

final featureFlagsProvider = FutureProvider<Map<String, bool>>((ref) async {
  final client = ref.read(apiClientProvider).client;
  try {
    final response = await client.get('/meta/flags');
    return Map<String, bool>.from(response.data);
  } catch (e) {
    return {}; 
  }
});