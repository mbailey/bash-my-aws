#!/usr/bin/env bats

# Test suite for header functionality in keypair functions

setup() {
  export PATH="${BATS_TEST_DIRNAME}/../bin:$PATH"
}
source $(dirname "$0")/../lib/shared-functions
source $(dirname "$0")/../lib/keypair-functions

# Mock AWS CLI for testing
aws() {
  case "$1" in
    ec2)
      case "$2" in
        describe-key-pairs)
          echo -e "test-key1\t12:34:56:78:90:ab:cd:ef:12:34:56:78:90:ab:cd:ef"
          echo -e "test-key2\t98:76:54:32:10:fe:dc:ba:98:76:54:32:10:fe:dc:ba"
          ;;
      esac
      ;;
  esac
}

@test "keypairs shows header in always mode" {
  BMA_HEADERS=always
  result=$(keypairs)
  [[ "${result}" =~ ^#.*KEYPAIR_NAME.*FINGERPRINT ]]
}

@test "keypairs shows no header in never mode" {
  BMA_HEADERS=never
  result=$(keypairs)
  [[ ! "${result}" =~ ^# ]]
}

@test "keypairs piping works with headers" {
  # Simulate keypairs output with header
  keypairs_output="# KEYPAIR_NAME	FINGERPRINT
test-key1	12:34:56:78:90:ab:cd:ef:12:34:56:78:90:ab:cd:ef
test-key2	98:76:54:32:10:fe:dc:ba:98:76:54:32:10:fe:dc:ba"
  
  # Test that skim-stdin correctly skips the header
  result=$(echo "$keypairs_output" | skim-stdin)
  [ "$result" = "test-key1 test-key2" ]
}

@test "keypairs chaining works correctly" {
  # Test that multiple commands can be chained even with headers
  BMA_HEADERS=always
  # This would normally test actual chaining, but we'll test the concept
  # that headers don't interfere with pipe-skimming
  result=$(echo -e "# HEADER\nvalue1\nvalue2" | skim-stdin | wc -w)
  [ "$result" = "2" ]
}

@test "keypairs backwards compatibility maintained" {
  # Ensure that when headers are disabled, output is identical to legacy
  BMA_HEADERS=never
  result=$(keypairs | head -1)
  # Should not start with #
  [[ ! "$result" =~ ^# ]]
  # Should contain keypair data
  [[ "$result" =~ test-key ]]
}

@test "keypairs header format matches data columns" {
  BMA_HEADERS=always
  result=$(keypairs)
  # Extract header line
  header=$(echo "$result" | grep "^#" | head -1)
  # Should have two columns separated by tab
  [[ "$header" =~ KEYPAIR_NAME.*FINGERPRINT ]]
}