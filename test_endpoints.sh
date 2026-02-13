#!/bin/bash

# Test script for meppi-rails endpoints
# Zero Script QA methodology

SERVER_URL="http://localhost:3000"
LOG_FILE="qa_test_$(date +%Y%m%d_%H%M%S).log"

# Initialize report
cat > zero-script-qa-report.md << EOF
# Zero Script QA Report - meppi-rails

## Date: $(date)
## Server: $SERVER_URL

## Test Scope
1. **Dashboard Home** - Root path, navigation cards
2. **Channel Comparison** - /channel-comparison
3. **Competition** - /competition (index + compare actions)
4. **Promotion** - /promotion
5. **Regional Price** - /regional-price
6. **API v1 Navigation** - /api/v1/navigation (Hotwire Native bridge)
7. **Semantic Search** - POST /api/v1/semantic_search

## Monitoring Setup
- Server: Rails 7.1.6 production mode
- Log monitoring: Active
- Error detection: Enabled

## Test Results

### Testing Frontend Endpoints
EOF

# Test function
test_endpoint() {
    local endpoint=$1
    local description=$2
    echo "Testing: $endpoint ($description)" | tee -a $LOG_FILE

    # Test the endpoint
    local response=$(curl -s -w "Status: %{http_code}\nTime: %{time_total}\n" $SERVER_URL$endpoint -o /tmp/response.html 2>&1)

    # Extract status code
    local status=$(echo "$response" | grep "Status:" | cut -d' ' -f2)

    # Log results
    echo "Endpoint: $endpoint" >> $LOG_FILE
    echo "Status: $status" >> $LOG_FILE

    if [ "$status" = "200" ]; then
        echo "✅ PASS - $endpoint returned 200" | tee -a $LOG_FILE
        echo "" >> $LOG_FILE
    else
        echo "❌ FAIL - $endpoint returned $status" | tee -a $LOG_FILE
        echo "Response headers:" | tee -a $LOG_FILE
        echo "$response" | head -10 | tee -a $LOG_FILE
        echo "" >> $LOG_FILE
    fi

    # Check response content
    if [ -f /tmp/response.html ] && [ -s /tmp/response.html ]; then
        local content=$(head -20 /tmp/response.html)
        if echo "$content" | grep -q "error\|Error\|ERROR\|exception\|Exception"; then
            echo "⚠️  ERROR DETECTED in response" | tee -a $LOG_FILE
            echo "Content: $content" | tee -a $LOG_FILE
            echo "" >> $LOG_FILE
        fi
    fi
}

# Test all frontend endpoints
echo "=== Starting Frontend Endpoint Tests ===" | tee -a $LOG_FILE
test_endpoint "/" "Dashboard Home"
test_endpoint "/dashboard" "Dashboard Index"
test_endpoint "/channel-comparison" "Channel Comparison"
test_endpoint "/competition" "Competition Index"
test_endpoint "/promotion" "Promotion Index"
test_endpoint "/regional-price" "Regional Price"

# Test API endpoints
echo "=== Testing API Endpoints ===" | tee -a $LOG_FILE
test_endpoint "/health" "Health Check"
test_endpoint "/api/v1/navigation" "API Navigation"

# Test semantic search API
echo "=== Testing Semantic Search API ===" | tee -a $LOG_FILE
local search_response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"query": "iPhone 15"}' \
    $SERVER_URL/api/v1/semantic_search \
    -o /tmp/search_response.json \
    -w "Status: %{http_code}\nTime: %{time_total}\n")

local search_status=$(echo "$search_response" | grep "Status:" | cut -d' ' -f2)
echo "Semantic Search Status: $search_status" | tee -a $LOG_FILE

if [ "$search_status" = "200" ]; then
    echo "✅ PASS - Semantic API returned 200" | tee -a $LOG_FILE
    if [ -f /tmp/search_response.json ]; then
        local search_content=$(cat /tmp/search_response.json)
        echo "Response: $search_content" | tee -a $LOG_FILE
    fi
else
    echo "❌ FAIL - Semantic API returned $search_status" | tee -a $LOG_FILE
fi

echo "" >> $LOG_FILE

# Summary
echo "=== Test Summary ===" >> zero-script-qa-report.md
echo "Test completed at $(date)" >> zero-script-qa-report.md
echo "Check $LOG_FILE for detailed logs" >> zero-script-qa-report.md

# Add issue log to report
cat >> zero-script-qa-report.md << EOF

## Issue Log

### Issues Found
EOF

# Update report with test results
grep -E "(✅|❌|⚠️)" $LOG_FILE >> zero-script-qa-report.md

echo "QA Test completed. Report saved to zero-script-qa-report.md"
echo "Logs saved to $LOG_FILE"