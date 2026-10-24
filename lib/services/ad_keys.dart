// ===== Saare ad-network credentials — SIRF YAHI FILE badalni hai =====
// Poori app mein ab tak sirf ek hi ad network hai: AppLovin MAX (applovin_max).
// Zaroorat padi to koi naya ad network (mediation ke andar koi aur network) add ho,
// us ke keys/IDs bhi isi file mein rakhna — taake "live credentials kahan daalein" ka
// jawab hamesha ek hi jagah rahe, idhar-udhar dhoondhna na pade.
//
// PLACEHOLDER values hain — AppLovin (jaisa AdMob ke mukhtalif) koi public "test ID"
// nahi deta, har app ko apna khud ka SDK Key aur ad unit IDs AppLovin MAX dashboard
// (applovin.com) se banane parte hain. Jab tak yahan asal values nahi daalte, SDK
// initialize nahi hoga aur ads chupchaap load/show nahi honge (app crash nahi karegi,
// bas ad wali jagah par kuch nahi dikhega) — isliye real values daalna zaroori hai
// testing ke liye bhi.
//
// Kahan se milengi: applovin.com par account banao → app add karo → "SDK Key" account
// settings mein milti hai → Rewarded aur Interstitial, do alag "Ad Unit" banao (MAX
// dashboard → Manage → Ad Units) → in teeno values ko neeche daal do. Poori app
// (lib/services/applovin_ads.dart) khud-ba-khud inhi ko istemal kar legi.

/// AppLovin MAX SDK Key — poori app ke liye ek hi, pehla initialize call isi se hota hai
const maxSdkKey = 'YOUR_APPLOVIN_SDK_KEY';

/// Rewarded ad unit ID (Android) — "Break Free" aur dhaal lene pe dikhta hai
const maxRewardedAndroid = 'YOUR_ANDROID_REWARDED_AD_UNIT_ID';

/// Interstitial ad unit ID (Android) — chapter khatam hone pe dikhta hai
const maxInterstitialAndroid = 'YOUR_ANDROID_INTERSTITIAL_AD_UNIT_ID';
