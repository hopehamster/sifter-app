# Flutter-specific rules
-keepattributes *Annotation*
-keep class androidx.lifecycle.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }

# Keep model classes - adjust to your package
-keep class com.sifterapp.chat.models.** { *; }
-keepclassmembers class com.sifterapp.chat.models.** { *; }

# Keep serializable classes for Firebase/JSON
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# For native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Java 8 lambdas
-dontwarn java.lang.invoke.**

# Location libraries
-keep class com.google.android.gms.location.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.firebase.** { *; }
-keep class org.apache.** { *; }
-keepnames class com.fasterxml.jackson.** { *; }
-keepnames class javax.servlet.** { *; }
-keepnames class org.ietf.jgss.** { *; } 