plugins {
    id("com.android.application")
    id("kotlin-android")
    id 'com.android.application' // or 'com.android.library'
    id 'com.google.gms.google-services'
}

android {
    namespace = "com.example.doo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

compileSdkVersion 34

defaultConfig {
    minSdkVersion 21
    targetSdkVersion 34
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
