import 'dart:io';

import 'applovin_ads.dart';
import 'ads.dart';

AdService createAds() => Platform.isAndroid ? AppLovinAds() : PlaceholderAds();
