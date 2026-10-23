package com.example.orderservice.service;

import java.util.UUID;

/** Die angefragte Bestellung existiert nicht. */
public class OrderNotFoundException extends RuntimeException {

    public OrderNotFoundException(UUID id) {
        super("Bestellung " + id + " nicht gefunden");
    }
}
