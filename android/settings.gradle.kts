pluginManagement {
    val flutterSdkPath = run {
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

    resolutionStrategy {
        eachPlugin {
            val kotlinPluginIds = setOf(
                "org.jetbrains.kotlin.android",
                "org.jetbrains.kotlin.jvm",
                "org.jetbrains.kotlin.kapt",
                "org.jetbrains.kotlin.plugin.parcelize",
                "kotlin-android",
                "kotlin-kapt",
                "kotlin-parcelize"
            )

            if (requested.id.id in kotlinPluginIds) {
                useVersion("2.2.0")
            }
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.2.0" apply false
}

include(":app")
