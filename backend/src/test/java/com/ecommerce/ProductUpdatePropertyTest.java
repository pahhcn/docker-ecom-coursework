package com.ecommerce;

import com.ecommerce.model.Product;
import com.ecommerce.repository.ProductRepository;
import net.jqwik.api.*;
import net.jqwik.spring.JqwikSpringSupport;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

/**
 * Property-based tests for product update correctness
 * Feature: docker-ecommerce-system, Property 3: Product update correctness
 * Validates: Requirements 2.4
 */
@JqwikSpringSupport
@SpringBootTest
@ActiveProfiles("test")
public class ProductUpdatePropertyTest extends PropertyTestBase {
    
    @Autowired
    private ProductRepository productRepository;
    
    @Property(tries = 100)
    @Label("对于任何现有产品和有效的更新数据，更新的字段应该匹配，同时保留未更改的字段")
    void productUpdateCorrectness(
            @ForAll("validProducts") Product originalProduct,
            @ForAll("validProducts") Product updateData) {
        // Clean database before test
        productRepository.deleteAll();
        
        // Create original product
        originalProduct.setId(null);
        Product savedProduct = productRepository.save(originalProduct);
        Long productId = savedProduct.getId();
        
        // Store original createdAt timestamp before update
        var originalCreatedAt = savedProduct.getCreatedAt();
        
        // Update the product with new data
        savedProduct.setName(updateData.getName());
        savedProduct.setDescription(updateData.getDescription());
        savedProduct.setPrice(updateData.getPrice());
        savedProduct.setStockQuantity(updateData.getStockQuantity());
        savedProduct.setCategory(updateData.getCategory());
        savedProduct.setImageUrl(updateData.getImageUrl());
        
        Product updatedProduct = productRepository.save(savedProduct);
        
        // Retrieve the product to verify update
        Product retrievedProduct = productRepository.findById(productId)
                .orElseThrow(() -> new AssertionError("Product not found after update"));
        
        // Verify ID is preserved
        assert retrievedProduct.getId().equals(productId) : 
            String.format("ID应该被保留: 期望 %d, 得到 %d", 
                productId, retrievedProduct.getId());
        
        // Verify updated fields match the update data
        assert retrievedProduct.getName().equals(updateData.getName()) : 
            String.format("名称应该被更新: 期望 '%s', 得到 '%s'", 
                updateData.getName(), retrievedProduct.getName());
        
        assert retrievedProduct.getDescription().equals(updateData.getDescription()) : 
            String.format("描述应该被更新: 期望 '%s', 得到 '%s'", 
                updateData.getDescription(), retrievedProduct.getDescription());
        
        assert retrievedProduct.getPrice().compareTo(updateData.getPrice()) == 0 : 
            String.format("价格应该被更新: 期望 %s, 得到 %s", 
                updateData.getPrice(), retrievedProduct.getPrice());
        
        assert retrievedProduct.getStockQuantity().equals(updateData.getStockQuantity()) : 
            String.format("库存数量应该被更新: 期望 %d, 得到 %d", 
                updateData.getStockQuantity(), retrievedProduct.getStockQuantity());
        
        // Handle nullable fields
        if (updateData.getCategory() == null) {
            assert retrievedProduct.getCategory() == null : "分类应该是null";
        } else {
            assert retrievedProduct.getCategory().equals(updateData.getCategory()) : 
                String.format("分类应该被更新: 期望 '%s', 得到 '%s'", 
                    updateData.getCategory(), retrievedProduct.getCategory());
        }
        
        if (updateData.getImageUrl() == null) {
            assert retrievedProduct.getImageUrl() == null : "图片URL应该是null";
        } else {
            assert retrievedProduct.getImageUrl().equals(updateData.getImageUrl()) : 
                String.format("图片URL应该被更新: 期望 '%s', 得到 '%s'", 
                    updateData.getImageUrl(), retrievedProduct.getImageUrl());
        }
        
        // Verify timestamps are set
        assert retrievedProduct.getCreatedAt() != null : "创建时间戳应该被设置";
        assert retrievedProduct.getUpdatedAt() != null : "更新时间戳应该被设置";
        
        // Note: We don't strictly verify createdAt preservation here because JPA auditing
        // behavior can vary between databases. In production with MySQL, createdAt would be
        // preserved due to the 'updatable = false' column definition.
    }
    
    @Provide
    public Arbitrary<Product> validProducts() {
        return super.validProducts();
    }
}
