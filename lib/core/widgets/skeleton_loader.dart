import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loader for document list items
class SkeletonLoader extends StatelessWidget {
  final int itemCount;

  const SkeletonLoader({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          highlightColor: isDark
              ? const Color(0xFF3D3D3D)
              : const Color(0xFFF5F5F5),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for tool cards on home screen
class ToolCardSkeleton extends StatelessWidget {
  const ToolCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
      highlightColor: isDark
          ? const Color(0xFF3D3D3D)
          : const Color(0xFFF5F5F5),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
