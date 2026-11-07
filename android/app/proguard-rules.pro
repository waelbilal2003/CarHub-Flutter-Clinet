# Suppress optional legacy Firebase IID references reported by R8.
-dontwarn com.google.firebase.iid.FirebaseInstanceId

# google_mlkit_text_recognition references every script's options class, but only the Latin
# recognizer is bundled (VIN = Latin letters + digits). The other scripts are never used.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
