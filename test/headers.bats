#!/usr/bin/env bats

# Test suite for header functionality in bash-my-aws
# Tests the enhanced skim-stdin function and __bma_output_header helper

setup() {
  export PATH="${BATS_TEST_DIRNAME}/../bin:$PATH"
}
source $(dirname "$0")/../lib/shared-functions

# Test skim-stdin with comment lines

@test "skim-stdin: skips comment lines" {
  result=$(echo -e "# HEADER\nvalue1 data1\nvalue2 data2" | skim-stdin)
  [ "$result" = "value1 value2" ]
}

@test "skim-stdin: handles multiple comment lines" {
  result=$(echo -e "# HEADER1\n# HEADER2\nvalue1 data1\nvalue2 data2" | skim-stdin)
  [ "$result" = "value1 value2" ]
}

@test "skim-stdin: handles comment lines interspersed with data" {
  result=$(echo -e "value1 data1\n# COMMENT\nvalue2 data2" | skim-stdin)
  [ "$result" = "value1 value2" ]
}

@test "skim-stdin: handles empty input" {
  result=$(echo -n "" | skim-stdin)
  [ "$result" = "" ]
}

@test "skim-stdin: handles only comment lines" {
  result=$(echo -e "# HEADER1\n# HEADER2" | skim-stdin)
  [ "$result" = "" ]
}

@test "skim-stdin: preserves arguments when no stdin" {
  result=$(skim-stdin arg1 arg2)
  [ "$result" = "arg1 arg2" ]
}

@test "skim-stdin: appends stdin values to arguments" {
  result=$(echo -e "value1 data1\nvalue2 data2" | skim-stdin arg1 arg2)
  [ "$result" = "arg1 arg2 value1 value2" ]
}

@test "skim-stdin: appends stdin values to arguments while skipping comments" {
  result=$(echo -e "# HEADER\nvalue1 data1\nvalue2 data2" | skim-stdin arg1 arg2)
  [ "$result" = "arg1 arg2 value1 value2" ]
}

@test "skim-stdin: handles lines with leading spaces" {
  result=$(echo -e "  value1 data1\n  value2 data2" | skim-stdin)
  [ "$result" = "value1 value2" ]
}

@test "skim-stdin: handles tabs as delimiters" {
  result=$(echo -e "value1\tdata1\nvalue2\tdata2" | skim-stdin)
  [ "$result" = "value1 value2" ]
}

@test "skim-stdin: handles mixed delimiters" {
  result=$(echo -e "value1 data1\tmore\nvalue2\tdata2 more" | skim-stdin)
  [ "$result" = "value1 value2" ]
}

# Test __bma_output_header with BMA_HEADERS environment variable

@test "__bma_output_header: auto mode outputs to terminal" {
  # This test would need to be run with terminal emulation
  # Skipping for now as bats runs in non-terminal mode
  skip "Cannot test terminal detection in bats"
}

@test "__bma_output_header: auto mode suppresses in pipe" {
  BMA_HEADERS=auto
  result=$(__bma_output_header "HEADER1	HEADER2" | cat)
  [ "$result" = "" ]
}

@test "__bma_output_header: always mode outputs to pipe" {
  BMA_HEADERS=always
  result=$(__bma_output_header "HEADER1	HEADER2" | cat)
  [ "$result" = "# HEADER1	HEADER2" ]
}

@test "__bma_output_header: never mode suppresses always" {
  BMA_HEADERS=never
  result=$(__bma_output_header "HEADER1	HEADER2" | cat)
  [ "$result" = "" ]
}

@test "__bma_output_header: defaults to auto when BMA_HEADERS unset" {
  unset BMA_HEADERS
  result=$(__bma_output_header "HEADER1	HEADER2" | cat)
  [ "$result" = "" ]
}

@test "__bma_output_header: formats header with # prefix" {
  BMA_HEADERS=always
  result=$(__bma_output_header "INSTANCE_ID	AMI_ID	TYPE")
  [ "$result" = "# INSTANCE_ID	AMI_ID	TYPE" ]
}

# Integration tests

@test "integration: skim-stdin works with __bma_output_header output" {
  BMA_HEADERS=always
  # Simulate a function that outputs headers followed by data
  result=$(
    __bma_output_header "INSTANCE_ID	AMI_ID"
    echo -e "i-12345	ami-67890\ni-23456	ami-78901"
  ) | skim-stdin
  [ "$result" = "i-12345 i-23456" ]
}

@test "integration: chained skim-stdin calls work correctly" {
  # Simulate piping from one function to another, both with headers
  result=$(
    echo -e "# HEADER1\nvalue1 data1\nvalue2 data2"
  ) | skim-stdin | xargs -n1 echo | skim-stdin
  [ "$result" = "value1 value2" ]
}

# Backwards compatibility tests

@test "backwards compatibility: skim-stdin works with legacy input (no headers)" {
  result=$(echo -e "value1 data1\nvalue2 data2" | skim-stdin)
  [ "$result" = "value1 value2" ]
}

@test "backwards compatibility: skim-stdin with arguments unchanged" {
  result=$(echo -e "value1 data1\nvalue2 data2" | skim-stdin arg1)
  [ "$result" = "arg1 value1 value2" ]
}

@test "backwards compatibility: empty skim-stdin behavior unchanged" {
  result=$(skim-stdin)
  [ "$result" = "" ]
}

# Edge cases

@test "edge case: comment with no space after #" {
  result=$(echo -e "#HEADER\nvalue1 data1" | skim-stdin)
  [ "$result" = "value1" ]
}

@test "edge case: data line starting with ##" {
  result=$(echo -e "## COMMENT\nvalue1 data1" | skim-stdin)
  [ "$result" = "value1" ]
}

@test "edge case: mixed comment styles" {
  result=$(echo -e "# HEADER\n## SUBHEADER\n### SUBSUBHEADER\nvalue1 data1" | skim-stdin)
  [ "$result" = "value1" ]
}

@test "edge case: very long header line" {
  long_header="# $(printf 'COLUMN_%d\t' {1..50})"
  result=$(echo -e "${long_header}\nvalue1 data1" | skim-stdin)
  [ "$result" = "value1" ]
}

@test "edge case: unicode in comments" {
  result=$(echo -e "# HÉADER with ñoñ-ASCII 文字\nvalue1 data1" | skim-stdin)
  [ "$result" = "value1" ]
}