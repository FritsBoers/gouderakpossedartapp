import 'dart:math';
import 'package:flutter/material.dart';

/// A full-screen confetti/party popper animation overlay.
class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  const ConfettiOverlay({super.key, required this.child});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  static const _colors = [
    Color(0xFFFFD700),
    Color(0xFFFF4444),
    Color(0xFF44FF44),
    Color(0xFF4488FF),
    Color(0xFFFF44FF),
    Color(0xFFFF8800),
    Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(80, (_) {
      final fromLeft = rng.nextBool();
      return _Particle(
        x: fromLeft ? -0.05 : 1.05,
        y: 0.15 + rng.nextDouble() * 0.15,
        vx: (fromLeft ? 1 : -1) * (0.3 + rng.nextDouble() * 0.7),
        vy: -(0.5 + rng.nextDouble() * 0.8),
        rotation: rng.nextDouble() * 2 * pi,
        rotationSpeed: (rng.nextDouble() - 0.5) * 8,
        size: 6 + rng.nextDouble() * 6,
        color: _colors[rng.nextInt(_colors.length)],
        shape: rng.nextInt(3),
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(_particles, _controller.value),
            ),
          ),
        ),
      ],
    );
  }
}

class _Particle {
  final double x, y, vx, vy, rotation, rotationSpeed, size;
  final Color color;
  final int shape;

  const _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.shape,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  const _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 3.0;
    for (final p in particles) {
      final px = (p.x + p.vx * t) * size.width;
      final py = (p.y + p.vy * t + 0.75 * t * t) * size.height;
      final opacity = progress > 0.7
          ? (1.0 - (progress - 0.7) / 0.3).clamp(0.0, 1.0)
          : 1.0;
      if (py > size.height || px < -20 || px > size.width + 20) continue;
      final paint = Paint()..color = p.color.withOpacity(opacity);
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation + p.rotationSpeed * t);
      switch (p.shape) {
        case 0:
          canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero, width: p.size, height: p.size),
            paint,
          );
        case 1:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
        default:
          canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero,
                width: p.size * 0.4,
                height: p.size * 1.5),
            paint,
          );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
