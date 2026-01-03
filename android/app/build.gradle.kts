plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin 必須在 Android 和 Kotlin Gradle plugins 之後
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.expense_snap"
    compileSdk = 35
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
        minSdk = 21
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 啟用 multidex 支援大型依賴
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: 正式發佈時配置簽名
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Multidex 支援
    implementation("androidx.multidex:multidex:2.0.1")
}
