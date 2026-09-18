/// Analytics service abstraction (pluggable - Firebase, Mixpanel, etc.)
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  bool _isEnabled = true;

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Log a simple event
  void logEvent(String name, [Map<String, dynamic>? params]) {
    if (!_isEnabled) return;
    // TODO: Connect to Firebase Analytics or another provider
    // FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
    _debugLog('EVENT: $name ${params ?? ''}');
  }

  /// Log screen view
  void logScreenView(String screenName) {
    if (!_isEnabled) return;
    logEvent('screen_view', {'screen_name': screenName});
  }

  /// Set user property
  void setUserProperty(String name, String value) {
    if (!_isEnabled) return;
    _debugLog('USER_PROP: $name = $value');
  }

  /// Log error
  void logError(String error, {StackTrace? stackTrace}) {
    _debugLog('ERROR: $error');
    // TODO: Connect to Crashlytics
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  void _debugLog(String message) {
    assert(() {
      // ignore: avoid_print
      print('[Analytics] $message');
      return true;
    }());
  }
}
