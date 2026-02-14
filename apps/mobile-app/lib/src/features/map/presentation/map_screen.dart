import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/ui/animated_glass_button.dart';
import 'package:traces_mobile/src/core/ui/proximity_capsule.dart';
import 'package:traces_mobile/src/features/home/presentation/feed_drawer.dart';
import 'package:traces_mobile/src/core/services/haptic_service.dart';
import 'package:traces_mobile/src/core/ui/dynamic_island.dart';
import 'package:traces_mobile/src/features/home/presentation/feed_notifier.dart';
import 'map_providers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  
  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(userLocationProvider);
    final tracesAsync = ref.watch(nearbyTracesProvider);
    final currentCenter = ref.watch(mapCenterProvider);

    // Dynamic Island Listener
    ref.listen(newTraceEventProvider, (prev, next) {
      if (next != null) {
        DynamicIslandNotification.show(
          context, 
          title: "NEW TRACE DETECTED", 
          message: "${next['profiles']?['username'] ?? "Someone"} just dropped a memory nearby.",
          icon: Icons.radar,
        );
      }
    });

    ref.listen(userLocationProvider, (previous, next) {
      next.whenData((position) {
        final newCenter = LatLng(position.latitude, position.longitude);
        ref.read(mapCenterProvider.notifier).state = newCenter;
      });
    });

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentCenter,
              initialZoom: 16.0,
              onMapEvent: (event) {
                if (event.source == MapEventSource.dragStart || event.source == MapEventSource.multiFingerGestureStart) {
                   HapticService.lightImpact();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.traces.app',
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: currentCenter,
                    radius: 100,
                    useRadiusInMeter: true,
                    color: DesignTokens.liquidBlue.withOpacity(0.1),
                    borderColor: DesignTokens.liquidBlue.withOpacity(0.3),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentCenter,
                    width: 60, height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: DesignTokens.liquidBlue, blurRadius: 10, spreadRadius: 5)],
                          ),
                        ),
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: DesignTokens.liquidBlue.withOpacity(0.5), width: 2),
                          ),
                        ).animate(onPlay: (c) => c.repeat())
                         .scale(duration: 2.seconds, begin: const Offset(0.5, 0.5), end: const Offset(2, 2), curve: Curves.easeOut)
                         .fadeOut(),
                      ],
                    ),
                  ),
                  ...tracesAsync.when(
                    data: (traces) => traces.map((trace) {
                      final lat = (trace['lat'] as num).toDouble();
                      final long = (trace['long'] as num).toDouble();
                      return Marker(
                        point: LatLng(lat, long),
                        width: 50, height: 50,
                        child: GestureDetector(
                          onTap: () {
                            HapticService.heavyImpact();
                            context.push('/trace/${trace['id']}');
                          },
                          child: Icon(Icons.location_on, color: DesignTokens.liquidBlue, size: 40)
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scaleXY(end: 1.2, duration: 1.seconds)
                              .shimmer(color: Colors.white.withOpacity(0.5)),
                        ),
                      );
                    }).toList(),
                    loading: () => [],
                    error: (_, __) => [],
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 60, left: 20, right: 20,
            child: GlassPanel.pill(
              height: 56,
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white70),
                  const SizedBox(width: 12),
                  const Text("Search places...", style: TextStyle(color: Colors.white60, fontSize: 16)),
                ],
              ),
              onTap: () {},
            ).animate().slideY(begin: -1.5, end: 0, duration: 600.ms, curve: Curves.easeOutBack),
          ),

          Positioned(
            bottom: 120, left: 20, right: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassPanel.pill(
                      height: 36, width: 120,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      backgroundColor: Colors.black.withOpacity(0.3),
                      child: Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: DesignTokens.neonGreen, shape: BoxShape.circle),
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 500.ms).fadeOut(delay: 500.ms),
                          const SizedBox(width: 8),
                          const Text("Scanning...", style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const ProximityCapsule(fillPercentage: 0.3),
                  ],
                ),
                const Spacer(),
                AnimatedGlassButton(
                  icon: const Icon(Icons.my_location, color: Colors.white),
                  onTap: () {
                     locationAsync.whenData((loc) {
                       _mapController.move(LatLng(loc.latitude, loc.longitude), 16);
                     });
                  },
                ),
              ],
            ).animate().slideY(begin: 1.0, end: 0, duration: 800.ms, curve: Curves.easeOutQuint),
          ),
          
          const FeedDrawer(),
        ],
      ),
    );
  }
}
