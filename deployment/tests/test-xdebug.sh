#!/bin/bash

# Test script to verify Xdebug availability and configuration
# This script should be run inside the container

set -e

# Load environment variables from .env file if it exists
if [ -f "/var/www/html/.env" ]; then
    echo "📋 Loading environment variables from .env file"
    export $(grep -v '^#' /var/www/html/.env | xargs)
fi

echo "🐛 Testing Xdebug Availability and Configuration"
echo "==============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print test results
print_result() {
    local status=$1
    local message=$2
    if [ "$status" -eq 0 ]; then
        echo -e "${GREEN}✅ $message${NC}"
    else
        echo -e "${RED}❌ $message${NC}"
        exit 1 # Exit on first failure
    fi
}

# Test 1: Check if Xdebug extension is loaded
echo -e "\n${YELLOW}1. Checking Xdebug Extension${NC}"
if php84 -m | grep -q "xdebug"; then
    print_result 0 "Xdebug extension is loaded"
    echo "   Extension version: $(php84 -i | grep 'xdebug version' | cut -d: -f2 | xargs)"
else
    print_result 1 "Xdebug extension is not loaded"
fi

# Test 2: Check Xdebug configuration file
echo -e "\n${YELLOW}2. Checking Xdebug Configuration File${NC}"
if [ -f "/etc/php84/conf.d/50_xdebug.ini" ]; then
    print_result 0 "Xdebug configuration file exists"
    echo "   Configuration file: /etc/php84/conf.d/50_xdebug.ini"
else
    print_result 1 "Xdebug configuration file missing"
fi

# Test 3: Check Xdebug mode
echo -e "\n${YELLOW}3. Checking Xdebug Mode${NC}"
XDEBUG_MODE=$(php84 -i | grep 'xdebug.mode' | awk '{print $3}')
if [ -n "$XDEBUG_MODE" ]; then
    print_result 0 "Xdebug mode is configured: $XDEBUG_MODE"
else
    print_result 1 "Xdebug mode is not configured"
fi

# Test 4: Check client host configuration
echo -e "\n${YELLOW}4. Checking Client Host Configuration${NC}"
CLIENT_HOST=$(php84 -i | grep 'xdebug.client_host' | awk '{print $3}')
if [ "$CLIENT_HOST" = "host.docker.internal" ]; then
    print_result 0 "Client host configured for Docker: $CLIENT_HOST"
else
    print_result 1 "Client host not configured for Docker (found: $CLIENT_HOST)"
fi

# Test 5: Check client port
echo -e "\n${YELLOW}5. Checking Client Port${NC}"
CLIENT_PORT=$(php84 -i | grep 'xdebug.client_port' | awk '{print $3}')
if [ "$CLIENT_PORT" = "9003" ]; then
    print_result 0 "Client port configured: $CLIENT_PORT"
else
    print_result 1 "Client port not configured correctly (found: $CLIENT_PORT)"
fi

# Test 6: Check start with request
echo -e "\n${YELLOW}6. Checking Start With Request${NC}"
START_WITH_REQUEST=$(php84 -i | grep 'xdebug.start_with_request' | awk '{print $3}')
if [ "$START_WITH_REQUEST" = "yes" ]; then
    print_result 0 "Start with request enabled: $START_WITH_REQUEST"
else
    print_result 1 "Start with request not enabled (found: $START_WITH_REQUEST)"
fi

# Test 7: Check IDE key
echo -e "\n${YELLOW}7. Checking IDE Key${NC}"
IDE_KEY=$(php84 -i | grep 'xdebug.idekey' | awk '{print $3}')
if [ -n "$IDE_KEY" ]; then
    print_result 0 "IDE key configured: $IDE_KEY"
else
    print_result 1 "IDE key not configured"
fi

# Test 8: Check Xdebug functions availability
echo -e "\n${YELLOW}8. Checking Xdebug Functions${NC}"
if php84 -r "if (function_exists('xdebug_info')) { echo 'xdebug_info available'; } else { echo 'xdebug_info not available'; }" | grep -q "xdebug_info available"; then
    print_result 0 "Xdebug functions are available"
else
    print_result 1 "Xdebug functions are not available"
fi

# Test 9: Check Xdebug version
echo -e "\n${YELLOW}9. Checking Xdebug Version${NC}"
XDEBUG_VERSION=$(php84 -i | grep 'with Xdebug' | awk '{print $3}')
if [ -n "$XDEBUG_VERSION" ]; then
    print_result 0 "Xdebug version: $XDEBUG_VERSION"
else
    print_result 1 "Xdebug version not found"
fi

# Test 10: Check Xdebug log configuration
echo -e "\n${YELLOW}10. Checking Xdebug Log Configuration${NC}"
LOG_LEVEL=$(php84 -i | grep 'xdebug.log_level' | awk '{print $3}')
LOG_FILE=$(php84 -i | grep 'xdebug.log' | awk '{print $3}')
if [ -n "$LOG_LEVEL" ] && [ -n "$LOG_FILE" ]; then
    print_result 0 "Xdebug logging configured (level: $LOG_LEVEL, file: $LOG_FILE)"
else
    print_result 1 "Xdebug logging not properly configured"
fi

echo -e "\n${GREEN}🎉 All Xdebug tests passed!${NC}"
echo "Xdebug is properly configured for Docker development with host.docker.internal."
