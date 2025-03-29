plugins {
    id("com.android.application")
    id("kotlin-android")
}

android {
    namespace = "com.example.intercargo" // Substitua pelo seu pacote
    compileSdk = 33

    defaultConfig {
        applicationId = "com.example.intercargo" // Substitua pelo seu pacote
        minSdk = 21
        targetSdk = 33
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }
}

flutter {
    source = "../../" // Certifique-se de que o caminho está correto
}
