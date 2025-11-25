# E-commerce Backend Service

## Docker Build

### Multi-stage Build Strategy

This Dockerfile uses a multi-stage build approach to optimize the final image size:

**Stage 1: Build Stage**
- Base image: `maven:3.9-eclipse-temurin-17`
- Purpose: Compile and package the Spring Boot application
- Optimization: Copies `pom.xml` first to leverage Docker layer caching for dependencies

**Stage 2: Runtime Stage**
- Base image: `eclipse-temurin:17-jre-alpine`
- Purpose: Run the application with minimal footprint
- Size: < 200MB (target < 500MB per requirements)
- Security: Runs as non-root user

### Build Instructions

```bash
# Build the Docker image
docker build -t ecommerce-backend:latest .

# Run the container
docker run -p 8080:8080 \
  -e DB_HOST=mysql \
  -e DB_PORT=3306 \
  -e DB_NAME=ecommerce \
  -e DB_USER=root \
  -e DB_PASSWORD=password \
  ecommerce-backend:latest
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| DB_HOST | Database hostname | mysql |
| DB_PORT | Database port | 3306 |
| DB_NAME | Database name | ecommerce |
| DB_USER | Database username | root |
| DB_PASSWORD | Database password | (required) |
| SPRING_PROFILES_ACTIVE | Active Spring profile | default |

### Health Check

The container includes a health check that verifies the application is running:
- Endpoint: `http://localhost:8080/actuator/health`
- Interval: 30 seconds
- Timeout: 3 seconds
- Start period: 40 seconds
- Retries: 3

### Image Optimization

The Dockerfile implements several optimizations:

1. **Layer Caching**: Dependencies are downloaded in a separate layer that only rebuilds when `pom.xml` changes
2. **Multi-stage Build**: Build artifacts are not included in the final image
3. **Alpine Base**: Uses Alpine Linux for minimal image size
4. **JRE Only**: Runtime stage uses JRE instead of full JDK
5. **Non-root User**: Application runs as unprivileged user for security

### Expected Image Size

- Build stage: ~800MB (not included in final image)
- Runtime stage: ~180-200MB
- Total final image: < 200MB (well under 500MB requirement)
