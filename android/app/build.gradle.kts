// Imported rather than fully qualified: inside a Kotlin DSL build script the
// name `java` resolves to Gradle's Java plugin extension, which shadows the
// `java.*` packages and makes `java.util.Properties` fail to resolve.
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Processes google-services.json for firebase_core / firebase_messaging.
    id("com.google.gms.google-services")
}

// Upload-key material, kept out of version control. Create android/key.properties
// from key.properties.example after generating the keystore; see README.
// Absent (a fresh clone, CI without secrets) the release build falls back to the
// debug key so `flutter run --release` still works — such a build is fine for
// local testing but Play rejects it, which is the intended safety net.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { stream ->
        keystoreProperties.load(stream)
    }
}
val hasUploadKey = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "app.ileny.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Fixed at the first Play upload — the store identifies the app by
        // this, and it can never be changed afterwards. Must match the package
        // name registered on the Firebase Android app.
        applicationId = "app.ileny.mobile"
        // Pinned per plan.txt section 1/6: Android 7+ floor, not whatever
        // the Flutter template default happens to be.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadKey) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasUploadKey) {
                signingConfigs.getByName("release")
            } else {
                // println, not logger.warn: Flutter filters Gradle's warning
                // channel out of `flutter build` output, and this needs to be
                // impossible to miss.
                println(
                    "\n**********************************************************\n" +
                        "ileny: android/key.properties not found. Signing this\n" +
                        "release build with the DEBUG key — Google Play will\n" +
                        "reject the artifact. See android/key.properties.example.\n" +
                        "**********************************************************\n"
                )
                signingConfigs.getByName("debug")
            }
            // R8 shrink + obfuscate. Flutter's own consumer rules cover the
            // engine and plugins; app code is pure Dart, so nothing here
            // relies on Java reflection that would need a keep rule.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
