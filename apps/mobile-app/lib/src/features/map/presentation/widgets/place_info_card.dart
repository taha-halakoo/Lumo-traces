import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/services/haptic_service.dart';
import '../../data/geocoding_repository.dart';

class PlaceInfoCard extends StatelessWidget {
  final PlaceResult place;
  final VoidCallback onClose;

  const PlaceInfoCard({
    super.key,
    required this.place,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // Generate a placeholder image URL based on place type or name if no real image
    // In a real app, this would come from an API. Here we simulate it or use a placeholder.
    // For now, we will assume we don't have a real image URL from OSM Nominatim immediately,
    // so we keep the "Live Preview" placeholder but ready for integration.
    final String? imageUrl = null; 

    return GlassPanel(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      radius: 24,
      backgroundColor: DesignTokens.glassDarkBase.withOpacity(0.6), 
      border: Border.all(color: DesignTokens.liquidBlue.withOpacity(0.4), width: 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.displayName.split(',')[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ).animate()
                     .fadeIn(duration: 400.ms)
                     .slideX(begin: -0.2, end: 0, curve: Curves.easeOutBack),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      place.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticService.selectionClick();
                  onClose();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: imageUrl != null 
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildPlaceholder(),
                    errorWidget: (context, url, error) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
            ),
          ).animate().fadeIn().shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.1)),

          const SizedBox(height: 20),

          Row(
            children: [
              _AnimatedStatChip(
                icon: Icons.people_outline,
                label: "12 Nearby",
                color: DesignTokens.neonGreen,
                delay: 300.ms,
              ),
              const SizedBox(width: 10),
              _AnimatedStatChip(
                icon: Icons.local_fire_department,
                label: "Hot Spot",
                color: Colors.orangeAccent,
                delay: 450.ms,
              ),
            ],
          ),

          const SizedBox(height: 20),

          GestureDetector(
            onTap: () {
              HapticService.heavyImpact();
            },
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DesignTokens.liquidBlue.withOpacity(0.3),
                    DesignTokens.liquidBlue.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DesignTokens.liquidBlue.withOpacity(0.5)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            width: 20,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0),
                                  Colors.white.withOpacity(0.4),
                                  Colors.white.withOpacity(0),
                                ],
                              ),
                            ),
                          ).animate(onPlay: (c) => c.repeat())
                           .slideX(begin: -1, end: 2, duration: 2.seconds);
                        },
                      ),
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.radar, color: DesignTokens.liquidBlue, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "SCAN FOR MEMORIES",
                        style: TextStyle(
                          color: DesignTokens.liquidBlue,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate(delay: 600.ms)
           .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack)
           .fadeIn(),
        ],
      ),
    ).animate()
     .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutQuint)
     .fadeIn();
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.liquidBlue.withOpacity(0.2),
            Colors.purpleAccent.withOpacity(0.2),
            DesignTokens.neonGreen.withOpacity(0.2),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -20, left: -20,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: Colors.white.withOpacity(0.1)
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(1,1), end: const Offset(1.5,1.5), duration: 3.seconds),
          ),
          const Icon(Icons.image_not_supported, color: Colors.white24, size: 40),
          Positioned(
            bottom: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("LIVE PREVIEW", style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Duration delay;

  const _AnimatedStatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1.seconds),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ).animate(delay: delay)
     .scale(begin: const Offset(0, 0), curve: Curves.elasticOut, duration: 600.ms)
     .fadeIn();
  }
}
