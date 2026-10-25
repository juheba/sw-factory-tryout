package com.example.orderservice.web;

import com.example.orderservice.api.model.OrderSort;
import org.springframework.core.convert.converter.Converter;
import org.springframework.stereotype.Component;

/** Wandelt den Query-Parameter {@code sort} (z. B. {@code createdAt_desc}) über den Spec-Wert in {@link OrderSort}. */
@Component
public class OrderSortConverter implements Converter<String, OrderSort> {

    @Override
    public OrderSort convert(String source) {
        return OrderSort.fromValue(source);
    }
}
