package com.ecommerce;

import org.junit.jupiter.api.*;
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
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.time.Duration;

/**
 * Integration tests for service communication
 * Tests frontend-backend and backend-database communication
 * Validates: Requirements 4.3, 4.4, 6.3, 6.4
 */
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class ServiceCommunicationIntegrationTest {
    
    private static Network network;
    private static MySQLContainer<?> mysqlContainer;
    private static GenericContainer<?> backendContainer;
    private static GenericContainer<?> frontendContainer;
    private static HttpClient httpClient;
    
    @BeforeAll
    static void setupContainers() {
        // Create a shared network for all containers
        network = Network.newNetwork();
        
        // Start MySQL container with network alias
        mysqlContainer = new MySQLContainer<>(DockerImageName.parse("mysql:8.0"))
                .withNetwork(network)
                .withNetworkAliases("database")
                .withDatabaseName("ecommerce")
                .withUsername("root")
                .withPassword("rootpassword")
                .withCommand(
                    "--character-set-server=utf8mb4",
                    "--collation-server=utf8mb4_unicode_ci"
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
                ") ENGINE=InnoDB"
            );
        } catch (Exception e) {
            throw new RuntimeException("Failed to initialize database", e);
        }
        
        // Start backend container with network alias
        backendContainer = new GenericContainer<>(DockerImageName.parse("ecommerce-backend:latest"))
                .withNetwork(network)
                .withNetworkAliases("backend")
                .withEnv("DB_HOST", "database")
                .withEnv("DB_PORT", "3306")
                .withEnv("DB_NAME", "ecommerce")
                .withEnv("DB_USER", "root")
                .withEnv("DB_PASSWORD", "rootpassword")
                .withExposedPorts(8080)
                .waitingFor(Wait.forHttp("/actuator/health")
                    .forPort(8080)
                    .withStartupTimeout(Duration.ofMinutes(2)))
                .dependsOn(mysqlContainer);
        
        backendContainer.start();
        
        // Start frontend container with network alias
        frontendContainer = new GenericContainer<>(DockerImageName.parse("ecommerce-frontend:latest"))
                .withNetwork(network)
                .withNetworkAliases("frontend")
                .withExposedPorts(80)
                .waitingFor(Wait.forHttp("/health")
                    .forPort(80)
                    .withStartupTimeout(Duration.ofSeconds(30)))
                .dependsOn(backendContainer);
        
        frontendContainer.start();
        
        // Set up HTTP client
        httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
    }
    
    @AfterAll
    static void teardownContainers() {
        if (frontendContainer != null) {
            frontendContainer.stop();
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
    
    @Test
    @Order(1)
    @DisplayName("Backend should connect to database using service name as hostname")
    void testBackendDatabaseConnection() throws Exception {
        // Verify backend can connect to database by checking health endpoint
        String backendUrl = "http://" + backendContainer.getHost() + ":" + 
                           backendContainer.getMappedPort(8080);
        
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(backendUrl + "/actuator/health"))
                .GET()
                .timeout(Duration.ofSeconds(10))
                .build();
        
        HttpResponse<String> response = httpClient.send(
            request, HttpResponse.BodyHandlers.ofString());
        
        Assertions.assertEquals(200, response.statusCode(), 
            "后端健康检查应该返回200");
        Assertions.assertTrue(response.body().contains("UP"), 
            "后端应该连接到数据库并状态为UP");
        
        // Verify database is accessible directly
        String jdbcUrl = mysqlContainer.getJdbcUrl();
        try (Connection conn = DriverManager.getConnection(
                jdbcUrl, "root", "rootpassword");
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT 1")) {
            Assertions.assertTrue(rs.next(), "数据库应该可访问");
        }
    }
    
    @Test
    @Order(2)
    @DisplayName("Backend should perform CRUD operations on database")
    void testBackendCrudOperations() throws Exception {
        String backendUrl = "http://" + backendContainer.getHost() + ":" + 
                           backendContainer.getMappedPort(8080);
        
        // Create a product
        String productJson = "{\"name\":\"Test Product\",\"description\":\"Test Description\"," +
                           "\"price\":99.99,\"stockQuantity\":10,\"category\":\"Electronics\"}";
        
        HttpRequest createRequest = HttpRequest.newBuilder()
                .uri(URI.create(backendUrl + "/api/products"))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(productJson))
                .timeout(Duration.ofSeconds(10))
                .build();
        
        HttpResponse<String> createResponse = httpClient.send(
            createRequest, HttpResponse.BodyHandlers.ofString());
        
        Assertions.assertEquals(201, createResponse.statusCode(), 
            "产品创建应该返回201");
        
        // Retrieve products
        HttpRequest getRequest = HttpRequest.newBuilder()
                .uri(URI.create(backendUrl + "/api/products"))
                .GET()
                .timeout(Duration.ofSeconds(10))
                .build();
        
        HttpResponse<String> getResponse = httpClient.send(
            getRequest, HttpResponse.BodyHandlers.ofString());
        
        Assertions.assertEquals(200, getResponse.statusCode(), 
            "产品检索应该返回200");
        Assertions.assertTrue(getResponse.body().contains("Test Product"), 
            "响应应该包含创建的产品");
    }
    
    @Test
    @Order(3)
    @DisplayName("Frontend should reach backend API through network")
    void testFrontendBackendCommunication() throws Exception {
        String frontendUrl = "http://" + frontendContainer.getHost() + ":" + 
                            frontendContainer.getMappedPort(80);
        
        // Test frontend health endpoint
        HttpRequest healthRequest = HttpRequest.newBuilder()
                .uri(URI.create(frontendUrl + "/health"))
                .GET()
                .timeout(Duration.ofSeconds(10))
                .build();
        
        HttpResponse<String> healthResponse = httpClient.send(
            healthRequest, HttpResponse.BodyHandlers.ofString());
        
        Assertions.assertEquals(200, healthResponse.statusCode(), 
            "前端健康检查应该返回200");
        Assertions.assertTrue(healthResponse.body().contains("healthy"), 
            "前端应该报告健康状态");
        
        // Test frontend can proxy API requests to backend
        HttpRequest apiRequest = HttpRequest.newBuilder()
                .uri(URI.create(frontendUrl + "/api/products"))
                .GET()
                .timeout(Duration.ofSeconds(10))
                .build();
        
        HttpResponse<String> apiResponse = httpClient.send(
            apiRequest, HttpResponse.BodyHandlers.ofString());
        
        Assertions.assertEquals(200, apiResponse.statusCode(), 
            "前端应该成功将API请求代理到后端");
    }
    
    @Test
    @Order(4)
    @DisplayName("Services should communicate using service names as hostnames")
    void testServiceNameResolution() throws Exception {
        // Verify backend can resolve 'database' hostname
        String backendUrl = "http://" + backendContainer.getHost() + ":" + 
                           backendContainer.getMappedPort(8080);
        
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(backendUrl + "/actuator/health"))
                .GET()
                .timeout(Duration.ofSeconds(10))
                .build();
        
        HttpResponse<String> response = httpClient.send(
            request, HttpResponse.BodyHandlers.ofString());
        
        // If backend is healthy, it successfully resolved 'database' hostname
        Assertions.assertEquals(200, response.statusCode(), 
            "后端应该解析数据库主机名并成功连接");
        
        // Verify frontend can resolve 'backend' hostname by proxying requests
        String frontendUrl = "http://" + frontendContainer.getHost() + ":" + 
                            frontendContainer.getMappedPort(80);
        
        HttpRequest frontendRequest = HttpRequest.newBuilder()
                .uri(URI.create(frontendUrl + "/api/products"))
                .GET()
                .timeout(Duration.ofSeconds(10))
                .build();
        
        HttpResponse<String> frontendResponse = httpClient.send(
            frontendRequest, HttpResponse.BodyHandlers.ofString());
        
        // If frontend can proxy to backend, it successfully resolved 'backend' hostname
        Assertions.assertEquals(200, frontendResponse.statusCode(), 
            "前端应该解析后端主机名并成功代理请求");
    }
    
    @Test
    @Order(5)
    @DisplayName("Health checks should work correctly for all services")
    void testHealthChecks() throws Exception {
        // Test database health
        String jdbcUrl = mysqlContainer.getJdbcUrl();
        try (Connection conn = DriverManager.getConnection(
                jdbcUrl, "root", "rootpassword");
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT 1")) {
            Assertions.assertTrue(rs.next(), "数据库健康检查应该通过");
        }
        
        // Test backend health
        String backendUrl = "http://" + backendContainer.getHost() + ":" + 
                           backendContainer.getMappedPort(8080);
        
        HttpRequest backendRequest = HttpRequest.newBuilder()
                .uri(URI.create(backendUrl + "/actuator/health"))
                .GET()
                .timeout(Duration.ofSeconds(10))
                .build();
        
        HttpResponse<String> backendResponse = httpClient.send(
            backendRequest, HttpResponse.BodyHandlers.ofString());
        
        Assertions.assertEquals(200, backendResponse.statusCode(), 
            "后端健康检查应该返回200");
        Assertions.assertTrue(backendResponse.body().contains("UP"), 
            "后端健康状态应该是UP");
        
        // Test frontend health
        String frontendUrl = "http://" + frontendContainer.getHost() + ":" + 
                            frontendContainer.getMappedPort(80);
        
        HttpRequest frontendRequest = HttpRequest.newBuilder()
                .uri(URI.create(frontendUrl + "/health"))
                .GET()
                .timeout(Duration.ofSeconds(10))
                .build();
        
        HttpResponse<String> frontendResponse = httpClient.send(
            frontendRequest, HttpResponse.BodyHandlers.ofString());
        
        Assertions.assertEquals(200, frontendResponse.statusCode(), 
            "前端健康检查应该返回200");
        Assertions.assertTrue(frontendResponse.body().contains("healthy"), 
            "前端健康状态应该是healthy");
    }
}
