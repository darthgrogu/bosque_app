# --- Regras Gerais Flutter ---
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}
-dontwarn io.flutter.embedding.**

# Protege o Flutter e plugins em geral

# --- Regras para package:location (com.lyokone.location) ---
-keep class com.lyokone.** { *; }
-keep interface com.lyokone.location.** { *; }
-keep class com.lyokone.location.** { *; }
-keep class com.lyokone.location.services.** { *; }

# --- Regras para package:flutter_compass (com.hemanthraj.fluttercompass) ---
-keep class com.hemanthraj.fluttercompass.** { *; }
-keep interface com.hemanthraj.fluttercompass.** { *; }

# --- Regras para package:geolocator (com.baseflow.geolocator) ---
-keep class com.baseflow.geolocator.** { *; }
-keep interface com.baseflow.geolocator.** { *; }
# Se usar outros plugins Baseflow, descomente/adicione as regras deles aqui se necessário

# --- Outras Regras ---
# Adicione regras para outras bibliotecas (Gson, etc.) se necessário

-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication

# Protege o LocationMarker e Streams
-keep class dev.fleaflet.location_marker.** { *; }