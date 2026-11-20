package com.example.orderservice.web;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import jakarta.validation.Validation;
import jakarta.validation.ValidatorFactory;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import java.lang.reflect.Method;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;

class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    /** Kleine Testklasse mit Parametergrenzen, wie sie ein Endpunkt aus der Spec bekäme. */
    static class Sample {
        void countOrders(@Size(min = 1, max = 64) String customerId, @Min(1) int limit) {
        }
    }

    private ConstraintViolationException violations(String customerId, int limit) throws Exception {
        Method method = Sample.class.getDeclaredMethod("countOrders", String.class, int.class);
        try (ValidatorFactory factory = Validation.buildDefaultValidatorFactory()) {
            Set<ConstraintViolation<Sample>> result = factory.getValidator().forExecutables()
                    .validateParameters(new Sample(), method, new Object[] {customerId, limit});
            return new ConstraintViolationException(result);
        }
    }

    @Test
    void singleViolationNamesOnlyParameter() throws Exception {
        ProblemDetail problem = handler.handleConstraintViolation(violations("", 5));

        assertThat(problem.getStatus()).isEqualTo(HttpStatus.BAD_REQUEST.value());
        assertThat(problem.getDetail()).isEqualTo("customerId: size must be between 1 and 64");
    }

    @Test
    void multipleViolationsAreSortedByParameterName() throws Exception {
        ProblemDetail problem = handler.handleConstraintViolation(violations("", 0));

        assertThat(problem.getDetail())
                .isEqualTo("customerId: size must be between 1 and 64; limit: must be greater than or equal to 1");
    }

    @Test
    void detailContainsNoMethodOrClassName() throws Exception {
        ProblemDetail problem = handler.handleConstraintViolation(violations("", 0));

        assertThat(problem.getDetail()).doesNotContain("countOrders", "Sample", ".");
    }
}
