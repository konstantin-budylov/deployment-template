# Docker Container Test Suite

This directory contains test scripts to verify the functionality and availability of the Docker container setup.

## Test Scripts

### `run-tests.sh` - Main Test Runner
The main test script that runs all available tests. Can be executed from the host system or inside the container.

**Usage:**
```bash
# From host system
./deployment/tests/run-tests.sh

# Inside container
bash /var/www/html/deployment/tests/run-tests.sh
```

### `test-nginx.sh` - Nginx Functionality Tests
Tests nginx availability, configuration, and basic functionality.

**Tests performed:**
- Nginx process status
- Port availability (80, 443)
- HTTP/HTTPS connectivity
- Configuration syntax validation
- PHP-FPM integration
- Security headers

### `test-ssl.sh` - SSL/TLS Functionality Tests
Tests SSL certificate validity, TLS protocols, and security features.

**Tests performed:**
- SSL certificate file existence
- Certificate validation and expiration
- SSL handshake testing
- TLS protocol support (1.2, 1.3)
- HTTPS connectivity
- Cipher suite negotiation
- HTTP to HTTPS redirect
- Security headers over HTTPS

## Running Tests

### From Host System
```bash
# Run all tests
./deployment/tests/run-tests.sh

# Run individual tests
docker-compose exec web bash /var/www/html/deployment/tests/test-nginx.sh
docker-compose exec web bash /var/www/html/deployment/tests/test-ssl.sh
```

### Inside Container
```bash
# Run all tests
bash /var/www/html/deployment/tests/run-tests.sh

# Run individual tests
bash /var/www/html/deployment/tests/test-nginx.sh
bash /var/www/html/deployment/tests/test-ssl.sh
```

## Test Output

The test scripts provide colored output with:
- ✅ Green: Test passed
- ❌ Red: Test failed
- ℹ️ Blue: Information
- 🎉 Success: All tests passed

## Prerequisites

- Docker and Docker Compose installed
- Container running (`docker-compose up -d`)
- `curl` and `openssl` available in container
- `jq` available on host (for health check parsing)

## Troubleshooting

If tests fail:

1. **Check container status:**
   ```bash
   docker-compose ps
   ```

2. **View container logs:**
   ```bash
   docker-compose logs web
   ```

3. **Check container health:**
   ```bash
   docker inspect web --format='{{json .State.Health}}' | jq .
   ```

4. **Access container shell:**
   ```bash
   docker-compose exec web sh
   ```

## Test Coverage

The test suite covers:
- ✅ Nginx service availability
- ✅ SSL certificate functionality
- ✅ HTTP/HTTPS connectivity
- ✅ Security headers
- ✅ Container health monitoring
- ✅ External accessibility
- ✅ Configuration validation
