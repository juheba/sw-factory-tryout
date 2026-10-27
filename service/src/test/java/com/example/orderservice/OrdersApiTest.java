package com.example.orderservice;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

@SpringBootTest
class OrdersApiTest {

    private static final String VALID_ORDER = """
        {"customerId": "c-1", "items": [{"sku": "BOOK-001", "quantity": 2}]}
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
    void listsOldestFirstWithSortCreatedAtAsc() throws Exception {
        List<String> ids = createOrdersWithDistinctTimestamps(3);

        assertThat(listIds(ids, null, "createdAt_asc")).containsExactlyElementsOf(ids);
    }

    @Test
    void listsNewestFirstWithSortCreatedAtDesc() throws Exception {
        List<String> ids = createOrdersWithDistinctTimestamps(3);

        assertThat(listIds(ids, null, "createdAt_desc")).containsExactlyElementsOf(List.of(
            ids.get(2), ids.get(1), ids.get(0)));
    }

    @Test
    void keepsCreationOrderWithoutSort() throws Exception {
        List<String> ids = createOrdersWithDistinctTimestamps(3);

        assertThat(listIds(ids, null, null)).containsExactlyElementsOf(ids);
    }

    @Test
    void combinesSortWithStatusFilter() throws Exception {
        List<String> ids = createOrdersWithDistinctTimestamps(4);
        mvc.perform(post("/orders/{id}/cancel", ids.get(1))).andExpect(status().isOk());
        mvc.perform(post("/orders/{id}/cancel", ids.get(3))).andExpect(status().isOk());

        assertThat(listIds(ids, "CANCELLED", "createdAt_desc"))
            .containsExactly(ids.get(3), ids.get(1));
        assertThat(listIds(ids, "CREATED", "createdAt_desc"))
            .containsExactly(ids.get(2), ids.get(0));
    }

    @Test
    void listReturnsProblemDetailsForInvalidSort() throws Exception {
        mvc.perform(get("/orders").param("sort", "BOGUS"))
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
                .content("{\"customerId\": \"c-1\", \"items\": [{\"sku\": \"BOOK-001\", \"quantity\": 0}]}"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void rejectsUnknownSku() throws Exception {
        mvc.perform(post("/orders").contentType(MediaType.APPLICATION_JSON)
                .content("{\"customerId\": \"c-1\", \"items\": [{\"sku\": \"X-1\", \"quantity\": 1}]}"))
            .andExpect(status().isBadRequest())
            .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
            .andExpect(jsonPath("$.status").value(400))
            .andExpect(jsonPath("$.detail").value("Unbekannte Artikelnummer: X-1"));
    }

    @Test
    void listsAllUnknownSkusInRequestOrder() throws Exception {
        mvc.perform(post("/orders").contentType(MediaType.APPLICATION_JSON)
                .content("{\"customerId\": \"c-1\", \"items\": [{\"sku\": \"X-1\", \"quantity\": 1},"
                    + " {\"sku\": \"BOOK-001\", \"quantity\": 1}, {\"sku\": \"Y-2\", \"quantity\": 1}]}"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.detail").value("Unbekannte Artikelnummer: X-1, Y-2"));
    }

    @Test
    void storesNothingForMixedKnownAndUnknownSkus() throws Exception {
        int before = countOrders();

        mvc.perform(post("/orders").contentType(MediaType.APPLICATION_JSON)
                .content("{\"customerId\": \"c-1\", \"items\": [{\"sku\": \"BOOK-001\", \"quantity\": 1},"
                    + " {\"sku\": \"X-1\", \"quantity\": 1}]}"))
            .andExpect(status().isBadRequest());

        assertThat(countOrders()).isEqualTo(before);
    }

    private int countOrders() throws Exception {
        String body = mvc.perform(get("/orders")).andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        List<String> ids = JsonPath.read(body, "$[*].id");
        return ids.size();
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

    private List<String> createOrdersWithDistinctTimestamps(int count) throws Exception {
        List<String> ids = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            ids.add(createOrderAndReturnId());
            Thread.sleep(5);
        }
        return ids;
    }

    /** Liefert die Ids aus der Antwort in Antwortreihenfolge, beschränkt auf {@code knownIds}. */
    private List<String> listIds(List<String> knownIds, String statusParam, String sortParam) throws Exception {
        MockHttpServletRequestBuilder request = get("/orders");
        if (statusParam != null) {
            request = request.param("status", statusParam);
        }
        if (sortParam != null) {
            request = request.param("sort", sortParam);
        }
        String body = mvc.perform(request).andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        List<String> all = JsonPath.read(body, "$[*].id");
        return all.stream().filter(knownIds::contains).toList();
    }

    private String createOrderAndReturnId() throws Exception {
        String body = mvc.perform(post("/orders").contentType(MediaType.APPLICATION_JSON).content(VALID_ORDER))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.id");
    }
}
