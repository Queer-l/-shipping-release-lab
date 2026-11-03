package edu.course.shipping;

import static org.junit.jupiter.api.Assertions.assertEquals;
import java.math.BigDecimal;
import org.junit.jupiter.api.Test;

class ShippingCalculatorTest {
    private final ShippingCalculator calculator = new ShippingCalculator();

    @Test
    void vipOrderAboveThresholdGetsFreeShipping() {
        assertFee("120.00", "VIP", "0");
    }

    @Test
    void standardOrderWellAboveThresholdGetsFreeShipping() {
        assertFee("250.00", "STANDARD", "0");
    }

    @Test
    void standardOrderBelowThresholdPaysNormalFee() {
        assertFee("100.00", "STANDARD", "15.00");
    }

    private void assertFee(String total, String tier, String expected) {
        BigDecimal actual = calculator.shippingFee(new Order(new BigDecimal(total), tier));
        assertEquals(0, actual.compareTo(new BigDecimal(expected)));
    }
}
