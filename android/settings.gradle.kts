pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // ملاحظة: هذه الإصدارات مثبّتة عمداً لتطابق أدوات البناء المخزّنة محلياً.
    // AGP 8.13.1 يطلب intellij-core و kotlin-compiler نسخة 31.13.1 (~88 ميجا)
    // ويُنزّلهما في كل بناء release ضمن مهمة extractReleaseAnnotations؛ وهو غير
    // ممكن على الاتصال الحالي. النسختان أدناه تحتاجان 31.9.2 وهي مخزّنة مسبقاً،
    // فيكتمل البناء دون أي تنزيل. ترقيتهما لاحقاً تتطلب اتصالاً جيداً أولاً.
    id("com.android.application") version "8.9.2" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
