package com.example.orderservice;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

@SpringBootTest
class ProductsApiTest {

    @Autowired
    private WebApplicationContext context;

    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).build();
    }

    @Test
    void listsProductsSortedBySku() throws Exception {
        mvc.perform(get("/products"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$", hasSize(5)))
            .andExpect(jsonPath("$[0].sku").value("BAG-001"))
            .andExpect(jsonPath("$[1].sku").value("BOOK-001"))
            .andExpect(jsonPath("$[2].sku").value("BOOK-002"))
            .andExpect(jsonPath("$[3].sku").value("MUG-001"))
            .andExpect(jsonPath("$[4].sku").value("PEN-001"));
    }

    @Test
    void returnsProductBySku() throws Exception {
        mvc.perform(get("/products/MUG-001"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.sku").value("MUG-001"))
            .andExpect(jsonPath("$.name").value("Kaffeebecher"))
            .andExpect(jsonPath("$.priceCents").value(899));
    }

    @Test
    void returnsProblemForUnknownSku() throws Exception {
        mvc.perform(get("/products/UNKNOWN"))
            .andExpect(status().isNotFound())
            .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
            .andExpect(jsonPath("$.status").value(404))
            .andExpect(jsonPath("$.detail").value("Produkt UNKNOWN nicht gefunden"));
    }
}
