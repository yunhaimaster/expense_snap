import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin 必須在 Android 和 Kotlin Gradle plugins 之後
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "hk.expense.snap"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 啟用 core library desugaring (flutter_local_notifications 需要)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "hk.expense.snap"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 啟用 multidex 支援大型依賴
        multiDexEnabled = true
    }

    // Release 簽名設定
    val keystorePropertiesFile = file("../key.properties")
    val useReleaseKeystore = keystorePropertiesFile.exists()

    signingConfigs {
        if (useReleaseKeystore) {
            create("release") {
                val props = Properties()
                props.load(keystorePropertiesFile.inputStream())
                storeFile = file(props.getProperty("storeFile"))
                storePassword = props.getProperty("storePassword")
                keyAlias = props.getProperty("keyAlias")
                keyPassword = props.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // 啟用代碼縮減和混淆
            isMinifyEnabled = true
            isShrinkResources = true

            // ProGuard 規則
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // 使用 Release 簽名（若有），否則 fallback 至 debug
            signingConfig = if (useReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // 開發環境沒有 key.properties 時使用 debug 簽名
                println("⚠️ key.properties not found, using debug signing for release build")
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Multidex 支援
    implementation("androidx.multidex:multidex:2.0.1")
    // Core library desugaring (Java 8+ APIs on older Android)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // ML Kit 中文文字識別模型（bundled，離線可用）
    implementation("com.google.mlkit:text-recognition-chinese:16.0.1")
}
