import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AnimatedMeshBackground extends StatefulWidget {
  final List<Color> colors;
  final Widget child;

  const AnimatedMeshBackground({
    super.key,
    required this.child,
    this.colors = const [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.accentCyan,
    ],
  });

  @override
  State<AnimatedMeshBackground> createState() =>
      _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<AnimatedMeshBackground>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _animations;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.colors.length,
          (i) => AnimationController(
        vsync: this,
        duration: Duration(seconds: 8 + i * 3),
      )..repeat(reverse: true),
    );

    _animations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: Offset(
          _random.nextDouble() * 0.6,
          _random.nextDouble() * 0.6,
        ),
        end: Offset(
          _random.nextDouble() * 0.6 + 0.2,
          _random.nextDouble() * 0.6 + 0.2,
        ),
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base background
        Container(color: AppTheme.bgDark),
        // Animated blobs
        ...List.generate(widget.colors.length, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (context, child) {
              return Positioned.fill(
                child: Align(
                  alignment: Alignment(
                    (_animations[i].value.dx * 2) - 1,
                    (_animations[i].value.dy * 2) - 1,
                  ),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.colors[i].withOpacity(0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
        // Content
        widget.child,
      ],
    );
  }
}