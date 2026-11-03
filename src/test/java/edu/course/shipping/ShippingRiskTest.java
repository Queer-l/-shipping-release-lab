package edu.course.shipping;

import static org.junit.jupiter.api.Assertions.assertEquals;
import java.math.BigDecimal;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/**
 * TODO-J1: add six boundary cases from the requirement, asserting the fee.
 * TODO-J2: add a separate new String("VIP") case at 120.00.
 * Run the new tests before fixing ShippingCalculator; explain each failure.
 * Keep the original three tests unchanged.
 */
class ShippingRiskTest {
    @Test
    void standardJustBelowThresholdPaysNormalFee() {
        assertFee("198.99", "STANDARD", "15.00");
    }

    @Test
    void standardAtThresholdGetsFreeShipping() {
        assertFee("199.00", "STANDARD", "0");
    }

    @Test
    void standardJustAboveThresholdGetsFreeShipping() {
        assertFee("199.01", "STANDARD", "0");
    }

    @Test
    void vipJustBelowThresholdPaysNormalFee() {
        assertFee("98.99", "VIP", "15.00");
    }

    @Test
    void vipAtThresholdGetsFreeShipping() {
        assertFee("99.00", "VIP", "0");
    }

    @Test
    void vipJustAboveThresholdGetsFreeShipping() {
        assertFee("99.01", "VIP", "0");
    }

    @Test
    void vipTierMatchedByValueNotReference() {
        assertFee("120.00", new String("VIP"), "0");
    }

    // Write your @Test methods above or below this helper. It is not a test itself.
    // Pass expected values derived from the requirement; do not change the helper.
    private void assertFee(String total, String tier, String expected) {
        Order order = new Order(new BigDecimal(total), tier);
        BigDecimal actual = new ShippingCalculator().shippingFee(order);
        assertEquals(0, actual.compareTo(new BigDecimal(expected)));
    }
}
