package com.example.orderservice.architecture;

import static com.tngtech.archunit.base.DescribedPredicate.not;
import static com.tngtech.archunit.core.domain.JavaClass.Predicates.resideInAPackage;
import static com.tngtech.archunit.core.domain.JavaClass.Predicates.simpleNameEndingWith;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noFields;
import static com.tngtech.archunit.library.dependencies.SlicesRuleDefinition.slices;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.library.GeneralCodingRules;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.RestController;

/**
 * Architekturregeln als Gate (Issue #196). Maßstab: config/standards/architektur.md.
 *
 * <p>Dieser Ordner ist Schutzbereich: Regeln ändert nur der Owner. Generierter Code aus der Spec
 * (Paket {@code api}) ist von den Regeln ausgenommen, er wird nie von Hand geändert (ARCH-1).
 */
class ArchitectureTest {

    private static final String ROOT = "com.example.orderservice";
    private static final String API = ROOT + ".api..";
    private static final String WEB = ROOT + ".web..";
    private static final String SERVICE = ROOT + ".service..";

    private static final JavaClasses CLASSES = new ClassFileImporter()
        .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
        .importPackages(ROOT);

    // Stufe 1: Grundregeln

    @Test
    void serviceDoesNotDependOnWebOrHttp() {
        noClasses().that().resideInAPackage(SERVICE)
            .should().dependOnClassesThat()
            .resideInAnyPackage(WEB, "org.springframework.http..", "org.springframework.web..")
            .because("ARCH-2: Abhängigkeiten nach innen – Fachliche Logik hängt nicht von der Transportschicht ab")
            .check(CLASSES);
    }

    @Test
    void problemDetailsAreCreatedOnlyInWeb() {
        noClasses().that().resideOutsideOfPackages(WEB, API)
            .should().dependOnClassesThat().areAssignableTo(ProblemDetail.class)
            .because("ARCH-4: Fehler innen, Format außen – Problem-Details entstehen nur im Paket web")
            .check(CLASSES);
    }

    @Test
    void controllersLiveInWebAndImplementGeneratedApi() {
        classes().that().areAnnotatedWith(RestController.class)
            .should().resideInAPackage(WEB)
            .andShould().implement(resideInAPackage(ROOT + ".api").and(simpleNameEndingWith("Api")))
            .because("DoD-A2: Controller implementieren Api und ARCH-1: Vertrag zuerst – "
                + "Controller implementieren die generierten *Api-Interfaces")
            .check(CLASSES);
    }

    @Test
    void noFieldInjection() {
        noFields().that().areDeclaredInClassesThat().resideOutsideOfPackage(API)
            .should().beAnnotatedWith(Autowired.class)
            .because("ARCH-7: Konstruktor-Injektion – Abhängigkeiten kommen über den Konstruktor")
            .check(CLASSES);
    }

    // Stufe 2: allgemeine Regeln

    @Test
    void packagesAreFreeOfCycles() {
        slices().matching(ROOT + ".(*)..")
            .should().beFreeOfCycles()
            .because("ARCH-2: Abhängigkeiten nach innen – Abhängigkeiten zeigen in eine Richtung")
            .check(CLASSES);
    }

    @Test
    void noStandardStreams() {
        noClasses().that(not(resideInAPackage(API)))
            .should(GeneralCodingRules.ACCESS_STANDARD_STREAMS)
            .because("ARCH-9: Querschnitt konfiguriert – Ausgaben laufen über Logging, "
                + "nicht über System.out oder System.err")
            .check(CLASSES);
    }

    @Test
    void noGenericExceptions() {
        noClasses().that(not(resideInAPackage(API)))
            .should(GeneralCodingRules.THROW_GENERIC_EXCEPTIONS)
            .because("ARCH-4: Fehler innen, Format außen – Fehler sind eigene, sprechende Typen")
            .check(CLASSES);
    }

    @Test
    void noJavaUtilLogging() {
        noClasses().that(not(resideInAPackage(API)))
            .should(GeneralCodingRules.USE_JAVA_UTIL_LOGGING)
            .because("ARCH-9: Querschnitt konfiguriert – einheitliches Logging über Spring Boot")
            .check(CLASSES);
    }
}
