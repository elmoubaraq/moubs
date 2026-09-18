/// Remote config keys for feature flags and A/B testing
class RemoteConfigKeys {
  RemoteConfigKeys._();

  // Feature Flags
  static const String enableCloudSync = 'enable_cloud_sync';
  static const String enableWatermark = 'enable_watermark';
  static const String enableBatchProcessing = 'enable_batch_processing';
  static const String enableSmartEdgeCleanup = 'enable_smart_edge_cleanup';
  static const String enableFormFiller = 'enable_form_filler';
  static const String enableDocumentFolders = 'enable_document_folders';

  // Ad Controls
  static const String interstitialFrequency = 'interstitial_frequency';
  static const String showBannerInResults = 'show_banner_in_results';
  static const String enableRewardedAds = 'enable_rewarded_ads';

  // Limits
  static const String maxFreeExports = 'max_free_exports';
  static const String maxScanPages = 'max_scan_pages';
  static const String maxFileSizeMb = 'max_file_size_mb';

  // Premium
  static const String premiumMonthlyPrice = 'premium_monthly_price';
  static const String premiumYearlyPrice = 'premium_yearly_price';
  static const String showPremiumBanner = 'show_premium_banner';

  // Defaults
  static const Map<String, dynamic> defaults = {
    enableCloudSync: false,
    enableWatermark: false,
    enableBatchProcessing: false,
    enableSmartEdgeCleanup: false,
    enableFormFiller: false,
    enableDocumentFolders: false,
    interstitialFrequency: 3,
    showBannerInResults: true,
    enableRewardedAds: true,
    maxFreeExports: 10,
    maxScanPages: 50,
    maxFileSizeMb: 50,
    premiumMonthlyPrice: '\$4.99',
    premiumYearlyPrice: '\$29.99',
    showPremiumBanner: true,
  };
}
