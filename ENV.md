# Environment Variables Configuration

This project uses environment variables to configure Docker Compose settings. This allows for flexible configuration across different environments without modifying the docker-compose.yml file.

## Setup

1. **Copy the environment template:**
   ```bash
   cp env.dist .env
   ```

2. **Edit the `.env` file** with your desired values:
   ```bash
   nano .env
   ```

## Available Variables

### Port Configuration
- `HTTP_PORT` - HTTP port mapping (default: 8000)
- `HTTPS_PORT` - HTTPS port mapping (default: 8443)

### Container Configuration
- `NGINX_CONTAINER_NAME` - Container name (default: web)

### SSL Certificate Paths
- `SSL_CERT_PATH` - SSL certificate directory path

### Application Settings
- `APP_NAME` - Application name (default: deployment-template)
- `APP_ENV` - Environment (development/production)
- `APP_DEBUG` - Debug mode (true/false)

## Usage Examples

### Development Environment
```bash
# .env file for development
HTTP_PORT=8000
HTTPS_PORT=8443
APP_ENV=development
APP_DEBUG=true
```

### Production Environment
```bash
# .env file for production
HTTP_PORT=80
HTTPS_PORT=443
APP_ENV=production
APP_DEBUG=false
```

### Custom Ports
```bash
# .env file with custom ports
HTTP_PORT=3000
HTTPS_PORT=3443
NGINX_CONTAINER_NAME=deployment-template-web
```

## Running with Environment Variables

The docker-compose.yml file will automatically use the values from your `.env` file:

```bash
# Start with environment variables
docker-compose up -d

# Check which ports are being used
docker-compose ps
```

## Default Values

If no `.env` file is present, the following defaults are used:
- HTTP_PORT: 8000
- HTTPS_PORT: 8443
- NGINX_CONTAINER_NAME: web
- All other settings use their respective defaults

## Security Note

- **Never commit `.env` files** to version control
- The `env.dist` file is safe to commit as it contains no sensitive data
- Use different `.env` files for different environments (dev, staging, prod)
