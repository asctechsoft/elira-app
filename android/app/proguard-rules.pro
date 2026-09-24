# AGP 9 enables R8 for release builds by default and expects this file to exist.
# Flutter's own engine rules ship with the engine; these cover what this app adds.

# Flutter embedding: referenced reflectively by the generated plugin registrant.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase / Google Play services read annotations and model classes reflectively.
-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firestore deserialises into model classes by field name, so their members
# must survive obfuscation.
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <fields>;
    @com.google.firebase.firestore.PropertyName <methods>;
}

# Keep the crash-report line numbers useful.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
