# Flutter specific ProGuard rules
# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Gson classes for API responses
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep model classes
-keep class com.example.cric11_app.data.models.** { *; }

# Keep Socket.IO client
-keep class io.socket.** { *; }

# Keep Dio
-keep class dio.** { *; }
-keepclassmembers,allowshrinking,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}

# Prevent obfuscation of classes with @Keep annotation
-keep @androidx.annotation.Keep class *
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# ========================================================
# Google Play Core Library - Required for Flutter
# These classes are referenced by Flutter embedding
# but may be tree-shaken by R8
# ========================================================

# Keep Google Play Core SplitCompat
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }

# Keep Google Play Core SplitInstall
-keep class com.google.android.play.core.splitinstall.SplitInstallException { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallManager { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallManagerFactory { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallRequest { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallRequest$Builder { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallSessionState { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }

# Keep Google Play Core Tasks
-keep class com.google.android.play.core.tasks.OnFailureListener { *; }
-keep class com.google.android.play.core.tasks.OnSuccessListener { *; }
-keep class com.google.android.play.core.tasks.Task { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep entire Play Core library (alternative - uncomment if needed)
# -keep class com.google.android.play.core.** { *; }


# HaishinKit RTMP broadcaster (uses kotlinx.serialization via reflection)
-keep class com.haishinkit.** { *; }
-keepclassmembers class kotlinx.serialization.json.** { *; }
-keepattributes *Annotation*, InnerClasses
-dontwarn kotlinx.serialization.**
