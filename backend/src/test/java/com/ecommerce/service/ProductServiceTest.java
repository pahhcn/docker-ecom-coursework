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
        // Arrange
        List<Product> products = Arrays.asList(testProduct, new Product());
        when(productRepository.findAll()).thenReturn(products);
        
        // Act
        List<Product> result = productService.getAllProducts();
        
        // Assert
        assertEquals(2, result.size());
        verify(productRepository, times(1)).findAll();
    }
    
    @Test
    void getProductById_WhenProductExists_ShouldReturnProduct() {
        // Arrange
        when(productRepository.findById(1L)).thenReturn(Optional.of(testProduct));
        
        // Act
        Optional<Product> result = productService.getProductById(1L);
        
        // Assert
        assertTrue(result.isPresent());
        assertEquals("Test Product", result.get().getName());
        verify(productRepository, times(1)).findById(1L);
    }
    
    @Test
    void getProductById_WhenProductDoesNotExist_ShouldReturnEmpty() {
        // Arrange
        when(productRepository.findById(anyLong())).thenReturn(Optional.empty());
        
        // Act
        Optional<Product> result = productService.getProductById(999L);
        
        // Assert
        assertFalse(result.isPresent());
        verify(productRepository, times(1)).findById(999L);
    }
    
    @Test
    void createProduct_ShouldSetIdToNullAndSaveProduct() {
        // Arrange
        Product newProduct = new Product();
        newProduct.setId(999L); // This should be ignored
        newProduct.setName("New Product");
        newProduct.setPrice(new BigDecimal("49.99"));
        newProduct.setStockQuantity(5);
        
        Product savedProduct = new Product();
        savedProduct.setId(1L);
        savedProduct.setName("New Product");
        savedProduct.setPrice(new BigDecimal("49.99"));
        savedProduct.setStockQuantity(5);
        
        when(productRepository.save(any(Product.class))).thenReturn(savedProduct);
        
        // Act
        Product result = productService.createProduct(newProduct);
        
        // Assert
        assertNotNull(result);
        assertEquals(1L, result.getId());
        assertEquals("New Product", result.getName());
        verify(productRepository, times(1)).save(any(Product.class));
        
        // Verify that ID was set to null before saving
        assertNull(newProduct.getId());
    }
    
    @Test
    void updateProduct_WhenProductExists_ShouldUpdateAndReturnProduct() {
        // Arrange
        Product updateData = new Product();
        updateData.setName("Updated Product");
        updateData.setDescription("Updated Description");
        updateData.setPrice(new BigDecimal("149.99"));
        updateData.setStockQuantity(20);
        updateData.setCategory("Updated Category");
        updateData.setImageUrl("https://example.com/updated.jpg");
        
        when(productRepository.findById(1L)).thenReturn(Optional.of(testProduct));
        when(productRepository.save(any(Product.class))).thenReturn(testProduct);
        
        // Act
        Optional<Product> result = productService.updateProduct(1L, updateData);
        
        // Assert
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
        // Arrange
        Product updateData = new Product();
        updateData.setName("Updated Product");
        
        when(productRepository.findById(anyLong())).thenReturn(Optional.empty());
        
        // Act
        Optional<Product> result = productService.updateProduct(999L, updateData);
        
        // Assert
        assertFalse(result.isPresent());
        verify(productRepository, times(1)).findById(999L);
        verify(productRepository, never()).save(any(Product.class));
    }
    
    @Test
    void deleteProduct_WhenProductExists_ShouldReturnTrue() {
        // Arrange
        when(productRepository.existsById(1L)).thenReturn(true);
        doNothing().when(productRepository).deleteById(1L);
        
        // Act
        boolean result = productService.deleteProduct(1L);
        
        // Assert
        assertTrue(result);
        verify(productRepository, times(1)).existsById(1L);
        verify(productRepository, times(1)).deleteById(1L);
    }
    
    @Test
    void deleteProduct_WhenProductDoesNotExist_ShouldReturnFalse() {
        // Arrange
        when(productRepository.existsById(anyLong())).thenReturn(false);
        
        // Act
        boolean result = productService.deleteProduct(999L);
        
        // Assert
        assertFalse(result);
        verify(productRepository, times(1)).existsById(999L);
        verify(productRepository, never()).deleteById(anyLong());
    }
}
