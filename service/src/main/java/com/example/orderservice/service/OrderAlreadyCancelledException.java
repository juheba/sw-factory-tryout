package com.example.orderservice.service;

import java.util.UUID;

/** Die Bestellung wurde bereits storniert und kann nicht erneut storniert werden. */
public class OrderAlreadyCancelledException extends RuntimeException {

    public OrderAlreadyCancelledException(UUID id) {
        super("Bestellung " + id + " ist bereits storniert");
    }
}
