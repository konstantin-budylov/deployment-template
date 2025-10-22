# Docker Compose Setup - Nginx + PHP 8.4-FPM

This document provides detailed information about the Docker setup for the Manogama project, including the custom Dockerfile, source images, and PHP installation process.

## Overview

The project uses a single-container approach with both Nginx and PHP 8.4-FPM running together. This setup provides a lightweight, efficient web server environment for PHP applications.

## Architecture

```
┌─────────────────────────────────────┐
│           Docker Container          │
│  ┌─────────────┐  ┌───────────────┐ │
│  │    Nginx    │  │  PHP 8.4-FPM  │ │
│  │   (Port 80) │  │  (Port 9000)  │ │
│  └─────────────┘  └───────────────┘ │
│           │              │          │
│           └──────┬───────┘          │
│                  │                  │
│            FastCGI Protocol         │
└─────────────────────────────────────┘
```

## Dockerfile Details

### Base Image
- **Source**: `nginx:alpine`
- **Repository**: [nginxinc/docker-nginx](https://github.com/nginxinc/docker-nginx)
- **Alpine Version**: Latest stable Alpine Linux
- **Size**: ~15MB base image

### PHP Installation Process

The Dockerfile installs PHP 8.4-FPM and essential extensions using Alpine's package manager (`apk`):

```dockerfile
RUN apk add --no-cache \
    php84 \
    php84-fpm \
    php84-mysqli \
    php84-pdo \
    php84-pdo_mysql \
    # ... additional extensions
```

#### Installed PHP Extensions

| Extension | Purpose | Status |
|-----------|---------|--------|
| `php84` | Core PHP runtime | ✅ Installed |
| `php84-fpm` | FastCGI Process Manager | ✅ Installed |
| `php84-mysqli` | MySQL database connectivity | ✅ Installed |
| `php84-pdo` | PHP Data Objects | ✅ Installed |
| `php84-pdo_mysql` | PDO MySQL driver | ✅ Installed |
| `php84-json` | JSON processing | ✅ Installed |
| `php84-curl` | HTTP client library | ✅ Installed |
| `php84-mbstring` | Multibyte string handling | ✅ Installed |
| `php84-xml` | XML processing | ✅ Installed |
| `php84-zip` | ZIP archive handling | ✅ Installed |
| `php84-gd` | Image processing | ✅ Installed |
| `php84-opcache` | Opcode caching | ✅ Installed |
| `php84-tokenizer` | PHP tokenizer | ✅ Installed |
| `php84-fileinfo` | File type detection | ✅ Installed |
| `php84-intl` | Internationalization | ✅ Installed |
| `php84-bcmath` | Arbitrary precision math | ✅ Installed |
| `php84-openssl` | OpenSSL support | ✅ Installed |
| `php84-ctype` | Character type checking | ✅ Installed |
| `php84-dom` | DOM manipulation | ✅ Installed |
| `php84-phar` | PHP Archive support | ✅ Installed |
| `php84-session` | Session management | ✅ Installed |
| `php84-simplexml` | Simple XML processing | ✅ Installed |
| `php84-xmlreader` | XML reader | ✅ Installed |
| `php84-xmlwriter` | XML writer | ✅ Installed |
| `php84-zlib` | Compression library | ✅ Installed |

### Configuration Changes

The Dockerfile makes several configuration adjustments:

#### PHP-FPM Configuration
```bash
# Change from TCP socket to Unix socket
sed -i 's/listen = 127.0.0.1:9000/listen = 9000/' /etc/php84/php-fpm.d/www.conf

# Set proper ownership
sed -i 's/;listen.owner = www-data/listen.owner = nginx/' /etc/php84/php-fpm.d/www.conf
sed -i 's/;listen.group = www-data/listen.group = nginx/' /etc/php84/php-fpm.d/www.conf
sed -i 's/;listen.mode = 0660/listen.mode = 0660/' /etc/php84/php-fpm.d/www.conf
```

#### Startup Script
A custom startup script runs both services:
```bash
#!/bin/sh
php-fpm84 -D          # Start PHP-FPM in background
nginx -g "daemon off;" # Start Nginx in foreground
```

## Docker Compose Configuration

### Service Definition
```yaml
services:
  web:
    build:
      context: ./deployment/images
      dockerfile: Dockerfile
    container_name: web
    ports:
      - "8000:80"
    volumes:
      - .:/var/www/html
      - ./deployment/config/nginx.conf:/etc/nginx/conf.d/default.conf
    working_dir: /var/www/html
```

### Volume Mappings
- **Project Root** → `/var/www/html` (Application files)
- **Nginx Config** → `/etc/nginx/conf.d/default.conf` (Server configuration)

### Port Mapping
- **Host Port**: 8000
- **Container Port**: 80 (Nginx)

## Nginx Configuration

The Nginx configuration (`deployment/config/nginx.conf`) includes:

### Server Block
```nginx
server {
    listen 80;
    server_name localhost;
    root /var/www/html;
    index index.php index.html index.htm;
}
```

### PHP Processing
```nginx
location ~ \.php$ {
    fastcgi_pass 127.0.0.1:9000;  # Connect to PHP-FPM
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
}
```

### URL Rewriting
```nginx
location / {
    try_files $uri $uri/ /index.php?$query_string;
}
```

## Usage Instructions

### Building the Image
```bash
# Build the custom image
docker-compose build

# Build with no cache (force rebuild)
docker-compose build --no-cache
```

### Running the Container
```bash
# Start in background
docker-compose up -d

# Start with logs
docker-compose up

# Stop the container
docker-compose down
```

### Accessing the Application
- **HTTP URL**: http://localhost:8000 (redirects to HTTPS)
- **HTTPS URL**: https://localhost:8443
- **Document Root**: `/var/www/html` (mapped to project root)

### SSL/HTTPS Configuration
- **SSL Certificates**: Self-signed certificates in `deployment/ssl/`
- **Certificate Validity**: 1 year (development use)
- **Security Headers**: HSTS, X-Frame-Options, X-Content-Type-Options, etc.
- **TLS Protocols**: TLSv1.2 and TLSv1.3
- **HTTP/2**: Enabled for better performance

### Development Workflow
1. Place PHP files in the project root
2. Files are automatically available at `http://localhost:8000`
3. Changes are reflected immediately (no rebuild needed)

## Troubleshooting

### Check Container Status
```bash
docker-compose ps
```

### View Logs
```bash
docker-compose logs web
```

### Access Container Shell
```bash
docker-compose exec web sh
```

### Verify PHP Extensions
Visit `http://localhost:8000` to see the PHP info page showing loaded extensions.

## Performance Considerations

### Opcache Status
- **OpCache**: Not loaded by default (can be enabled in production)
- **Reason**: Development environment prioritizes code changes over performance

### Memory Usage
- **Base Image**: ~15MB (nginx:alpine)
- **With PHP**: ~83MB total
- **Runtime Memory**: ~20-50MB depending on application

## Security Notes

### Container Security
- Runs as non-root user where possible
- Minimal attack surface with Alpine Linux
- No unnecessary services running

### File Permissions
- PHP-FPM runs as nginx user
- Proper file ownership configured
- Secure file permissions (660) for Unix sockets

## Source References

- **Nginx Docker**: https://github.com/nginxinc/docker-nginx
- **Alpine Linux**: https://alpinelinux.org/
- **PHP 8.4**: https://www.php.net/releases/8.4/en.php
- **PHP-FPM**: https://www.php.net/manual/en/install.fpm.php

## Maintenance

### Updating PHP
To update PHP version, modify the Dockerfile:
```dockerfile
# Change from php84 to php85 (when available)
RUN apk add --no-cache php85 php85-fpm ...
```

### Adding Extensions
Add new PHP extensions to the Dockerfile:
```dockerfile
RUN apk add --no-cache \
    # existing extensions...
    php84-redis \
    php84-memcached
```

### Custom Configuration
Modify `deployment/config/nginx.conf` for custom Nginx settings or create additional configuration files as needed.
