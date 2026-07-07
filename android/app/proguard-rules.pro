# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Play Core (needed for Flutter deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Supabase / PostgREST
-keep class com.supabase.** { *; }
-keep class org.postgrest.** { *; }
-keep class kotlinx.serialization.** { *; }

# Keep model classes
-keep class com.ironbook.app.** { *; }

# Keep Gson/JSON serialization
-keepattributes *Annotation*, Signature, Exception
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
