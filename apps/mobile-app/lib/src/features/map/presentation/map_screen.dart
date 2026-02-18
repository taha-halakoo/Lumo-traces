import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/ui/animated_glass_button.dart';
import 'package:traces_mobile/src/core/services/haptic_service.dart';
import 'package:traces_mobile/src/features/home/presentation/feed_drawer.dart';
import 'package:traces_mobile/src/features/map/presentation/map_providers.dart';
import 'package:traces_mobile/src/features/map/presentation/map_view_model.dart';
import 'widgets/scanner_overlay.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Initial fetch handled by provider or map event
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(mapViewModelProvider.notifier).updateSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapViewModelProvider);
    final userLocAsync = ref.watch(userLocationProvider);

    // Filter traces based on active filters
    final displayedTraces = mapState.traces.where((t) {
      if (mapState.activeFilters.isEmpty) return true;
      return mapState.activeFilters.contains(t['type']);
    }).toList();

    return Scaffold(
      resizeToAvoidBottomInset: false, // Map shouldn't resize for keyboard
      body: Stack(
        children: [
          // 1. MAP LAYER
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapState.center == const LatLng(0, 0) 
                  ? const LatLng(35.6895, 139.6917) // Tokyo Default
                  : mapState.center,
              initialZoom: 16.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onMapReady: () {
                // Initialize bounds
                 final bounds = _mapController.camera.visibleBounds;
                 ref.read(mapViewModelProvider.notifier).updateBounds(bounds);
              },
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  ref.read(mapViewModelProvider.notifier).updateBounds(position.visibleBounds);
                  ref.read(mapViewModelProvider.notifier).updateCenter(position.center);
                }
              },
              onMapEvent: (event) {
                 if (event.source == MapEventSource.dragStart) {
                   FocusManager.instance.primaryFocus?.unfocus(); // Close keyboard
                 }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.traces.app',
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              // User Location Marker
              if (userLocAsync.hasValue)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(userLocAsync.value!.latitude, userLocAsync.value!.longitude),
                      width: 80, height: 80, // Larger hit box for visuals
                      child: _PulsingUserMarker(),
                    ),
                  ],
                ),
              // Traces Markers
              MarkerLayer(
                markers: displayedTraces.map((trace) {
                  return Marker(
                    point: LatLng((trace['lat'] as num).toDouble(), (trace['long'] as num).toDouble()),
                    width: 50, height: 50,
                    child: _LiquidTraceMarker(
                      trace: trace,
                      onTap: () {
                        HapticService.heavyImpact();
                        context.push('/trace/${trace['id']}');
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 2. SCANNER OVERLAY (Shader)
          Positioned.fill(
            child: ScannerOverlay(isScanning: mapState.isScanning),
          ),

          // 3. TOP BAR (Search)
          Positioned(
            top: 60, left: 16, right: 16,
            child: GlassPanel.pill(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "Search places, memories...",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                    ),
                ],
              ),
            ).animate().slideY(begin: -1.5, end: 0, duration: 600.ms, curve: Curves.easeOutBack),
          ),

          // 4. BOTTOM CONTROLS
          Positioned(
            bottom: 40, left: 16, right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                          label: "Story", 
                          selected: mapState.activeFilters.contains('STORY'),
                          onTap: () => ref.read(mapViewModelProvider.notifier).toggleFilter('STORY')
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                          label: "Challenge", 
                          selected: mapState.activeFilters.contains('CHALLENGE'),
                          onTap: () => ref.read(mapViewModelProvider.notifier).toggleFilter('CHALLENGE')
                      ),
                       const SizedBox(width: 8),
                      _FilterChip(
                          label: "Orb", 
                          selected: mapState.activeFilters.contains('ORB'),
                          onTap: () => ref.read(mapViewModelProvider.notifier).toggleFilter('ORB')
                      ),
                       const SizedBox(width: 8),
                      _FilterChip(
                          label: "Friend", 
                          selected: mapState.activeFilters.contains('FRIEND'),
                          onTap: () => ref.read(mapViewModelProvider.notifier).toggleFilter('FRIEND')
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideX(),

                const SizedBox(height: 16),

                // Action Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Zoom Controls
                    Column(
                      children: [
                        AnimatedGlassButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onTap: () {
                            _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                          },
                        ),
                        const SizedBox(height: 12),
                        AnimatedGlassButton(
                          icon: const Icon(Icons.remove, color: Colors.white),
                          onTap: () {
                            _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                          },
                        ),
                      ],
                    ),

                    // Scan / Refresh Button
                    GestureDetector(
                      onTap: () {
                        HapticService.lightImpact();
                        ref.read(mapViewModelProvider.notifier).scanArea();
                      },
                      child: GlassPanel.pill(
                        height: 50, width: 140,
                        backgroundColor: mapState.isScanning 
                            ? DesignTokens.neonGreen.withOpacity(0.2) 
                            : Colors.black.withOpacity(0.3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (mapState.isScanning)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 12, height: 12,
                                child: const CircularProgressIndicator(strokeWidth: 2, color: DesignTokens.neonGreen),
                              )
                            else 
                              const Icon(Icons.radar, color: DesignTokens.neonGreen, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              mapState.isScanning ? "SCANNING" : "SCAN AREA",
                              style: const TextStyle(
                                color: DesignTokens.neonGreen, 
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2
                              ),
                            ),
                          ],
                        ),
                      ).animate(target: mapState.isScanning ? 1 : 0)
                       .shimmer(duration: 1.seconds, color: DesignTokens.neonGreen),
                    ),

                    // My Location
                    AnimatedGlassButton(
                      icon: const Icon(Icons.my_location, color: Colors.white),
                      onTap: () {
                         userLocAsync.whenData((loc) {
                           _mapController.move(LatLng(loc.latitude, loc.longitude), 16);
                         });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const FeedDrawer(),
        ],
      ),
    );
  }
}

class _PulsingUserMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Pulse
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              DesignTokens.liquidBlue.withOpacity(0.3),
              DesignTokens.liquidBlue.withOpacity(0.0)
            ]),
          ),
        ).animate(onPlay: (c) => c.repeat())
         .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), duration: 2.seconds, curve: Curves.easeOut)
         .fadeOut(duration: 2.seconds),
         
        // Core
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: DesignTokens.liquidBlue, blurRadius: 10, spreadRadius: 2),
              const BoxShadow(color: Colors.white, blurRadius: 5, spreadRadius: 1),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiquidTraceMarker extends StatelessWidget {
  final dynamic trace;
  final VoidCallback onTap;

  const _LiquidTraceMarker({required this.trace, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = trace['type'] ?? 'STANDARD';
    Color color = Colors.white;
    IconData icon = Icons.location_on;

    switch (type) {
      case 'STORY': color = Colors.purpleAccent; icon = Icons.auto_stories; break;
      case 'CHALLENGE': color = Colors.orangeAccent; icon = Icons.emoji_events; break;
      case 'ORB': color = DesignTokens.neonGreen; icon = Icons.catching_pokemon; break;
      case 'FRIEND': color = Colors.blueAccent; icon = Icons.face; break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glass Base
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, spreadRadius: 1),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scaleXY(begin: 1.0, end: 1.1, duration: 1.5.seconds, curve: Curves.easeInOut),
           
          // Icon
          Icon(icon, color: Colors.white, size: 20),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: GlassPanel.pill(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: selected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          border: selected ? Border.all(color: Colors.white, width: 1) : null,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
