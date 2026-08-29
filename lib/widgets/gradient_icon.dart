import 'package:flutter/material.dart';

class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Gradient gradient;
  final double? fill;

  const GradientIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.gradient = _defaultGradient,
    this.fill,
  });

  static const Gradient _defaultGradient = LinearGradient(
    colors: [Color(0xFF6D5DF6), Color(0xFFB15CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Icon(icon, size: size, color: Colors.white, fill: fill),
    );
  }
}

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final TextAlign textAlign;

  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient = _defaultGradient,
    this.textAlign = TextAlign.center,
  });

  static const Gradient _defaultGradient = LinearGradient(
    colors: [Color(0xFF6D5DF6), Color(0xFFB15CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style?.copyWith(color: Colors.white), textAlign: textAlign),
    );
  }
}

class GradientContainer extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const GradientContainer({
    super.key,
    required this.child,
    this.gradient = _defaultGradient,
    this.borderRadius = 16,
    this.padding = EdgeInsets.zero,
  });

  static const Gradient _defaultGradient = LinearGradient(
    colors: [Color(0xFF6D5DF6), Color(0xFFB15CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}
