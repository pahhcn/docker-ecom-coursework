# Multi-stage build for frontend service
# Stage 1: Build stage (for potential future build steps)
FROM nginx:alpine AS builder

# Copy static files to a temporary location
COPY html /tmp/html

# Stage 2: Runtime stage
FROM nginx:alpine

# Add metadata labels
LABEL maintainer="ecommerce-team"
LABEL description="Frontend service for e-commerce system"
LABEL version="1.0"

# Remove default nginx configuration
RUN rm /etc/nginx/nginx.conf

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy static files from builder stage
COPY --from=builder /tmp/html /usr/share/nginx/html

# Create a simple health check HTML page
RUN echo "healthy" > /usr/share/nginx/html/health.html

# Expose port 80
EXPOSE 80

# Health check configuration
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://127.0.0.1/health || exit 1

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
