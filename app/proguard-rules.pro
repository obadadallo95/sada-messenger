# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Keep only classes accessed via reflection or JNI
-keep class org.sada.messenger.data.entities.** { *; }
-keep class org.sada.messenger.data.db.** { *; }
-keep class org.sada.messenger.data.models.** { *; }
-keep class org.sada.messenger.network.MeshMessage { *; }
-keep class org.sada.messenger.core.services.MeshForegroundService { *; }

# Keep libsodium native bindings
-keep class com.goterl.lazysodium.** { *; }
-keep class com.sun.jna.** { *; }
-keep class net.java.dev.jna.** { *; }

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

