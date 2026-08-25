import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class CosmoNebula extends StatefulWidget {
  const CosmoNebula({
    super.key,
    this.child,
  });

  final Widget? child;

  @override
  State<CosmoNebula> createState() => _CosmoNebulaState();
}

class _CosmoNebulaState extends State<CosmoNebula>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )
      ..repeat();

    _loadShader();
  }

  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/cosmo_nebula.frag',
    );

    if (!mounted) return;

    setState(() {
      _shader = program.fragmentShader();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;

    if (shader == null) {
      return ColoredBox(
        color: const Color(0xFF050816),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _CosmoNebulaPainter(
            shader: shader,
            time: _controller.value * 60.0,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _CosmoNebulaPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;

  const _CosmoNebulaPainter({
    required this.shader,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _CosmoNebulaPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}