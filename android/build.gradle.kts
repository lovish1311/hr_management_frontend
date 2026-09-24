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
    fun setSdk(proj: Project) {
        val android = proj.extensions.findByName("android")
        if (android != null) {
            try {
                val m = android.javaClass.getMethod("setCompileSdk", java.lang.Integer::class.java)
                m.invoke(android, 36)
                println("SUCCESS: setCompileSdk(36) on ${proj.name}")
            } catch (e: Exception) {
                try {
                    val m = android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    m.invoke(android, 36)
                    println("SUCCESS: setCompileSdkVersion(36) on ${proj.name}")
                } catch (e2: Exception) {
                    println("FAILED on ${proj.name}: $e2")
                }
            }
        }
    }

    if (state.executed) {
        setSdk(this)
    } else {
        afterEvaluate {
            setSdk(this)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
