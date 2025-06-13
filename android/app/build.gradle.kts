plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.news_app"
    compileSdk = 35                    // Fixed: Changed from flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"       // Fixed: Changed from flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true  // Fixed: Added for API desugaring
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.news_app"
        minSdk = 21                    // Fixed: Set explicit value instead of flutter.minSdkVersion
        targetSdk = 34                 // Fixed: Set explicit value instead of flutter.targetSdkVersion
        versionCode = 1                // Fixed: Set explicit value instead of flutter.versionCode
        versionName = "1.0.0"          // Fixed: Set explicit value instead of flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Fixed: Added desugaring dependency to resolve compatibility issues
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
