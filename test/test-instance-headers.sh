#!/usr/bin/env bash

# Test script for instance functions with header support

source $(dirname $0)/../lib/shared-functions
source $(dirname $0)/../lib/instance-functions

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
    describe-instances)
      case "$4" in
        *instance-ids*)
          # Return specific instances when IDs provided
          echo -e "i-12345\tami-12345\tt3.nano\trunning\ttest-instance\t2023-01-01T10:00:00Z\tus-east-1a\tvpc-12345"
          ;;
        *)
          # Return multiple instances
          echo -e "i-12345\tami-12345\tt3.nano\trunning\ttest-instance\t2023-01-01T10:00:00Z\tus-east-1a\tvpc-12345"
          echo -e "i-67890\tami-67890\tt3.small\tstopped\tprod-instance\t2023-01-02T11:00:00Z\tus-east-1b\tvpc-67890"
          ;;
      esac
      ;;
    describe-tags)
      echo -e "i-12345\tName\ttest-instance"
      echo -e "i-12345\tEnvironment\ttest"
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

echo "Testing instance functions with headers..."

# Test 1: instances shows header
BMA_HEADERS=always
result=$(instances | head -1)
test_case "instances shows header" "InstanceId" "$result"

# Test 2: instances no header in never mode
BMA_HEADERS=never
result=$(instances)
if [[ ! "$result" =~ ^# ]]; then
  echo -e "${GREEN}✓${NC} instances shows no header in never mode"
  PASSED=$((PASSED + 1))
else
  echo -e "${RED}✗${NC} instances shows no header in never mode"
  FAILED=$((FAILED + 1))
fi
TESTS=$((TESTS + 1))

# Test 3: instances piping works
BMA_HEADERS=always
result=$(instances | skim-stdin)
test_case "instances output works with skim-stdin" "i-12345 i-67890" "$result"

# Test 4: instance-asg shows header
BMA_HEADERS=always
# Mock specific response for instance-asg
aws() {
  echo -e "asg-name\ti-12345"
}
result=$(echo "i-12345" | instance-asg | head -1)
test_case "instance-asg shows header" "AutoscalingGroupName" "$result"

# Test 5: instance-ip shows header  
BMA_HEADERS=always
# Mock for instance-ip
aws() {
  case "$2" in
    describe-instances)
      echo -e "i-12345\t10.0.0.1\t52.1.2.3"
      ;;
  esac
}
result=$(echo "i-12345" | instance-ip | head -1)
test_case "instance-ip shows header" "InstanceId" "$result"

# Test 6: instance-state shows header
BMA_HEADERS=always
# Mock for instance-state
aws() {
  case "$2" in
    describe-instances)
      echo -e "i-12345\trunning"
      ;;
  esac
}
result=$(echo "i-12345" | instance-state | head -1)
test_case "instance-state shows header" "InstanceId" "$result"

# Test 7: instance-type shows header
BMA_HEADERS=always
# Mock for instance-type
aws() {
  case "$2" in
    describe-instances)
      echo -e "i-12345\tt3.nano"
      ;;
  esac
}
result=$(echo "i-12345" | instance-type | head -1)
test_case "instance-type shows header" "InstanceId" "$result"

# Test 8: Integration - instance functions chain
BMA_HEADERS=always
# Reset AWS mock for chaining test
aws() {
  case "$2" in
    describe-instances)
      case "$4" in
        *instance-ids*)
          echo -e "i-12345\tami-12345\tt3.nano\trunning\ttest-instance\t2023-01-01T10:00:00Z\tus-east-1a\tvpc-12345"
          ;;
        *)
          echo -e "i-12345\tami-12345\tt3.nano\trunning\ttest-instance\t2023-01-01T10:00:00Z\tus-east-1a\tvpc-12345"
          ;;
      esac
      ;;
  esac
}
result=$(instances | grep -v "^#" | head -1 | awk '{print $1}')
test_case "Integration: can extract instance ID from output" "i-12345" "$result"

# Test 9: Backwards compatibility
BMA_HEADERS=never
result=$(instances | head -1)
test_case "instances backwards compatibility" "i-12345" "$result"

# Test 10: instance-vpc shows header
BMA_HEADERS=always
# Mock for instance-vpc
aws() {
  case "$2" in
    describe-instances)
      echo -e "vpc-12345\ti-12345"
      ;;
  esac
}
result=$(echo "i-12345" | instance-vpc | head -1)
test_case "instance-vpc shows header" "VpcId" "$result"

echo ""
echo "Summary: $PASSED/$TESTS tests passed"

if [ $FAILED -gt 0 ]; then
  echo -e "${RED}$FAILED tests failed${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi