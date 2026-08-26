allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Older plugins (telephony 0.2.0) predate the AGP 8 namespace requirement.
// Inject a synthetic namespace so the module resolves without patching the
// package's pub-cache sources.
fun injectNamespace(p: Project) {
    if (!p.plugins.hasPlugin("com.android.library")) return
    val android = p.extensions.findByName("android")
        as? com.android.build.gradle.LibraryExtension
    if (android != null && android.namespace == null) {
        android.namespace = p.group?.toString()
            ?: "com.example.${p.name.replace('-', '_')}"
    }
}

subprojects {
    if (project.state.executed) {
        injectNamespace(project)
    } else {
        project.afterEvaluate { injectNamespace(project) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
