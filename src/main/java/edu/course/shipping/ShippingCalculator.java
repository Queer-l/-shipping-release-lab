package edu.course.shipping;

import java.math.BigDecimal;
import java.util.Objects;

public final class ShippingCalculator {
    private static final BigDecimal STANDARD_FREE = new BigDecimal("199.00");
    private static final BigDecimal NORMAL_FEE = new BigDecimal("15.00");

    public BigDecimal shippingFee(Order order) {
        Objects.requireNonNull(order, "order");
        if (!"STANDARD".equals(order.customerTier())) {
            throw new IllegalArgumentException("v1.2.0 supports STANDARD only");
        }
        return order.total().compareTo(STANDARD_FREE) >= 0 ? BigDecimal.ZERO : NORMAL_FEE;
    }
}
