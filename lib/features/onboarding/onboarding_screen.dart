import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _bgAnimController;
  late Animation<double> _bgAnim;

  static const _pages = [
    _OnboardPage(
      title: 'Scan Anything,\nAnywhere',
      subtitle: 'Capture documents with your camera. Smart edge detection and auto-enhancement make every scan crystal clear.',
      icon: Icons.document_scanner_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF047857), Color(0xFF059669), Color(0xFF0891B2)],
        stops: [0.0, 0.5, 1.0],
      ),
      accentColor: Color(0xFF34D399),
      emoji: '📄',
    ),
    _OnboardPage(
      title: 'PDF Powerhouse\nat Your Fingertips',
      subtitle: 'Merge, split, compress, encrypt and watermark PDFs instantly. Everything you need, nothing you don\'t.',
      icon: Icons.picture_as_pdf_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF8B5CF6)],
        stops: [0.0, 0.5, 1.0],
      ),
      accentColor: Color(0xFF818CF8),
      emoji: '⚡',
    ),
    _OnboardPage(
      title: 'Sign & Share\nin Seconds',
      subtitle: 'Draw your signature directly on documents. Share instantly via email, WhatsApp, or save to your device.',
      icon: Icons.draw_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0E7490), Color(0xFF0891B2), Color(0xFF06B6D4)],
        stops: [0.0, 0.5, 1.0],
      ),
      accentColor: Color(0xFF22D3EE),
      emoji: '✍️',
    ),
    _OnboardPage(
      title: 'Smart OCR\nText Extraction',
      subtitle: 'Extract text from any image or scanned document with AI-powered accuracy. Copy, edit, and export in one tap.',
      icon: Icons.auto_awesome_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7C3AED), Color(0xFFA855F7), Color(0xFFEC4899)],
        stops: [0.0, 0.5, 1.0],
      ),
      accentColor: Color(0xFFF0ABFC),
      emoji: '🔍',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgAnimController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _complete();
    }
  }

  void _skip() {
    HapticFeedback.lightImpact();
    _complete();
  }

  Future<void> _complete() async {
    // Use StorageService (Hive) consistently
    final storage = StorageService();
    await storage.setOnboardingComplete();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(gradient: page.gradient),
          child: SafeArea(
            child: Column(
              children: [
                // ── Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _currentPage < _pages.length - 1
                        ? TextButton(
                            onPressed: _skip,
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ).animate().fadeIn(delay: 300.ms)
                        : const SizedBox(height: 44),
                  ),
                ),

                // ── Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _PageContent(page: _pages[index], bgAnim: _bgAnim);
                    },
                  ),
                ),

                // ── Bottom controls
                _BottomControls(
                  currentPage: _currentPage,
                  pageCount: _pages.length,
                  accentColor: page.accentColor,
                  isLast: _currentPage == _pages.length - 1,
                  onNext: _nextPage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardPage page;
  final Animation<double> bgAnim;

  const _PageContent({required this.page, required this.bgAnim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated floating icon
          AnimatedBuilder(
            animation: bgAnim,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -8 + bgAnim.value * 16),
                child: child,
              );
            },
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(page.icon, size: 64, color: Colors.white),
                    const SizedBox(height: 4),
                    Text(page.emoji, style: const TextStyle(fontSize: 28)),
                  ],
                ),
              ),
            ),
          ).animate(key: ValueKey(page.title))
              .scale(begin: const Offset(0.6, 0.6), duration: 700.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ).animate(key: ValueKey('t${page.title}'))
              .fadeIn(delay: 150.ms, duration: 500.ms)
              .slideY(begin: 0.3, end: 0, delay: 150.ms, duration: 500.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.80),
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ).animate(key: ValueKey('s${page.title}'))
              .fadeIn(delay: 250.ms, duration: 500.ms)
              .slideY(begin: 0.3, end: 0, delay: 250.ms, duration: 500.ms, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final Color accentColor;
  final bool isLast;
  final VoidCallback onNext;

  const _BottomControls({
    required this.currentPage,
    required this.pageCount,
    required this.accentColor,
    required this.isLast,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pageCount, (i) {
              final active = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),

          // Next / Get Started button
          SizedBox(
            width: double.infinity,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onNext,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLast ? 'Get Started' : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                          color: const Color(0xFF111827),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Color accentColor;
  final String emoji;

  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.emoji,
  });
}
