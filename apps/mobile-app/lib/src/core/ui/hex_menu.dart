import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/services/haptic_service.dart';

class HexMenu extends StatefulWidget {
  final List<HexMenuItem> items;
  final bool isOpen;
  final VoidCallback onClose;

  const HexMenu({
    super.key,
    required this.items,
    required this.isOpen,
    required this.onClose,
  });

  @override
  State<HexMenu> createState() => _HexMenuState();
}

class _HexMenuState extends State<HexMenu> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blur Background
          GestureDetector(
            onTap: () {
              HapticService.lightImpact();
              widget.onClose();
            },
            child: Container(
              color: Colors.black.withOpacity(0.3), // Light dimmer
            ).animate().fadeIn(duration: 300.ms),
          ),

          // Hex Grid
          SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Center Close Button
                _buildHexButton(
                  icon: Icons.close,
                  color: Colors.redAccent,
                  offset: const Offset(0, 0),
                  onTap: widget.onClose,
                  delay: 0,
                ),
                // Dynamic Items in Hex Pattern
                ...List.generate(widget.items.length, (index) {
                  final item = widget.items[index];
                  // Simple Hex layout for up to 6 items
                  final offsets = [
                    const Offset(0, -100),  // Top
                    const Offset(86, -50),  // Top Right
                    const Offset(86, 50),   // Bottom Right
                    const Offset(0, 100),   // Bottom
                    const Offset(-86, 50),  // Bottom Left
                    const Offset(-86, -50), // Top Left
                  ];
                  final offset = offsets[index % 6];
                  
                  return _buildHexButton(
                    icon: item.icon,
                    label: item.label,
                    color: item.color,
                    offset: offset,
                    onTap: item.onTap,
                    delay: index * 50,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHexButton({
    required IconData icon,
    String? label,
    required Color color,
    required Offset offset,
    required VoidCallback onTap,
    required int delay,
  }) {
    return Transform.translate(
      offset: offset,
      child: GestureDetector(
        onTap: () {
          HapticService.selectionClick();
          onTap();
          // Optional: Close menu on selection?
          // widget.onClose();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hexagon Shape
            ClipPath(
              clipper: _HexagonClipper(),
              child: GlassPanel(
                width: 80,
                height: 92, // Hex ratio
                padding: EdgeInsets.zero,
                backgroundColor: color.withOpacity(0.2),
                border: Border.all(color: color.withOpacity(0.6), width: 1.5),
                child: Center(
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate()
     .scale(begin: const Offset(0, 0), curve: Curves.easeOutBack, duration: 400.ms, delay: delay.ms)
     .fadeIn();
  }
}

class HexMenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  HexMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    
    // Flat topped hexagon
    path.moveTo(width * 0.25, 0);
    path.lineTo(width * 0.75, 0);
    path.lineTo(width, height * 0.5);
    path.lineTo(width * 0.75, height);
    path.lineTo(width * 0.25, height);
    path.lineTo(0, height * 0.5);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
