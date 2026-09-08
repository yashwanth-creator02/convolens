// Workaround for AGP AndroidLocationsException when both ANDROID_PREFS_ROOT and ANDROID_USER_HOME are set in environment
try {
    System.clearProperty("ANDROID_PREFS_ROOT")
    val peClass = Class.forName("java.lang.ProcessEnvironment")
    val fields =
        arrayOf("theEnvironment", "theUnmodifiableEnvironment", "theCaseInsensitiveEnvironment")
    for (fieldName in fields) {
        try {
            val field = peClass.getDeclaredField(fieldName)
            field.isAccessible = true
            val map = field.get(null) as? MutableMap<*, *>
            map?.remove("ANDROID_PREFS_ROOT")
            map?.remove("android_prefs_root")
        } catch (_: Exception) {
        }
    }
} catch (_: Exception) {
}

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
