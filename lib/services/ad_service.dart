/// Ad Service for Banner and Interstitial Ads
///
/// Handles Google Mobile Ads integration with banner and interstitial ads.
/// Uses test ad unit IDs for development and includes proper error handling.
// ignore_for_file: use_build_context_synchronously
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:developer' as developer;

/// Provider for the AdService (returns singleton instance)
final adServiceProvider = Provider<AdService>((ref) => AdService.instance);

enum BannerLoadState { idle, loading, loaded, failed }

class BannerSlotState {
  const BannerSlotState({
    required this.status,
    this.ad,
    this.lastError,
    this.adUnitId,
    this.attemptCount = 0,
  });

  final BannerLoadState status;
  final BannerAd? ad;
  final String? lastError;
  final String? adUnitId;
  final int attemptCount;

  const BannerSlotState.idle() : this(status: BannerLoadState.idle);

  BannerSlotState copyWith({
    BannerLoadState? status,
    BannerAd? ad,
    bool clearAd = false,
    String? lastError,
    bool clearLastError = false,
    String? adUnitId,
    int? attemptCount,
  }) {
    return BannerSlotState(
      status: status ?? this.status,
      ad: clearAd ? null : (ad ?? this.ad),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      adUnitId: adUnitId ?? this.adUnitId,
      attemptCount: attemptCount ?? this.attemptCount,
    );
  }
}

/// Ad service that handles banner and interstitial ads
class AdService {
  // Singleton pattern to ensure same instance is used everywhere
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Expose instance for direct access
  static AdService get instance => _instance;

  // ============================================================================
  // AD CONFIGURATION - UPDATE THESE FOR PRODUCTION
  // ============================================================================

  /// Enables test ad units in release when troubleshooting via --dart-define.
  static const bool _forceTestAdsInRelease =
      bool.fromEnvironment('FORCE_TEST_ADS', defaultValue: false);

  /// Enables ad diagnostics logs in release via --dart-define.
  static const bool _enableAdDiagnostics =
      bool.fromEnvironment('ENABLE_ADS_DIAGNOSTICS', defaultValue: false);

  /// Optional comma-separated iOS/Android test device IDs for ad requests.
  static const String _testDeviceIdsRaw =
      String.fromEnvironment('ADS_TEST_DEVICE_IDS', defaultValue: '');

  /// Debug/profile always use test IDs.
  /// Production IDs are used only in release builds unless forced for diagnostics.
  bool get _useTestAds => !kReleaseMode || _forceTestAdsInRelease;

  // Test Ad Unit IDs (Google's test IDs - safe for development)
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  // Production Ad Unit IDs from AdMob (AquaPulse)
  static const String _productionBannerTopAdUnitId =
      'ca-app-pub-9175122739049501/8207290201'; // AquaPulse Banner Top
  static const String _productionBannerBottomAdUnitId =
      'ca-app-pub-9175122739049501/1577760102'; // AquaPulse Banner Bottom
  static const String _productionInterstitialAdUnitId =
      'ca-app-pub-9175122739049501/7325453376'; // AquaPulse Interstitial

  // Get the appropriate ad unit IDs based on mode
  String get bannerTopAdUnitId =>
      _useTestAds ? _testBannerAdUnitId : _productionBannerTopAdUnitId;
  String get bannerBottomAdUnitId =>
      _useTestAds ? _testBannerAdUnitId : _productionBannerBottomAdUnitId;
  String get interstitialAdUnitId =>
      _useTestAds ? _testInterstitialAdUnitId : _productionInterstitialAdUnitId;
  // Legacy: defaults to top banner (for any other callers)
  String get bannerAdUnitId => bannerTopAdUnitId;

