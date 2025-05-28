#!/usr/bin/env bash

# Test script for vpc functions with header support

source $(dirname $0)/../lib/shared-functions
source $(dirname $0)/../lib/vpc-functions

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
    describe-vpcs)
      echo -e "vpc-12345\tdefault-vpc\ttest-vpc\t10.0.0.0/16\tNO_STACK\tNO_VERSION"
      echo -e "vpc-67890\tnot-default\tprod-vpc\t172.16.0.0/16\tprod-stack\tv1.0"
      ;;
    describe-subnets)
      echo -e "subnet-11111\tvpc-12345\tus-east-1a\t10.0.1.0/24\ttest-subnet"
      echo -e "subnet-22222\tvpc-12345\tus-east-1b\t10.0.2.0/24\tNO_NAME"
      ;;
    describe-vpc-peering-connections)
      echo -e "pcx-12345\tactive\t123456:us-east-1:vpc-12345\t789012:us-west-2:vpc-67890\ttest-peering"
      ;;
    describe-vpc-endpoints)
      echo -e "vpce-12345\tvpc-12345\tavailable\tGateway\tcom.amazonaws.us-east-1.s3"
      ;;
    describe-vpc-endpoint-services)
      echo -e "com.amazonaws.us-east-1.s3\tGateway"
      echo -e "com.amazonaws.us-east-1.ec2\tInterface"
      ;;
    describe-internet-gateways)
      echo -e "igw-12345\tvpc-12345"
      ;;
    describe-route-tables)
      echo -e "rtb-12345\tvpc-12345\tmain-route-table"
      ;;
    describe-nat-gateways)
      echo -e "nat-12345\tvpc-12345\t52.1.2.3"
      ;;
    describe-network-acls)
      echo -e "acl-12345\tvpc-12345"
      ;;
    describe-network-interfaces)
      echo -e "10.0.1.10\t52.1.2.3\teni-12345\tvpc-12345\tsubnet-11111\tin-use\tTest interface"
      ;;
    list-functions)
      echo -e "vpc-12345\ttest-lambda-function"
      ;;
    describe-db-instances)
      echo -e "test-db\tvpc-12345\ttestdb"
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

echo "Testing vpc functions with headers..."

# Test 1: vpcs shows header
BMA_HEADERS=always
result=$(vpcs | head -1)
test_case "vpcs shows header" "VpcId" "$result"

# Test 2: subnets shows header
BMA_HEADERS=always
result=$(subnets | head -1)
test_case "subnets shows header" "SubnetId" "$result"

# Test 3: pcxs shows header
BMA_HEADERS=always
result=$(pcxs | head -1)
test_case "pcxs shows header" "PeeringConnectionId" "$result"

# Test 4: vpc-endpoints shows header
BMA_HEADERS=always
result=$(vpc-endpoints | head -1)
test_case "vpc-endpoints shows header" "VpcEndpointId" "$result"

# Test 5: vpc-endpoint-services shows header
BMA_HEADERS=always
result=$(vpc-endpoint-services | head -1)
test_case "vpc-endpoint-services shows header" "ServiceName" "$result"

# Test 6: network-interfaces shows header
BMA_HEADERS=always
result=$(network-interfaces | head -1)
test_case "network-interfaces shows header" "PrivateIpAddress" "$result"

# Test 7: vpcs piping works
BMA_HEADERS=always
result=$(vpcs | skim-stdin)
test_case "vpcs output works with skim-stdin" "vpc-12345 vpc-67890" "$result"

# Test 8: Headers disabled
BMA_HEADERS=never
result=$(vpcs)
if [[ ! "$result" =~ ^# ]]; then
  echo -e "${GREEN}✓${NC} vpcs shows no header in never mode"
  PASSED=$((PASSED + 1))
else
  echo -e "${RED}✗${NC} vpcs shows no header in never mode"
  FAILED=$((FAILED + 1))
fi
TESTS=$((TESTS + 1))

# Test 9: Integration - vpc functions chain
BMA_HEADERS=always
result=$(echo "vpc-12345" | vpc-igw | skim-stdin)
test_case "Integration: vpc functions can be chained" "igw-12345" "$result"

# Test 10: Backwards compatibility
BMA_HEADERS=never
result=$(vpcs | head -1)
test_case "vpcs backwards compatibility" "vpc-12345" "$result"

echo ""
echo "Summary: $PASSED/$TESTS tests passed"

if [ $FAILED -gt 0 ]; then
  echo -e "${RED}$FAILED tests failed${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi