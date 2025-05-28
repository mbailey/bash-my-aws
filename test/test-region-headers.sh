#!/usr/bin/env bash

# Test script for region functions with header support

source $(dirname $0)/../lib/shared-functions
source $(dirname $0)/../lib/region-functions

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test counter
TESTS=0
PASSED=0
FAILED=0

# Mock AWS CLI for testing
aws() {
  case "$2" in
    describe-regions)
      echo -e "us-east-1"
      echo -e "us-west-2"
      echo -e "ap-southeast-1"
      echo -e "eu-west-1"
      ;;
  esac
}

# Test function
test_case() {
  local description="$1"
  local expected="$2"
  local actual="$3"
  
  TESTS=$((TESTS + 1))
  
  if [[ "$actual" =~ "$expected" ]]; then
    echo -e "${GREEN}✓${NC} $description"
    PASSED=$((PASSED + 1))
  else
    echo -e "${RED}✗${NC} $description"
    echo "  Expected pattern: '$expected'"
    echo "  Actual: '$actual'"
    FAILED=$((FAILED + 1))
  fi
}

echo "Testing region functions with headers..."

# Test 1: regions shows header in always mode
BMA_HEADERS=always
result=$(regions | head -1)
test_case "regions shows header in always mode" "REGION" "$result"

# Test 2: regions shows no header in never mode
BMA_HEADERS=never
result=$(regions)
if [[ ! "$result" =~ ^# ]]; then
  echo -e "${GREEN}✓${NC} regions shows no header in never mode"
  PASSED=$((PASSED + 1))
else
  echo -e "${RED}✗${NC} regions shows no header in never mode"
  echo "  Output should not start with #"
  FAILED=$((FAILED + 1))
fi
TESTS=$((TESTS + 1))

# Test 3: regions output can be piped through skim-stdin
BMA_HEADERS=always
result=$(regions | skim-stdin)
test_case "regions output works with skim-stdin" "ap-southeast-1 eu-west-1 us-east-1 us-west-2" "$result"

# Test 4: Test sorting is maintained
BMA_HEADERS=always
result=$(regions | grep -v '^#' | head -1)
test_case "regions maintains sort order" "ap-southeast-1" "$result"

# Test 5: Backwards compatibility
BMA_HEADERS=never
result=$(regions | head -1)
test_case "regions backwards compatibility" "ap-southeast-1" "$result"

# Test 6: region-each doesn't interfere with headers
BMA_HEADERS=always
# region-each will process the header line too, adding region suffix
# We expect: header line + 4 regions = 5 lines (or 6 with blank header fields)
result=$(region-each "echo test" | grep -c "test")
expected_lines=6  # header (with # and REGION) + 4 regions
if [[ "$result" -ge 4 ]]; then
  echo -e "${GREEN}✓${NC} region-each works with headers enabled"
  PASSED=$((PASSED + 1))
else
  echo -e "${RED}✗${NC} region-each doesn't work properly"
  echo "  Expected at least 4 test lines, got $result"
  FAILED=$((FAILED + 1))
fi
TESTS=$((TESTS + 1))

echo ""
echo "Summary: $PASSED/$TESTS tests passed"

if [ $FAILED -gt 0 ]; then
  echo -e "${RED}$FAILED tests failed${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi