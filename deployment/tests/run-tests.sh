#!/bin/bash

# Main test runner script for Docker container tests
# This script can be run from host or inside the container

set -e

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
    echo "📋 Loading environment variables from .env file"
    export $(grep -v '^#' .env | xargs)
fi

echo "🧪 Docker Container Test Suite"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print section headers
print_section() {
    echo -e "\n${PURPLE}📋 $1${NC}"
    echo "----------------------------------------"
}

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if running inside container or from host
if [ -f "/.dockerenv" ]; then
    echo -e "${BLUE}🐳 Running inside Docker container${NC}"
    RUNNING_IN_CONTAINER=true
else
    echo -e "${BLUE}🖥️  Running from host system${NC}"
    RUNNING_IN_CONTAINER=false
fi

# Test 1: Nginx Availability and Functionality
print_section "Testing Nginx Availability and Functionality"

if [ "$RUNNING_IN_CONTAINER" = true ]; then
    # Run directly inside container
    bash "$SCRIPT_DIR/test-nginx.sh"
    NGINX_RESULT=$?
else
    # Run via docker-compose exec
    echo "Running nginx tests via docker-compose..."
    if docker-compose exec -T web sh /var/www/html/deployment/tests/test-nginx.sh; then
        NGINX_RESULT=0
    else
        NGINX_RESULT=1
    fi
fi

print_result $NGINX_RESULT "Nginx functionality test"

# Test 2: SSL/TLS Functionality
print_section "Testing SSL/TLS Functionality"

if [ "$RUNNING_IN_CONTAINER" = true ]; then
    # Run directly inside container
    bash "$SCRIPT_DIR/test-ssl.sh"
    SSL_RESULT=$?
else
    # Run via docker-compose exec
    echo "Running SSL tests via docker-compose..."
    if docker-compose exec -T web sh /var/www/html/deployment/tests/test-ssl.sh; then
        SSL_RESULT=0
    else
        SSL_RESULT=1
    fi
fi

print_result $SSL_RESULT "SSL/TLS functionality test"

# Test 3: Xdebug Functionality
print_section "Testing Xdebug Functionality"

if [ "$RUNNING_IN_CONTAINER" = true ]; then
    # Run directly inside container
    bash "$SCRIPT_DIR/test-xdebug.sh"
    XDEBUG_RESULT=$?
else
    # Run via docker-compose exec
    echo "Running Xdebug tests via docker-compose..."
    if docker-compose exec -T web sh /var/www/html/deployment/tests/test-xdebug.sh; then
        XDEBUG_RESULT=0
    else
        XDEBUG_RESULT=1
    fi
fi

print_result $XDEBUG_RESULT "Xdebug functionality test"

# Test 4: Container Health Check
print_section "Testing Container Health"

