#!/bin/bash

# Test script to verify SSL/TLS functionality
# This script should be run inside the container

set -e

echo "🔐 Testing SSL/TLS Functionality"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Function to print info
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Test 1: Check SSL certificate files exist
echo -e "\n${YELLOW}1. Checking SSL Certificate Files${NC}"
if [ -f "/etc/nginx/ssl/nginx.crt" ] && [ -f "/etc/nginx/ssl/nginx.key" ]; then
    print_result 0 "SSL certificate files exist"
    echo "   Certificate: /etc/nginx/ssl/nginx.crt"
    echo "   Private Key: /etc/nginx/ssl/nginx.key"
else
    print_result 1 "SSL certificate files missing"
fi

# Test 2: Validate SSL certificate
echo -e "\n${YELLOW}2. Validating SSL Certificate${NC}"
if openssl x509 -in /etc/nginx/ssl/nginx.crt -text -noout >/dev/null 2>&1; then
    print_result 0 "SSL certificate is valid"
    
    # Extract certificate details
    SUBJECT=$(openssl x509 -in /etc/nginx/ssl/nginx.crt -noout -subject 2>/dev/null | sed 's/subject=//')
    ISSUER=$(openssl x509 -in /etc/nginx/ssl/nginx.crt -noout -issuer 2>/dev/null | sed 's/issuer=//')
    NOT_AFTER=$(openssl x509 -in /etc/nginx/ssl/nginx.crt -noout -enddate 2>/dev/null | sed 's/notAfter=//')
    
    echo "   Subject: $SUBJECT"
    echo "   Issuer: $ISSUER"
    echo "   Expires: $NOT_AFTER"
else
    print_result 1 "SSL certificate is invalid or corrupted"
fi

# Test 3: Test SSL handshake
echo -e "\n${YELLOW}3. Testing SSL Handshake${NC}"
SSL_HANDSHAKE=$(echo | openssl s_client -connect localhost:443 -servername localhost 2>/dev/null | grep "Verify return code" || echo "FAILED")
if echo "$SSL_HANDSHAKE" | grep -q "Verify return code: 0"; then
    print_result 0 "SSL handshake successful"
    echo "   $SSL_HANDSHAKE"
else
    # For self-signed certificates, we expect a different return code
    if echo "$SSL_HANDSHAKE" | grep -q "Verify return code: 18"; then
        print_result 0 "SSL handshake successful (self-signed certificate)"
        echo "   $SSL_HANDSHAKE"
    else
        print_result 1 "SSL handshake failed"
        echo "   $SSL_HANDSHAKE"
    fi
fi

# Test 4: Check TLS protocols
echo -e "\n${YELLOW}4. Testing TLS Protocols${NC}"
TLS12_TEST=$(echo | openssl s_client -connect localhost:443 -tls1_2 2>/dev/null | grep "Protocol" || echo "FAILED")
TLS13_TEST=$(echo | openssl s_client -connect localhost:443 -tls1_3 2>/dev/null | grep "Protocol" || echo "FAILED")

if echo "$TLS12_TEST" | grep -q "TLSv1.2"; then
    print_result 0 "TLS 1.2 is supported"
else
    print_result 1 "TLS 1.2 is not supported"
fi

if echo "$TLS13_TEST" | grep -q "TLSv1.3"; then
    print_result 0 "TLS 1.3 is supported"
else
    print_result 1 "TLS 1.3 is not supported"
fi

