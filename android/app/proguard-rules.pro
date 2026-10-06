# Flutter default rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# R8/ProGuard fixes for Flutter Play Store SplitCompat
-dontwarn com.google.android.play.core.**

# Dio
-keep class com.squareup.okhttp.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# GetX
-keep class org.getx.** { *; }

# Hive & Type Adapters
-keep class *.HiveObject { *; }
-keep class *.Adapter { *; }
-keep class com.example.file_search_tools.data.models.** { *; }

# JSON serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class com.google.gson.** { *; }
