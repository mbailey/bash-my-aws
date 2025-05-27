#!/usr/bin/env bash

# Test script for keypair functions with header support

source $(dirname $0)/../lib/shared-functions
source $(dirname $0)/../lib/keypair-functions

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
    describe-key-pairs)
      echo -e "test-key1\t12:34:56:78:90:ab:cd:ef:12:34:56:78:90:ab:cd:ef"
      echo -e "test-key2\t98:76:54:32:10:fe:dc:ba:98:76:54:32:10:fe:dc:ba"
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

echo "Testing keypairs function with headers..."

# Test 1: keypairs shows header in always mode
BMA_HEADERS=always
result=$(keypairs | head -1)
test_case "keypairs shows header in always mode" "KEYPAIR_NAME" "$result"

# Test 2: keypairs shows no header in never mode
BMA_HEADERS=never
result=$(keypairs)
if [[ ! "$result" =~ ^# ]]; then
  echo -e "${GREEN}✓${NC} keypairs shows no header in never mode"
  PASSED=$((PASSED + 1))
else
  echo -e "${RED}✗${NC} keypairs shows no header in never mode"
  echo "  Output should not start with #"
  echo "  Actual: '$result'"
  FAILED=$((FAILED + 1))
fi
TESTS=$((TESTS + 1))

# Test 3: keypairs output can be piped through skim-stdin
BMA_HEADERS=always
result=$(keypairs | skim-stdin)
test_case "keypairs output works with skim-stdin" "test-key1 test-key2" "$result"

# Test 4: Test backwards compatibility
BMA_HEADERS=never
result=$(keypairs | head -1)
test_case "keypairs backwards compatibility" "test-key1" "$result"

echo ""
echo "Summary: $PASSED/$TESTS tests passed"

if [ $FAILED -gt 0 ]; then
  echo -e "${RED}$FAILED tests failed${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi