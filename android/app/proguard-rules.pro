# Keep standard Java collections and other classes
-keep class java.util.** { *; }
-keep class java.nio.** { *; }

# Keep Agora SDK classes
-keep class io.agora.** { *; }
-keep class com.google.devtools.build.android.desugar.runtime.ThrowableExtension { *; }

# Add any other custom rules as needed
