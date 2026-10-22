import org.springframework.boot.gradle.plugin.SpringBootPlugin

plugins {
    java
    checkstyle
    jacoco
    alias(libs.plugins.spring.boot)
    alias(libs.plugins.openapi.generator)
}

group = "com.example"
version = "0.1.0-SNAPSHOT"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(25)
    }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation(platform(SpringBootPlugin.BOM_COORDINATES))
    implementation("org.springframework.boot:spring-boot-starter-webmvc")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-actuator")

    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.yaml:snakeyaml")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

// ---------------------------------------------------------------------------
// Spec-first: openapi/openapi.yaml ist die Wahrheit, API-Interfaces und Modelle werden generiert.
// ---------------------------------------------------------------------------
val openApiSpec = rootProject.layout.projectDirectory.file("openapi/openapi.yaml")
val openApiOutput = layout.buildDirectory.dir("generated/openapi")

openApiGenerate {
    generatorName.set("spring")
    inputSpec.set(openApiSpec.asFile.path)
    outputDir.set(openApiOutput.get().asFile.path)
    apiPackage.set("com.example.orderservice.api")
    modelPackage.set("com.example.orderservice.api.model")
    // Nur APIs und Modelle erzeugen, keine pom.xml, README, Tests oder Docs.
    globalProperties.set(mapOf("apis" to "", "models" to ""))
    generateApiTests.set(false)
    generateModelTests.set(false)
    generateApiDocumentation.set(false)
    generateModelDocumentation.set(false)
    configOptions.set(
        mapOf(
            "interfaceOnly" to "true",
            "useSpringBoot4" to "true",
            "useJackson3" to "true",
            "useTags" to "true",
            "useBeanValidation" to "true",
            "skipDefaultInterface" to "true",
            "openApiNullable" to "false",
            "documentationProvider" to "none",
            "annotationLibrary" to "none",
            "hideGenerationTimestamp" to "true",
        ),
    )
}

sourceSets {
    main {
        java {
            srcDir(openApiOutput.map { it.dir("src/main/java") })
        }
    }
}

tasks.compileJava {
    dependsOn(tasks.openApiGenerate)
    options.encoding = "UTF-8"
}

// ---------------------------------------------------------------------------
// Qualität: ./gradlew :service:build ist das Gate (Generieren, Kompilieren, Tests, Checkstyle, Coverage-Report).
// ---------------------------------------------------------------------------
checkstyle {
    configFile = rootProject.layout.projectDirectory.file("config/checkstyle/checkstyle.xml").asFile
    maxWarnings = 0
}

tasks.withType<Checkstyle>().configureEach {
    dependsOn(tasks.openApiGenerate)
    // Generierter Code wird nicht geprüft.
    exclude { it.file.path.contains("generated") }
}

jacoco {
    toolVersion = "0.8.14"
}

tasks.test {
    useJUnitPlatform()
    // Der Contract-Test liest die Spec direkt aus openapi/.
    systemProperty("openapi.spec", openApiSpec.asFile.path)
    inputs.file(openApiSpec)
    finalizedBy(tasks.jacocoTestReport)
}

tasks.jacocoTestReport {
    dependsOn(tasks.test)
    reports {
        xml.required = true
        html.required = true
    }
    classDirectories.setFrom(
        files(
            classDirectories.files.map {
                fileTree(it) { exclude("com/example/orderservice/api/**") }
            },
        ),
    )
}
