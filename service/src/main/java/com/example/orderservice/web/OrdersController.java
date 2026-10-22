package com.example.orderservice.web;

import com.example.orderservice.api.OrdersApi;
import com.example.orderservice.api.model.CreateOrderRequest;
import com.example.orderservice.api.model.Order;
import com.example.orderservice.service.OrderService;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/** Implementiert das aus openapi.yaml generierte Interface {@link OrdersApi}. */
@RestController
public class OrdersController implements OrdersApi {

    private final OrderService orderService;

    public OrdersController(OrderService orderService) {
        this.orderService = orderService;
    }

    @Override
    public ResponseEntity<List<Order>> listOrders() {
        return ResponseEntity.ok(orderService.findAll());
    }

    @Override
    public ResponseEntity<Order> createOrder(CreateOrderRequest createOrderRequest) {
        Order created = orderService.create(createOrderRequest);
        return ResponseEntity.created(URI.create("/orders/" + created.getId())).body(created);
    }

    @Override
    public ResponseEntity<Order> getOrder(UUID id) {
        return orderService.find(id)
            .map(ResponseEntity::ok)
            .orElseThrow(() -> new ResponseStatusException(
                HttpStatus.NOT_FOUND, "Bestellung " + id + " nicht gefunden"));
    }
}
