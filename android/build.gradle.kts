allprojects {
    repositories {
        // ML Kit's bundled text model (18 MB aar) times out from slow networks; it can be fetched
        // with a resumable download into ~/.m2. Only com.google.mlkit is looked up here; anything
        // missing falls through to google() as usual.
        mavenLocal {
            content { includeGroup("com.google.mlkit") }
        }
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Some plugins (google_mlkit_text_recognition 0.15.0 -> AGP 8.7.0, google_mlkit_commons -> 8.13.0)
    // put their own AGP on their buildscript classpath. That AGP is never used (the project's 8.9.2 is
    // already loaded) but Gradle still downloads it (tens of MB from dl.google.com). Pin it to ours.
    buildscript.configurations.configureEach {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.android.tools.build" && requested.name == "gradle") {
                useVersion("8.9.2")
                because("use the project's AGP; avoids downloading the plugin's own AGP")
            }
        }
    }

    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // إجبار نسخة transition متوفرة بصيغة aar على جميع الوحدات الفرعية
    configurations.all {
        resolutionStrategy {
            force("androidx.transition:transition:1.5.1")
        }
    }
}

subprojects {
    // Configure Kotlin JVM target for all subprojects
    pluginManager.withPlugin("org.jetbrains.kotlin.android") {
        extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension> {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }

    // Configure Java compatibility for all Android subprojects
    pluginManager.withPlugin("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
            // ── إجبار كل الوحدات الفرعية على نسخة NDK الموجودة لديك ──
            ndkVersion = "27.3.13750724"
        }
    }

    pluginManager.withPlugin("com.android.application") {
        extensions.configure<com.android.build.gradle.AppExtension> {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
            ndkVersion = "27.3.13750724"
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
