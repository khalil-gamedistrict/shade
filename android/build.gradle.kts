allprojects {
    repositories {
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
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// applovin_max (aur ho sakta hai koi aur plugin) apne hi build.gradle mein purana
// compileSdkVersion (31) likha hua laata hai, jabke uski apni androidx dependencies
// (lifecycle, fragment, savedstate waghera) 34+ maangti hain — app ka apna compileSdk
// (build.gradle.kts mein 36) is masle ko theek nahi karta kyunki yeh check har plugin
// module ke APNE compileSdk pe hoti hai. Yahan har Android library module ko force se
// 36 pe la dete hain taake AAR-metadata check pass ho.
subprojects {
    // :app khud apna compileSdk build.gradle.kts mein set karta hai, aur evaluationDependsOn
    // (upar) use pehle hi evaluate kar chuka hota hai — dobara afterEvaluate lagane se
    // "already evaluated" crash hota hai, is liye sirf baaqi (plugin) modules pe lagao.
    if (project.name != "app") {
        afterEvaluate {
            extensions.findByName("android")?.let {
                (it as com.android.build.gradle.BaseExtension).compileSdkVersion(36)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
