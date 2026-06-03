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

subprojects {
    val configureNamespace = {
        val androidExtension = extensions.findByName("android")
        if (androidExtension != null) {
            val hasNamespace = try {
                val getNamespace = androidExtension.javaClass.getMethod("getNamespace")
                getNamespace.invoke(androidExtension) != null
            } catch (e: Exception) {
                false
            }

            if (!hasNamespace) {
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val manifestContent = manifestFile.readText()
                    val packageRegex = """package="([^"]+)"""".toRegex()
                    val matchResult = packageRegex.find(manifestContent)
                    val packageName = matchResult?.groupValues?.get(1)
                    if (packageName != null) {
                        try {
                            val setNamespace = androidExtension.javaClass.getMethod("setNamespace", String::class.java)
                            setNamespace.invoke(androidExtension, packageName)
                            logger.lifecycle("Dynamically set namespace to '$packageName' for subproject :${project.name}")
                        } catch (e: Exception) {
                            logger.error("Failed to dynamically set namespace for subproject :${project.name}: $e")
                        }
                    }
                }
            }
        }
    }

    if (state.executed) {
        configureNamespace()
    } else {
        afterEvaluate {
            configureNamespace()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
