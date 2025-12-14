plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.medico_transcribe"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.medico_transcribe"
        minSdk = 24
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // MultiDex support for larger apps
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // Disable minification to avoid R8 issues with Flutter
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    
    // Packaging options to avoid conflicts
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            excludes += "/META-INF/DEPENDENCIES"
        }
    }
}

flutter {
    source = "../.."
}
