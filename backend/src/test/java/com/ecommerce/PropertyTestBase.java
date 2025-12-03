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
     * 生成有效的产品名称
     */
    protected Arbitrary<String> productNames() {
        return Arbitraries.strings()
                .alpha()
                .numeric()
                .withChars(' ', '-', '_')
                .ofMinLength(1)
                .ofMaxLength(100)
                .filter(s -> !s.trim().isEmpty()); // 确保不为空
    }
    
    /**
     * 生成有效的描述
     */
    protected Arbitrary<String> descriptions() {
        return Arbitraries.strings()
                .alpha()
                .numeric()
                .withChars(' ', '.', ',', '-', '!', '?')
                .ofMaxLength(500);
    }
    
    /**
     * 生成有效的价格（0.01到9999.99）
     */
    protected Arbitrary<BigDecimal> prices() {
        return Arbitraries.doubles()
                .between(0.01, 9999.99)
                .map(d -> BigDecimal.valueOf(d).setScale(2, RoundingMode.HALF_UP));
    }
    
    /**
     * 生成有效的库存数量（0到10000）
     */
    protected Arbitrary<Integer> stockQuantities() {
        return Arbitraries.integers().between(0, 10000);
    }
    
    /**
     * 生成有效的分类
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
                null  // 允许null分类
        );
    }
    
    /**
     * 生成有效的图片URL
     */
    protected Arbitrary<String> imageUrls() {
        return Arbitraries.strings()
                .alpha()
                .numeric()
                .withChars('/', '.', '-', '_')
                .ofMinLength(10)
                .ofMaxLength(100)
                .map(s -> "https://example.com/images/" + s + ".jpg")
                .injectNull(0.1);  // 10%的null几率
    }
    
    /**
     * 生成有效的Product对象
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
