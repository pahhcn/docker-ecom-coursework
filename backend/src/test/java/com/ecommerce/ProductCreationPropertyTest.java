package com.ecommerce;

import com.ecommerce.model.Product;
import com.ecommerce.repository.ProductRepository;
import net.jqwik.api.*;
import net.jqwik.spring.JqwikSpringSupport;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

/**
 * 产品创建持久化的基于属性的测试
 * 特性：docker-ecommerce-system，属性2：产品创建持久化
 * 验证：需求2.3
 */
@JqwikSpringSupport
@SpringBootTest
@ActiveProfiles("test")
public class ProductCreationPropertyTest extends PropertyTestBase {
    
    @Autowired
    private ProductRepository productRepository;
    
    @Property(tries = 100)
    @Label("对于任何有效的产品数据，创建的产品应该可以检索并且所有字段匹配")
    void productCreationPersistence(@ForAll("validProducts") Product productToCreate) {
        // 测试前清理数据库
        productRepository.deleteAll();
        
        // 创建产品（确保新产品的ID为null）
        productToCreate.setId(null);
        Product createdProduct = productRepository.save(productToCreate);
        
        // Verify product was assigned an ID
        assert createdProduct.getId() != null : "创建的产品应该有ID";
        
        // 根据ID检索产品
        Product retrievedProduct = productRepository.findById(createdProduct.getId())
                .orElseThrow(() -> new AssertionError("创建后找不到产品"));
        
        // Verify all fields match
        assert retrievedProduct.getName().equals(productToCreate.getName()) : 
            String.format("名称不匹配: 期望 '%s', 得到 '%s'", 
                productToCreate.getName(), retrievedProduct.getName());
        
        assert retrievedProduct.getDescription().equals(productToCreate.getDescription()) : 
            String.format("描述不匹配: 期望 '%s', 得到 '%s'", 
                productToCreate.getDescription(), retrievedProduct.getDescription());
        
        assert retrievedProduct.getPrice().compareTo(productToCreate.getPrice()) == 0 : 
            String.format("价格不匹配: 期望 %s, 得到 %s", 
                productToCreate.getPrice(), retrievedProduct.getPrice());
        
        assert retrievedProduct.getStockQuantity().equals(productToCreate.getStockQuantity()) : 
            String.format("库存数量不匹配: 期望 %d, 得到 %d", 
                productToCreate.getStockQuantity(), retrievedProduct.getStockQuantity());
        
        // 分类和图片URL可以为null，所以需要处理
        if (productToCreate.getCategory() == null) {
            assert retrievedProduct.getCategory() == null : "分类应该是null";
        } else {
            assert retrievedProduct.getCategory().equals(productToCreate.getCategory()) : 
                String.format("分类不匹配: 期望 '%s', 得到 '%s'", 
                    productToCreate.getCategory(), retrievedProduct.getCategory());
        }
        
        if (productToCreate.getImageUrl() == null) {
            assert retrievedProduct.getImageUrl() == null : "图片URL应该是null";
        } else {
            assert retrievedProduct.getImageUrl().equals(productToCreate.getImageUrl()) : 
                String.format("图片URL不匹配: 期望 '%s', 得到 '%s'", 
                    productToCreate.getImageUrl(), retrievedProduct.getImageUrl());
        }
        
        // 验证时间戳已被设置
        assert retrievedProduct.getCreatedAt() != null : "创建时间戳应该被设置";
        assert retrievedProduct.getUpdatedAt() != null : "更新时间戳应该被设置";
    }
    
    @Provide
    public Arbitrary<Product> validProducts() {
        return super.validProducts();
    }
}
