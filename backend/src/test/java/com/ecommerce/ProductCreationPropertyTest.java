package com.ecommerce;

import com.ecommerce.model.Product;
import com.ecommerce.repository.ProductRepository;
import net.jqwik.api.*;
import net.jqwik.spring.JqwikSpringSupport;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

/**
 * Property-based tests for product creation persistence
 * Feature: docker-ecommerce-system, Property 2: Product creation persistence
 * Validates: Requirements 2.3
 */
@JqwikSpringSupport
@SpringBootTest
@ActiveProfiles("test")
public class ProductCreationPropertyTest extends PropertyTestBase {
    
    @Autowired
    private ProductRepository productRepository;
    
    @Property(tries = 100)
    @Label("For any valid product data, created product should be retrievable with all fields matching")
    void productCreationPersistence(@ForAll("validProducts") Product productToCreate) {
        // Clean database before test
        productRepository.deleteAll();
        
        // Create product (ensure ID is null for new products)
        productToCreate.setId(null);
        Product createdProduct = productRepository.save(productToCreate);
        
        // Verify product was assigned an ID
        assert createdProduct.getId() != null : "Created product should have an ID";
        
        // Retrieve the product by ID
        Product retrievedProduct = productRepository.findById(createdProduct.getId())
                .orElseThrow(() -> new AssertionError("Product not found after creation"));
        
        // Verify all fields match
        assert retrievedProduct.getName().equals(productToCreate.getName()) : 
            String.format("Name mismatch: expected '%s', got '%s'", 
                productToCreate.getName(), retrievedProduct.getName());
        
        assert retrievedProduct.getDescription().equals(productToCreate.getDescription()) : 
            String.format("Description mismatch: expected '%s', got '%s'", 
                productToCreate.getDescription(), retrievedProduct.getDescription());
        
        assert retrievedProduct.getPrice().compareTo(productToCreate.getPrice()) == 0 : 
            String.format("Price mismatch: expected %s, got %s", 
                productToCreate.getPrice(), retrievedProduct.getPrice());
        
        assert retrievedProduct.getStockQuantity().equals(productToCreate.getStockQuantity()) : 
            String.format("Stock quantity mismatch: expected %d, got %d", 
                productToCreate.getStockQuantity(), retrievedProduct.getStockQuantity());
        
        // Category and imageUrl can be null, so handle that
        if (productToCreate.getCategory() == null) {
            assert retrievedProduct.getCategory() == null : "Category should be null";
        } else {
            assert retrievedProduct.getCategory().equals(productToCreate.getCategory()) : 
                String.format("Category mismatch: expected '%s', got '%s'", 
                    productToCreate.getCategory(), retrievedProduct.getCategory());
        }
        
        if (productToCreate.getImageUrl() == null) {
            assert retrievedProduct.getImageUrl() == null : "Image URL should be null";
        } else {
            assert retrievedProduct.getImageUrl().equals(productToCreate.getImageUrl()) : 
                String.format("Image URL mismatch: expected '%s', got '%s'", 
                    productToCreate.getImageUrl(), retrievedProduct.getImageUrl());
        }
        
        // Verify timestamps were set
        assert retrievedProduct.getCreatedAt() != null : "Created timestamp should be set";
        assert retrievedProduct.getUpdatedAt() != null : "Updated timestamp should be set";
    }
    
    @Provide
    public Arbitrary<Product> validProducts() {
        return super.validProducts();
    }
}
