package com.ecommerce;

import com.ecommerce.model.Product;
import com.ecommerce.repository.ProductRepository;
import net.jqwik.api.*;
import net.jqwik.spring.JqwikSpringSupport;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;

/**
 * Property-based tests for product deletion completeness
 * Feature: docker-ecommerce-system, Property 4: Product deletion completeness
 * Validates: Requirements 2.5
 */
@JqwikSpringSupport
@SpringBootTest
@ActiveProfiles("test")
public class ProductDeletionPropertyTest extends PropertyTestBase {
    
    @Autowired
    private ProductRepository productRepository;
    
    @Property(tries = 100)
    @Label("For any existing product, after deletion it should not be retrievable")
    void productDeletionCompleteness(@ForAll("productSets") List<Product> productsToCreate) {
        // Clean database before test
        productRepository.deleteAll();
        
        // Skip empty lists
        if (productsToCreate.isEmpty()) {
            return;
        }
        
        // Create products
        List<Product> savedProducts = productRepository.saveAll(productsToCreate);
        
        // Pick a random product to delete
        Product productToDelete = savedProducts.get(0);
        Long deletedId = productToDelete.getId();
        
        // Delete the product
        productRepository.deleteById(deletedId);
        
        // Verify: Product is no longer retrievable by ID
        boolean exists = productRepository.existsById(deletedId);
        assert !exists : String.format("Product with ID %d should not exist after deletion", deletedId);
        
        // Verify: Product is not in the list of all products
        List<Product> remainingProducts = productRepository.findAll();
        for (Product p : remainingProducts) {
            assert !p.getId().equals(deletedId) : 
                String.format("Deleted product with ID %d should not appear in product list", deletedId);
        }
        
        // Verify: Correct number of products remain
        int expectedCount = savedProducts.size() - 1;
        assert remainingProducts.size() == expectedCount : 
            String.format("Expected %d products after deletion, but found %d", 
                expectedCount, remainingProducts.size());
        
        // Verify: All other products are still present
        for (Product saved : savedProducts) {
            if (!saved.getId().equals(deletedId)) {
                boolean stillExists = productRepository.existsById(saved.getId());
                assert stillExists : 
                    String.format("Product with ID %d should still exist after deleting product %d", 
                        saved.getId(), deletedId);
            }
        }
    }
    
    @Provide
    Arbitrary<List<Product>> productSets() {
        return validProducts().list().ofMinSize(1).ofMaxSize(20);
    }
    
    @Provide
    public Arbitrary<Product> validProducts() {
        return super.validProducts();
    }
}
