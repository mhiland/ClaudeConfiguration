#!/bin/bash
# Test script for hook failure response system
# This script creates scenarios to test automatic responses to hook failures

# Configuration
TEST_DIR="/tmp/claude_hook_tests"
TEST_LOG="$TEST_DIR/test_results.log"
HOOK_LOGS_DIR="$HOME/.claude/logs/hooks"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Setup test environment
setup_test_env() {
    echo "Setting up test environment..."
    
    # Create test directory
    mkdir -p "$TEST_DIR"
    mkdir -p "$HOOK_LOGS_DIR"
    
    # Initialize test log
    echo "=== Hook Response System Test Results ===" > "$TEST_LOG"
    echo "Test started at: $(date)" >> "$TEST_LOG"
    echo "" >> "$TEST_LOG"
    
    # Backup current settings
    if [[ -f "$HOME/.claude/settings.json" ]]; then
        cp "$HOME/.claude/settings.json" "$TEST_DIR/settings.json.backup"
    fi
    
    # Set test environment variables
    export CLAUDE_HOOK_OUTPUT_FORMAT="mixed"
    export CLAUDE_AUTO_FIX="true"
    export CLAUDE_LOG_LEVEL="info"
    export CLAUDE_HOOK_MONITOR="true"
}

# Cleanup test environment
cleanup_test_env() {
    echo "Cleaning up test environment..."
    
    # Restore settings if backup exists
    if [[ -f "$TEST_DIR/settings.json.backup" ]]; then
        cp "$TEST_DIR/settings.json.backup" "$HOME/.claude/settings.json"
    fi
    
    # Remove test files
    rm -rf "$TEST_DIR"
    
    echo "Test results summary:" >> "$TEST_LOG"
    echo "Tests passed: $TESTS_PASSED" >> "$TEST_LOG"
    echo "Tests failed: $TESTS_FAILED" >> "$TEST_LOG"
    echo "Test completed at: $(date)" >> "$TEST_LOG"
}

# Test helper functions
log_test() {
    echo "$1" | tee -a "$TEST_LOG"
}

