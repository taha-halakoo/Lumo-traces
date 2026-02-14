import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'glass.dart';

class GlassShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const GlassShimmer({
    super.key,
    required this.width,
    required this.height,
    this.radius = 16,
  });

  factory GlassShimmer.card({double height = 100}) {
    return GlassShimmer(width: double.infinity, height: height, radius: 24);
  }

  factory GlassShimmer.avatar({double size = 48}) {
    return GlassShimmer(width: size, height: size, radius: size / 2);
  }

  factory GlassShimmer.text({double width = 100, double height = 16}) {
    return GlassShimmer(width: width, height: height, radius: 4);
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.15),
      child: GlassPanel(
        width: width,
        height: height,
        radius: radius,
        padding: EdgeInsets.zero,
        child: const SizedBox(),
      ),
    );
  }
}
