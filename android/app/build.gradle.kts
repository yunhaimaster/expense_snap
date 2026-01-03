plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin 必須在 Android 和 Kotlin Gradle plugins 之後
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.expense_snap"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.expense_snap"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 啟用 multidex 支援大型依賴
        multiDexEnabled = true
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

            // TODO: 正式發佈時配置簽名
            // 1. 建立 key.properties 檔案（參見 key.properties.template）
            // 2. 取消下方註解並移除 debug signingConfig
            // signingConfig = signingConfigs.getByName("release")
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // 正式發佈時取消此區塊的註解
    // signingConfigs {
    //     create("release") {
    //         val keystoreFile = file("../key.properties")
    //         if (keystoreFile.exists()) {
    //             val props = java.util.Properties()
    //             props.load(keystoreFile.inputStream())
    //             storeFile = file(props.getProperty("storeFile"))
    //             storePassword = props.getProperty("storePassword")
    //             keyAlias = props.getProperty("keyAlias")
    //             keyPassword = props.getProperty("keyPassword")
    //         }
    //     }
    // }
}

flutter {
    source = "../.."
}

dependencies {
    // Multidex 支援
    implementation("androidx.multidex:multidex:2.0.1")
}
