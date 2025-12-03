package com.ecommerce;

import com.ecommerce.model.Product;
import com.fasterxml.jackson.databind.ObjectMapper;
import net.jqwik.api.*;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.springframework.http.MediaType;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.containers.Network;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.utility.DockerImageName;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;

import org.junit.jupiter.api.condition.EnabledIf;
import org.junit.jupiter.api.Assumptions;

/**
 * Property-based tests for end-to-end data flow integrity
 * Feature: docker-ecommerce-system, Property 6: End-to-end data flow integrity
 * Validates: Requirements 6.3
 * 
 * Note: This test requires Docker and the backend image to be built.
 * Set ENABLE_E2E_TESTS=true to run these tests.
 */
public class EndToEndDataFlowPropertyTest extends PropertyTestBase {
    
    private static Network network;
    private static MySQLContainer<?> mysqlContainer;
    private static GenericContainer<?> backendContainer;
    private static String backendBaseUrl;
    private static HttpClient httpClient;
    private static ObjectMapper objectMapper;
    
    @BeforeAll
    static void setupContainers() {
        // Only initialize if environment variable is set
        if (!"true".equals(System.getenv("ENABLE_E2E_TESTS"))) {
            return;
        }
        
        // Create a shared network for all containers
        network = Network.newNetwork();
        
        // Start MySQL container
        mysqlContainer = new MySQLContainer<>(DockerImageName.parse("mysql:8.0"))
                .withNetwork(network)
                .withNetworkAliases("database")
                .withDatabaseName("ecommerce")
                .withUsername("root")
                .withPassword("rootpassword")
                .withCommand(
                    "--character-set-server=utf8mb4",
                    "--collation-server=utf8mb4_unicode_ci",
                    "--default-time-zone=+00:00"
                );
        
        mysqlContainer.start();
        
        // Initialize database schema
        try {
            mysqlContainer.execInContainer(
                "mysql", "-uroot", "-prootpassword", "ecommerce", "-e",
                "CREATE TABLE IF NOT EXISTS products (" +
                "id BIGINT AUTO_INCREMENT PRIMARY KEY, " +
                "name VARCHAR(255) NOT NULL, " +
                "description TEXT, " +
                "price DECIMAL(10, 2) NOT NULL, " +
                "stock_quantity INT NOT NULL DEFAULT 0, " +
                "category VARCHAR(100), " +
                "image_url VARCHAR(500), " +
                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci"
            );
        } catch (Exception e) {
            throw new RuntimeException("Failed to initialize database schema", e);
        }
        
        // Start backend container
        backendContainer = new GenericContainer<>(DockerImageName.parse("ecommerce-backend:latest"))
                .withNetwork(network)
                .withNetworkAliases("backend")
                .withEnv("DB_HOST", "database")
                .withEnv("DB_PORT", "3306")
                .withEnv("DB_NAME", "ecommerce")
                .withEnv("DB_USER", "root")
                .withEnv("DB_PASSWORD", "rootpassword")
                .withEnv("SPRING_PROFILES_ACTIVE", "prod")
                .withExposedPorts(8080)
                .waitingFor(Wait.forHttp("/actuator/health")
                    .forPort(8080)
                    .withStartupTimeout(Duration.ofMinutes(2)))
                .dependsOn(mysqlContainer);
        
        backendContainer.start();
        
        // Set up HTTP client and base URL
        backendBaseUrl = "http://" + backendContainer.getHost() + ":" + 
                        backendContainer.getMappedPort(8080);
        httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
        objectMapper = new ObjectMapper();
    }
    
    @AfterAll
    static void teardownContainers() {
        // Only cleanup if environment variable is set
        if (!"true".equals(System.getenv("ENABLE_E2E_TESTS"))) {
            return;
        }
        
        if (backendContainer != null) {
            backendContainer.stop();
        }
        if (mysqlContainer != null) {
            mysqlContainer.stop();
        }
        if (network != null) {
            network.close();
        }
    }
    
