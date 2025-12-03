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
    @Label("对于任何现有产品，删除后应该无法检索")
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
        assert !exists : String.format("删除后ID为 %d 的产品应该不存在", deletedId);
        
        // Verify: Product is not in the list of all products
        List<Product> remainingProducts = productRepository.findAll();
        for (Product p : remainingProducts) {
            assert !p.getId().equals(deletedId) : 
                String.format("删除的产品ID %d 不应该出现在产品列表中", deletedId);
        }
        
        // Verify: Correct number of products remain
        int expectedCount = savedProducts.size() - 1;
        assert remainingProducts.size() == expectedCount : 
            String.format("删除后期望剩余 %d 个产品，但找到 %d 个", 
                expectedCount, remainingProducts.size());
        
        // Verify: All other products are still present
        for (Product saved : savedProducts) {
            if (!saved.getId().equals(deletedId)) {
                boolean stillExists = productRepository.existsById(saved.getId());
                assert stillExists : 
                    String.format("删除产品 %d 后，产品ID %d 应该仍然存在", 
                        deletedId, saved.getId());
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
