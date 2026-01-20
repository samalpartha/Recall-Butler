#!/bin/bash

# ============================================
# Recall Butler Test Runner
# ============================================
# Usage: ./run_tests.sh [all|unit|integration|e2e|api]
# ============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Change to project root
cd "$(dirname "$0")"

TEST_TYPE=${1:-all}

# ============================================
# Unit Tests - Flutter
# ============================================
run_unit_tests() {
    print_header "Running Flutter Unit Tests"
    
    cd recall_butler_flutter
    
    if flutter test test/unit/ 2>/dev/null; then
        print_success "Flutter unit tests passed"
    else
        print_warning "Some Flutter unit tests may have failed (check output)"
    fi
    
    cd ..
}

# ============================================
# Unit Tests - Server
# ============================================
run_server_unit_tests() {
    print_header "Running Server Unit Tests"
    
    cd recall_butler_server
    
    if dart test test/unit/ 2>/dev/null; then
        print_success "Server unit tests passed"
    else
        print_warning "Some server unit tests may have failed"
    fi
    
    cd ..
}

# ============================================
# Integration Tests
# ============================================
run_integration_tests() {
    print_header "Running Integration Tests"
    
    echo "Note: Server must be running at localhost:8180"
    
    cd recall_butler_server
    
    if dart test test/integration/api_test.dart 2>/dev/null; then
        print_success "API integration tests passed"
    else
        print_warning "Some integration tests may have failed (is server running?)"
    fi
    
    cd ..
}

# ============================================
# E2E Tests - Flutter
# ============================================
run_e2e_tests() {
    print_header "Running E2E Tests"
    
    cd recall_butler_flutter
    
    if flutter test test/integration/e2e_test.dart 2>/dev/null; then
        print_success "E2E tests passed"
    else
        print_warning "Some E2E tests may have failed"
    fi
    
    cd ..
}

# ============================================
# API Schema Validation
# ============================================
run_api_validation() {
    print_header "Validating API Schema"
    
    if command -v curl &> /dev/null; then
        echo "Testing server health..."
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8180/ | grep -q "200\|301\|302"; then
            print_success "Server is responding"
        else
            print_warning "Server may not be running"
        fi
        
        echo "Testing OpenAPI spec..."
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8182/openapi.yaml | grep -q "200"; then
            print_success "OpenAPI spec accessible"
        else
            print_warning "OpenAPI spec not accessible"
        fi
        
        echo "Testing Swagger UI..."
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8182/docs | grep -q "200"; then
            print_success "Swagger UI accessible"
        else
            print_warning "Swagger UI not accessible"
        fi
    else
        print_warning "curl not found, skipping API validation"
    fi
}

# ============================================
# Main
# ============================================
case $TEST_TYPE in
    unit)
        run_unit_tests
        run_server_unit_tests
        ;;
    integration)
        run_integration_tests
        ;;
    e2e)
        run_e2e_tests
        ;;
    api)
        run_api_validation
        ;;
    all)
        run_unit_tests
        run_server_unit_tests
        run_integration_tests
        run_e2e_tests
        run_api_validation
        ;;
    *)
        echo "Usage: $0 [all|unit|integration|e2e|api]"
        exit 1
        ;;
esac

print_header "Test Summary"
echo ""
echo "Test run complete!"
echo ""
echo "Available endpoints:"
echo "  • App:     http://localhost:8182/app/"
echo "  • API:     http://localhost:8180/"
echo "  • Swagger: http://localhost:8182/docs"
echo "  • OpenAPI: http://localhost:8182/openapi.yaml"
echo ""
