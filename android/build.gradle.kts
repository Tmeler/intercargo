plugins {
    id("com.android.application")
    id("kotlin-android")
    // O Plugin do Flutter deve ser aplicado após os plugins Android e Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.intercargo" // Atualize para o seu pacote correto
    compileSdk = 33 // Ajuste conforme necessário
    ndkVersion = "27.0.12077973" // Ajuste conforme sua necessidade

    defaultConfig {
        applicationId = "com.example.intercargo" // Atualize para o seu pacote correto
        minSdk = 21 // Defina conforme a necessidade
        targetSdk = 33
        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    signingConfigs {
        create("release") {
            storeFile = project.findProperty("storeFile")?.toString()?.let { file(it) }
            storePassword = project.findProperty("storePassword")?.toString()
            keyAlias = project.findProperty("keyAlias")?.toString()
            keyPassword = project.findProperty("keyPassword")?.toString()
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true // Ativa a minificação de código
            isShrinkResources = true // Ativa a remoção de recursos não utilizados
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../../" // Certifique-se de que o caminho está correto
}

// Certifique-se de que os repositórios estão corretos
dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.8.0")
}
