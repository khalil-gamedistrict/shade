// Asli rewarded + interstitial ad (AppLovin MAX). Sirf Android pe — web pe [PlaceholderAds].
import 'dart:async';

import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/material.dart';

import 'ad_keys.dart';
import 'ads.dart';

class AppLovinAds implements AdService {
  bool _initDone = false;
  Completer<void>? _initializing;

  bool _rewardedReady = false;
  bool _rewardedLoading = false;
  bool _interReady = false;
  bool _interLoading = false;

  /// App shuru hote hi: SDK chalu karo aur dono ad listener laga do (poori app ke liye ek hi
  /// dafa — AppLovin MAX ka API globally listen karta hai, per-ad object nahi deta)
  AppLovinAds() {
    AppLovinMAX.setRewardedAdListener(
      RewardedAdListener(
        onAdLoadedCallback: (ad) {
          _rewardedReady = true;
          _rewardedLoading = false;
        },
        onAdLoadFailedCallback: (adUnitId, error) {
          _rewardedReady = false;
          _rewardedLoading = false;
          debugPrint('MAX rewarded load failed: ${error.message}');
        },
        onAdDisplayedCallback: (ad) {},
        onAdDisplayFailedCallback: (ad, error) {
          _rewardedReady = false;
          debugPrint('MAX rewarded show failed: ${error.message}');
          // Dikhane mein hi masla aa gaya — khiladi ki ghalti nahi, inaam de do
          if (_rewardEarned?.isCompleted == false) {
            _rewardEarned!.complete(true);
          }
          _loadRewarded();
        },
        onAdClickedCallback: (ad) {},
        onAdHiddenCallback: (ad) {
          _rewardedReady = false;
          if (_rewardEarned?.isCompleted == false) {
            _rewardEarned!.complete(false); // beech mein band = koi inaam nahi
          }
          _loadRewarded(); // agle dafa ke liye
        },
        onAdReceivedRewardCallback: (ad, reward) =>
            _rewardEarned?.complete(true),
      ),
    );
    AppLovinMAX.setInterstitialListener(
      InterstitialListener(
        onAdLoadedCallback: (ad) {
          _interReady = true;
          _interLoading = false;
        },
        onAdLoadFailedCallback: (adUnitId, error) {
          _interReady = false;
          _interLoading = false;
          debugPrint('MAX interstitial load failed: ${error.message}');
        },
        onAdDisplayedCallback: (ad) {},
        onAdDisplayFailedCallback: (ad, error) {
          _interReady = false;
          debugPrint('MAX interstitial show failed: ${error.message}');
          _interDone?.complete();
        },
        onAdClickedCallback: (ad) {},
        onAdHiddenCallback: (ad) {
          _interReady = false;
          _interDone?.complete();
          _loadInterstitial(); // agle dafa ke liye
        },
      ),
    );
    _init();
  }

  Future<void> _init() {
    if (_initDone) return Future.value();
    if (_initializing != null) return _initializing!.future;
    final done = Completer<void>();
    _initializing = done;
    AppLovinMAX.initialize(maxSdkKey).then((_) {
      _initDone = true;
      done.complete();
      _loadRewarded();
      _loadInterstitial();
    });
    return done.future;
  }

  void _loadRewarded() {
    if (_rewardedReady || _rewardedLoading) return;
    _rewardedLoading = true;
    AppLovinMAX.loadRewardedAd(maxRewardedAndroid);
  }

  void _loadInterstitial() {
    if (_interReady || _interLoading) return;
    _interLoading = true;
    AppLovinMAX.loadInterstitial(maxInterstitialAndroid);
  }

  Completer<bool>? _rewardEarned;

  @override
  Future<bool> showRewarded(BuildContext context) async {
    await _init();
    // Thora intezar karo ke pehla load poora ho jaye (app shuru hote hi turant dabaya ho to)
    for (var i = 0; i < 16 && !_rewardedReady && _rewardedLoading; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
    }
    if (!_rewardedReady) {
      // Internet nahi / ad nahi mila — khiladi ki ghalti nahi, is liye inaam phir bhi
      _loadRewarded();
      return true;
    }
    _rewardEarned = Completer<bool>();
    AppLovinMAX.showRewardedAd(maxRewardedAndroid);
    final earned = await _rewardEarned!.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () => false,
    );
    return earned;
  }

  Completer<void>? _interDone;

  @override
  Future<void> showInterstitial(BuildContext context) async {
    await _init();
    for (var i = 0; i < 16 && !_interReady && _interLoading; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
    }
    if (!_interReady) {
      _loadInterstitial();
      return; // internet/ad nahi mila — chuppe chaap aagay barh jao
    }
    _interDone = Completer<void>();
    AppLovinMAX.showInterstitial(maxInterstitialAndroid);
    await _interDone!.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {},
    );
  }
}
