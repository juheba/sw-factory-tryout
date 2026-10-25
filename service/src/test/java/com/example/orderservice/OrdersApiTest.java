package com.example.orderservice;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

@SpringBootTest
class OrdersApiTest {

    private static final String VALID_ORDER = """
        {"customerId": "c-1", "items": [{"sku": "ABC-1", "quantity": 2}]}
        """;

    @Autowired
    private WebApplicationContext context;

    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).build();
    }

    @Test
    void createsOrder() throws Exception {
        mvc.perform(post("/orders").contentType(MediaType.APPLICATION_JSON).content(VALID_ORDER))
            .andExpect(status().isCreated())
            .andExpect(header().exists("Location"))
            .andExpect(jsonPath("$.id", notNullValue()))
            .andExpect(jsonPath("$.status").value("CREATED"))
            .andExpect(jsonPath("$.customerId").value("c-1"))
            .andExpect(jsonPath("$.items", hasSize(1)));
    }

    @Test
    void returnsCreatedOrderById() throws Exception {
        String body = mvc.perform(post("/orders").contentType(MediaType.APPLICATION_JSON).content(VALID_ORDER))
            .andReturn().getResponse().getContentAsString();
        String id = JsonPath.read(body, "$.id");

        mvc.perform(get("/orders/{id}", id))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(id));
    }

    @Test
    void listsOrders() throws Exception {
        mvc.perform(post("/orders").contentType(MediaType.APPLICATION_JSON).content(VALID_ORDER));

        mvc.perform(get("/orders"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$").isArray());
    }

    @Test
    void listsOnlyCancelledOrdersWithStatusCancelled() throws Exception {
        String activeId = createOrderAndReturnId();
        String cancelledId = createOrderAndReturnId();
        mvc.perform(post("/orders/{id}/cancel", cancelledId)).andExpect(status().isOk());

        mvc.perform(get("/orders").param("status", "CANCELLED"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[?(@.id == '" + cancelledId + "')]", hasSize(1)))
            .andExpect(jsonPath("$[?(@.id == '" + activeId + "')]", hasSize(0)))
            .andExpect(jsonPath("$[?(@.status != 'CANCELLED')]", hasSize(0)));
    }

    @Test
    void listsOnlyActiveOrdersWithStatusCreated() throws Exception {
        String activeId = createOrderAndReturnId();
        String cancelledId = createOrderAndReturnId();
        mvc.perform(post("/orders/{id}/cancel", cancelledId)).andExpect(status().isOk());

        mvc.perform(get("/orders").param("status", "CREATED"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[?(@.id == '" + activeId + "')]", hasSize(1)))
            .andExpect(jsonPath("$[?(@.id == '" + cancelledId + "')]", hasSize(0)))
            .andExpect(jsonPath("$[?(@.status != 'CREATED')]", hasSize(0)));
    }

    @Test
    void listsAllOrdersWithoutStatus() throws Exception {
        String activeId = createOrderAndReturnId();
        String cancelledId = createOrderAndReturnId();
        mvc.perform(post("/orders/{id}/cancel", cancelledId)).andExpect(status().isOk());

        mvc.perform(get("/orders"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[?(@.id == '" + activeId + "')]", hasSize(1)))
            .andExpect(jsonPath("$[?(@.id == '" + cancelledId + "')]", hasSize(1)));
    }

    @Test
    void listReturnsProblemDetailsForInvalidStatus() throws Exception {
        mvc.perform(get("/orders").param("status", "BOGUS"))
            .andExpect(status().isBadRequest())
            .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
            .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void rejectsOrderWithoutItems()throws Exception {
        mvc.perform(post("/orders").contentType(MediaType.APPLICATION_JSON)
                .content("{\"customerId\": \"c-1\", \"items\": []}"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void rejectsItemWithZeroQuantity() throws Exception {
        mvc.perform(post("/orders").contentType(MediaType.APPLICATION_JSON)
                .content("{\"customerId\": \"c-1\", \"items\": [{\"sku\": \"A\", \"quantity\": 0}]}"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void returnsNotFoundForUnknownOrder() throws Exception {
        mvc.perform(get("/orders/{id}", UUID.randomUUID()))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404));
    }

    @Test
    void returnsBadRequestForMalformedId() throws Exception {
        mvc.perform(get("/orders/{id}", "not-a-uuid"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void cancelsOrder() throws Exception {
        String id = createOrderAndReturnId();

        mvc.perform(post("/orders/{id}/cancel", id))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(id))
            .andExpect(jsonPath("$.status").value("CANCELLED"));

        mvc.perform(get("/orders/{id}", id))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("CANCELLED"));
    }

    @Test
    void cancelReturnsNotFoundForUnknownOrder() throws Exception {
        mvc.perform(post("/orders/{id}/cancel", UUID.randomUUID()))
            .andExpect(status().isNotFound())
            .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
            .andExpect(jsonPath("$.status").value(404));
    }

    @Test
    void cancelReturnsConflictForAlreadyCancelledOrder() throws Exception {
        String id = createOrderAndReturnId();
        mvc.perform(post("/orders/{id}/cancel", id)).andExpect(status().isOk());

        mvc.perform(post("/orders/{id}/cancel", id))
            .andExpect(status().isConflict())
            .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
            .andExpect(jsonPath("$.status").value(409));
    }

    @Test
    void cancelReturnsBadRequestForMalformedId() throws Exception {
        mvc.perform(post("/orders/{id}/cancel", "not-a-uuid"))
            .andExpect(status().isBadRequest());
    }

    private String createOrderAndReturnId() throws Exception {
        String body = mvc.perform(post("/orders").contentType(MediaType.APPLICATION_JSON).content(VALID_ORDER))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.id");
    }
}
