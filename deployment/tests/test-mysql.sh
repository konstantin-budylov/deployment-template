#!/bin/bash

# Test script to verify MySQL availability and functionality
# This script should be run inside the container

set -e

# Load environment variables from .env file if it exists
if [ -f "/var/www/html/.env" ]; then
    echo "📋 Loading environment variables from .env file"
    export $(grep -v '^#' /var/www/html/.env | xargs)
fi

echo "🗄️  Testing MySQL Availability and Functionality"
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

# Test 1: Check if MySQL container is running
echo -e "\n${YELLOW}1. Checking MySQL Container${NC}"
if docker-compose ps mysql | grep -q "Up"; then
    print_result 0 "MySQL container is running"
    echo "   Container status: $(docker-compose ps mysql --format 'table {{.State}}')"
else
    print_result 1 "MySQL container is not running"
fi

# Test 2: Check if MySQL is listening on port 3306
echo -e "\n${YELLOW}2. Checking MySQL Port 3306${NC}"
if nc -z mysql 3306 2>/dev/null; then
    print_result 0 "MySQL is listening on port 3306"
else
    print_result 1 "MySQL is not listening on port 3306"
fi

# Test 3: Test MySQL connection
echo -e "\n${YELLOW}3. Testing MySQL Connection${NC}"
if mysqladmin ping -h mysql -u root -p${MYSQL_ROOT_PASSWORD:-rootpassword} > /dev/null 2>&1; then
    print_result 0 "MySQL connection successful"
else
    print_result 1 "MySQL connection failed"
fi

# Test 4: Check if database exists
echo -e "\n${YELLOW}4. Checking Database Existence${NC}"
DB_NAME=${MYSQL_DATABASE:-manogama}
if mysql -h mysql -u root -p${MYSQL_ROOT_PASSWORD:-rootpassword} -e "USE $DB_NAME;" > /dev/null 2>&1; then
    print_result 0 "Database '$DB_NAME' exists"
else
    print_result 1 "Database '$DB_NAME' does not exist"
fi

# Test 5: Check if user exists
echo -e "\n${YELLOW}5. Checking MySQL User${NC}"
MYSQL_USER=${MYSQL_USER:-manogama_user}
if mysql -h mysql -u root -p${MYSQL_ROOT_PASSWORD:-rootpassword} -e "SELECT User FROM mysql.user WHERE User='$MYSQL_USER';" | grep -q "$MYSQL_USER"; then
    print_result 0 "MySQL user '$MYSQL_USER' exists"
else
    print_result 1 "MySQL user '$MYSQL_USER' does not exist"
fi

# Test 6: Test user connection
echo -e "\n${YELLOW}6. Testing User Connection${NC}"
MYSQL_PASSWORD=${MYSQL_PASSWORD:-manogama_password}
if mysql -h mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -e "SELECT 1;" > /dev/null 2>&1; then
    print_result 0 "User connection successful"
else
    print_result 1 "User connection failed"
fi

# Test 7: Check if tables exist
echo -e "\n${YELLOW}7. Checking Database Tables${NC}"
TABLE_COUNT=$(mysql -h mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $DB_NAME -e "SHOW TABLES;" 2>/dev/null | wc -l)
if [ "$TABLE_COUNT" -gt 0 ]; then
    print_result 0 "Database tables exist ($TABLE_COUNT tables found)"
    echo "   Tables:"
    mysql -h mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $DB_NAME -e "SHOW TABLES;" 2>/dev/null | tail -n +2 | sed 's/^/   - /'
else
    print_result 1 "No database tables found"
fi

# Test 8: Check MySQL version
echo -e "\n${YELLOW}8. Checking MySQL Version${NC}"
MYSQL_VERSION=$(mysql -h mysql -u root -p${MYSQL_ROOT_PASSWORD:-rootpassword} -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
if [ -n "$MYSQL_VERSION" ]; then
    print_result 0 "MySQL version: $MYSQL_VERSION"
else
    print_result 1 "Could not retrieve MySQL version"
fi

# Test 9: Check MySQL configuration
echo -e "\n${YELLOW}9. Checking MySQL Configuration${NC}"
if mysql -h mysql -u root -p${MYSQL_ROOT_PASSWORD:-rootpassword} -e "SHOW VARIABLES LIKE 'character_set%';" > /dev/null 2>&1; then
    print_result 0 "MySQL configuration accessible"
    echo "   Character set:"
    mysql -h mysql -u root -p${MYSQL_ROOT_PASSWORD:-rootpassword} -e "SHOW VARIABLES LIKE 'character_set_database';" 2>/dev/null | tail -n 1 | awk '{print "   - " $2}'
else
    print_result 1 "MySQL configuration not accessible"
fi

# Test 10: Test sample data
echo -e "\n${YELLOW}10. Checking Sample Data${NC}"
USER_COUNT=$(mysql -h mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $DB_NAME -e "SELECT COUNT(*) FROM users;" 2>/dev/null | tail -n 1)
if [ "$USER_COUNT" -gt 0 ]; then
    print_result 0 "Sample data exists ($USER_COUNT users found)"
else
    print_result 1 "No sample data found"
fi

echo -e "\n${GREEN}🎉 All MySQL tests passed!${NC}"
echo "MySQL is properly configured and running with database initialization."
