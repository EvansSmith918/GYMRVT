plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Match your manifest package
    namespace = "com.evans.gymrvt"

    // Required by camera_android (API 36)
    compileSdk = 36

    // Pin to the good NDK you installed earlier
    ndkVersion = "27.0.12077973"

    compileOptions {
        // These are fine to keep at 11 (JDK itself should be 17 in Android Studio settings)
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        // Kotlin target bytecode (11 is fine); your Gradle JDK should be 17
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.evans.gymrvt"

        // Health Connect needs >= 26
        minSdk = 26

        // Target latest to satisfy plugins
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Debug signing so `flutter run --release` works until you add a real keystore
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

