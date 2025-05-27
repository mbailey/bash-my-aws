#!/usr/bin/env bash

# Test script for stack functions with header support

source $(dirname $0)/../lib/shared-functions
source $(dirname $0)/../lib/stack-functions

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
    list-stacks)
      echo -e "test-stack1\tCREATE_COMPLETE\t2023-01-01T10:00:00Z\tNEVER_UPDATED\tNOT_NESTED"
      echo -e "test-stack2\tUPDATE_COMPLETE\t2023-01-02T11:00:00Z\t2023-01-03T12:00:00Z\tNESTED"
      ;;
    describe-stacks)
      echo -e "test-stack1\tCREATE_COMPLETE"
      ;;
    list-exports)
      echo -e "export-key1\texport-value1"
      echo -e "export-key2\texport-value2"
      ;;
    describe-stack-resources)
      echo -e "i-12345\tAWS::EC2::Instance\tCREATE_COMPLETE\ttest-stack1"
      echo -e "vpc-67890\tAWS::EC2::VPC\tCREATE_COMPLETE\ttest-stack1"
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

echo "Testing stack functions with headers..."

# Test 1: stacks shows header in always mode
BMA_HEADERS=always
result=$(stacks | head -1)
test_case "stacks shows header in always mode" "STACK_NAME" "$result"

# Test 2: stacks shows no header in never mode
BMA_HEADERS=never
result=$(stacks)
if [[ ! "$result" =~ ^# ]]; then
  echo -e "${GREEN}✓${NC} stacks shows no header in never mode"
  PASSED=$((PASSED + 1))
else
  echo -e "${RED}✗${NC} stacks shows no header in never mode"
  echo "  Output should not start with #"
  FAILED=$((FAILED + 1))
fi
TESTS=$((TESTS + 1))

# Test 3: stacks output can be piped through skim-stdin
BMA_HEADERS=always
result=$(stacks | skim-stdin)
test_case "stacks output works with skim-stdin" "test-stack1 test-stack2" "$result"

# Test 4: stack-exports shows header
BMA_HEADERS=always
result=$(stack-exports | head -1)
test_case "stack-exports shows header" "EXPORT_NAME" "$result"

# Test 5: stack-resources shows header
BMA_HEADERS=always
result=$(stack-resources test-stack1 | head -1)
test_case "stack-resources shows header" "PHYSICAL_RESOURCE_ID" "$result"

# Test 6: stack-status shows header
BMA_HEADERS=always
result=$(stack-status test-stack1 | head -1)
test_case "stack-status shows header" "STACK_NAME" "$result"

# Test 7: Integration test - chaining stacks functions
BMA_HEADERS=always
result=$(echo "test-stack1" | stacks | skim-stdin)
test_case "Integration: stacks can be chained" "test-stack1" "$result"

# Test 8: Backwards compatibility
BMA_HEADERS=never
result=$(stacks | head -1)
test_case "stacks backwards compatibility" "test-stack1" "$result"

echo ""
echo "Summary: $PASSED/$TESTS tests passed"

if [ $FAILED -gt 0 ]; then
  echo -e "${RED}$FAILED tests failed${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi