# Meketa (Scam Shield) ProGuard & R8 Hardening Rules

# 1. Protect native SMS receiver and MethodChannel entry points
-keep class com.ethio.scamshield.scam_shield.MainActivity { *; }
-keep class com.ethio.scamshield.scam_shield.SmsReceiver { *; }
-keepclassmembers class com.ethio.scamshield.scam_shield.SmsReceiver {
    public static ** smsCallback;
}

# 2. Protect Flutter Engine & Plugin Registration
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keepclassmembers class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler {
    public void onMethodCall(io.flutter.plugin.common.MethodCall, io.flutter.plugin.common.MethodChannel$Result);
}

# 3. Protect Sqflite native bindings
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# 4. Protect Shared Preferences & Local Notifications
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# 5. Preserve line numbers and source attributes for crash stacktraces
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable,Signature,*Annotation*
