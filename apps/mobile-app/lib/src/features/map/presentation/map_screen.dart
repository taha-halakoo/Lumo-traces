import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/services/haptic_service.dart';
import 'package:traces_mobile/src/core/ui/hex_menu.dart';
import 'package:traces_mobile/src/features/home/presentation/feed_drawer.dart';
import 'package:traces_mobile/src/features/map/presentation/map_providers.dart';
import 'package:traces_mobile/src/features/map/presentation/map_view_model.dart';
import 'widgets/scanner_overlay.dart';
import 'widgets/search_suggestions.dart';
import 'widgets/place_info_card.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _isMoving = false;
  bool _isHexMenuOpen = false;

  @override
  void dispose() {
    super.dispose();
  }

  int _lastHapticTime = 0;
  void _handleMapEvent(MapEvent event) {
    if (event is MapEventMoveStart || event is MapEventRotateStart) {
       HapticService.mediumImpact();
       FocusManager.instance.primaryFocus?.unfocus();
       setState(() => _isMoving = true);
    } else if (event is MapEventMoveEnd || event is MapEventRotateEnd) {
       HapticService.mediumImpact();
       setState(() => _isMoving = false);
    } else if (_isMoving && (event is MapEventMove || event is MapEventRotate)) {
       final now = DateTime.now().millisecondsSinceEpoch;
       if (now - _lastHapticTime > 150) {
         HapticService.lightImpact();
         _lastHapticTime = now;
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapViewModelProvider);
    final userLocAsync = ref.watch(userLocationProvider);

    ref.listen(mapViewModelProvider, (previous, next) {
      if (next.selectedPlace != null && next.selectedPlace != previous?.selectedPlace) {
        _mapController.move(next.selectedPlace!.location, 16.0);
        HapticService.heavyImpact();
      }
    });

    final displayedTraces = mapState.traces.where((t) {
      if (mapState.activeFilters.isEmpty) return true;
      return mapState.activeFilters.contains(t['type']);
    }).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. IMMERSIVE MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapState.center == const LatLng(0, 0) ? const LatLng(35.6895, 139.6917) : mapState.center,
              initialZoom: 16.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onMapReady: () => ref.read(mapViewModelProvider.notifier).updateBounds(_mapController.camera.visibleBounds),
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  ref.read(mapViewModelProvider.notifier).updateBounds(position.visibleBounds);
                  ref.read(mapViewModelProvider.notifier).updateCenter(position.center);
                }
              },
              onMapEvent: _handleMapEvent,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.traces.app',
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              if (userLocAsync.hasValue)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(userLocAsync.value!.latitude, userLocAsync.value!.longitude),
                      width: 120, height: 120,
                      child: _PulsingUserMarker(),
                    ),
                  ],
                ),
              if (mapState.selectedPlace != null)
                 MarkerLayer(
                  markers: [
                    Marker(
                      point: mapState.selectedPlace!.location,
                      width: 60, height: 60,
                      child: Icon(Icons.location_on, color: DesignTokens.neonGreen, size: 50)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2))
                          .shimmer(color: Colors.white),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: displayedTraces.map((trace) {
                  return Marker(
                    point: LatLng((trace['lat'] as num).toDouble(), (trace['long'] as num).toDouble()),
                    width: 60, height: 60,
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

          Positioned.fill(child: ScannerOverlay(isScanning: mapState.isScanning)),

          // 2. LIQUID TOP BAR (Menu)
          Positioned(
            top: 60, left: 16, right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Hex Menu Trigger (Floating Glass Orb)
                    GestureDetector(
                      onTap: () {
                        HapticService.selectionClick();
                        setState(() => _isHexMenuOpen = true);
                      },
                      child: GlassPanel(
                        width: 50, height: 50, radius: 25, padding: EdgeInsets.zero, blur: 25,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        child: const Icon(Icons.blur_on, color: Colors.white70),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
                  ],
                ),
              ],
            ),
          ),

          // 3. SELECTED PLACE CARD
          Positioned(
            top: 130, left: 16, right: 16,
            child: AnimatedSwitcher(
              duration: 500.ms,
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: mapState.selectedPlace != null 
                ? PlaceInfoCard(
                    key: ValueKey(mapState.selectedPlace!.location),
                    place: mapState.selectedPlace!,
                    onClose: () => ref.read(mapViewModelProvider.notifier).clearSelection(),
                  )
                : const SizedBox.shrink(),
            ),
          ),

          // 4. DYNAMIC BOTTOM ISLAND (Unified Controls)
          Positioned(
            bottom: 120, left: 24, right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Minimalist Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MinimalFilter(icon: Icons.auto_stories, label: "Stories", active: mapState.activeFilters.contains('STORY'), onTap: () => ref.read(mapViewModelProvider.notifier).toggleFilter('STORY')),
                      const SizedBox(width: 12),
                      _MinimalFilter(icon: Icons.emoji_events, label: "Challenges", active: mapState.activeFilters.contains('CHALLENGE'), onTap: () => ref.read(mapViewModelProvider.notifier).toggleFilter('CHALLENGE')),
                      const SizedBox(width: 12),
                      _MinimalFilter(icon: Icons.catching_pokemon, label: "Orbs", active: mapState.activeFilters.contains('ORB'), onTap: () => ref.read(mapViewModelProvider.notifier).toggleFilter('ORB')),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5),

                const SizedBox(height: 24),

                // Core Action Hub
                GlassPanel.pill(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  blur: 30,
                  backgroundColor: Colors.white.withOpacity(0.03),
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Locate Me
                      IconButton(
                        icon: const Icon(Icons.my_location, color: Colors.white70),
                        onPressed: () {
                          HapticService.mediumImpact();
                          userLocAsync.whenData((loc) => _mapController.move(LatLng(loc.latitude, loc.longitude), 16));
                        },
                      ),
                      
                      // Massive Center Scan Button
                      GestureDetector(
                        onTap: () {
                          HapticService.heavyImpact();
                          ref.read(mapViewModelProvider.notifier).scanArea();
                        },
                        child: Container(
                          width: 140, height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(27),
                            gradient: LinearGradient(
                              colors: mapState.isScanning 
                                ? [DesignTokens.neonGreen.withOpacity(0.5), DesignTokens.neonGreen.withOpacity(0.2)]
                                : [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                            ),
                            boxShadow: mapState.isScanning ? [BoxShadow(color: DesignTokens.neonGreen.withOpacity(0.3), blurRadius: 20)] : [],
                            border: Border.all(color: mapState.isScanning ? DesignTokens.neonGreen : Colors.white.withOpacity(0.2)),
                          ),
                          child: Center(
                            child: mapState.isScanning
                                ? const CircularProgressIndicator(strokeWidth: 2, color: DesignTokens.neonGreen).animate().scale(curve: Curves.elasticOut)
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.radar, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text("SCAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12)),
                                    ],
                                  ),
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.02, duration: 2.seconds),

                      // Feed Toggle (Visual Cue)
                      IconButton(
                        icon: const Icon(Icons.view_agenda_outlined, color: Colors.white70),
                        onPressed: () {
                          HapticService.selectionClick();
                          // Tapping this could programmatically open the feed drawer if we add a controller, 
                          // but for now it acts as a visual hint.
                        },
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -3, duration: 1.seconds),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5),
              ],
            ),
          ),
          
          const FeedDrawer(),

          HexMenu(
            isOpen: _isHexMenuOpen,
            onClose: () => setState(() => _isHexMenuOpen = false),
            items: [
              HexMenuItem(icon: Icons.layers, label: "Reality Layers", color: DesignTokens.liquidBlue, onTap: () {}),
              HexMenuItem(icon: Icons.settings, label: "System Config", color: Colors.grey, onTap: () => context.push('/settings')),
              HexMenuItem(icon: Icons.person, label: "Identity", color: DesignTokens.neonGreen, onTap: () => context.push('/profile')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MinimalFilter extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _MinimalFilter({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeOutExpo,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? Colors.white.withOpacity(0.4) : Colors.white.withOpacity(0.05)),
          boxShadow: active ? [BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 10)] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? Colors.white : Colors.white54, size: 14),
            if (active) ...[
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ]
          ],
        ),
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
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [DesignTokens.liquidBlue.withOpacity(0.4), DesignTokens.liquidBlue.withOpacity(0.0)]),
          ),
        ).animate(onPlay: (c) => c.repeat())
         .scale(begin: const Offset(0.3, 0.3), end: const Offset(1.0, 1.0), duration: 3.seconds, curve: Curves.easeOutQuad)
         .fadeOut(duration: 3.seconds),
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: DesignTokens.liquidBlue, blurRadius: 15, spreadRadius: 3),
              const BoxShadow(color: Colors.white, blurRadius: 8, spreadRadius: 1),
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
      case 'STORY': color = DesignTokens.electricPurple; icon = Icons.auto_stories; break;
      case 'CHALLENGE': color = Colors.orangeAccent; icon = Icons.emoji_events; break;
      case 'ORB': color = DesignTokens.neonGreen; icon = Icons.catching_pokemon; break;
      case 'FRIEND': color = DesignTokens.liquidBlue; icon = Icons.face; break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
              border: Border.all(color: color.withOpacity(0.8), width: 2),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scaleXY(begin: 1.0, end: 1.15, duration: 2.seconds, curve: Curves.easeInOut),
          Icon(icon, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}
