/// Analytics event names for tracking user behavior
class AnalyticsEvents {
  AnalyticsEvents._();

  // Onboarding
  static const String onboardingStarted = 'onboarding_started';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String onboardingSkipped = 'onboarding_skipped';

  // Scanning
  static const String scanStarted = 'scan_started';
  static const String scanCompleted = 'scan_completed';
  static const String scanFailed = 'scan_failed';
  static const String scanPageAdded = 'scan_page_added';
  static const String scanPageRemoved = 'scan_page_removed';

  // PDF Operations
  static const String pdfCreated = 'pdf_created';
  static const String pdfMerged = 'pdf_merged';
  static const String pdfSplit = 'pdf_split';
  static const String pdfCompressed = 'pdf_compressed';
  static const String pdfSigned = 'pdf_signed';
  static const String pdfShared = 'pdf_shared';
  static const String pdfOpened = 'pdf_opened';
  static const String pdfDeleted = 'pdf_deleted';

  // Image Operations
  static const String imageToPdf = 'image_to_pdf';
  static const String imageCropped = 'image_cropped';
  static const String idPhotoCropped = 'id_photo_cropped';

  // OCR
  static const String ocrStarted = 'ocr_started';
  static const String ocrCompleted = 'ocr_completed';
  static const String ocrFailed = 'ocr_failed';
  static const String ocrTextCopied = 'ocr_text_copied';

  // Ads
  static const String adImpression = 'ad_impression';
  static const String adClicked = 'ad_clicked';
  static const String adFailed = 'ad_failed';
  static const String interstitialShown = 'interstitial_shown';
  static const String rewardedAdShown = 'rewarded_ad_shown';

  // Premium
  static const String premiumViewed = 'premium_viewed';
  static const String premiumPurchased = 'premium_purchased';
  static const String premiumRestored = 'premium_restored';

  // General
  static const String appOpened = 'app_opened';
  static const String fileExported = 'file_exported';
  static const String settingsOpened = 'settings_opened';
  static const String themeChanged = 'theme_changed';
  static const String languageChanged = 'language_changed';
  static const String feedbackSent = 'feedback_sent';
  static const String ratingPromptShown = 'rating_prompt_shown';
}
