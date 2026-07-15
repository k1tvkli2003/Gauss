plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val gaussKeystorePath = System.getenv("GAUSS_KEYSTORE_PATH")

android {
    namespace = "com.gauss.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.gauss.app"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = System.getenv("GAUSS_VERSION_CODE")?.toIntOrNull()
            ?: flutter.versionCode
        versionName = System.getenv("GAUSS_VERSION_NAME") ?: flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (gaussKeystorePath != null) {
                storeFile = file(gaussKeystorePath)
                storePassword = System.getenv("GAUSS_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("GAUSS_KEY_ALIAS")
                keyPassword = System.getenv("GAUSS_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (gaussKeystorePath != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