    @Property(tries = 100)
    @Label("对于任何产品数据，端到端流程应该保持从创建到检索的数据完整性")
    void endToEndDataFlowIntegrity(@ForAll("validProducts") Product productToCreate) {
        // Skip test if environment variable is not set
        Assumptions.assumeTrue("true".equals(System.getenv("ENABLE_E2E_TESTS")), 
            "Skipping E2E test: Set ENABLE_E2E_TESTS=true to run this test");
        
        try {
            // Step 1: Create product via backend API (POST)
            productToCreate.setId(null); // Ensure ID is null for creation
            String productJson = objectMapper.writeValueAsString(productToCreate);
            
            HttpRequest createRequest = HttpRequest.newBuilder()
                    .uri(URI.create(backendBaseUrl + "/api/products"))
                    .header("Content-Type", MediaType.APPLICATION_JSON_VALUE)
                    .POST(HttpRequest.BodyPublishers.ofString(productJson))
                    .timeout(Duration.ofSeconds(10))
                    .build();
            
            HttpResponse<String> createResponse = httpClient.send(
                createRequest, HttpResponse.BodyHandlers.ofString());
            
            assert createResponse.statusCode() == 201 : 
                String.format("期望201状态码，得到 %d: %s", 
                    createResponse.statusCode(), createResponse.body());
            
            // Parse created product to get ID
            Product createdProduct = objectMapper.readValue(
                createResponse.body(), Product.class);
            assert createdProduct.getId() != null : "创建的产品应该有ID";
            
            // Step 2: Retrieve product via backend API (GET by ID)
            HttpRequest getRequest = HttpRequest.newBuilder()
                    .uri(URI.create(backendBaseUrl + "/api/products/" + createdProduct.getId()))
                    .GET()
                    .timeout(Duration.ofSeconds(10))
                    .build();
            
            HttpResponse<String> getResponse = httpClient.send(
                getRequest, HttpResponse.BodyHandlers.ofString());
            
            assert getResponse.statusCode() == 200 : 
                String.format("期望200状态码，得到 %d: %s", 
                    getResponse.statusCode(), getResponse.body());
            
            // Parse retrieved product
            Product retrievedProduct = objectMapper.readValue(
                getResponse.body(), Product.class);
            
            // Step 3: Verify data integrity - all fields should match
            assert retrievedProduct.getId().equals(createdProduct.getId()) : 
                String.format("ID不匹配: 期望 %d, 得到 %d", 
                    createdProduct.getId(), retrievedProduct.getId());
            
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
            
            // Handle nullable fields
            if (productToCreate.getCategory() == null) {
                assert retrievedProduct.getCategory() == null : 
                    "分类应该是null但得到: " + retrievedProduct.getCategory();
            } else {
                assert retrievedProduct.getCategory().equals(productToCreate.getCategory()) : 
                    String.format("分类不匹配: 期望 '%s', 得到 '%s'", 
                        productToCreate.getCategory(), retrievedProduct.getCategory());
            }
            
            if (productToCreate.getImageUrl() == null) {
                assert retrievedProduct.getImageUrl() == null : 
                    "图片URL应该是null但得到: " + retrievedProduct.getImageUrl();
            } else {
                assert retrievedProduct.getImageUrl().equals(productToCreate.getImageUrl()) : 
                    String.format("图片URL不匹配: 期望 '%s', 得到 '%s'", 
                        productToCreate.getImageUrl(), retrievedProduct.getImageUrl());
            }
            
            // Step 4: Verify product appears in list endpoint
            HttpRequest listRequest = HttpRequest.newBuilder()
                    .uri(URI.create(backendBaseUrl + "/api/products"))
                    .GET()
                    .timeout(Duration.ofSeconds(10))
                    .build();
            
            HttpResponse<String> listResponse = httpClient.send(
                listRequest, HttpResponse.BodyHandlers.ofString());
            
            assert listResponse.statusCode() == 200 : 
                String.format("列表期望200状态码，得到 %d", listResponse.statusCode());
            
            // Verify the created product is in the list
            String listBody = listResponse.body();
            assert listBody.contains(createdProduct.getId().toString()) : 
                "产品列表应该包含创建的产品ID";
            assert listBody.contains(productToCreate.getName()) : 
                "产品列表应该包含产品名称";
            
            // Clean up: Delete the product
            HttpRequest deleteRequest = HttpRequest.newBuilder()
                    .uri(URI.create(backendBaseUrl + "/api/products/" + createdProduct.getId()))
                    .DELETE()
                    .timeout(Duration.ofSeconds(10))
                    .build();
            
            httpClient.send(deleteRequest, HttpResponse.BodyHandlers.ofString());
            
        } catch (IOException | InterruptedException e) {
            throw new RuntimeException("HTTP request failed", e);
        }
    }
    
    @Provide
    public Arbitrary<Product> validProducts() {
        return super.validProducts();
    }
}
