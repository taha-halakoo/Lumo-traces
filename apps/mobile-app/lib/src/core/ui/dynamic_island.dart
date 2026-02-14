import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';

class DynamicIslandNotification extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;

  const DynamicIslandNotification({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.notifications_active,
  });

  static void show(BuildContext context, {required String title, required String message, IconData? icon}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: DynamicIslandNotification(title: title, message: message, icon: icon ?? Icons.notifications_active),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(4.seconds, () => entry.remove());
  }

  @override
  State<DynamicIslandNotification> createState() => _DynamicIslandNotificationState();
}

class _DynamicIslandNotificationState extends State<DynamicIslandNotification> {
  @override
  Widget build(BuildContext context) {
    return GlassPanel.pill(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.black.withOpacity(0.8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.liquidBlue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: DesignTokens.liquidBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(widget.message, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    ).animate()
     .fadeIn(duration: 400.ms)
     .slideY(begin: -1, end: 0, curve: Curves.elasticOut)
     .then(delay: 3.seconds)
     .fadeOut(duration: 400.ms)
     .slideY(begin: 0, end: -1);
  }
}
