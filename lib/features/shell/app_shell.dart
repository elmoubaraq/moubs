import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

/// Premium App Shell with frosted glass bottom navigation
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path == '/') return 0;
    if (path == '/files') return 1;
    if (path == '/settings') return 2;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    switch (index) {
      case 0: context.go('/');
      case 1: context.go('/files');
      case 2: context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: _BottomNav(
        selectedIndex: selectedIndex,
        isDark: isDark,
        onTap: (i) => _onTap(context, i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.isDark,
    required this.onTap,
  });

  static const _items = [
    _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
    _NavItem(Icons.folder_rounded, Icons.folder_outlined, 'Files'),
    _NavItem(Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.cardDark.withValues(alpha: 0.85)
                : AppTheme.cardLight.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (i) {
                  final item = _items[i];
                  final selected = i == selectedIndex;
                  return _NavButton(
                    item: item,
                    selected: selected,
                    isDark: isDark,
                    onTap: () => onTap(i),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _pillAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnim = Tween<double>(begin: 1, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _pillAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    if (widget.selected) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _NavButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _controller.forward();
    } else if (!widget.selected && oldWidget.selected) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isDark ? AppTheme.primaryLight : AppTheme.primary;
    final inactiveColor = widget.isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  children: [
                    // Indicator pill
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: widget.selected ? 36 : 0,
                      height: 3,
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Icon with animated background
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 32,
                      decoration: BoxDecoration(
                        color: widget.selected
                            ? activeColor.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.selected ? widget.item.activeIcon : widget.item.icon,
                        size: 22,
                        color: widget.selected ? activeColor : inactiveColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Label
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                        color: widget.selected ? activeColor : inactiveColor,
                        fontFamily: 'PlusJakartaSans',
                      ),
                      child: Text(widget.item.label),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;

  const _NavItem(this.activeIcon, this.icon, this.label);
}
