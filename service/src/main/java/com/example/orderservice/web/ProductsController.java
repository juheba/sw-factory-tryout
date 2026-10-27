package com.example.orderservice.web;

import com.example.orderservice.api.ProductsApi;
import com.example.orderservice.api.model.Product;
import com.example.orderservice.service.ProductService;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

/** Implementiert das aus openapi.yaml generierte Interface {@link ProductsApi}. */
@RestController
public class ProductsController implements ProductsApi {

    private final ProductService productService;

    public ProductsController(ProductService productService) {
        this.productService = productService;
    }

    @Override
    public ResponseEntity<List<Product>> listProducts() {
        return ResponseEntity.ok(productService.findAll());
    }

    @Override
    public ResponseEntity<Product> getProduct(String sku) {
        return ResponseEntity.ok(productService.get(sku));
    }
}
