import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsProvider = Provider((ref) => AnalyticsService());

class AnalyticsService {
  Future<void> logEvent(String name, [Map<String, dynamic>? parameters]) async {
    print("ANALYTICS: $name $parameters");
  }

  Future<void> setUserProperty(String name, String value) async {
    print("ANALYTICS USER PROP: $name = $value");
  }
}