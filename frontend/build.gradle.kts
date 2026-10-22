// Dieses Gradle-Projekt erzeugt nur den Dart-Client aus der Spec.
// Gebaut, analysiert und getestet wird das Frontend mit Flutter (siehe tool/verify.sh).
plugins {
    alias(libs.plugins.openapi.generator)
}

openApiGenerate {
    generatorName.set("dart")
    inputSpec.set(rootProject.layout.projectDirectory.file("openapi/openapi.yaml").asFile.path)
    outputDir.set(layout.projectDirectory.dir("packages/order_api").asFile.path)
    generateApiTests.set(false)
    generateModelTests.set(false)
    generateApiDocumentation.set(false)
    generateModelDocumentation.set(false)
    configOptions.set(
        mapOf(
            "pubName" to "order_api",
            "pubLibrary" to "order_api",
            "pubDescription" to "Generierter Client für den Order Service",
            "sourceFolder" to "",
        ),
    )
}
