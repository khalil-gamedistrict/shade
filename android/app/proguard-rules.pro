# AppLovin MAX ki OMID (ad-viewability) library mein Amazon Privacy Pass attestation ka
# optional code hai jo hum use nahi karte — R8 isko missing class samajh kar warn karta
# hai, yeh rules bas wo warning dabati hain (build.gradle.kts ne khud generate ki thi).
-dontwarn com.amazon.privacypass.PrivacyPass
-dontwarn com.amazon.privacypass.VerificationContext
-dontwarn com.amazon.privacypass.callback.AttestAPICallback
