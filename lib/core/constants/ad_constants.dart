/// AdMob configuration constants
class AdConstants {
  AdConstants._();

  // AdMob App ID (configured in AndroidManifest.xml)
  static const String appId = 'ca-app-pub-1534677402087236~2567030180';

  // Production Ad Unit IDs provided by user
  static const String rewardedId =
      'ca-app-pub-1534677402087236/1253948510';
  static const String rewardedInterstitialId =
      'ca-app-pub-1534677402087236/1253948510';
  static const String nativeAdvancedId =
      'ca-app-pub-1534677402087236/6006522250';

  // Active production ad unit getters
  static String get activeRewardedId => rewardedId;
  static String get activeRewardedInterstitialId => rewardedInterstitialId;
  static String get activeNativeId => nativeAdvancedId;
  static String get activeBannerId => nativeAdvancedId;
  static String get activeInterstitialId => rewardedId;
}
