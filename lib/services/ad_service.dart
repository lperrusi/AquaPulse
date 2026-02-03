/// Ad Service for Banner and Interstitial Ads
///
/// Handles Google Mobile Ads integration with banner and interstitial ads.
/// Uses test ad unit IDs for development and includes proper error handling.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the AdService (returns singleton instance)
final adServiceProvider = Provider<AdService>((ref) => AdService.instance);

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

  /// Set to false to use production ad IDs, true for test IDs
  /// IMPORTANT: Set to false before releasing to production!
  static const bool _useTestAds = true;

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

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  /// Initialize the ad service
  Future<void> initialize() async {
    try {
      // Initialize with test application ID
      await MobileAds.instance.initialize();
      debugPrint('Ad service initialized successfully');
      _loadInterstitialAd();
    } catch (e) {
      debugPrint('Ad service initialization failed: $e');
      // Don't throw - ads are not critical for app functionality
    }
  }

  /// Load interstitial ad
  Future<void> _loadInterstitialAd() async {
    try {
      debugPrint('Interstitial Ad: Starting to load ad...');
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdReady = true;
            debugPrint(
                'Interstitial Ad: ✅ Loaded successfully and ready to show');

            // Set full screen content callback
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint(
                    'Interstitial Ad: User dismissed ad, loading next one...');
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialAdReady = false;
                _loadInterstitialAd(); // Load next ad
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Interstitial Ad: ❌ Failed to show: $error');
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialAdReady = false;
                _loadInterstitialAd(); // Try loading again
              },
              onAdShowedFullScreenContent: (ad) {
                debugPrint('Interstitial Ad: ✅ Ad is now showing');
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint(
                'Interstitial Ad: ❌ Failed to load: ${error.message} (Code: ${error.code})');
            _isInterstitialAdReady = false;
            // Retry after a delay
            Future.delayed(const Duration(seconds: 30), () {
              debugPrint(
                  'Interstitial Ad: Retrying to load after 30 seconds...');
              _loadInterstitialAd();
            });
          },
        ),
      );
    } catch (e) {
      debugPrint('Interstitial Ad: ❌ Exception loading ad: $e');
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
          debugPrint('Interstitial Ad: Ad not ready. Attempting to load...');
          _loadInterstitialAd();

          // Wait up to 5 seconds for the ad to load
          int attempts = 0;
          while ((!_isInterstitialAdReady || _interstitialAd == null) &&
              attempts < 10) {
            await Future.delayed(const Duration(milliseconds: 500));
            attempts++;
            debugPrint(
                'Interstitial Ad: Waiting for ad to load... (attempt $attempts/10)');
          }
        }

        // Show ad if it's ready
        if (_isInterstitialAdReady && _interstitialAd != null) {
          debugPrint('Interstitial Ad: Ad is ready, showing now');

          // Mark as not ready to prevent double-showing
          // The callback will handle reloading after dismissal
          _isInterstitialAdReady = false;

          // Add a small delay to ensure UI is ready and any animations complete
          await Future.delayed(const Duration(milliseconds: 500));

          // Show the ad - ensure we still have a valid reference
          if (_interstitialAd != null) {
            try {
              debugPrint('Interstitial Ad: Calling show() now...');
              _interstitialAd!.show();
              debugPrint('Interstitial Ad: ✅ show() called successfully');
            } catch (showError, stackTrace) {
              debugPrint('Interstitial Ad: ❌ Error calling show(): $showError');
              debugPrint('Interstitial Ad: Stack trace: $stackTrace');
              // Dispose the ad and try to reload for next time
              _interstitialAd?.dispose();
              _interstitialAd = null;
              _isInterstitialAdReady = false;
              _loadInterstitialAd();
            }
          } else {
            debugPrint('Interstitial Ad: ❌ Ad became null before showing');
            _isInterstitialAdReady = false;
            _loadInterstitialAd();
          }
        } else {
          debugPrint(
              'Interstitial Ad: ❌ Ad still not ready after waiting. Ready: $_isInterstitialAdReady, Ad: ${_interstitialAd != null}');
          // Try to reload for next time
          _loadInterstitialAd();
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

  /// Create a banner ad widget.
  /// [isBottom] true = bottom banner (AquaPulse Banner Bottom), false = top banner (AquaPulse Banner Top).
  Widget createBannerAd(WidgetRef ref, {bool isBottom = false}) {
    final adUnitId = isBottom ? bannerBottomAdUnitId : bannerTopAdUnitId;
    try {
      return Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        child: AdWidget(
          ad: BannerAd(
            adUnitId: adUnitId,
            size: AdSize.banner,
            request: const AdRequest(),
            listener: BannerAdListener(
              onAdLoaded: (ad) {
                debugPrint('Banner ad loaded successfully');
              },
              onAdFailedToLoad: (ad, error) {
                debugPrint('Banner ad failed to load: $error');
                ad.dispose();
              },
            ),
          )..load(),
        ),
      );
    } catch (e) {
      debugPrint('Error creating banner ad: $e');
      // Return a placeholder if ad creation fails
      return Container(
        width: double.infinity,
        height: 60,
        color: Colors.grey[200],
        child: const Center(
          child: Text(
            'Ad Space',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      );
    }
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
    _interstitialAd?.dispose();
    _isInterstitialAdReady = false;
  }
}
