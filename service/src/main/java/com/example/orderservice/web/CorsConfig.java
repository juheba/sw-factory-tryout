package com.example.orderservice.web;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Erlaubt dem Frontend (z. B. Flutter Web im Entwicklungsmodus auf wechselnden localhost-Ports)
 * den Zugriff auf die API. Für Produktion per Property {@code app.cors.allowed-origin-patterns} einschränken.
 */
@Configuration
public class CorsConfig implements WebMvcConfigurer {

    private final String[] allowedOriginPatterns;

    public CorsConfig(@Value("${app.cors.allowed-origin-patterns:http://localhost:*}") String[] allowedOriginPatterns) {
        this.allowedOriginPatterns = allowedOriginPatterns;
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/orders/**")
            .allowedOriginPatterns(allowedOriginPatterns)
            .allowedMethods("GET", "POST");
    }
}
