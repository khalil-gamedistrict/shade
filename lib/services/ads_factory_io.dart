import 'dart:io';

import 'admob_ads.dart';
import 'ads.dart';

AdService createAds() => Platform.isAndroid ? AdMobAds() : PlaceholderAds();
