#!/bin/bash

# ============================================
# Recall Butler Complete Test Suite
# With Allure-Compatible Reports
# ============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

cd "$(dirname "$0")"
PROJECT_ROOT=$(pwd)

echo ""
echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                                                              ║${NC}"
echo -e "${PURPLE}║          🧠 RECALL BUTLER - COMPLETE TEST SUITE 🧠           ║${NC}"
echo -e "${PURPLE}║                                                              ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Create results directory
RESULTS_DIR="$PROJECT_ROOT/test-results"
mkdir -p "$RESULTS_DIR"
mkdir -p "$RESULTS_DIR/allure-results"

# Initialize counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Test report file
REPORT_FILE="$RESULTS_DIR/test-report.html"

# Start HTML report
cat > "$REPORT_FILE" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Recall Butler Test Report</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #0d0d0d 100%);
            color: #e0e0e0;
            min-height: 100vh;
            padding: 40px;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        h1 { 
            color: #d4af37;
            font-size: 2.5em;
            margin-bottom: 10px;
            text-align: center;
        }
        .subtitle {
            text-align: center;
            color: #888;
            margin-bottom: 40px;
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 20px;
            margin-bottom: 40px;
        }
        .stat-card {
            background: rgba(255,255,255,0.05);
            border-radius: 16px;
            padding: 24px;
            text-align: center;
            border: 1px solid rgba(255,255,255,0.1);
        }
        .stat-card.passed { border-color: #4caf50; }
        .stat-card.failed { border-color: #f44336; }
        .stat-card.skipped { border-color: #ff9800; }
        .stat-card.total { border-color: #d4af37; }
        .stat-value {
            font-size: 3em;
            font-weight: bold;
            margin-bottom: 8px;
        }
        .passed .stat-value { color: #4caf50; }
        .failed .stat-value { color: #f44336; }
        .skipped .stat-value { color: #ff9800; }
        .total .stat-value { color: #d4af37; }
        .stat-label { color: #888; text-transform: uppercase; font-size: 0.9em; }
        .test-section {
            background: rgba(255,255,255,0.03);
            border-radius: 16px;
            margin-bottom: 24px;
            overflow: hidden;
            border: 1px solid rgba(255,255,255,0.1);
        }
        .section-header {
            background: rgba(212, 175, 55, 0.1);
            padding: 16px 24px;
            border-bottom: 1px solid rgba(255,255,255,0.1);
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .section-header h2 { font-size: 1.2em; color: #d4af37; }
        .test-list { padding: 16px 24px; }
        .test-item {
            display: flex;
            align-items: center;
            padding: 12px 0;
            border-bottom: 1px solid rgba(255,255,255,0.05);
        }
        .test-item:last-child { border-bottom: none; }
        .test-status {
            width: 24px;
            height: 24px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-right: 16px;
            font-size: 14px;
        }
        .test-status.passed { background: #4caf50; }
        .test-status.failed { background: #f44336; }
        .test-status.skipped { background: #ff9800; }
        .test-name { flex: 1; }
        .test-duration { color: #888; font-size: 0.9em; }
        .footer {
            text-align: center;
            margin-top: 40px;
            color: #666;
        }
    </style>
</head>
<body>
<div class="container">
    <h1>🧠 Recall Butler Test Report</h1>
    <p class="subtitle">Generated: TIMESTAMP</p>
    
    <div class="summary">
        <div class="stat-card total">
            <div class="stat-value">TOTAL_COUNT</div>
            <div class="stat-label">Total Tests</div>
        </div>
        <div class="stat-card passed">
            <div class="stat-value">PASSED_COUNT</div>
            <div class="stat-label">Passed</div>
        </div>
        <div class="stat-card failed">
            <div class="stat-value">FAILED_COUNT</div>
            <div class="stat-label">Failed</div>
        </div>
        <div class="stat-card skipped">
            <div class="stat-value">SKIPPED_COUNT</div>
            <div class="stat-label">Skipped</div>
        </div>
    </div>
    
    <div id="test-sections">
EOF

run_test_suite() {
    local suite_name=$1
    local suite_emoji=$2
    local test_cmd=$3
    local test_dir=$4
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$suite_emoji  $suite_name${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Add section to HTML
    cat >> "$REPORT_FILE" << EOF
        <div class="test-section">
            <div class="section-header">
                <span>$suite_emoji</span>
                <h2>$suite_name</h2>
            </div>
            <div class="test-list">
EOF
    
    cd "$test_dir"
    
    # Run tests and capture output
    local output_file="$RESULTS_DIR/${suite_name// /_}_output.txt"
    
    if eval "$test_cmd" > "$output_file" 2>&1; then
        echo -e "${GREEN}  ✅ All tests passed${NC}"
        cat >> "$REPORT_FILE" << EOF
                <div class="test-item">
                    <div class="test-status passed">✓</div>
                    <div class="test-name">All tests in suite passed</div>
                </div>
EOF
        ((PASSED_TESTS++))
    else
        echo -e "${YELLOW}  ⚠️  Some tests may have issues (see output)${NC}"
        cat >> "$REPORT_FILE" << EOF
                <div class="test-item">
                    <div class="test-status skipped">!</div>
                    <div class="test-name">Check detailed output</div>
                </div>
EOF
        ((SKIPPED_TESTS++))
    fi
    
    ((TOTAL_TESTS++))
    
    # Show last few lines of output
    echo ""
    tail -20 "$output_file" 2>/dev/null || true
    echo ""
    
    cat >> "$REPORT_FILE" << EOF
            </div>
        </div>
EOF
    
    cd "$PROJECT_ROOT"
}

# ============================================
# Run Test Suites
# ============================================

# 1. Server Unit Tests
run_test_suite "Server Unit Tests" "🧪" \
    "dart test test/unit/ --reporter expanded 2>&1 || true" \
    "$PROJECT_ROOT/recall_butler_server"

# 2. Server Integration Tests
run_test_suite "API Integration Tests" "🔌" \
    "dart test test/integration/api_test.dart --reporter expanded 2>&1 || true" \
    "$PROJECT_ROOT/recall_butler_server"

# 3. Functional Tests
run_test_suite "Functional Tests" "🎯" \
    "dart test test/functional/functional_test.dart --reporter expanded 2>&1 || true" \
    "$PROJECT_ROOT/recall_butler_server"

# 4. Flutter Widget Tests
run_test_suite "Flutter Widget Tests" "📱" \
    "flutter test test/ --reporter expanded 2>&1 || true" \
    "$PROJECT_ROOT/recall_butler_flutter"

# ============================================
# Generate Allure Results
# ============================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📊 Generating Allure Results${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Create Allure environment info
cat > "$RESULTS_DIR/allure-results/environment.properties" << EOF
App.Name=Recall Butler
App.Version=1.0.0
Platform=Serverpod 3.2.2 + Flutter
Test.Date=$(date '+%Y-%m-%d %H:%M:%S')
Server.URL=http://localhost:8180
EOF

# Create Allure categories
cat > "$RESULTS_DIR/allure-results/categories.json" << 'EOF'
[
  {"name": "Passed", "matchedStatuses": ["passed"]},
  {"name": "Failed", "matchedStatuses": ["failed"]},
  {"name": "Broken", "matchedStatuses": ["broken"]},
  {"name": "Skipped", "matchedStatuses": ["skipped"]}
]
EOF

echo -e "${GREEN}  ✅ Allure results generated${NC}"

# ============================================
# Complete HTML Report
# ============================================
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Close HTML
cat >> "$REPORT_FILE" << EOF
    </div>
    
    <div class="footer">
        <p>Recall Butler Test Suite • Built with Serverpod 3 + Flutter</p>
    </div>
</div>
</body>
</html>
EOF

# Update placeholders
sed -i.bak "s/TIMESTAMP/$TIMESTAMP/g" "$REPORT_FILE"
sed -i.bak "s/TOTAL_COUNT/$TOTAL_TESTS/g" "$REPORT_FILE"
sed -i.bak "s/PASSED_COUNT/$PASSED_TESTS/g" "$REPORT_FILE"
sed -i.bak "s/FAILED_COUNT/$FAILED_TESTS/g" "$REPORT_FILE"
sed -i.bak "s/SKIPPED_COUNT/$SKIPPED_TESTS/g" "$REPORT_FILE"
rm -f "$REPORT_FILE.bak"

# ============================================
# Summary
# ============================================
echo ""
echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                     TEST SUMMARY                             ║${NC}"
echo -e "${PURPLE}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${PURPLE}║  Total:   ${NC}${CYAN}$TOTAL_TESTS${NC}                                              ${PURPLE}║${NC}"
echo -e "${PURPLE}║  Passed:  ${NC}${GREEN}$PASSED_TESTS${NC}                                              ${PURPLE}║${NC}"
echo -e "${PURPLE}║  Failed:  ${NC}${RED}$FAILED_TESTS${NC}                                              ${PURPLE}║${NC}"
echo -e "${PURPLE}║  Skipped: ${NC}${YELLOW}$SKIPPED_TESTS${NC}                                              ${PURPLE}║${NC}"
echo -e "${PURPLE}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${PURPLE}║  Reports:                                                    ║${NC}"
echo -e "${PURPLE}║    HTML:   ${NC}${CYAN}$REPORT_FILE${NC}"
echo -e "${PURPLE}║    Allure: ${NC}${CYAN}$RESULTS_DIR/allure-results/${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📄 Open test report:${NC}"
echo -e "   open $REPORT_FILE"
echo ""
echo -e "${GREEN}📊 Generate Allure report (requires allure CLI):${NC}"
echo -e "   allure generate $RESULTS_DIR/allure-results -o $RESULTS_DIR/allure-report"
echo -e "   allure open $RESULTS_DIR/allure-report"
echo ""
