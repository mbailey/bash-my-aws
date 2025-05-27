#!/usr/bin/env bash

# Simple test script for header functionality

source $(dirname $0)/../lib/shared-functions

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test counter
TESTS=0
PASSED=0
FAILED=0

# Test function
test_case() {
  local description="$1"
  local expected="$2"
  local actual="$3"
  
  TESTS=$((TESTS + 1))
  
  if [ "$expected" = "$actual" ]; then
    echo -e "${GREEN}✓${NC} $description"
    PASSED=$((PASSED + 1))
  else
    echo -e "${RED}✗${NC} $description"
    echo "  Expected: '$expected'"
    echo "  Actual:   '$actual'"
    FAILED=$((FAILED + 1))
  fi
}

echo "Testing skim-stdin functionality..."

# Test 1: skim-stdin skips comment lines
result=$(echo -e "# HEADER\nvalue1 data1\nvalue2 data2" | skim-stdin)
test_case "skim-stdin skips comment lines" "value1 value2" "$result"

# Test 2: skim-stdin handles multiple comment lines
result=$(echo -e "# HEADER1\n# HEADER2\nvalue1 data1\nvalue2 data2" | skim-stdin)
test_case "skim-stdin handles multiple comment lines" "value1 value2" "$result"

# Test 3: skim-stdin handles empty input
result=$(echo -n "" | skim-stdin)
test_case "skim-stdin handles empty input" "" "$result"

# Test 4: skim-stdin handles only comment lines
result=$(echo -e "# HEADER1\n# HEADER2" | skim-stdin)
test_case "skim-stdin handles only comment lines" "" "$result"

# Test 5: skim-stdin preserves arguments
result=$(skim-stdin arg1 arg2)
test_case "skim-stdin preserves arguments" "arg1 arg2" "$result"

# Test 6: skim-stdin appends stdin to arguments
result=$(echo -e "value1 data1\nvalue2 data2" | skim-stdin arg1 arg2)
test_case "skim-stdin appends stdin to arguments" "arg1 arg2 value1 value2" "$result"

echo ""
echo "Testing __bma_output_header functionality..."

# Test 7: __bma_output_header in always mode
BMA_HEADERS=always
result=$(__bma_output_header "HEADER1	HEADER2" | cat)
test_case "__bma_output_header always mode" "# HEADER1	HEADER2" "$result"

# Test 8: __bma_output_header in never mode
BMA_HEADERS=never
result=$(__bma_output_header "HEADER1	HEADER2" | cat)
test_case "__bma_output_header never mode" "" "$result"

# Test 9: __bma_output_header defaults to always
unset BMA_HEADERS
result=$(__bma_output_header "HEADER1	HEADER2" | cat)
test_case "__bma_output_header always mode (default)" "# HEADER1	HEADER2" "$result"

# Test 10: Integration test - headers don't interfere with skim-stdin
BMA_HEADERS=always
result=$(echo -e "# INSTANCE_ID	AMI_ID\ni-12345	ami-67890\ni-23456	ami-78901" | skim-stdin)
test_case "Integration: headers work with skim-stdin" "i-12345 i-23456" "$result"

echo ""
echo "Summary: $PASSED/$TESTS tests passed"

if [ $FAILED -gt 0 ]; then
  echo -e "${RED}$FAILED tests failed${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi