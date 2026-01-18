# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter Background Service
-keep class id.flutter.flutter_background_service.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# SharedPreferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Drift / SQLite
-keep class com.tekartik.sqflite.** { *; }
-keep class org.sqlite.** { *; }

# Keep entry points for background service
-keep class * extends io.flutter.embedding.android.FlutterActivity { *; }
-keep class * extends io.flutter.embedding.android.FlutterFragmentActivity { *; }

# Keep classes with Keep annotation
-keep @androidx.annotation.Keep class *
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Gson (if used)
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }

# OkHttp / HTTP client
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# General Android rules
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Kotlin
-dontwarn kotlin.**
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Google Play Core (for deferred components, not used but referenced by Flutter)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
