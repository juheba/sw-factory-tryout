package com.example.orderservice.web;

import com.example.orderservice.service.OrderAlreadyCancelledException;
import com.example.orderservice.service.OrderNotFoundException;
import com.example.orderservice.service.ProductNotFoundException;
import com.example.orderservice.service.UnknownProductException;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import jakarta.validation.Path;
import java.util.stream.Collectors;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

/** Einheitliche Fehlerantworten als RFC-9457-Problem-Details (application/problem+json). */
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    @ExceptionHandler(OrderNotFoundException.class)
    public ProblemDetail handleOrderNotFound(OrderNotFoundException ex) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
    }

    @ExceptionHandler(ProductNotFoundException.class)
    public ProblemDetail handleProductNotFound(ProductNotFoundException ex) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
    }

    @ExceptionHandler(OrderAlreadyCancelledException.class)
    public ProblemDetail handleOrderAlreadyCancelled(OrderAlreadyCancelledException ex) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, ex.getMessage());
    }

    @ExceptionHandler(UnknownProductException.class)
    public ProblemDetail handleUnknownProduct(UnknownProductException ex) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, ex.getMessage());
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ProblemDetail handleConstraintViolation(ConstraintViolationException ex) {
        String detail = ex.getConstraintViolations().stream()
                .map(violation -> lastNodeName(violation) + ": " + violation.getMessage())
                .sorted()
                .collect(Collectors.joining("; "));
        return ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, detail);
    }

    /** Letztes Glied des Property-Pfads (Parametername), ohne Methoden- oder Klassennamen. */
    private static String lastNodeName(ConstraintViolation<?> violation) {
        String name = "";
        for (Path.Node node : violation.getPropertyPath()) {
            name = node.getName();
        }
        return name;
    }
}
