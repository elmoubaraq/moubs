import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A reusable glassmorphism card widget.
/// Applies a frosted glass effect using [BackdropFilter].
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double blurSigma;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.backgroundColor,
    this.borderColor,
    this.blurSigma = 12,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor =
        backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.75));

    final border =
        borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.9));

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border, width: 1),
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      return Container(
        margin: margin,
        child: onTap != null
            ? GestureDetector(onTap: onTap, child: content)
            : content,
      );
    }

    return onTap != null
        ? GestureDetector(onTap: onTap, child: content)
        : content;
  }
}

/// A gradient card with a rich color background and optional icon.
class GradientCard extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    required this.gradient,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: boxShadow,
            ),
            child: child,
          ),
        ),
      ),
    );

    if (margin != null) {
      return Container(margin: margin, child: card);
    }
    return card;
  }
}

/// A subtle surface card with border and soft shadow.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? color;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = color ?? (isDark ? AppTheme.cardDark : AppTheme.cardLight);
    final borderCol = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    final card = Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderCol, width: 1),
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      return Container(margin: margin, child: card);
    }
    return card;
  }
}

/// A tool icon container with gradient background.
class ToolIconContainer extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final double size;
  final double iconSize;

  const ToolIconContainer({
    super.key,
    required this.icon,
    required this.gradient,
    this.size = 48,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: (gradient as LinearGradient).colors.first.withValues(
              alpha: 0.35,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}
