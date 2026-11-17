import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Clé de signature de publication : jamais dans Git (cours 6, *.jks et key.properties dans .gitignore).
// En local, android/key.properties ; en CI, recréé à partir des secrets GitHub.
val proprietesCle = Properties()
val fichierCle = rootProject.file("key.properties")
if (fichierCle.exists()) proprietesCle.load(FileInputStream(fichierCle))

android {
    namespace = "fr.parquetclub.parquet"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true // exigé par flutter_local_notifications
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "fr.parquetclub.parquet"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Android 9 minimum : local_auth plante sous Android 8 avec le thème par défaut.
        // Choix de cible = décision business (cours 1) : Android 8 et moins est devenu très rare.
        minSdk = 28
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = proprietesCle["keyAlias"] as String?
            keyPassword = proprietesCle["keyPassword"] as String?
            storeFile = (proprietesCle["storeFile"] as String?)?.let { file(it) }
            storePassword = proprietesCle["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // Sans key.properties (poste de dev, CI sans secrets) : clé de debug, pour que le build passe.
            // Un tel binaire ne doit jamais être publié : le store le refuserait de toute façon.
            signingConfig = signingConfigs.getByName(if (fichierCle.exists()) "release" else "debug")
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
