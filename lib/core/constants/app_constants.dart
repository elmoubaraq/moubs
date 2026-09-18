/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Evergreen';
  static const String appVersion = '2.0.0';
  static const int appBuildNumber = 3;
  static const String packageName = 'com.moubscorps.evergreen';
  static const String privacyPolicyUrl = 'https://moubscorps.com/privacy';
  static const String termsOfServiceUrl = 'https://moubscorps.com/terms';
  static const String supportEmail = 'support@moubscorps.com';

  // Storage Keys
  static const String hiveBoxName = 'evergreen_box';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String themeKey = 'theme_mode';
  static const String premiumKey = 'is_premium';
  static const String languageKey = 'language';
  static const String recentFilesKey = 'recent_files';
  static const String totalProcessedKey = 'total_processed';

  // Ad Placement
  static const int interstitialFrequency =
      3; // Show interstitial every N exports
  static const int maxFreeExportsPerDay = 999999;

  // File limits
  static const int maxPdfSizeMB = 50;
  static const int maxImageSizeMB = 20;
  static const int maxMergeFiles = 20;
  static const int maxScanPages = 50;

  // OCR
  static const int ocrMaxImageDimension = 2048;

  // Premium features
  static const List<String> premiumFeatures = [
    'Remove all ads',
    'Batch processing',
    'Cloud sync',
    'Unlimited exports',
    'Priority support',
  ];
}
