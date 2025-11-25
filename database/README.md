# Database Service

MySQL 8.0 database service for the e-commerce system.

## Configuration

- **Character Set**: UTF-8 (utf8mb4)
- **Collation**: utf8mb4_unicode_ci
- **Timezone**: UTC
- **Max Connections**: 100
- **Connection Timeout**: 30 seconds

## Schema

### Products Table

| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT | Primary key, auto-increment |
| name | VARCHAR(255) | Product name (required) |
| description | TEXT | Product description |
| price | DECIMAL(10,2) | Product price (required) |
| stock_quantity | INT | Available stock (default: 0) |
| category | VARCHAR(100) | Product category |
| image_url | VARCHAR(500) | Product image URL |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Last update timestamp |

### Indexes

- `idx_category`: Index on category column for faster filtering
- `idx_name`: Index on name column for faster searching

## Initialization

The `init.sql` script:
1. Creates the `ecommerce` database with UTF-8 encoding
2. Creates the `products` table with proper schema
3. Seeds 8 sample products for testing

## Building and Running

### Using Docker

```bash
# Build the image
docker build -t ecommerce-mysql ./database

# Run the container
docker run -d \
  --name ecommerce-db \
  -p 3306:3306 \
  -v mysql-data:/var/lib/mysql \
  ecommerce-mysql
```

### Using Docker Compose

The database service is configured in `docker-compose.yml` and will start automatically with other services.

## Environment Variables

- `MYSQL_ROOT_PASSWORD`: Root user password
- `MYSQL_DATABASE`: Database name (default: ecommerce)
- `MYSQL_USER`: Application user
- `MYSQL_PASSWORD`: Application user password

## Health Check

The container includes a health check that pings MySQL every 10 seconds to ensure the service is running properly.

## Data Persistence

Data is persisted using a Docker volume mounted at `/var/lib/mysql`. This ensures data survives container restarts and removals.

## Connecting to the Database

### From Backend Service

The backend service connects using environment variables:
- Host: `mysql` (service name in Docker network)
- Port: `3306`
- Database: `ecommerce`
- User: `ecommerce_user`
- Password: `ecommerce_pass`

### Direct Connection (Development)

```bash
# Using MySQL client
mysql -h localhost -P 3306 -u ecommerce_user -p

# Using Docker exec
docker exec -it ecommerce-db mysql -u ecommerce_user -p
```

## Backup and Restore

### Backup

```bash
docker exec ecommerce-db mysqldump -u root -p ecommerce > backup.sql
```

### Restore

```bash
docker exec -i ecommerce-db mysql -u root -p ecommerce < backup.sql
```

## Troubleshooting

### Connection Refused

- Ensure the container is running: `docker ps`
- Check health status: `docker inspect ecommerce-db`
- Verify port mapping: `docker port ecommerce-db`

### Initialization Script Not Running

- The init script only runs on first startup with an empty data directory
- To re-run: remove the volume and restart the container

### Character Encoding Issues

- Verify configuration: `docker exec ecommerce-db mysql -u root -p -e "SHOW VARIABLES LIKE 'char%';"`
- Should show `utf8mb4` for all character set variables
