import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/ad_constants.dart';

/// Centralized ad management service
class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isInitialized = false;
  int _taskCompletionCount = 0;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _preloadInterstitial();
      _preloadRewarded();
      _preloadRewardedInterstitial();
    } catch (e) {
      debugPrint('AdService initialization failed: $e');
    }
  }

  // ---- Banner Ad ----
  BannerAd createBannerAd({
    AdSize size = AdSize.banner,
    VoidCallback? onLoaded,
    VoidCallback? onFailed,
  }) {
    return BannerAd(
      adUnitId: AdConstants.activeBannerId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded?.call(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed?.call();
          debugPrint('Banner ad failed: ${error.message}');
        },
      ),
    )..load();
  }

  // ---- Interstitial Ad ----
  void _preloadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdConstants.activeInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _preloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _preloadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: ${error.message}');
          Future.delayed(const Duration(seconds: 30), _preloadInterstitial);
        },
      ),
    );
  }

  Future<bool> showInterstitialAfterTask() async {
    try {
      _taskCompletionCount++;
      if (_taskCompletionCount % 3 != 0) return false;
      return await showInterstitial().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> showInterstitial() async {
    try {
      if (_interstitialAd != null) {
        await _interstitialAd!.show();
        return true;
      }
      if (_rewardedInterstitialAd != null) {
        await _rewardedInterstitialAd!.show(onUserEarnedReward: (_, __) {});
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ---- Standard Rewarded Ad ----
  void _preloadRewarded() {
    RewardedAd.load(
      adUnitId: AdConstants.activeRewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _preloadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _preloadRewarded();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: ${error.message}');
          Future.delayed(const Duration(seconds: 30), _preloadRewarded);
        },
      ),
    );
  }

  // ---- Rewarded Interstitial Ad ----
  void _preloadRewardedInterstitial() {
    RewardedInterstitialAd.load(
      adUnitId: AdConstants.activeRewardedInterstitialId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedInterstitialAd = null;
              _preloadRewardedInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedInterstitialAd = null;
              _preloadRewardedInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded interstitial failed: ${error.message}');
          Future.delayed(
            const Duration(seconds: 30),
            _preloadRewardedInterstitial,
          );
        },
      ),
    );
  }

  /// Show a rewarded ad (either standard rewarded or rewarded interstitial).
  /// Calls [onRewarded] when the user earns the reward.
  Future<bool> showRewardedAd({
    required Function(RewardItem reward) onRewarded,
    VoidCallback? onDismissed,
  }) async {
    // 1. Try standard RewardedAd
    if (_rewardedAd != null) {
      final ad = _rewardedAd!;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _preloadRewarded();
          onDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          _preloadRewarded();
          onDismissed?.call();
        },
      );
      await ad.show(
        onUserEarnedReward: (ad, reward) => onRewarded(reward),
      );
      return true;
    }

    // 2. Try RewardedInterstitialAd
    if (_rewardedInterstitialAd != null) {
      final ad = _rewardedInterstitialAd!;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedInterstitialAd = null;
          _preloadRewardedInterstitial();
          onDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedInterstitialAd = null;
          _preloadRewardedInterstitial();
          onDismissed?.call();
        },
      );
      await ad.show(
        onUserEarnedReward: (ad, reward) => onRewarded(reward),
      );
      return true;
    }

    // 3. Fallback: Show interstitial if available so user is rewarded
    if (_interstitialAd != null) {
      await showInterstitial();
      onRewarded(RewardItem(1, 'fallback_reward'));
      onDismissed?.call();
      return true;
    }

    // If no ad is ready yet, grant reward so user flow is not broken
    onRewarded(RewardItem(1, 'immediate_reward'));
    onDismissed?.call();
    return false;
  }

  Future<bool> showRewardedInterstitial({
    required Function(RewardItem reward) onRewarded,
  }) async {
    return showRewardedAd(onRewarded: onRewarded);
  }

  // ---- Native Ad ----
  NativeAd createNativeAd({
    required Function(NativeAd) onLoaded,
    VoidCallback? onFailed,
    bool isDark = true,
  }) {
    return NativeAd(
      adUnitId: AdConstants.activeNativeId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) => onLoaded(ad as NativeAd),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed?.call();
          debugPrint('Native ad failed: ${error.message}');
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        cornerRadius: 16,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF059669),
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? Colors.white : const Color(0xFF111827),
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          size: 12,
        ),
      ),
    )..load();
  }

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _rewardedInterstitialAd?.dispose();
  }
}
