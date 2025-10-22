#!/bin/bash

# Test script to verify nginx availability and functionality
# This script should be run inside the container

set -e

echo "🔍 Testing Nginx Availability and Functionality"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        exit 1
    fi
}

# Test 1: Check if nginx process is running
echo -e "\n${YELLOW}1. Checking Nginx Process${NC}"
if pgrep nginx > /dev/null; then
    print_result 0 "Nginx process is running"
    echo "   Process ID: $(pgrep nginx)"
else
    print_result 1 "Nginx process is not running"
fi

# Test 2: Check if nginx is listening on port 80
echo -e "\n${YELLOW}2. Checking Nginx Port 80${NC}"
if netstat -tlnp | grep :80 > /dev/null; then
    print_result 0 "Nginx is listening on port 80"
else
    print_result 1 "Nginx is not listening on port 80"
fi

# Test 3: Check if nginx is listening on port 443
echo -e "\n${YELLOW}3. Checking Nginx Port 443${NC}"
if netstat -tlnp | grep :443 > /dev/null; then
    print_result 0 "Nginx is listening on port 443"
else
    print_result 1 "Nginx is not listening on port 443"
fi

# Test 4: Test HTTP connectivity
echo -e "\n${YELLOW}4. Testing HTTP Connectivity${NC}"
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/ || echo "000")
if [ "$HTTP_RESPONSE" = "301" ] || [ "$HTTP_RESPONSE" = "200" ]; then
    print_result 0 "HTTP connectivity working (Status: $HTTP_RESPONSE)"
else
    print_result 1 "HTTP connectivity failed (Status: $HTTP_RESPONSE)"
fi

# Test 5: Test HTTPS connectivity
echo -e "\n${YELLOW}5. Testing HTTPS Connectivity${NC}"
HTTPS_RESPONSE=$(curl -s -k -o /dev/null -w "%{http_code}" https://localhost:443/ || echo "000")
if [ "$HTTPS_RESPONSE" = "200" ]; then
    print_result 0 "HTTPS connectivity working (Status: $HTTPS_RESPONSE)"
else
    print_result 1 "HTTPS connectivity failed (Status: $HTTPS_RESPONSE)"
fi

# Test 6: Check nginx configuration syntax
echo -e "\n${YELLOW}6. Checking Nginx Configuration${NC}"
if nginx -t > /dev/null 2>&1; then
    print_result 0 "Nginx configuration syntax is valid"
else
    print_result 1 "Nginx configuration has syntax errors"
fi

# Test 7: Check if PHP-FPM is working
echo -e "\n${YELLOW}7. Testing PHP-FPM Integration${NC}"
PHP_RESPONSE=$(curl -s -k https://localhost:443/ | grep -o "PHP Version" || echo "")
if [ -n "$PHP_RESPONSE" ]; then
    print_result 0 "PHP-FPM integration working"
else
    print_result 1 "PHP-FPM integration failed"
fi

# Test 8: Check security headers
echo -e "\n${YELLOW}8. Checking Security Headers${NC}"
SECURITY_HEADERS=$(curl -s -k -I https://localhost:443/ | grep -E "(strict-transport-security|x-frame-options|x-content-type-options)" | wc -l)
if [ "$SECURITY_HEADERS" -ge 1 ]; then
    print_result 0 "Security headers present ($SECURITY_HEADERS headers found)"
else
    print_result 1 "Security headers missing (only $SECURITY_HEADERS headers found)"
fi

echo -e "\n${GREEN}🎉 All Nginx tests passed!${NC}"
echo "Nginx is properly configured and running with all required functionality."