if [ "$RUNNING_IN_CONTAINER" = false ]; then
    # Use environment variable or default for container name
    CONTAINER_NAME=${NGINX_CONTAINER_NAME:-web}
    
    # Check container health status
    HEALTH_STATUS=$(docker inspect $CONTAINER_NAME --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
    
    if [ "$HEALTH_STATUS" = "healthy" ]; then
        print_result 0 "Container health check ($CONTAINER_NAME): $HEALTH_STATUS"
        HEALTH_RESULT=0
    else
        print_result 1 "Container health check ($CONTAINER_NAME): $HEALTH_STATUS"
        HEALTH_RESULT=1
    fi
    
    # Check if container is running
    CONTAINER_STATUS=$(docker-compose ps --services --filter "status=running" | grep -q $CONTAINER_NAME && echo "running" || echo "not running")
    
    if [ "$CONTAINER_STATUS" = "running" ]; then
        print_result 0 "Container status ($CONTAINER_NAME): $CONTAINER_STATUS"
    else
        print_result 1 "Container status ($CONTAINER_NAME): $CONTAINER_STATUS"
    fi
else
    echo "Skipping container health check (running inside container)"
    HEALTH_RESULT=0
fi

# Test 4: MySQL Functionality
print_section "Testing MySQL Functionality"
echo "Running MySQL tests via docker-compose..."
MYSQL_RESULT=0
if docker-compose exec -T mysql mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD:-rootpassword} > /dev/null 2>&1; then
    echo -e "${GREEN}✅ MySQL connection test${NC}"
    
    # Test database existence
    if docker-compose exec -T mysql mysql -u root -p${MYSQL_ROOT_PASSWORD:-rootpassword} -e "USE ${MYSQL_DATABASE:-manogama};" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Database '${MYSQL_DATABASE:-manogama}' exists${NC}"
        
        # Test tables
        TABLE_COUNT=$(docker-compose exec -T mysql mysql -u ${MYSQL_USER:-manogama_user} -p${MYSQL_PASSWORD:-manogama_password} ${MYSQL_DATABASE:-manogama} -e "SHOW TABLES;" 2>/dev/null | wc -l)
        if [ "$TABLE_COUNT" -gt 0 ]; then
            echo -e "${GREEN}✅ Database tables exist ($TABLE_COUNT tables)${NC}"
            MYSQL_RESULT=0
        else
            echo -e "${RED}❌ No database tables found${NC}"
            MYSQL_RESULT=1
        fi
    else
        echo -e "${RED}❌ Database '${MYSQL_DATABASE:-manogama}' does not exist${NC}"
        MYSQL_RESULT=1
    fi
else
    echo -e "${RED}❌ MySQL connection failed${NC}"
    MYSQL_RESULT=1
fi

# Test 5: External Connectivity (from host only)
if [ "$RUNNING_IN_CONTAINER" = false ]; then
    print_section "Testing External Connectivity"
    
    # Use environment variables or defaults
    HTTP_PORT=${HTTP_PORT:-8000}
    HTTPS_PORT=${HTTPS_PORT:-8443}
    
    echo "Testing HTTP on port $HTTP_PORT and HTTPS on port $HTTPS_PORT"
    
    # Test HTTP redirect
    HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$HTTP_PORT/ || echo "000")
    if [ "$HTTP_RESPONSE" = "301" ]; then
        print_result 0 "HTTP redirect working on port $HTTP_PORT (Status: $HTTP_RESPONSE)"
    else
        print_result 1 "HTTP redirect failed on port $HTTP_PORT (Status: $HTTP_RESPONSE)"
    fi
    
    # Test HTTPS access
    HTTPS_RESPONSE=$(curl -s -k -o /dev/null -w "%{http_code}" https://localhost:$HTTPS_PORT/ || echo "000")
    if [ "$HTTPS_RESPONSE" = "200" ]; then
        print_result 0 "HTTPS access working on port $HTTPS_PORT (Status: $HTTPS_RESPONSE)"
    else
        print_result 1 "HTTPS access failed on port $HTTPS_PORT (Status: $HTTPS_RESPONSE)"
    fi
    
    if [ "$HTTP_RESPONSE" = "301" ] && [ "$HTTPS_RESPONSE" = "200" ]; then
        EXTERNAL_RESULT=0
    else
        EXTERNAL_RESULT=1
    fi
else
    echo "Skipping external connectivity test (running inside container)"
    EXTERNAL_RESULT=0
fi

# Summary
print_section "Test Summary"

TOTAL_TESTS=0
PASSED_TESTS=0

# Count results
if [ $NGINX_RESULT -eq 0 ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ $SSL_RESULT -eq 0 ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ $XDEBUG_RESULT -eq 0 ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ $MYSQL_RESULT -eq 0 ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if [ "$RUNNING_IN_CONTAINER" = false ]; then
    if [ $HEALTH_RESULT -eq 0 ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ $EXTERNAL_RESULT -eq 0 ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

echo "Tests passed: $PASSED_TESTS/$TOTAL_TESTS"

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "\n${GREEN}🎉 All tests passed! The Docker setup is working correctly.${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed. Please check the output above for details.${NC}"
    exit 1
fi
