#!/usr/bin/env bash
# myconmon test suite
# Run: ./test_myconmon.sh

set -euo pipefail

PASSED=0
FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

assert_eq() {
    local name="$1"
    local expected="$2"
    local actual="$3"
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $name"
        ((PASSED++)) || true
    else
        echo -e "${RED}✗${NC} $name"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        ((FAILED++)) || true
    fi
}

# Source the functions we need to test
# We'll extract them for testability
calculate_rpn() {
    local severity="$1"
    local occurrence="$2"
    local detectability="$3"
    echo $(( (severity * severity * occurrence * detectability) / 13 ))
}

phase_from_rpn() {
    local rpn="$1"
    if (( rpn > 300 )); then
        echo "CRITICAL"
    elif (( rpn > 100 )); then
        echo "HIGH"
    elif (( rpn > 30 )); then
        echo "MEDIUM"
    else
        echo "LOW"
    fi
}

echo "=== myconmon test suite ==="
echo ""

# RPN Calculation Tests
echo "--- RPN Calculation ---"

# Test 1: Minimum values (S=1, O=1, D=1)
# RPN = (1² × 1 × 1) / 13 = 0.07 → 0 (integer)
assert_eq "RPN min (1,1,1)" "0" "$(calculate_rpn 1 1 1)"

# Test 2: Low severity config drift (S=3, O=3, D=3)
# RPN = (9 × 3 × 3) / 13 = 81/13 = 6
assert_eq "RPN low drift (3,3,3)" "6" "$(calculate_rpn 3 3 3)"

# Test 3: Medium severity (S=5, O=5, D=5)
# RPN = (25 × 5 × 5) / 13 = 625/13 = 48
assert_eq "RPN medium (5,5,5)" "48" "$(calculate_rpn 5 5 5)"

# Test 4: High severity drift (S=8, O=5, D=5) - default for goss failures
# RPN = (64 × 5 × 5) / 13 = 1600/13 = 123
assert_eq "RPN high drift (8,5,5)" "123" "$(calculate_rpn 8 5 5)"

# Test 5: Critical - active exploit (S=13, O=13, D=8)
# RPN = (169 × 13 × 8) / 13 = 17576/13 = 1352
assert_eq "RPN critical (13,13,8)" "1352" "$(calculate_rpn 13 13 8)"

# Test 6: Timing belt paradox (S=13, O=8, D=13)
# RPN = (169 × 8 × 13) / 13 = 17576/13 = 1352
assert_eq "RPN timing belt (13,8,13)" "1352" "$(calculate_rpn 13 8 13)"

# Test 7: Maximum values (S=13, O=13, D=13)
# RPN = (169 × 13 × 13) / 13 = 28561/13 = 2197
assert_eq "RPN max (13,13,13)" "2197" "$(calculate_rpn 13 13 13)"

echo ""
echo "--- Phase Assignment ---"

# Phase thresholds: >300 CRITICAL, >100 HIGH, >30 MEDIUM, else LOW
assert_eq "Phase LOW (rpn=6)" "LOW" "$(phase_from_rpn 6)"
assert_eq "Phase LOW (rpn=30)" "LOW" "$(phase_from_rpn 30)"
assert_eq "Phase MEDIUM (rpn=31)" "MEDIUM" "$(phase_from_rpn 31)"
assert_eq "Phase MEDIUM (rpn=100)" "MEDIUM" "$(phase_from_rpn 100)"
assert_eq "Phase HIGH (rpn=101)" "HIGH" "$(phase_from_rpn 101)"
assert_eq "Phase HIGH (rpn=123)" "HIGH" "$(phase_from_rpn 123)"
assert_eq "Phase HIGH (rpn=300)" "HIGH" "$(phase_from_rpn 300)"
assert_eq "Phase CRITICAL (rpn=301)" "CRITICAL" "$(phase_from_rpn 301)"
assert_eq "Phase CRITICAL (rpn=1352)" "CRITICAL" "$(phase_from_rpn 1352)"

echo ""
echo "--- CLI ---"

# Test help
assert_eq "help exits 0" "0" "$( ./myconmon --help >/dev/null 2>&1; echo $? )"

# Test unknown command
assert_eq "unknown cmd exits 1" "1" "$( ./myconmon notacommand >/dev/null 2>&1; echo $? || true )"

echo ""
echo "=== Results ==="
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"

if (( FAILED > 0 )); then
    exit 1
fi
