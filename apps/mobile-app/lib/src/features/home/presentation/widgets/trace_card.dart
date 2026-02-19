import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/services/haptic_service.dart';

class TraceCard extends StatelessWidget {
  final dynamic trace;
  final VoidCallback? onTap;

  const TraceCard({super.key, required this.trace, this.onTap});

  @override
  Widget build(BuildContext context) {
    final profile = trace['profiles'] ?? {};
    final username = profile['username'] ?? 'Anonymous';
    final avatar = profile['avatar_url'] ?? "https://api.dicebear.com/7.x/bottts/svg?seed=$username";
    final text = trace['content_text'] ?? '';
    final type = trace['type'] ?? 'STANDARD';
    final id = trace['id'];

    Color typeColor = Colors.white;
    switch (type) {
      case 'STORY': typeColor = Colors.purpleAccent; break;
      case 'CHALLENGE': typeColor = Colors.orangeAccent; break;
      case 'ORB': typeColor = DesignTokens.neonGreen; break;
      case 'FRIEND': typeColor = Colors.blueAccent; break;
    }

    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        if (onTap != null) {
          onTap!();
        } else {
          context.push('/trace/$id');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Stack(
          children: [
            // "Floating Shard" Effect - subtle shadow/glow behind
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: typeColor.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: -5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            
            // Main Glass Content
            GlassPanel(
              radius: 24,
              padding: const EdgeInsets.all(20),
              // Gradient Glass
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.06),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Hero(
                        tag: 'trace_avatar_$id',
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: typeColor.withOpacity(0.5)),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(avatar),
                            backgroundColor: Colors.black26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 10, color: typeColor),
                                const SizedBox(width: 4),
                                Text("$type • Nearby", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: typeColor.withOpacity(0.3)),
                        ),
                        child: Icon(Icons.nfc, size: 14, color: typeColor),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Content
                  Text(
                    text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                  ),
                  
                  // Media (if any)
                  if (trace['media_url'] != null) ...[
                    const SizedBox(height: 16),
                    Hero(
                      tag: 'trace_image_$id',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.network(
                              trace['media_url'], 
                              height: 180, 
                              width: double.infinity, 
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 180,
                                  color: Colors.black12,
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24)),
                                );
                              },
                              errorBuilder: (_,__,___) => Container(
                                height: 180, 
                                color: Colors.black12, 
                                child: const Icon(Icons.broken_image, color: Colors.white24)
                              ),
                            ),
                            // Liquid Shine Overlay on Image
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Actions Footer
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ActionButton(icon: Icons.favorite_border, label: "Like", onTap: () {}),
                      _ActionButton(icon: Icons.chat_bubble_outline, label: "Reply", onTap: () {}),
                      _ActionButton(icon: Icons.share_outlined, label: "Share", onTap: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0, duration: 400.ms);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.lightImpact();
        onTap();
      },
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
