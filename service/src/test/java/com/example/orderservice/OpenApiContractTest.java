package com.example.orderservice;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.mvc.method.RequestMappingInfo;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;
import org.yaml.snakeyaml.Yaml;

/**
 * Prüft, dass die laufende Anwendung genau die Operationen anbietet, die openapi.yaml beschreibt.
 * Schutz gegen Drift zwischen Vertrag und Implementierung.
 */
@SpringBootTest
class OpenApiContractTest {

    @Autowired
    private ApplicationContext context;

    @Test
    void implementedOperationsMatchTheSpecification() throws Exception {
        assertThat(implementedOperations()).containsExactlyInAnyOrderElementsOf(specifiedOperations());
    }

    @SuppressWarnings("unchecked")
    private Set<String> specifiedOperations() throws Exception {
        Set<String> operations = new HashSet<>();
        String specPath = System.getProperty("openapi.spec");
        assertThat(specPath).as("System Property openapi.spec (setzt Gradle)").isNotBlank();
        try (InputStream in = Files.newInputStream(Path.of(specPath))) {
            Map<String, Object> spec = new Yaml().load(in);
            Map<String, Map<String, Object>> paths = (Map<String, Map<String, Object>>) spec.get("paths");
            paths.forEach((path, item) -> item.keySet().stream()
                .filter(key -> Set.of("get", "put", "post", "delete", "patch").contains(key))
                .forEach(method -> operations.add(method.toUpperCase(Locale.ROOT) + " " + path)));
        }
        return operations;
    }

    private Set<String> implementedOperations() {
        Set<String> operations = new HashSet<>();
        var mappings = context.getBeansOfType(RequestMappingHandlerMapping.class).values();
        for (RequestMappingHandlerMapping mapping : mappings) {
            for (Map.Entry<RequestMappingInfo, HandlerMethod> entry : mapping.getHandlerMethods().entrySet()) {
                if (!entry.getValue().getBeanType().getPackageName().startsWith("com.example.orderservice")) {
                    continue;
                }
                RequestMappingInfo info = entry.getKey();
                for (RequestMethod method : info.getMethodsCondition().getMethods()) {
                    for (String pattern : info.getPathPatternsCondition().getPatternValues()) {
                        operations.add(method.name() + " " + pattern);
                    }
                }
            }
        }
        return operations;
    }
}
