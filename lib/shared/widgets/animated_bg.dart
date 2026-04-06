import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AnimatedBg extends StatefulWidget {
  final Widget child;
  const AnimatedBg({super.key, required this.child});

  @override
  State<AnimatedBg> createState() => _AnimatedBgState();
}

class _AnimatedBgState extends State<AnimatedBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        return Container(
          decoration: const BoxDecoration(gradient: AppColors.bgGradient),
          child: Stack(
            children: [
              // Orb 1
              Positioned(
                top: -100 + 60 * _anim.value,
                left: -80 + 40 * _anim.value,
                child: _Orb(
                  color: AppColors.primary.withOpacity(0.15),
                  size: 340,
                ),
              ),
              // Orb 2
              Positioned(
                bottom: -80 + 40 * (1 - _anim.value),
                right: -60 + 30 * _anim.value,
                child: _Orb(
                  color: AppColors.accent.withOpacity(0.12),
                  size: 280,
                ),
              ),
              // Orb 3
              Positioned(
                top: MediaQuery.of(context).size.height * 0.4,
                left: MediaQuery.of(context).size.width * 0.2,
                child: _Orb(
                  color: AppColors.secondary.withOpacity(0.08),
                  size: 200,
                ),
              ),
              // Dot grid overlay
              CustomPaint(
                size: Size(
                  MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height,
                ),
                painter: _DotGridPainter(),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E3A5F).withOpacity(0.3)
      ..strokeWidth = 1;

    const spacing = 32.0;
    const dotRadius = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}