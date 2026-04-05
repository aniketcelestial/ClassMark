import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AnimatedMeshBackground extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.bgDark,
            colors.first.withOpacity(0.15),
            AppTheme.bgDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}