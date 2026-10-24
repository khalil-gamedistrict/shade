// ===== Saare ad-network credentials — SIRF YAHI FILE badalni hai =====
// Poori app mein ab tak sirf ek hi ad network hai: Google AdMob (google_mobile_ads).
// Zaroorat padi to koi naya ad network (Unity Ads, AppLovin, mediation waghera) add ho,
// us ke keys/IDs bhi isi file mein rakhna — taake "live credentials kahan daalein" ka
// jawab hamesha ek hi jagah rahe, idhar-udhar dhoondhna na pade.
//
// Abhi Google ki TEST IDs hain (sirf testing ke liye; in pe click karna mehfooz hai).
// Asli keys admob.google.com se: App ID (~ wali), Rewarded ad unit ID aur Interstitial ad
// unit ID (dono / wali) — teeno yahan likh do, baaqi poori app khud-ba-khud inhi ko
// istemal kar legi:
//   - lib/services/admob_ads.dart (Rewarded + Interstitial dono)
//   - android/app/build.gradle.kts App ID isi file se (regex se) parh kar
//     AndroidManifest.xml mein daal deta hai — Manifest mein kahin alag se nahi likhna.

/// AdMob App ID (Android)
const admobAndroidAppId = 'ca-app-pub-3940256099942544~3347511713';

/// Rewarded ad unit ID (Android) — "Break Free" aur dhaal lene pe dikhta hai
const admobRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';

/// Interstitial ad unit ID (Android) — chapter khatam hone pe dikhta hai
const admobInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
