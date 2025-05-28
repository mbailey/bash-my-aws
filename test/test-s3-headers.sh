#!/usr/bin/env bash

# Test script for s3 functions with header support

source $(dirname $0)/../lib/shared-functions
source $(dirname $0)/../lib/s3-functions

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
    list-buckets)
      echo -e "bucket1\t2023-01-01T10:00:00.000Z"
      echo -e "bucket2\t2023-01-02T11:00:00.000Z"
      echo -e "bucket3\t2023-01-03T12:00:00.000Z"
      ;;
    get-bucket-acl)
      echo -e "$3\tREAD=AllUsers"
      ;;
    get-metric-statistics)
      # Mock CloudWatch response for bucket-size
      echo '{"Datapoints": [{"Average": 1073741824}]}'
      ;;
  esac
}

# Mock date command for bucket-size
date() {
  case "$2" in
    "2 days ago") echo "2023-01-01T00:00:00Z" ;;
    *) echo "2023-01-03T00:00:00Z" ;;
  esac
}

# Mock jq command for bucket-size
jq() {
  case "$1" in
    ".Datapoints | length") echo "1" ;;
    "-r .Datapoints[0].Average") echo "1073741824" ;;
  esac
}

# Mock mktemp
mktemp() {
  echo "/tmp/test-$$"
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

echo "Testing s3 functions with headers..."

# Test 1: buckets shows header in always mode
BMA_HEADERS=always
result=$(buckets | head -1)
test_case "buckets shows header in always mode" "BUCKET_NAME" "$result"

# Test 2: buckets shows no header in never mode
BMA_HEADERS=never
result=$(buckets)
if [[ ! "$result" =~ ^# ]]; then
  echo -e "${GREEN}✓${NC} buckets shows no header in never mode"
  PASSED=$((PASSED + 1))
else
  echo -e "${RED}✗${NC} buckets shows no header in never mode"
  echo "  Output should not start with #"
  FAILED=$((FAILED + 1))
fi
TESTS=$((TESTS + 1))

# Test 3: buckets output can be piped through skim-stdin
BMA_HEADERS=always
result=$(buckets | skim-stdin)
test_case "buckets output works with skim-stdin" "bucket1 bucket2 bucket3" "$result"

# Test 4: buckets backwards compatibility
BMA_HEADERS=never
result=$(buckets | head -1)
test_case "buckets backwards compatibility" "bucket1" "$result"

# Test 5: bucket-acls function works
BMA_HEADERS=always
result=$(bucket-acls bucket1 2>/dev/null | head -1)
# bucket-acls doesn't use columnise, so no headers expected
test_case "bucket-acls runs without error" "READ=AllUsers" "$result"

# Test 6: Integration test - buckets piping
BMA_HEADERS=always
result=$(echo "bucket1" | buckets | skim-stdin)
test_case "Integration: buckets can be filtered" "bucket1" "$result"

echo ""
echo "Summary: $PASSED/$TESTS tests passed"

if [ $FAILED -gt 0 ]; then
  echo -e "${RED}$FAILED tests failed${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi