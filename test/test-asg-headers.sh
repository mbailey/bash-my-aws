#!/usr/bin/env bash
#
# Test header functionality for asg-functions
#
# This test suite verifies that:
# 1. Headers are displayed correctly when BMA_HEADERS=always
# 2. Headers are skipped when piping between commands
# 3. Column alignment is maintained with headers
# 4. All listing functions include appropriate headers

# Set up test environment
export BMA_HEADERS=always
export PATH="$PWD/bin:$PATH"
source lib/shared-functions
source lib/asg-functions

# Test framework functions
pass() {
  echo "✓ $1"
}

fail() {
  echo "✗ $1"
  exit 1
}

# Mock AWS CLI for testing
aws() {
  case "$2" in
    "describe-auto-scaling-groups")
      if [[ "$*" == *"--auto-scaling-group-names"* ]]; then
        # Specific ASG query
        cat <<EOF
test-asg	test-stack	2	3	3	2024-01-15T10:30:00.000Z	us-east-1a,us-east-1b
EOF
      else
        # List all ASGs
        cat <<EOF
web-asg	web-stack	1	2	5	2024-01-15T10:30:00.000Z	us-east-1a,us-east-1b
app-asg	app-stack	2	4	10	2024-01-15T11:45:00.000Z	us-east-1a,us-east-1c
db-asg	db-stack	3	3	3	2024-01-16T08:20:00.000Z	us-east-1b,us-east-1c
EOF
      fi
      ;;
    "describe-launch-configurations")
      cat <<EOF
web-lc	ami-12345678	t3.micro
app-lc	ami-87654321	t3.small
db-lc	ami-11223344	t3.medium
EOF
      ;;
    *)
      echo "Unknown AWS command: $*" >&2
      return 1
      ;;
  esac
}

echo "Testing asg-functions header implementation..."

# Test 1: asgs() function shows headers
echo -n "Test 1: asgs() shows headers with BMA_HEADERS=always... "
output=$(asgs 2>&1)
if echo "$output" | head -1 | grep -q "^# ASG_NAME.*NAME_TAG.*CREATED_TIME.*AVAILABILITY_ZONES"; then
  pass "Headers present"
else
  fail "Headers missing"
  echo "Output: $output"
fi

# Test 2: asgs() headers have correct column names
echo -n "Test 2: asgs() headers have correct column names... "
header=$(asgs 2>&1 | head -1)
if [[ "$header" =~ "ASG_NAME" ]] && [[ "$header" =~ "NAME_TAG" ]] && 
   [[ "$header" =~ "CREATED_TIME" ]] && [[ "$header" =~ "AVAILABILITY_ZONES" ]]; then
  pass "Correct column names"
else
  fail "Incorrect column names"
  echo "Header: $header"
fi

# Test 3: asg-capacity() shows headers
echo -n "Test 3: asg-capacity() shows headers... "
output=$(echo "test-asg" | asg-capacity 2>&1)
if echo "$output" | head -1 | grep -q "^# ASG_NAME.*MIN_SIZE.*DESIRED_CAPACITY.*MAX_SIZE"; then
  pass "Headers present"
else
  fail "Headers missing"
  echo "Output: $output"
fi

# Test 4: launch-configurations() shows headers
echo -n "Test 4: launch-configurations() shows headers... "
output=$(launch-configurations 2>&1)
if echo "$output" | head -1 | grep -q "^# LAUNCH_CONFIG_NAME.*IMAGE_ID.*INSTANCE_TYPE"; then
  pass "Headers present"
else
  fail "Headers missing"
  echo "Output: $output"
fi

# Test 5: Headers are skipped with skim-stdin
echo -n "Test 5: skim-stdin skips header comments... "
test_input="# ASG_NAME NAME_TAG CREATED_TIME
web-asg web-stack 2024-01-15T10:30:00.000Z
app-asg app-stack 2024-01-15T11:45:00.000Z"
result=$(echo "$test_input" | skim-stdin)
if [[ "$result" == "web-asg app-asg" ]]; then
  pass "Headers correctly skipped"
else
  fail "Headers not skipped properly"
  echo "Result: '$result'"
fi

# Test 6: Headers work with BMA_HEADERS=never
echo -n "Test 6: No headers with BMA_HEADERS=never... "
BMA_HEADERS=never output=$(asgs 2>&1)
if echo "$output" | head -1 | grep -q "^#"; then
  fail "Headers shown when they shouldn't be"
  echo "Output: $output"
else
  pass "Headers correctly suppressed"
fi

# Test 7: launch-configuration-asgs() shows headers
echo -n "Test 7: launch-configuration-asgs() shows headers... "
BMA_HEADERS=always output=$(echo "web-lc" | launch-configuration-asgs 2>&1 || true)
if echo "$output" | grep -q "^# LAUNCH_CONFIG_NAME.*ASG_NAMES"; then
  pass "Headers present"
else
  fail "Headers missing"
  echo "Output: $output"
fi

# Test 8: asg-processes_suspended() shows headers
echo -n "Test 8: asg-processes_suspended() shows headers... "
output=$(echo "test-asg" | asg-processes_suspended 2>&1 || true)
if echo "$output" | grep -q "^# ASG_NAME.*SUSPENDED_PROCESSES"; then
  pass "Headers present"
else
  fail "Headers missing"
  echo "Output: $output"
fi

# Test 9: asg-stack() shows headers
echo -n "Test 9: asg-stack() shows headers... "
output=$(echo "test-asg" | asg-stack 2>&1 || true)
if echo "$output" | grep -q "^# STACK_NAME.*ASG_NAME"; then
  pass "Headers present"
else
  fail "Headers missing"
  echo "Output: $output"
fi

# Test 10: Verify columnise is called (functions end with | columnise)
echo -n "Test 10: Functions use columnise for alignment... "
if grep -A20 "^asgs()" lib/asg-functions | grep -q "} | columnise"; then
  pass "columnise pattern found"
else
  fail "columnise pattern missing"
fi

echo
echo "All asg-functions header tests passed! ✓"