package com.example.orderservice.service;

import java.util.List;

/** Eine Bestellung enthält Artikelnummern, die nicht im Katalog stehen. */
public class UnknownProductException extends RuntimeException {

    public UnknownProductException(List<String> skus) {
        super("Unbekannte Artikelnummer: " + String.join(", ", skus));
    }
}
