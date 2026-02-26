# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native bridge classes
-keep class org.sada.messenger.** { *; }

# Keep sodium_libs native bindings
-keep class com.warrenth.sodium.** { *; }
-keep class com.warrenth.sodium_libs.** { *; }
-keep class com.warrenth.** { *; }

# Keep JNI methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}

# Keep WiFi P2P classes
-keep class android.net.wifi.p2p.** { *; }

# Keep JSON classes
-keep class org.json.** { *; }

# Keep EventChannel and MethodChannel
-keep class io.flutter.plugin.common.** { *; }

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Don't warn about missing classes (for optional dependencies)
-dontwarn org.sada.messenger.**

# Google Play Core (optional dependency - don't warn if missing)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

