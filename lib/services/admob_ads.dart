// Asli rewarded ad (Google AdMob). Sirf Android pe — web pe [PlaceholderAds].
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_keys.dart';
import 'ads.dart';

class AdMobAds implements AdService {
  RewardedAd? _ready;
  bool _loading = false;
  InterstitialAd? _interReady;
  bool _interLoading = false;

  /// App shuru hote hi: SDK chalu karo aur pehla ad pehle se mangwa lo (dabate hi foran chale)
  AdMobAds() {
    MobileAds.instance.initialize().then((_) {
      _load();
      _loadInterstitial();
    });
  }

  Future<RewardedAd?> _load() {
    if (_ready != null) return Future.value(_ready);
    final done = Completer<RewardedAd?>();
    if (_loading) {
      // Pehle se aa raha hai — thori der intezar
      Timer(const Duration(seconds: 5), () => done.complete(_ready));
      return done.future;
    }
    _loading = true;
    RewardedAd.load(
      adUnitId: admobRewardedAndroid,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ready = ad;
          if (!done.isCompleted) done.complete(ad);
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          debugPrint('AdMob load failed: $error');
          if (!done.isCompleted) done.complete(null);
        },
      ),
    );
    return done.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => null,
    );
  }

  @override
  Future<bool> showRewarded(BuildContext context) async {
    final ad = _ready ?? await _load();
    // Internet nahi / ad nahi mila — khiladi ki ghalti nahi, is liye inaam phir bhi
    if (ad == null) return true;
    _ready = null;
    final result = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!result.isCompleted) result.complete(earned);
        _load(); // agle dafa ke liye
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        debugPrint('AdMob show failed: $error');
        if (!result.isCompleted) result.complete(true);
        _load();
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return result.future;
  }

  Future<InterstitialAd?> _loadInterstitial() {
    if (_interReady != null) return Future.value(_interReady);
    final done = Completer<InterstitialAd?>();
    if (_interLoading) {
      Timer(const Duration(seconds: 5), () => done.complete(_interReady));
      return done.future;
    }
    _interLoading = true;
    InterstitialAd.load(
      adUnitId: admobInterstitialAndroid,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interLoading = false;
          _interReady = ad;
          if (!done.isCompleted) done.complete(ad);
        },
        onAdFailedToLoad: (error) {
          _interLoading = false;
          debugPrint('AdMob interstitial load failed: $error');
          if (!done.isCompleted) done.complete(null);
        },
      ),
    );
    return done.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => null,
    );
  }

  @override
  Future<void> showInterstitial(BuildContext context) async {
    final ad = _interReady ?? await _loadInterstitial();
    if (ad == null) return; // internet/ad nahi mila — chuppe chaap aagay barh jao
    _interReady = null;
    final result = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!result.isCompleted) result.complete();
        _loadInterstitial(); // agle dafa ke liye
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        debugPrint('AdMob interstitial show failed: $error');
        if (!result.isCompleted) result.complete();
        _loadInterstitial();
      },
    );
    await ad.show();
    return result.future;
  }
}
