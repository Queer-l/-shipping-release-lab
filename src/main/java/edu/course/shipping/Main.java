package edu.course.shipping;

import java.math.BigDecimal;

/** A small manual probe; supported tiers are STANDARD and VIP. */
public final class Main {
    private Main() { }

    public static void main(String[] args) {
        if (args.length != 2 || !("STANDARD".equals(args[1]) || "VIP".equals(args[1]))) {
            throw new IllegalArgumentException("Usage: Main <non-negative total> <STANDARD|VIP>");
        }
        Order order = new Order(new BigDecimal(args[0]), args[1]);
        BigDecimal fee = new ShippingCalculator().shippingFee(order);
        System.out.println("shipping=" + fee.setScale(2).toPlainString());
    }
}
