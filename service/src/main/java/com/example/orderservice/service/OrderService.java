package com.example.orderservice.service;

import com.example.orderservice.api.model.CreateOrderRequest;
import com.example.orderservice.api.model.Order;
import com.example.orderservice.api.model.OrderStatus;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;
import org.springframework.stereotype.Service;

/** Einfache In-Memory-Verwaltung der Bestellungen. Ersetzt später eine Persistenzschicht. */
@Service
public class OrderService {

    private final Map<UUID, Order> orders = new ConcurrentHashMap<>();

    public Order create(CreateOrderRequest request) {
        Order order = new Order();
        order.setId(UUID.randomUUID());
        order.setCustomerId(request.getCustomerId());
        order.setItems(new ArrayList<>(request.getItems()));
        order.setStatus(OrderStatus.CREATED);
        order.setCreatedAt(OffsetDateTime.now());
        orders.put(order.getId(), order);
        return order;
    }

    /**
     * Storniert eine Bestellung atomar.
     *
     * @throws OrderNotFoundException wenn es die Bestellung nicht gibt
     * @throws OrderAlreadyCancelledException wenn sie bereits storniert ist
     */
    public Order cancel(UUID id) {
        AtomicBoolean alreadyCancelled = new AtomicBoolean(false);
        Order result = orders.computeIfPresent(id, (key, order) -> {
            if (order.getStatus() == OrderStatus.CANCELLED) {
                alreadyCancelled.set(true);
            } else {
                order.setStatus(OrderStatus.CANCELLED);
            }
            return order;
        });
        if (result == null) {
            throw new OrderNotFoundException(id);
        }
        if (alreadyCancelled.get()) {
            throw new OrderAlreadyCancelledException(id);
        }
        return result;
    }

    public Optional<Order> find(UUID id) {
        return Optional.ofNullable(orders.get(id));
    }

    public List<Order> findAll() {
        return orders.values().stream()
            .sorted(Comparator.comparing(Order::getCreatedAt))
            .toList();
    }
}
