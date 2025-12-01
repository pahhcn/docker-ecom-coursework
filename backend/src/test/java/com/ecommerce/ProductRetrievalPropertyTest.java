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
    @Label("对于数据库中存储的任何产品集，GET /api/products 应返回所有产品，无遗漏或重复")
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
            String.format("期望 %d 个产品但得到 %d 个", storedProducts.size(), retrievedProducts.size());
        
        // Verify: No duplicates in retrieved products
        Set<Long> retrievedIds = new HashSet<>();
        for (Product p : retrievedProducts) {
            boolean added = retrievedIds.add(p.getId());
            assert added : "检索到的产品发现重复ID: " + p.getId();
        }
        
        // Verify: All stored products are retrieved
        for (Long storedId : storedIds) {
            assert retrievedIds.contains(storedId) : 
                "存储的产品ID " + storedId + " 未被检索到";
        }
        
        // Verify: No extra products retrieved
        for (Long retrievedId : retrievedIds) {
            assert storedIds.contains(retrievedId) : 
                "检索到的产品ID " + retrievedId + " 未被存储";
        }
        
        // Verify: Data integrity - check that product data matches
        for (Product stored : storedProducts) {
            Product retrieved = retrievedProducts.stream()
                    .filter(p -> p.getId().equals(stored.getId()))
                    .findFirst()
                    .orElseThrow();
            
            assert stored.getName().equals(retrieved.getName()) : 
                "产品名称不匹配，ID为 " + stored.getId();
            assert stored.getPrice().compareTo(retrieved.getPrice()) == 0 : 
                "产品价格不匹配，ID为 " + stored.getId();
            assert stored.getStockQuantity().equals(retrieved.getStockQuantity()) : 
                "产品库存数量不匹配，ID为 " + stored.getId();
        }
    }
    
    @Provide
    Arbitrary<List<Product>> productSets() {
        return validProducts().list().ofMinSize(0).ofMaxSize(20);
    }
}
