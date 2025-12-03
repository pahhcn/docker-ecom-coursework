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
     * 获取所有产品
     * @return 所有产品的列表
     */
    public List<Product> getAllProducts() {
        return productRepository.findAll();
    }
    
    /**
     * 根据ID获取产品
     * @param id 产品ID
     * @return 如果找到则包含产品的Optional对象
     */
    public Optional<Product> getProductById(Long id) {
        return productRepository.findById(id);
    }
    
    /**
     * 创建新产品
     * @param product 要创建的产品
     * @return 创建的产品
     */
    public Product createProduct(Product product) {
        // 确保新产品的ID为null
        product.setId(null);
        return productRepository.save(product);
    }
    
    /**
     * 更新现有产品
     * @param id 产品ID
     * @param productDetails 更新的产品详情
     * @return 如果找到则返回更新后的产品
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
     * 删除产品
     * @param id 产品ID
     * @return 如果产品被删除则返回true，否则返回false
     */
    public boolean deleteProduct(Long id) {
        if (productRepository.existsById(id)) {
            productRepository.deleteById(id);
            return true;
        }
        return false;
    }
}
