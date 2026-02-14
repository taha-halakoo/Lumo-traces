import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class LiquidOrb extends StatefulWidget {
  final double size;

  const LiquidOrb({super.key, this.size = 300});

  @override
  State<LiquidOrb> createState() => _LiquidOrbState();
}

class _LiquidOrbState extends State<LiquidOrb> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _time = 0.0;
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _loadShader();
    _ticker = createTicker((elapsed) {
      setState(() {
        _time = elapsed.inMilliseconds / 1000.0;
      });
    });
    _ticker.start();
  }

  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset('assets/shaders/liquid_orb.frag');
    setState(() {
      _shader = program.fragmentShader();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: CircularProgressIndicator()), // Fallback
      );
    }

    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _ShaderPainter(_shader!, _time),
    );
  }
}

class _ShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;

  _ShaderPainter(this.shader, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    // Uniforms: uResolution (vec2), uTime (float), uMouse (vec2 - unused here)
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    shader.setFloat(3, 0); // mouse x
    shader.setFloat(4, 0); // mouse y

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _ShaderPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
