import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/scanner/scanner_screen.dart';
import '../../features/image_to_pdf/image_to_pdf_screen.dart';
import '../../features/merge_pdf/merge_pdf_screen.dart';
import '../../features/text_to_pdf/text_to_pdf_screen.dart';
import '../../features/compress_pdf/compress_pdf_screen.dart';
import '../../features/sign_document/sign_document_screen.dart';
import '../../features/id_photo/id_photo_screen.dart';
import '../../features/ocr/ocr_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/split_pdf/split_pdf_screen.dart';
import '../../features/watermark_pdf/watermark_pdf_screen.dart';
import '../../features/encrypt_pdf/encrypt_pdf_screen.dart';
import '../../features/pdf_to_image/pdf_to_image_screen.dart';
import '../../features/file_manager/file_manager_screen.dart';

import '../../features/pdf_viewer/pdf_viewer_screen.dart';
import '../../features/shell/app_shell.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  // Cache the router instance to prevent re-creation on every build
  static GoRouter? _cachedRouter;

  static GoRouter router({required bool isOnboardingComplete}) {
    _cachedRouter ??= GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: isOnboardingComplete ? '/' : '/onboarding',
      routes: [
        // Onboarding (full screen, no shell)
        GoRoute(
          path: '/onboarding',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const OnboardingScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),

        // App Shell with bottom nav
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const HomeScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            ),
            GoRoute(
              path: '/files',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const FileManagerScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const SettingsScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            ),
          ],
        ),

        // Full-screen feature routes
        GoRoute(
          path: '/scanner',
          pageBuilder: (context, state) => _slideTransition(
            state,
            const ScannerScreen(),
          ),
        ),
        GoRoute(
          path: '/image-to-pdf',
          pageBuilder: (context, state) => _slideTransition(
            state,
            const ImageToPdfScreen(),
          ),
        ),
        GoRoute(
          path: '/text-to-pdf',
          pageBuilder: (context, state) => _slideTransition(
            state,
            const TextToPdfScreen(),
          ),
        ),
        GoRoute(
          path: '/merge-pdf',
          pageBuilder: (context, state) => _slideTransition(
            state,
            const MergePdfScreen(),
          ),
        ),
        GoRoute(
          path: '/compress-pdf',
          pageBuilder: (context, state) => _slideTransition(
            state,
            const CompressPdfScreen(),
          ),
        ),
        GoRoute(
          path: '/split-pdf',
          pageBuilder: (context, state) => _slideTransition(
            state,
            const SplitPdfScreen(),
          ),
        ),
        GoRoute(
          path: '/watermark-pdf',
          pageBuilder: (context, state) => _slideTransition(
            state,
            const WatermarkPdfScreen(),
          ),
        ),
        GoRoute(
          path: '/encrypt-pdf',
          pageBuilder: (context, state) => _slideTransition(
            state,
            const EncryptPdfScreen(),
          ),
        ),
        GoRoute(
          path: '/pdf-to-image',
          pageBuilder: (context, state) => _slideTransition(
            state,
            const PdfToImageScreen(),
          ),
        ),
        GoRoute(
          path: '/sign-document',
          pageBuilder: (context, state) => _slideTransition(
            state,
            const SignDocumentScreen(),
          ),
        ),
        GoRoute(
          path: '/id-photo',
          pageBuilder: (context, state) => _slideTransition(
            state,
            const IdPhotoScreen(),
          ),
        ),
        GoRoute(
          path: '/ocr',
          pageBuilder: (context, state) => _slideTransition(
            state,
            const OcrScreen(),
          ),
        ),

        GoRoute(
          path: '/pdf-viewer',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return _slideTransition(
              state,
              PdfViewerScreen(
                filePath: extra?['filePath'] ?? '',
                title: extra?['title'] ?? 'PDF Viewer',
              ),
            );
          },
        ),
      ],
    );
    return _cachedRouter!;
  }

  static CustomTransitionPage _slideTransition(
      GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }
}
