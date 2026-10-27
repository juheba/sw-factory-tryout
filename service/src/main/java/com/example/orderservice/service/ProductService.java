package com.example.orderservice.service;

import com.example.orderservice.api.model.Product;
import java.util.Comparator;
import java.util.List;
import org.springframework.stereotype.Service;

/** Fester, nur lesender Produktkatalog im Speicher. */
@Service
public class ProductService {

    private final List<Product> products = List.of(
        new Product("BOOK-001", "Roman", 1299),
        new Product("BOOK-002", "Kochbuch", 2499),
        new Product("MUG-001", "Kaffeebecher", 899),
        new Product("PEN-001", "Kugelschreiber", 199),
        new Product("BAG-001", "Stoffbeutel", 599)
    ).stream().sorted(Comparator.comparing(Product::getSku)).toList();

    public List<Product> findAll() {
        return products;
    }

    public Product get(String sku) {
        return products.stream()
            .filter(product -> product.getSku().equals(sku))
            .findFirst()
            .orElseThrow(() -> new ProductNotFoundException(sku));
    }
}