  static const String _intakeCountKey = 'water_intake_count_for_ads';
  static const int _intakeIntervalForAd = 3; // Show ad after every 3rd intake
  static const Duration _bannerInitialRetryDelay = Duration(seconds: 20);
  static const Duration _interstitialInitialRetryDelay = Duration(seconds: 30);
  static const Duration _maxRetryDelay = Duration(minutes: 10);
  static const Duration _noFillCooldownDuration = Duration(minutes: 10);
  static const int _noFillCooldownThreshold = 3;
  static const Duration _minLoadInterval = Duration(seconds: 3);

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  bool _isInterstitialLoading = false;
  int _interstitialFailureCount = 0;
  DateTime? _interstitialCooldownUntil;
  DateTime? _lastInterstitialLoadAttemptAt;
  Timer? _interstitialRetryTimer;
  final ValueNotifier<BannerSlotState> _topBannerState =
      ValueNotifier<BannerSlotState>(const BannerSlotState.idle());
  final ValueNotifier<BannerSlotState> _bottomBannerState =
      ValueNotifier<BannerSlotState>(const BannerSlotState.idle());
  int _topBannerFailureCount = 0;
  int _bottomBannerFailureCount = 0;
  DateTime? _topBannerCooldownUntil;
  DateTime? _bottomBannerCooldownUntil;
  DateTime? _topBannerLastLoadAttemptAt;
  DateTime? _bottomBannerLastLoadAttemptAt;
  bool _disableBannerAutoLoadForTesting = false;
  Timer? _topBannerRetryTimer;
  Timer? _bottomBannerRetryTimer;

  ValueListenable<BannerSlotState> get topBannerState => _topBannerState;
  ValueListenable<BannerSlotState> get bottomBannerState => _bottomBannerState;

