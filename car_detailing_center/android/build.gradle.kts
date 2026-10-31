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
    val configureCompileSdk: () -> Unit = {
        val android = extensions.findByName("android")
        if (android != null) {
            for (method in android.javaClass.methods) {
                if ((method.name == "setCompileSdkVersion" || method.name == "compileSdkVersion" || method.name == "setCompileSdk") && method.parameterCount == 1) {
                    try {
                        val paramType = method.parameterTypes[0]
                        if (paramType == Int::class.javaPrimitiveType || paramType == java.lang.Integer::class.java) {
                            method.invoke(android, 36)
                            break
                        }
                    } catch (_: Throwable) {}
                }
            }
        }
    }

    if (state.executed) {
        configureCompileSdk()
    } else {
        afterEvaluate {
            configureCompileSdk()
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
