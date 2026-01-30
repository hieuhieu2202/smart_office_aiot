plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.smart_office_aiot"
    compileSdk = 36
    ndkVersion = "29.0.13846066" // Cập nhật NDK phiên bản cao nhất

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.smart_office_aiot"
        minSdk = 23
        targetSdk = 36
        val envVersionCode = System.getenv("ANDROID_VERSION_CODE")?.toIntOrNull()
        val envVersionName = System.getenv("ANDROID_VERSION_NAME")?.takeIf { it.isNotBlank() }

        versionCode = envVersionCode ?: flutter.versionCode
        versionName = envVersionName ?: flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Thêm để xóa splash screen mặc định
dependencies {
    implementation("androidx.appcompat:appcompat:1.6.1") // Cập nhật lên phiên bản mới hơn
}