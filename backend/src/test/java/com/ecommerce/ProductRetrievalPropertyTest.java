package com.ecommerce;

import com.ecommerce.model.Product;
import com.ecommerce.repository.ProductRepository;
import net.jqwik.api.*;
import net.jqwik.spring.JqwikSpringSupport;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Property-based tests for product retrieval completeness
 * Feature: docker-ecommerce-system, Property 1: Product retrieval completeness
 * Validates: Requirements 2.2
 */
@JqwikSpringSupport
@SpringBootTest
@ActiveProfiles("test")
public class ProductRetrievalPropertyTest extends PropertyTestBase {
    
    @Autowired
    private ProductRepository productRepository;
    
    @Property(tries = 100)
    @Label("For any set of products stored in database, GET /api/products returns all products with no omissions or duplicates")
    void productRetrievalCompleteness(@ForAll("productSets") List<Product> productsToStore) {
        // Clean database before test
        productRepository.deleteAll();
        
        // Store products in database
        List<Product> storedProducts = productRepository.saveAll(productsToStore);
        Set<Long> storedIds = new HashSet<>();
        for (Product p : storedProducts) {
            storedIds.add(p.getId());
        }
        
        // Retrieve all products
        List<Product> retrievedProducts = productRepository.findAll();
        
        // Verify: Same number of products
        assert retrievedProducts.size() == storedProducts.size() : 
            String.format("Expected %d products but got %d", storedProducts.size(), retrievedProducts.size());
        
        // Verify: No duplicates in retrieved products
        Set<Long> retrievedIds = new HashSet<>();
        for (Product p : retrievedProducts) {
            boolean added = retrievedIds.add(p.getId());
            assert added : "Duplicate product ID found: " + p.getId();
        }
        
        // Verify: All stored products are retrieved
        for (Long storedId : storedIds) {
            assert retrievedIds.contains(storedId) : 
                "Stored product with ID " + storedId + " was not retrieved";
        }
        
        // Verify: No extra products retrieved
        for (Long retrievedId : retrievedIds) {
            assert storedIds.contains(retrievedId) : 
                "Retrieved product with ID " + retrievedId + " was not stored";
        }
        
        // Verify: Data integrity - check that product data matches
        for (Product stored : storedProducts) {
            Product retrieved = retrievedProducts.stream()
                    .filter(p -> p.getId().equals(stored.getId()))
                    .findFirst()
                    .orElseThrow();
            
            assert stored.getName().equals(retrieved.getName()) : 
                "Product name mismatch for ID " + stored.getId();
            assert stored.getPrice().compareTo(retrieved.getPrice()) == 0 : 
                "Product price mismatch for ID " + stored.getId();
            assert stored.getStockQuantity().equals(retrieved.getStockQuantity()) : 
                "Product stock quantity mismatch for ID " + stored.getId();
        }
    }
    
    @Provide
    Arbitrary<List<Product>> productSets() {
        return validProducts().list().ofMinSize(0).ofMaxSize(20);
    }
}
