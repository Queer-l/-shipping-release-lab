package edu.course.shipping;

import java.math.BigDecimal;
import java.util.Objects;

public record Order(BigDecimal total, String customerTier) {
    public Order {
        Objects.requireNonNull(total, "total");
        Objects.requireNonNull(customerTier, "customerTier");
        if (total.signum() < 0) {
            throw new IllegalArgumentException("total must be non-negative");
        }
    }
}
