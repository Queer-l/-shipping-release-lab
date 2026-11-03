package edu.course.shipping;

import java.math.BigDecimal;
import java.util.Objects;

public final class ShippingCalculator {
    private static final BigDecimal STANDARD_FREE = new BigDecimal("199.00");
    private static final BigDecimal VIP_FREE = new BigDecimal("99.00");
    private static final BigDecimal NORMAL_FEE = new BigDecimal("15.00");

    public BigDecimal shippingFee(Order order) {
        Objects.requireNonNull(order, "order");
        // TODO-P: first add tests that expose risk; then fix these comparisons.
        if (order.customerTier().equals("VIP")
                && order.total().compareTo(VIP_FREE) >= 0) {
            return BigDecimal.ZERO;
        }
        if (order.total().compareTo(STANDARD_FREE) >= 0) {
            return BigDecimal.ZERO;
        }
        return NORMAL_FEE;
    }
}
