plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val gaussSigningEnvironment = mapOf(
    "GAUSS_KEYSTORE_PATH" to System.getenv("GAUSS_KEYSTORE_PATH"),
    "GAUSS_KEYSTORE_PASSWORD" to System.getenv("GAUSS_KEYSTORE_PASSWORD"),
    "GAUSS_KEY_ALIAS" to System.getenv("GAUSS_KEY_ALIAS"),
    "GAUSS_KEY_PASSWORD" to System.getenv("GAUSS_KEY_PASSWORD"),
)
val gaussReleaseRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (gaussReleaseRequested) {
    val missingSigningValues = gaussSigningEnvironment
        .filterValues { it.isNullOrBlank() }
        .keys
        .sorted()
    require(missingSigningValues.isEmpty()) {
        "Gauss release signing is fail-closed. Missing environment variables: " +
            missingSigningValues.joinToString(", ") +
            ". Use the protected Gauss signing identity; debug-signed release APKs are forbidden."
    }
    val configuredKeystore = file(gaussSigningEnvironment.getValue("GAUSS_KEYSTORE_PATH")!!)
    require(configuredKeystore.isFile) {
        "Gauss release signing is fail-closed. GAUSS_KEYSTORE_PATH does not point to a file."
    }
}

val gaussKeystorePath = gaussSigningEnvironment["GAUSS_KEYSTORE_PATH"]

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
                storePassword = gaussSigningEnvironment["GAUSS_KEYSTORE_PASSWORD"]
                keyAlias = gaussSigningEnvironment["GAUSS_KEY_ALIAS"]
                keyPassword = gaussSigningEnvironment["GAUSS_KEY_PASSWORD"]
            }
        }
    }

    buildTypes {
        getByName("profile") {
            // Keep performance probes isolated from the signed personal build
            // so profiling can never replace or clear the user's live store.
            applicationIdSuffix = ".profile"
        }
        release {
            signingConfig = signingConfigs.getByName("release")
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