pass_test() {
    local test_name="$1"
    echo -e "${GREEN}✓ PASS: $test_name${NC}"
    log_test "PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail_test() {
    local test_name="$1"
    local reason="$2"
    echo -e "${RED}✗ FAIL: $test_name${NC}"
    echo -e "${RED}  Reason: $reason${NC}"
    log_test "FAIL: $test_name - $reason"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Test 1: Create file with Python syntax errors
test_python_syntax_errors() {
    local test_name="Python syntax errors trigger hook failure"
    log_test "Running test: $test_name"
    
    # Create test file with syntax errors
    local test_file="$TEST_DIR/test_syntax_errors.py"
    cat > "$test_file" << 'EOF'
# Test file with intentional syntax errors
def broken_function()
    print("Missing colon")
    if True
        print("Missing colon again")
    
    # Long line that violates formatting
    very_long_variable_name_that_exceeds_line_length_limits = "This is a very long string that should trigger formatting issues and exceed the maximum line length limits"
    
# Missing docstring, low pylint score
def another_function():
    x=1+2+3+4+5+6+7+8+9+10
    return x
EOF
    
    # Test the hook directly
    local hook_output
    hook_output=$(bash ~/.claude/hooks/quality-check.sh 2>&1 <<< "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$test_file\"}}")
    local hook_exit_code=$?
    
    # Check if hook detected issues
    if [[ $hook_exit_code -eq 1 ]]; then
        if [[ "$hook_output" =~ "CLAUDE CODE: Fix the following issues immediately" ]]; then
            pass_test "$test_name"
        else
            fail_test "$test_name" "Hook failed but didn't provide clear instructions"
        fi
    else
        fail_test "$test_name" "Hook should have failed but returned exit code $hook_exit_code"
    fi
}

# Test 2: Test JSON output format
test_json_output_format() {
    local test_name="JSON output format for machine parsing"
    log_test "Running test: $test_name"
    
    # Set JSON output format
    export CLAUDE_HOOK_OUTPUT_FORMAT="json"
    
    # Create test file with issues
    local test_file="$TEST_DIR/test_json_output.py"
    cat > "$test_file" << 'EOF'
# Test file for JSON output
def bad_function():
    x=1+2+3+4+5+6+7+8+9+10+11+12+13+14+15+16+17+18+19+20+21+22+23+24+25+26+27+28+29+30
    return x
EOF
    
    # Test the hook
    local hook_output
    hook_output=$(bash ~/.claude/hooks/quality-check.sh 2>&1 <<< "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$test_file\"}}")
    local hook_exit_code=$?
    
    # Check if output is valid JSON
    if echo "$hook_output" | jq . >/dev/null 2>&1; then
        if [[ "$hook_output" =~ "\"hook\": \"quality-check\"" ]]; then
            pass_test "$test_name"
        else
            fail_test "$test_name" "JSON output missing expected fields"
        fi
    else
        fail_test "$test_name" "Hook output is not valid JSON"
    fi
    
    # Reset output format
    export CLAUDE_HOOK_OUTPUT_FORMAT="mixed"
}

# Test 3: Test emergency brake functionality
test_emergency_brake() {
    local test_name="Emergency brake prevents excessive failures"
    log_test "Running test: $test_name"
    
    # Source the debounce functions
    source ~/.claude/hooks/debounce.sh
    
    # Manually trigger emergency brake
    trigger_emergency_brake "quality-check" 1
    
    # Try to run hook - should be blocked
    local hook_output
    hook_output=$(bash ~/.claude/hooks/quality-check.sh 2>&1 <<< "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$TEST_DIR/test.py\"}}")
    local hook_exit_code=$?
    
    if [[ $hook_exit_code -eq 0 && "$hook_output" =~ "Emergency brake active" ]]; then
        pass_test "$test_name"
    else
        fail_test "$test_name" "Emergency brake did not prevent hook execution"
    fi
    
    # Reset the brake
    reset_debounce "quality-check"
}

# Test 4: Test bypass mechanism
test_bypass_mechanism() {
    local test_name="Bypass mechanism prevents infinite loops"
    log_test "Running test: $test_name"
    
    # Set bypass environment
    export CLAUDE_HOOK_BYPASS="true"
    
    # Create test file with issues
    local test_file="$TEST_DIR/test_bypass.py"
    cat > "$test_file" << 'EOF'
def bad_function():
    x=1+2+3+4+5+6+7+8+9+10
    return x
EOF
    
    # Test the hook
    local hook_output
    hook_output=$(bash ~/.claude/hooks/quality-check.sh 2>&1 <<< "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$test_file\"}}")
    local hook_exit_code=$?
    
    if [[ $hook_exit_code -eq 0 && "$hook_output" =~ "Hook bypassed" ]]; then
        pass_test "$test_name"
    else
        fail_test "$test_name" "Bypass mechanism did not work as expected"
    fi
    
    # Reset bypass
    unset CLAUDE_HOOK_BYPASS
}

# Test 5: Test monitoring and logging
test_monitoring_logging() {
    local test_name="Monitoring and logging functionality"
    log_test "Running test: $test_name"
    
    # Source monitoring functions
    source ~/.claude/hooks/monitor.sh
    
    # Create test file
    local test_file="$TEST_DIR/test_monitoring.py"
    echo "print('Hello, World!')" > "$test_file"
    
    # Test the hook (should pass)
    local hook_output
    hook_output=$(bash ~/.claude/hooks/quality-check.sh 2>&1 <<< "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$test_file\"}}")
    local hook_exit_code=$?
    
    # Check if log file was created
    local log_file="$HOOK_LOGS_DIR/quality-check.jsonl"
    if [[ -f "$log_file" ]]; then
        # Check if log contains expected entries
        if grep -q "\"event\": \"success\"" "$log_file"; then
            pass_test "$test_name"
        else
            fail_test "$test_name" "Log file doesn't contain expected success event"
        fi
    else
        fail_test "$test_name" "No log file created"
    fi
}

# Test 6: Test non-code file bypass
test_non_code_bypass() {
    local test_name="Non-code files are bypassed"
    log_test "Running test: $test_name"
    
    # Create test markdown file
    local test_file="$TEST_DIR/test.md"
    cat > "$test_file" << 'EOF'
# Test Markdown File
This is a test markdown file that should be bypassed by quality checks.
EOF
    
    # Test the hook
    local hook_output
    hook_output=$(bash ~/.claude/hooks/quality-check.sh 2>&1 <<< "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$test_file\"}}")
    local hook_exit_code=$?
    
    if [[ $hook_exit_code -eq 0 && "$hook_output" =~ "Non-code file type" ]]; then
        pass_test "$test_name"
    else
        fail_test "$test_name" "Non-code file was not bypassed as expected"
    fi
}

# Test 7: Test hook status utility
test_hook_status_utility() {
    local test_name="Hook status utility functions"
    log_test "Running test: $test_name"
    
    # Make sure the hook-status script is executable
    chmod +x ~/.claude/hooks/hook-status.sh
    
    # Test status command
    local status_output
    status_output=$(~/.claude/hooks/hook-status.sh status quality-check 2>&1)
    local status_exit_code=$?
    
    if [[ $status_exit_code -eq 0 && "$status_output" =~ "Status for quality-check" ]]; then
        pass_test "$test_name"
    else
        fail_test "$test_name" "Hook status utility did not work as expected"
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}Starting Hook Response System Tests${NC}"
    echo "======================================"
    
    # Setup
    setup_test_env
    
    # Run tests
    test_python_syntax_errors
    test_json_output_format
    test_emergency_brake
    test_bypass_mechanism
    test_monitoring_logging
    test_non_code_bypass
    test_hook_status_utility
    
    # Summary
    echo ""
    echo "======================================"
    echo -e "${BLUE}Test Results Summary${NC}"
    echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
    else
        echo -e "${YELLOW}Some tests failed. Check the log for details.${NC}"
    fi
    
    echo ""
    echo "Detailed test log: $TEST_LOG"
    
    # Cleanup
    cleanup_test_env
    
    # Return appropriate exit code
    [[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi