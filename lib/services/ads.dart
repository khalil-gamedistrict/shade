// Ads: [AdService] ke peeche asli ya nakli ad. Android pe AdMob (admob_ads.dart, keys ad_keys.dart),
// web aur tests mein [PlaceholderAds] — ads_factory.dart chunta hai.
import 'dart:async';

import 'package:flutter/material.dart';

abstract class AdService {
  /// Rewarded ad dikhao. Poora dekha to true (inaam milega), beech mein band kiya to false.
  Future<bool> showRewarded(BuildContext context);
}

/// Asli ad ki jagah: 3 second ka parda "Ad plays here", phir inaam
class PlaceholderAds implements AdService {
  @override
  Future<bool> showRewarded(BuildContext context) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) => const _FakeAd(),
    );
    return result ?? false;
  }
}

class _FakeAd extends StatefulWidget {
  const _FakeAd();

  @override
  State<_FakeAd> createState() => _FakeAdState();
}

class _FakeAdState extends State<_FakeAd> {
  int left = 3;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (left <= 1) {
        timer?.cancel();
        Navigator.of(context).pop(true);
      } else {
        setState(() => left--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AD',
                  style: TextStyle(
                    fontSize: 40,
                    letterSpacing: 10,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Your ad will play here',
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 2,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 20,
            child: Text(
              'Reward in $left',
              style: const TextStyle(fontSize: 14, color: Colors.white54),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white38),
              onPressed: () => Navigator.of(context)
                  .pop(false), // beech mein band = koi inaam nahi
            ),
          ),
        ],
      ),
    );
  }
}
