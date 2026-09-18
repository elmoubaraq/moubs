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
  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isInitialized = false;
  int _taskCompletionCount = 0;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;
    _preloadInterstitial();
    _preloadRewardedInterstitial();
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
    _taskCompletionCount++;
    if (_taskCompletionCount % 3 != 0) return false;
    return showInterstitial();
  }

  Future<bool> showInterstitial() async {
    if (_interstitialAd == null) return false;
    await _interstitialAd!.show();
    return true;
  }

  // ---- Rewarded Interstitial ----
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
              const Duration(seconds: 30), _preloadRewardedInterstitial);
        },
      ),
    );
  }

  Future<bool> showRewardedInterstitial({
    required Function(RewardItem reward) onRewarded,
  }) async {
    if (_rewardedInterstitialAd == null) return false;
    await _rewardedInterstitialAd!.show(
      onUserEarnedReward: (ad, reward) => onRewarded(reward),
    );
    return true;
  }

  // ---- Native Ad ----
  NativeAd createNativeAd({
    required Function(NativeAd) onLoaded,
    VoidCallback? onFailed,
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
        mainBackgroundColor: Colors.white,
        cornerRadius: 12,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF2E7D32),
          size: 14,
        ),
      ),
    )..load();
  }

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedInterstitialAd?.dispose();
  }
}
