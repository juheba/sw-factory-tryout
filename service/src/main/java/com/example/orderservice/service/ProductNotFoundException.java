package com.example.orderservice.service;

/** Das angefragte Produkt existiert nicht im Katalog. */
public class ProductNotFoundException extends RuntimeException {

    public ProductNotFoundException(String sku) {
        super("Produkt " + sku + " nicht gefunden");
    }
}
