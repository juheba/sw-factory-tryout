plugins {
    // Lädt fehlende JDKs (z. B. Java 25) automatisch nach, wenn lokal keins vorhanden ist.
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

rootProject.name = "sw-factory-tryout"

// service:  Spring Boot Microservice
// frontend: Flutter-App; Gradle erzeugt hier nur den Dart-Client aus openapi/openapi.yaml
include("service", "frontend")
