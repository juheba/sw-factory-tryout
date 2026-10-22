// Das Root-Projekt enthält keinen Code. Plugins werden hier nur einmal mit Version
// deklariert; die Teilprojekte wenden sie ohne Versionsangabe an.
plugins {
    alias(libs.plugins.spring.boot) apply false
    alias(libs.plugins.openapi.generator) apply false
}
