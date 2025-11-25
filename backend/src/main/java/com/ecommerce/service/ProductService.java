package com.ecommerce.service;

import com.ecommerce.model.Product;
import com.ecommerce.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class ProductService {
    
    private final ProductRepository productRepository;
    
    @Autowired
    public ProductService(ProductRepository productRepository) {
        this.productRepository = productRepository;
    }
    
    /**
     * Get all products
     * @return List of all products
     */
    public List<Product> getAllProducts() {
        return productRepository.findAll();
    }
    
    /**
     * Get product by ID
     * @param id Product ID
     * @return Optional containing the product if found
     */
    public Optional<Product> getProductById(Long id) {
        return productRepository.findById(id);
    }
    
    /**
     * Create a new product
     * @param product Product to create
     * @return Created product
     */
    public Product createProduct(Product product) {
        // Ensure ID is null for new products
        product.setId(null);
        return productRepository.save(product);
    }
    
    /**
     * Update an existing product
     * @param id Product ID
     * @param productDetails Updated product details
     * @return Updated product if found
     */
    public Optional<Product> updateProduct(Long id, Product productDetails) {
        return productRepository.findById(id)
                .map(existingProduct -> {
                    existingProduct.setName(productDetails.getName());
                    existingProduct.setDescription(productDetails.getDescription());
                    existingProduct.setPrice(productDetails.getPrice());
                    existingProduct.setStockQuantity(productDetails.getStockQuantity());
                    existingProduct.setCategory(productDetails.getCategory());
                    existingProduct.setImageUrl(productDetails.getImageUrl());
                    return productRepository.save(existingProduct);
                });
    }
    
    /**
     * Delete a product
     * @param id Product ID
     * @return true if product was deleted, false if not found
     */
    public boolean deleteProduct(Long id) {
        if (productRepository.existsById(id)) {
            productRepository.deleteById(id);
            return true;
        }
        return false;
    }
}
