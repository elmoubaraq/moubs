/// AdMob configuration constants
class AdConstants {
  AdConstants._();

  // AdMob App ID (configured in AndroidManifest.xml)
  static const String appId = 'ca-app-pub-1534677402087236~2567030180';

  // Ad Unit IDs
  static const String rewardedInterstitialId =
      'ca-app-pub-1534677402087236/1253948510';
  static const String nativeAdvancedId =
      'ca-app-pub-1534677402087236/6006522250';

  // Banner Ad ID (using test ID for now, replace with real one)
  static const String bannerId =
      'ca-app-pub-1534677402087236/6006522250'; // Use native as banner fallback

  // Test IDs for development
  static const String testBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedInterstitialId =
      'ca-app-pub-3940256099942544/5354046379';
  static const String testNativeId =
      'ca-app-pub-3940256099942544/2247696110';

  // Use test ads in debug mode
  static bool get useTestAds {
    assert(() {
      return true;
    }());
    // In release mode, this will be false
    bool isDebug = false;
    assert(() {
      isDebug = true;
      return true;
    }());
    return isDebug;
  }

  static String get activeBannerId =>
      useTestAds ? testBannerId : bannerId;
  static String get activeInterstitialId =>
      useTestAds ? testInterstitialId : rewardedInterstitialId;
  static String get activeRewardedInterstitialId =>
      useTestAds ? testRewardedInterstitialId : rewardedInterstitialId;
  static String get activeNativeId =>
      useTestAds ? testNativeId : nativeAdvancedId;
}
