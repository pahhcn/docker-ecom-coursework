package com.ecommerce;

import com.ecommerce.model.Product;
import net.jqwik.api.Arbitraries;
import net.jqwik.api.Arbitrary;
import net.jqwik.api.Combinators;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.math.RoundingMode;

@SpringBootTest
@ActiveProfiles("test")
public abstract class PropertyTestBase {
    
    /**
     * Generate valid product names
     */
    protected Arbitrary<String> productNames() {
        return Arbitraries.strings()
                .alpha()
                .numeric()
                .withChars(' ', '-', '_')
                .ofMinLength(1)
                .ofMaxLength(100)
                .filter(s -> !s.trim().isEmpty()); // Ensure not blank
    }
    
    /**
     * Generate valid descriptions
     */
    protected Arbitrary<String> descriptions() {
        return Arbitraries.strings()
                .alpha()
                .numeric()
                .withChars(' ', '.', ',', '-', '!', '?')
                .ofMaxLength(500);
    }
    
    /**
     * Generate valid prices (0.01 to 9999.99)
     */
    protected Arbitrary<BigDecimal> prices() {
        return Arbitraries.doubles()
                .between(0.01, 9999.99)
                .map(d -> BigDecimal.valueOf(d).setScale(2, RoundingMode.HALF_UP));
    }
    
    /**
     * Generate valid stock quantities (0 to 10000)
     */
    protected Arbitrary<Integer> stockQuantities() {
        return Arbitraries.integers().between(0, 10000);
    }
    
    /**
     * Generate valid categories
     */
    protected Arbitrary<String> categories() {
        return Arbitraries.of(
                "Electronics",
                "Clothing",
                "Books",
                "Home & Garden",
                "Sports",
                "Toys",
                "Food & Beverage",
                "Health & Beauty",
                null  // Allow null categories
        );
    }
    
    /**
     * Generate valid image URLs
     */
    protected Arbitrary<String> imageUrls() {
        return Arbitraries.strings()
                .alpha()
                .numeric()
                .withChars('/', '.', '-', '_')
                .ofMinLength(10)
                .ofMaxLength(100)
                .map(s -> "https://example.com/images/" + s + ".jpg")
                .injectNull(0.1);  // 10% chance of null
    }
    
    /**
     * Generate valid Product objects
     */
    protected Arbitrary<Product> validProducts() {
        return Combinators.combine(
                productNames(),
                descriptions(),
                prices(),
                stockQuantities(),
                categories(),
                imageUrls()
        ).as(Product::new);
    }
}
