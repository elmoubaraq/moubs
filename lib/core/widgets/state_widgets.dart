import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Beautiful animated empty state widget
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon container
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: isDark ? 0.12 : 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: isDark ? 0.2 : 0.15),
                width: 1.5,
              ),
            ),
            child: Icon(icon, size: 44, color: AppTheme.primary.withValues(alpha: 0.6)),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0), duration: 2.seconds),

          const SizedBox(height: 24),

          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

          const SizedBox(height: 8),

          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(actionLabel!),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms)
                .scale(begin: const Offset(0.9, 0.9), delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
          ],
        ],
      ),
    );
  }
}

/// Error state widget with retry
class ErrorStateWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, size: 36, color: AppTheme.error),
          ).animate().shake(duration: 500.ms, delay: 100.ms),

          const SizedBox(height: 20),

          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),

          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],

          if (onRetry != null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen processing overlay with animated ring
class ProcessingOverlay extends StatelessWidget {
  final String message;
  final double? progress;
  final LinearGradient? gradient;

  const ProcessingOverlay({
    super.key,
    this.message = 'Processing...',
    this.progress,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: progress != null
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 5,
                            backgroundColor: AppTheme.borderLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                          ),
                          Text(
                            '${(progress! * 100).toInt()}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(
                        strokeWidth: 5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      ),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

              const SizedBox(height: 20),

              Text(
                message,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 8),

              Text(
                'Please wait...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
