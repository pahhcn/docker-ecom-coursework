package com.ecommerce.service;

import com.ecommerce.model.Product;
import com.ecommerce.repository.ProductRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ProductServiceTest {
    
    @Mock
    private ProductRepository productRepository;
    
    @InjectMocks
    private ProductService productService;
    
    private Product testProduct;
    
    @BeforeEach
    void setUp() {
        testProduct = new Product();
        testProduct.setId(1L);
        testProduct.setName("Test Product");
        testProduct.setDescription("Test Description");
        testProduct.setPrice(new BigDecimal("99.99"));
        testProduct.setStockQuantity(10);
        testProduct.setCategory("Electronics");
        testProduct.setImageUrl("https://example.com/image.jpg");
    }
    
    @Test
    void getAllProducts_ShouldReturnAllProducts() {
        // 准备
        List<Product> products = Arrays.asList(testProduct, new Product());
        when(productRepository.findAll()).thenReturn(products);
        
        // 执行
        List<Product> result = productService.getAllProducts();
        
        // 断言
        assertEquals(2, result.size());
        verify(productRepository, times(1)).findAll();
    }
    
    @Test
    void getProductById_WhenProductExists_ShouldReturnProduct() {
        // 准备
        when(productRepository.findById(1L)).thenReturn(Optional.of(testProduct));
        
        // 执行
        Optional<Product> result = productService.getProductById(1L);
        
        // 断言
        assertTrue(result.isPresent());
        assertEquals("Test Product", result.get().getName());
        verify(productRepository, times(1)).findById(1L);
    }
    
    @Test
    void getProductById_WhenProductDoesNotExist_ShouldReturnEmpty() {
        // 准备
        when(productRepository.findById(anyLong())).thenReturn(Optional.empty());
        
        // 执行
        Optional<Product> result = productService.getProductById(999L);
        
        // 断言
        assertFalse(result.isPresent());
        verify(productRepository, times(1)).findById(999L);
    }
    
    @Test
    void createProduct_ShouldSetIdToNullAndSaveProduct() {
        // 准备
        Product newProduct = new Product();
        newProduct.setId(999L); // 这应该被忽略
        newProduct.setName("New Product");
        newProduct.setPrice(new BigDecimal("49.99"));
        newProduct.setStockQuantity(5);
        
        Product savedProduct = new Product();
        savedProduct.setId(1L);
        savedProduct.setName("New Product");
        savedProduct.setPrice(new BigDecimal("49.99"));
        savedProduct.setStockQuantity(5);
        
        when(productRepository.save(any(Product.class))).thenReturn(savedProduct);
        
        // 执行
        Product result = productService.createProduct(newProduct);
        
        // 断言
        assertNotNull(result);
        assertEquals(1L, result.getId());
        assertEquals("New Product", result.getName());
        verify(productRepository, times(1)).save(any(Product.class));
        
        // 验证保存前ID被设置为null
        assertNull(newProduct.getId());
    }
    
    @Test
    void updateProduct_WhenProductExists_ShouldUpdateAndReturnProduct() {
        // 准备
        Product updateData = new Product();
        updateData.setName("Updated Product");
        updateData.setDescription("Updated Description");
        updateData.setPrice(new BigDecimal("149.99"));
        updateData.setStockQuantity(20);
        updateData.setCategory("Updated Category");
        updateData.setImageUrl("https://example.com/updated.jpg");
        
        when(productRepository.findById(1L)).thenReturn(Optional.of(testProduct));
        when(productRepository.save(any(Product.class))).thenReturn(testProduct);
        
        // 执行
        Optional<Product> result = productService.updateProduct(1L, updateData);
        
        // 断言
        assertTrue(result.isPresent());
        assertEquals("Updated Product", result.get().getName());
        assertEquals("Updated Description", result.get().getDescription());
        assertEquals(new BigDecimal("149.99"), result.get().getPrice());
        assertEquals(20, result.get().getStockQuantity());
        verify(productRepository, times(1)).findById(1L);
        verify(productRepository, times(1)).save(testProduct);
    }
    
    @Test
    void updateProduct_WhenProductDoesNotExist_ShouldReturnEmpty() {
        // 准备
        Product updateData = new Product();
        updateData.setName("Updated Product");
        
        when(productRepository.findById(anyLong())).thenReturn(Optional.empty());
        
        // 执行
        Optional<Product> result = productService.updateProduct(999L, updateData);
        
        // 断言
        assertFalse(result.isPresent());
        verify(productRepository, times(1)).findById(999L);
        verify(productRepository, never()).save(any(Product.class));
    }
    
    @Test
    void deleteProduct_WhenProductExists_ShouldReturnTrue() {
        // 准备
        when(productRepository.existsById(1L)).thenReturn(true);
        doNothing().when(productRepository).deleteById(1L);
        
        // 执行
        boolean result = productService.deleteProduct(1L);
        
        // 断言
        assertTrue(result);
        verify(productRepository, times(1)).existsById(1L);
        verify(productRepository, times(1)).deleteById(1L);
    }
    
    @Test
    void deleteProduct_WhenProductDoesNotExist_ShouldReturnFalse() {
        // 准备
        when(productRepository.existsById(anyLong())).thenReturn(false);
        
        // 执行
        boolean result = productService.deleteProduct(999L);
        
        // 断言
        assertFalse(result);
        verify(productRepository, times(1)).existsById(999L);
        verify(productRepository, never()).deleteById(anyLong());
    }
}
