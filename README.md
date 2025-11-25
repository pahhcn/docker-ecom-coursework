# Docker E-commerce Data Management System

A containerized three-tier e-commerce application demonstrating modern DevOps practices with Docker, Docker Compose, and CI/CD pipelines.

## Overview

This project showcases comprehensive containerization skills including:
- Multi-stage Dockerfile creation and optimization
- Docker Compose orchestration
- Container networking and volume management
- CI/CD pipeline implementation
- Property-based testing for correctness verification

## Architecture

The system consists of three containerized services:

1. **Frontend Service**: Nginx-based static web server serving product catalog pages
2. **Backend API Service**: Spring Boot REST API providing CRUD operations for product management
3. **Database Service**: MySQL database with persistent storage

```
┌─────────────────────────────────────────────────────────────┐
│                        Host Machine                          │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Docker Custom Network                      │ │
│  │                                                          │ │
│  │  ┌──────────────┐      ┌──────────────┐      ┌───────┐│ │
│  │  │   Frontend   │─────▶│   Backend    │─────▶│ MySQL ││ │
│  │  │   (Nginx)    │      │ (Spring Boot)│      │  DB   ││ │
│  │  │   Port 80    │      │  Port 8080   │      │ 3306  ││ │
│  │  └──────────────┘      └──────────────┘      └───────┘│ │
│  │                                                          │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Technology Stack

- **Frontend**: HTML5, CSS3, JavaScript, Nginx Alpine
- **Backend**: Java 17, Spring Boot 3.x, Maven
- **Database**: MySQL 8.0
- **Containerization**: Docker, Docker Compose
- **Testing**: JUnit 5, jqwik (property-based testing), TestContainers
- **CI/CD**: Jenkins or GitLab CI

## Prerequisites

- Docker 20.10 or higher
- Docker Compose 2.0 or higher
- Git

## Quick Start

### Local Development

1. Clone the repository:
```bash
git clone <repository-url>
cd ecommerce-docker-system
```

2. Start all services:
```bash
docker-compose up --build
```

3. Access the application:
   - Frontend: http://localhost:80
   - Backend API: http://localhost:8080/api/products
   - Database: localhost:3306 (for direct access if needed)

4. Stop all services:
```bash
docker-compose down
```

5. Stop and remove volumes (clean slate):
```bash
docker-compose down -v
```

## Project Structure

```
ecommerce-docker-system/
├── frontend/               # Frontend service
│   ├── Dockerfile
│   ├── nginx.conf
│   └── html/
│       ├── index.html
│       ├── product-detail.html
│       ├── css/
│       │   └── styles.css
│       └── js/
│           └── app.js
├── backend/                # Backend API service
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/
│       ├── main/
│       │   ├── java/
│       │   │   └── com/ecommerce/
│       │   │       ├── EcommerceApplication.java
│       │   │       ├── controller/
│       │   │       ├── service/
│       │   │       ├── repository/
│       │   │       └── model/
│       │   └── resources/
│       │       └── application.yml
│       └── test/
│           └── java/
│               └── com/ecommerce/
├── database/               # Database initialization
│   └── init.sql
├── k8s/                    # Kubernetes manifests (advanced)
│   ├── frontend/
│   ├── backend/
│   └── database/
├── docs/                   # Documentation
├── docker-compose.yml      # Development orchestration
├── docker-compose.prod.yml # Production orchestration
├── .gitignore
├── .dockerignore
└── README.md
```

## API Endpoints

### Products API

| Method | Endpoint | Description | Response |
|--------|----------|-------------|----------|
| GET | /api/products | List all products | 200 + Product[] |
| GET | /api/products/{id} | Get product by ID | 200 + Product |
| POST | /api/products | Create new product | 201 + Product |
| PUT | /api/products/{id} | Update product | 200 + Product |
| DELETE | /api/products/{id} | Delete product | 204 |

### Example Product Object

```json
{
  "id": 1,
  "name": "Product Name",
  "description": "Product description",
  "price": 99.99,
  "stockQuantity": 100,
  "category": "Electronics",
  "imageUrl": "https://example.com/image.jpg",
  "createdAt": "2025-11-24T10:00:00",
  "updatedAt": "2025-11-24T10:00:00"
}
```

## Development

### Building Individual Services

```bash
# Build frontend
docker build -t ecommerce-frontend ./frontend

# Build backend
docker build -t ecommerce-backend ./backend

# Build all services
docker-compose build
```

### Running Tests

```bash
# Run backend unit tests
cd backend
mvn test

# Run backend integration tests
mvn verify

# Run property-based tests
mvn test -Dtest=*PropertyTest
```

### Viewing Logs

```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs frontend
docker-compose logs backend
docker-compose logs mysql

# Follow logs in real-time
docker-compose logs -f
```

## Configuration

### Environment Variables

Backend service configuration (set in docker-compose.yml):

- `DB_HOST`: Database hostname (default: mysql)
- `DB_PORT`: Database port (default: 3306)
- `DB_NAME`: Database name (default: ecommerce)
- `DB_USER`: Database username
- `DB_PASSWORD`: Database password
- `SPRING_PROFILES_ACTIVE`: Active profile (dev/prod)

## Testing Strategy

The project implements comprehensive testing:

1. **Unit Tests**: Test individual components in isolation
2. **Property-Based Tests**: Verify correctness properties across random inputs (100+ iterations)
3. **Integration Tests**: Test service communication using TestContainers
4. **End-to-End Tests**: Verify complete workflows

### Property-Based Testing

This project uses jqwik for property-based testing to verify correctness properties:

- Product retrieval completeness
- Product creation persistence
- Product update correctness
- Product deletion completeness
- Volume persistence across container lifecycle
- End-to-end data flow integrity

## CI/CD Pipeline

The project includes automated CI/CD pipeline configuration:

1. **Build Stage**: Build Docker images for all services
2. **Test Stage**: Run unit, integration, and property tests
3. **Push Stage**: Push images to container registry
4. **Deploy Stage**: Deploy to target environment

## Production Deployment

For production deployment:

```bash
# Build production images
docker-compose -f docker-compose.prod.yml build

# Push to registry
docker-compose -f docker-compose.prod.yml push

# Deploy
docker-compose -f docker-compose.prod.yml up -d
```

## Advanced Features

### Kubernetes Deployment

Kubernetes manifests are available in the `k8s/` directory for production orchestration.

### Monitoring

Optional APM monitoring with Prometheus/Grafana or SkyWalking for observability.

### Deployment Strategies

Support for blue-green and canary deployment strategies for zero-downtime releases.

## Troubleshooting

### Common Issues

**Services can't communicate:**
- Verify all services are on the same Docker network
- Check service names match in docker-compose.yml

**Database connection failures:**
- Ensure database health check passes before backend starts
- Verify environment variables are set correctly

**Port conflicts:**
- Check if ports 80, 8080, or 3306 are already in use
- Modify port mappings in docker-compose.yml

**Volume permission issues:**
- On Linux, ensure proper permissions for volume mounts
- Use named volumes instead of bind mounts

For more troubleshooting information, see [docs/troubleshooting.md](docs/troubleshooting.md).

## Contributing

1. Create a feature branch from `develop`
2. Make your changes
3. Write tests for new functionality
4. Ensure all tests pass
5. Create a pull request to `develop`

### Commit Message Format

Follow Conventional Commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

## License

This project is for educational and demonstration purposes.

## Documentation

- [Architecture Documentation](docs/architecture.md)
- [Deployment Guide](docs/deployment.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [API Documentation](docs/api.md)

## Contact

For questions or issues, please open an issue in the repository.