  /// Initialize the ad service
  Future<void> initialize() async {
    try {
      final testDeviceIds = _parseTestDeviceIds(_testDeviceIdsRaw);
      if (testDeviceIds.isNotEmpty) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: testDeviceIds),
        );
        _logAd('Init', 'configured test device IDs (${testDeviceIds.length})');
      }

      // Initialize with test application ID
      await MobileAds.instance.initialize();
      _logAd('Init',
          'initialized successfully (mode: ${_useTestAds ? 'TEST' : 'PRODUCTION'})');
      _loadInterstitialAd(trigger: 'initialize');
    } catch (e) {
      _logAd('Init', 'initialization failed: $e');
      // Don't throw - ads are not critical for app functionality
    }
  }

  /// Load interstitial ad
  Future<void> _loadInterstitialAd({String trigger = 'auto'}) async {
    try {
      final now = DateTime.now();
      if (_isInterstitialLoading) {
        _logAd('Interstitial', 'skip load (already loading) trigger=$trigger');
        return;
      }
      if (_interstitialAd != null && _isInterstitialAdReady) {
        _logAd('Interstitial', 'skip load (already ready) trigger=$trigger');
        return;
      }
      if (_interstitialCooldownUntil != null &&
          now.isBefore(_interstitialCooldownUntil!)) {
        _logAd(
          'Interstitial',
          'skip load (cooldown until ${_interstitialCooldownUntil!.toIso8601String()}) trigger=$trigger',
        );
        return;
      }
      if (_lastInterstitialLoadAttemptAt != null &&
          now.difference(_lastInterstitialLoadAttemptAt!) < _minLoadInterval) {
        _logAd('Interstitial', 'skip load (throttled) trigger=$trigger');
        return;
      }

      _lastInterstitialLoadAttemptAt = now;
      _isInterstitialLoading = true;
      _logAd(
        'Interstitial',
        'loading start trigger=$trigger mode=${_useTestAds ? 'TEST' : 'PRODUCTION'} unitId=$interstitialAdUnitId',
      );
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialRetryTimer?.cancel();
            _interstitialAd = ad;
            _isInterstitialAdReady = true;
            _isInterstitialLoading = false;
            _interstitialFailureCount = 0;
            _interstitialCooldownUntil = null;
            _logAd('Interstitial', 'loaded successfully');

            // Set full screen content callback
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint(
                    'Interstitial Ad: User dismissed ad, loading next one...');
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialAdReady = false;
                _loadInterstitialAd(trigger: 'dismissed'); // Load next ad
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                _logAd('Interstitial', 'failed to show: $error');
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialAdReady = false;
                _loadInterstitialAd(trigger: 'failed_to_show'); // Try loading again
              },
              onAdShowedFullScreenContent: (ad) {
                _logAd('Interstitial', 'ad is now showing');
              },
            );
          },
          onAdFailedToLoad: (error) {
            _isInterstitialLoading = false;
            _isInterstitialAdReady = false;
            _interstitialFailureCount++;
            _logAd(
              'Interstitial',
              'failed code=${error.code} domain=${error.domain} message=${error.message} failures=$_interstitialFailureCount',
            );
            _scheduleInterstitialRetry(error.code);
          },
        ),
      );
    } catch (e) {
      _logAd('Interstitial', 'exception loading ad: $e');
      _isInterstitialLoading = false;
      _isInterstitialAdReady = false;
    }
  }

  /// Show interstitial ad after water intake (if conditions are met)
  Future<void> showInterstitialAdAfterIntake(BuildContext? context) async {
    try {
      // Get current intake count
      final prefs = await SharedPreferences.getInstance();
      int intakeCount = prefs.getInt(_intakeCountKey) ?? 0;
      intakeCount++;

      debugPrint(
          'Interstitial Ad Check: Intake count = $intakeCount, Ready = $_isInterstitialAdReady, Ad exists = ${_interstitialAd != null}');

      // Save updated count
      await prefs.setInt(_intakeCountKey, intakeCount);

      // Show ad if it's the 3rd intake (or multiple of 3)
      if (intakeCount % _intakeIntervalForAd == 0) {
        debugPrint(
            'Interstitial Ad: Intake count is a multiple of $_intakeIntervalForAd');

        // If ad is not ready, try to load it and wait
        if (!_isInterstitialAdReady || _interstitialAd == null) {
          _logAd('Interstitial', 'not ready, attempting load');
          _loadInterstitialAd(trigger: 'intake_threshold');

          // Wait up to 5 seconds for the ad to load
          int attempts = 0;
          while ((!_isInterstitialAdReady || _interstitialAd == null) &&
              attempts < 10) {
            await Future.delayed(const Duration(milliseconds: 500));
            attempts++;
            _logAd('Interstitial', 'waiting for load attempt $attempts/10');
          }
        }

        // Show ad if it's ready
        if (_isInterstitialAdReady && _interstitialAd != null) {
          _logAd('Interstitial', 'ad ready, showing now');

          // Mark as not ready to prevent double-showing
          // The callback will handle reloading after dismissal
          _isInterstitialAdReady = false;

          // Add a small delay to ensure UI is ready and any animations complete
          await Future.delayed(const Duration(milliseconds: 500));

          // Show the ad - ensure we still have a valid reference
          if (_interstitialAd != null) {
            try {
              _logAd('Interstitial', 'calling show()');
              _interstitialAd!.show();
              _logAd('Interstitial', 'show() called successfully');
            } catch (showError, stackTrace) {
              _logAd('Interstitial', 'error calling show(): $showError');
              _logAd('Interstitial', 'stack trace: $stackTrace');
              // Dispose the ad and try to reload for next time
              _interstitialAd?.dispose();
              _interstitialAd = null;
              _isInterstitialAdReady = false;
              _loadInterstitialAd(trigger: 'show_exception');
            }
          } else {
            _logAd('Interstitial', 'ad became null before showing');
            _isInterstitialAdReady = false;
            _loadInterstitialAd(trigger: 'ad_became_null');
          }
        } else {
          _logAd(
            'Interstitial',
            'ad still not ready after waiting. ready=$_isInterstitialAdReady exists=${_interstitialAd != null}',
          );
          // Keep trying for next natural opportunity, but avoid duplicate active loads.
          _loadInterstitialAd(trigger: 'not_ready_after_wait');
        }
      } else {
        debugPrint(
            'Interstitial Ad: Not showing (count $intakeCount is not a multiple of $_intakeIntervalForAd)');
      }
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
    }
  }

  /// Show a helpful instruction before the ad appears
  Future<void> _showCloseButtonInstruction(BuildContext context) async {
    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          // Auto-dismiss after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          });

          return PopScope(
            canPop: false,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF2196F3),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ad will appear',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.close,
                          color: Colors.black54,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Look for the close button (X) in the top-right corner',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing close button instruction: $e');
    }
  }

  /// Loads a dashboard banner if needed.
  /// [isBottom] true = bottom banner, false = top banner.
  void ensureBannerLoaded({bool isBottom = false}) {
    if (_disableBannerAutoLoadForTesting) return;

    final state = _getBannerNotifier(isBottom);
    final current = state.value.status;
    if (current == BannerLoadState.loading || current == BannerLoadState.loaded) {
      return;
    }

    final now = DateTime.now();
    final cooldownUntil = _getBannerCooldown(isBottom);
    if (cooldownUntil != null && now.isBefore(cooldownUntil)) {
      debugPrint(
          'Banner Ad [${isBottom ? 'bottom' : 'top'}]: skip load (cooldown until ${cooldownUntil.toIso8601String()})');
      return;
    }
    final lastAttempt = _getBannerLastAttempt(isBottom);
    if (lastAttempt != null && now.difference(lastAttempt) < _minLoadInterval) {
      debugPrint(
          'Banner Ad [${isBottom ? 'bottom' : 'top'}]: skip load (throttled)');
      return;
    }
    _setBannerLastAttempt(isBottom, now);

    final adUnitId = isBottom ? bannerBottomAdUnitId : bannerTopAdUnitId;
    final placement = isBottom ? 'bottom' : 'top';
    final platform = defaultTargetPlatform.name;
    _cancelBannerRetry(isBottom);
    state.value = state.value.copyWith(
      status: BannerLoadState.loading,
      clearAd: true,
      clearLastError: true,
      adUnitId: adUnitId,
      attemptCount: state.value.attemptCount + 1,
    );
    debugPrint(
        'Banner Ad [$placement/$platform]: loading with unitId=$adUnitId mode=${_useTestAds ? 'TEST' : 'PRODUCTION'}');

    final ad = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loadedAd) {
          _setBannerFailureCount(isBottom, 0);
          _setBannerCooldown(isBottom, null);
          state.value = BannerSlotState(
            status: BannerLoadState.loaded,
            ad: loadedAd as BannerAd,
            adUnitId: adUnitId,
            attemptCount: state.value.attemptCount,
          );
          debugPrint('Banner Ad [$placement/$platform]: loaded successfully');
        },
        onAdFailedToLoad: (failedAd, error) {
          debugPrint(
              'Banner Ad [$placement/$platform]: failed code=${error.code} domain=${error.domain} message=${error.message} unitId=$adUnitId');
          failedAd.dispose();
          state.value = state.value.copyWith(
            status: BannerLoadState.failed,
            clearAd: true,
            lastError:
                'code=${error.code}; domain=${error.domain}; message=${error.message}',
            adUnitId: adUnitId,
          );
          _setBannerFailureCount(
              isBottom, _getBannerFailureCount(isBottom) + 1);
          _scheduleBannerRetry(isBottom, error.code);
        },
      ),
    );

    state.value.ad?.dispose();
    state.value = state.value.copyWith(clearAd: true);
    ad.load();
  }

  void _scheduleBannerRetry(bool isBottom, int errorCode) {
    if (_disableBannerAutoLoadForTesting) return;
    _cancelBannerRetry(isBottom);
    final placement = isBottom ? 'bottom' : 'top';
    final failureCount = _getBannerFailureCount(isBottom);
    final now = DateTime.now();
    Duration delay;
    if (errorCode == 1 && failureCount >= _noFillCooldownThreshold) {
      final cooldownUntil = now.add(_noFillCooldownDuration);
      _setBannerCooldown(isBottom, cooldownUntil);
      delay = _noFillCooldownDuration;
      debugPrint(
          'Banner Ad [$placement]: entering no-fill cooldown for ${delay.inMinutes}m');
    } else {
      _setBannerCooldown(isBottom, null);
      delay = _nextRetryDelay(
        failureCount: failureCount,
        initial: _bannerInitialRetryDelay,
      );
    }
    final retryTimer = Timer(
      delay,
      () {
        debugPrint('Banner Ad [$placement]: retrying load after failure');
        ensureBannerLoaded(isBottom: isBottom);
      },
    );
    if (isBottom) {
      _bottomBannerRetryTimer = retryTimer;
    } else {
      _topBannerRetryTimer = retryTimer;
    }
  }

  void _cancelBannerRetry(bool isBottom) {
    if (isBottom) {
      _bottomBannerRetryTimer?.cancel();
      _bottomBannerRetryTimer = null;
      return;
    }
    _topBannerRetryTimer?.cancel();
    _topBannerRetryTimer = null;
  }

  int _getBannerFailureCount(bool isBottom) =>
      isBottom ? _bottomBannerFailureCount : _topBannerFailureCount;

  void _setBannerFailureCount(bool isBottom, int value) {
    if (isBottom) {
      _bottomBannerFailureCount = value;
    } else {
      _topBannerFailureCount = value;
    }
  }

  DateTime? _getBannerCooldown(bool isBottom) =>
      isBottom ? _bottomBannerCooldownUntil : _topBannerCooldownUntil;

  void _setBannerCooldown(bool isBottom, DateTime? value) {
    if (isBottom) {
      _bottomBannerCooldownUntil = value;
    } else {
      _topBannerCooldownUntil = value;
    }
  }

  DateTime? _getBannerLastAttempt(bool isBottom) =>
      isBottom ? _bottomBannerLastLoadAttemptAt : _topBannerLastLoadAttemptAt;

  void _setBannerLastAttempt(bool isBottom, DateTime value) {
    if (isBottom) {
      _bottomBannerLastLoadAttemptAt = value;
    } else {
      _topBannerLastLoadAttemptAt = value;
    }
  }

  Duration _nextRetryDelay({
    required int failureCount,
    required Duration initial,
  }) {
    final exponent = (failureCount - 1).clamp(0, 10);
    final candidate = initial * (1 << exponent);
    return candidate > _maxRetryDelay ? _maxRetryDelay : candidate;
  }

  void _scheduleInterstitialRetry(int errorCode) {
    _interstitialRetryTimer?.cancel();
    Duration delay;
    if (errorCode == 1 && _interstitialFailureCount >= _noFillCooldownThreshold) {
      _interstitialCooldownUntil = DateTime.now().add(_noFillCooldownDuration);
      delay = _noFillCooldownDuration;
      _logAd(
        'Interstitial',
        'entering no-fill cooldown for ${delay.inMinutes}m',
      );
    } else {
      _interstitialCooldownUntil = null;
      delay = _nextRetryDelay(
        failureCount: _interstitialFailureCount,
        initial: _interstitialInitialRetryDelay,
      );
    }

    _interstitialRetryTimer = Timer(delay, () {
      _logAd('Interstitial', 'retrying load after ${delay.inSeconds}s');
      _loadInterstitialAd(trigger: 'scheduled_retry');
    });
  }

  void _logAd(String scope, String message) {
    if (!_enableAdDiagnostics && kReleaseMode) return;
    final mode = _useTestAds ? 'TEST' : 'PRODUCTION';
    developer.log(
      'Ad[$scope][$mode]: $message',
      name: 'AdService',
    );
  }

  List<String> _parseTestDeviceIds(String raw) {
    if (raw.trim().isEmpty) return const <String>[];
    return raw
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  ValueNotifier<BannerSlotState> _getBannerNotifier(bool isBottom) {
    return isBottom ? _bottomBannerState : _topBannerState;
  }

  @visibleForTesting
  void debugSetBannerState({
    required bool isBottom,
    required BannerLoadState status,
  }) {
    _getBannerNotifier(isBottom).value =
        BannerSlotState(status: status, ad: null, attemptCount: 1);
  }

  @visibleForTesting
  void debugDisableBannerAutoLoad(bool disable) {
    _disableBannerAutoLoadForTesting = disable;
  }

  @visibleForTesting
  void debugResetBannerStates() {
    _cancelBannerRetry(false);
    _cancelBannerRetry(true);
    _topBannerState.value = const BannerSlotState.idle();
    _bottomBannerState.value = const BannerSlotState.idle();
    _topBannerFailureCount = 0;
    _bottomBannerFailureCount = 0;
    _topBannerCooldownUntil = null;
    _bottomBannerCooldownUntil = null;
    _topBannerLastLoadAttemptAt = null;
    _bottomBannerLastLoadAttemptAt = null;
    _disableBannerAutoLoadForTesting = false;
  }

  /// Get the current status of the interstitial ad (for debugging)
  Future<Map<String, dynamic>> getInterstitialAdStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final intakeCount = prefs.getInt(_intakeCountKey) ?? 0;
    return {
      'isReady': _isInterstitialAdReady,
      'adExists': _interstitialAd != null,
      'adUnitId': interstitialAdUnitId,
      'intakeCount': intakeCount,
      'nextAdAt':
          ((intakeCount ~/ _intakeIntervalForAd) + 1) * _intakeIntervalForAd,
    };
  }

  /// Manually trigger interstitial ad (for testing)
  Future<void> showInterstitialAdForTesting(BuildContext? context) async {
    try {
      debugPrint('Interstitial Ad Test: Manually triggering ad...');
      debugPrint(
          'Interstitial Ad Test: Ready = $_isInterstitialAdReady, Ad exists = ${_interstitialAd != null}');

      if (_isInterstitialAdReady && _interstitialAd != null) {
        debugPrint('Interstitial Ad Test: Showing ad now');

        // Show instruction dialog before the ad
        if (context != null) {
          await _showCloseButtonInstruction(context);
          await Future.delayed(const Duration(milliseconds: 300));
        }

        _interstitialAd!.show();
        _isInterstitialAdReady = false;
      } else {
        debugPrint('Interstitial Ad Test: Ad not ready. Attempting to load...');
        await _loadInterstitialAd();
        // Wait a bit for the ad to load
        await Future.delayed(const Duration(seconds: 2));
        if (_isInterstitialAdReady && _interstitialAd != null) {
          debugPrint('Interstitial Ad Test: Ad loaded, showing now');
          if (context != null) {
            await _showCloseButtonInstruction(context);
            await Future.delayed(const Duration(milliseconds: 300));
          }
          _interstitialAd!.show();
          _isInterstitialAdReady = false;
        } else {
          debugPrint(
              'Interstitial Ad Test: Still not ready after loading attempt');
        }
      }
    } catch (e) {
      debugPrint('Error in showInterstitialAdForTesting: $e');
    }
  }

  /// Reset the intake count (for testing)
  Future<void> resetIntakeCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_intakeCountKey);
    debugPrint('Interstitial Ad: Intake count reset');
  }

  /// Dispose any resources
  void dispose() {
    _interstitialRetryTimer?.cancel();
    _cancelBannerRetry(false);
    _cancelBannerRetry(true);
    _topBannerState.value.ad?.dispose();
    _bottomBannerState.value.ad?.dispose();
    _interstitialAd?.dispose();
    _isInterstitialAdReady = false;
  }
}
