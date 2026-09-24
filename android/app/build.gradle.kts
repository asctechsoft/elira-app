plugins {
    id("com.android.application")
    // Required by the `kotlin { compilerOptions { ... } }` block below and by
    // MainActivity.kt. gradle.properties sets android.builtInKotlin=false, so
    // nothing applies the Kotlin plugin implicitly.
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.asc.elira"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        resValues = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.asc.elira"
        // Pinned, not inherited: firebase_auth requires >= 23 and flutter.minSdkVersion moves between SDK releases.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "env"

    productFlavors {
        create("alpha") {
            dimension = "env"
            applicationIdSuffix = ".alpha"
            versionNameSuffix = "-alpha"
            resValue("string", "app_name", "Elira Alpha")
        }
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Elira Dev")
        }
        create("product") {
            dimension = "env"
            resValue("string", "app_name", "ASC Photo AI")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
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

// google-services aborts the build when no config file is present, which would block every
// developer who has not been granted Firebase console access yet. Apply it only once a
// google-services.json actually exists; dropping the file in is all it takes to enable Firebase.
val flavorsWithFirebaseConfig = listOf("dev", "alpha", "product")
    .filter { file("src/$it/google-services.json").exists() }

if (flavorsWithFirebaseConfig.isNotEmpty() || file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.lifecycle("[elira] No google-services.json found - Firebase Android wiring is inactive.")
}