# Test 5: Test HTTPS connectivity with curl
echo -e "\n${YELLOW}5. Testing HTTPS Connectivity${NC}"
HTTPS_RESPONSE=$(curl -s -k -o /dev/null -w "%{http_code}" https://localhost:443/ || echo "000")
if [ "$HTTPS_RESPONSE" = "200" ]; then
    print_result 0 "HTTPS connectivity working (Status: $HTTPS_RESPONSE)"
else
    print_result 1 "HTTPS connectivity failed (Status: $HTTPS_RESPONSE)"
fi

# Test 6: Check SSL cipher suites
echo -e "\n${YELLOW}6. Testing SSL Cipher Suites${NC}"
CIPHER_TEST=$(echo | openssl s_client -connect localhost:443 2>/dev/null | grep "Cipher:" || echo "FAILED")
if echo "$CIPHER_TEST" | grep -q "Cipher:"; then
    print_result 0 "SSL cipher negotiation working"
    echo "   $CIPHER_TEST"
else
    # Try a different approach for cipher detection
    CIPHER_ALT=$(echo | openssl s_client -connect localhost:443 2>/dev/null | grep -E "(Cipher|TLS)" | head -1 || echo "FAILED")
    if echo "$CIPHER_ALT" | grep -q -E "(Cipher|TLS)"; then
        print_result 0 "SSL cipher negotiation working (alternative detection)"
        echo "   $CIPHER_ALT"
    else
        print_result 1 "SSL cipher negotiation failed"
    fi
fi

# Test 7: Test HTTP to HTTPS redirect
echo -e "\n${YELLOW}7. Testing HTTP to HTTPS Redirect${NC}"
REDIRECT_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/ || echo "000")
if [ "$REDIRECT_RESPONSE" = "301" ]; then
    print_result 0 "HTTP to HTTPS redirect working (Status: $REDIRECT_RESPONSE)"
else
    print_result 1 "HTTP to HTTPS redirect failed (Status: $REDIRECT_RESPONSE)"
fi

# Test 8: Check security headers over HTTPS
echo -e "\n${YELLOW}8. Checking HTTPS Security Headers${NC}"
HSTS_HEADER=$(curl -s -k -I https://localhost:443/ | grep "Strict-Transport-Security" || echo "")
XFRAME_HEADER=$(curl -s -k -I https://localhost:443/ | grep "X-Frame-Options" || echo "")
XCONTENT_HEADER=$(curl -s -k -I https://localhost:443/ | grep "X-Content-Type-Options" || echo "")

SECURITY_COUNT=0
if [ -n "$HSTS_HEADER" ]; then
    echo "   ✅ HSTS header present"
    SECURITY_COUNT=$((SECURITY_COUNT + 1))
else
    echo "   ❌ HSTS header missing"
fi

if [ -n "$XFRAME_HEADER" ]; then
    echo "   ✅ X-Frame-Options header present"
    SECURITY_COUNT=$((SECURITY_COUNT + 1))
else
    echo "   ❌ X-Frame-Options header missing"
fi

if [ -n "$XCONTENT_HEADER" ]; then
    echo "   ✅ X-Content-Type-Options header present"
    SECURITY_COUNT=$((SECURITY_COUNT + 1))
else
    echo "   ❌ X-Content-Type-Options header missing"
fi

if [ $SECURITY_COUNT -ge 3 ]; then
    print_result 0 "All security headers present ($SECURITY_COUNT/3)"
else
    print_result 1 "Security headers incomplete ($SECURITY_COUNT/3)"
fi

# Test 9: Test SSL certificate expiration
echo -e "\n${YELLOW}9. Checking SSL Certificate Expiration${NC}"
CERT_END_DATE=$(openssl x509 -in /etc/nginx/ssl/nginx.crt -noout -enddate | cut -d= -f2)
CERT_END_EPOCH=$(date -d "$CERT_END_DATE" +%s 2>/dev/null || echo "0")
CURRENT_EPOCH=$(date +%s)

if [ "$CERT_END_EPOCH" -gt "$CURRENT_EPOCH" ]; then
    DAYS_LEFT=$(( (CERT_END_EPOCH - CURRENT_EPOCH) / 86400 ))
    print_result 0 "SSL certificate is valid (expires in $DAYS_LEFT days)"
    echo "   Expiration date: $CERT_END_DATE"
else
    print_result 1 "SSL certificate has expired"
fi

echo -e "\n${GREEN}🎉 All SSL/TLS tests passed!${NC}"
echo "SSL configuration is working correctly with proper security settings."
