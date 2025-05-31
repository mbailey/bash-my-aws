#!/bin/bash
#
# Query Function Template
# 
# This template provides a standardized structure for bash-my-aws query functions
# (resource listing functions). Query functions list AWS resources with key attributes.
#
# USAGE INSTRUCTIONS:
# 1. Copy this template to your target library file (e.g., lib/service-functions)
# 2. Replace ALL_CAPS placeholders with actual values
# 3. Customize the AWS CLI command and JMESPath query
# 4. Test the function thoroughly
# 5. Add to bash completion (scripts/completions/)
#
# NAMING CONVENTION: Use plural resource name (e.g., instances, stacks, buckets)

RESOURCES() {
  # BRIEF_DESCRIPTION_OF_WHAT_THIS_FUNCTION_LISTS
  #
  # Lists AWS RESOURCE_TYPE resources with key identifying attributes.
  # Supports filtering output using grep-style patterns.
  #
  # USAGE:
  #     $ RESOURCES
  #     COLUMN1           COLUMN2          COLUMN3          COLUMN4
  #     resource-id-1     value1           value2           value3
  #     resource-id-2     value1           value2           value3
  #
  # FILTERING:
  #     $ RESOURCES filter-pattern
  #     Shows only resources matching the filter pattern
  #
  # EXAMPLES:
  #     $ RESOURCES
  #     List all RESOURCE_TYPE resources
  #
  #     $ RESOURCES production
  #     List resources containing "production"
  #
  #     $ RESOURCES web | head -5
  #     List first 5 resources containing "web"

  # Output column headers (always include for query functions)
  __bma_output_header COLUMN1 COLUMN2 COLUMN3 COLUMN4

  # Handle input and filtering
  # skim-stdin processes both command-line arguments and piped input
  # __bma_read_filters converts arguments to grep-compatible filter patterns
  local resource_ids=$(skim-stdin "$@")
  local filters=$(__bma_read_filters "$@")

  # Optional: Input validation (uncomment if specific resources are required)
  # [[ -z "$resource_ids" ]] && __bma_usage "resource-id [resource-id]" && return 1

  # AWS CLI command with proper formatting
  # CUSTOMIZE THIS SECTION:
  # 1. Replace 'service' with actual AWS service (e.g., ec2, s3, cloudformation)
  # 2. Replace 'describe-resources' with actual API call
  # 3. Update the JMESPath query to extract the desired columns
  # 4. Adjust any resource ID parameters if needed
  {
    __bma_output_header COLUMN1 COLUMN2 COLUMN3 COLUMN4
    aws SERVICE describe-resources \
      ${resource_ids:+--resource-ids $resource_ids} \
      --output text \
      --query 'RESOURCES[].join(`"\t"`,[
        FIELD1 || `"NO_VALUE"`,
        FIELD2 || `"NO_VALUE"`,
        FIELD3 || `"NO_VALUE"`,
        FIELD4 || `"NO_VALUE"`
      ])'
  } |
  grep -E -- "$filters" |
  LC_ALL=C sort -t$'\t' -k SORT_COLUMN |
  columnise
}

# ALTERNATIVE PATTERNS FOR DIFFERENT SCENARIOS:

# Pattern 1: Simple single-column output
simple_resources() {
  # List RESOURCE_TYPE resource identifiers only
  #
  #     $ simple_resources
  #     resource-id-1
  #     resource-id-2

  __bma_output_header RESOURCE_ID

  local filters=$(__bma_read_filters "$@")

  {
    __bma_output_header RESOURCE_ID
    aws SERVICE list-resources \
      --output text \
      --query 'RESOURCES[].ID'
  } |
  grep -E -- "$filters" |
  LC_ALL=C sort |
  columnise
}

# Pattern 2: Complex multi-service query
complex_resources() {
  # List RESOURCE_TYPE resources with data from multiple API calls
  #
  # NOTE: Use this pattern when you need to combine data from multiple
  # AWS CLI calls or when the standard describe-* call doesn't provide
  # all needed information.

  __bma_output_header RESOURCE_ID TYPE STATUS EXTRA_INFO

  local filters=$(__bma_read_filters "$@")

  {
    __bma_output_header RESOURCE_ID TYPE STATUS EXTRA_INFO
    
    # Main query
    aws SERVICE describe-resources \
      --output text \
      --query 'RESOURCES[].[ID, Type, Status]' |
    while read -r resource_id type status; do
      # Additional data lookup (if needed)
      extra_info=$(aws SERVICE describe-resource-detail \
        --resource-id "$resource_id" \
        --output text \
        --query 'Resource.ExtraField' 2>/dev/null || echo "NO_INFO")
      
      printf "%s\t%s\t%s\t%s\n" "$resource_id" "$type" "$status" "$extra_info"
    done
  } |
  grep -E -- "$filters" |
  LC_ALL=C sort -t$'\t' -k 1 |
  columnise
}

# Pattern 3: Resource with tags
tagged_resources() {
  # List RESOURCE_TYPE resources with tag information
  #
  # Common pattern for resources that have tag support

  __bma_output_header RESOURCE_ID TYPE NAME ENVIRONMENT

  local filters=$(__bma_read_filters "$@")

  {
    __bma_output_header RESOURCE_ID TYPE NAME ENVIRONMENT
    aws SERVICE describe-resources \
      --output text \
      --query 'RESOURCES[].join(`"\t"`,[
        ID,
        Type,
        Tags[?Key==`"Name"`].Value | [0] || `"NO_NAME"`,
        Tags[?Key==`"Environment"`].Value | [0] || `"NO_ENV"`
      ])'
  } |
  grep -E -- "$filters" |
  LC_ALL=C sort -t$'\t' -k 3 |  # Sort by name
  columnise
}

# Pattern 4: Time-based sorting
time_sorted_resources() {
  # List RESOURCE_TYPE resources sorted by creation time
  #
  # Use this pattern when resources have timestamps that should be
  # the primary sorting field

  __bma_output_header RESOURCE_ID NAME CREATED STATUS

  local filters=$(__bma_read_filters "$@")

  {
    __bma_output_header RESOURCE_ID NAME CREATED STATUS
    aws SERVICE describe-resources \
      --output text \
      --query 'RESOURCES[].join(`"\t"`,[
        ID,
        Name || `"NO_NAME"`,
        CreationTime,
        Status
      ])'
  } |
  grep -E -- "$filters" |
  LC_ALL=C sort -t$'\t' -k 3 |  # Sort by creation time
  columnise
}

# CUSTOMIZATION CHECKLIST:
# 
# Required Changes:
# [ ] Replace RESOURCES with actual function name (plural)
# [ ] Replace BRIEF_DESCRIPTION with actual description
# [ ] Replace RESOURCE_TYPE with actual resource type
# [ ] Replace SERVICE with actual AWS service name
# [ ] Replace describe-resources with actual AWS CLI command
# [ ] Replace COLUMN1, COLUMN2, etc. with actual column names
# [ ] Replace FIELD1, FIELD2, etc. with actual JMESPath fields
# [ ] Set appropriate SORT_COLUMN for sorting
# [ ] Update usage examples with real examples
# 
# Optional Changes:
# [ ] Add input validation if specific resource IDs are required
# [ ] Add additional filtering logic if needed
# [ ] Customize error handling for specific scenarios
# [ ] Add completion support in scripts/completions/
# [ ] Add test cases in test/ directory
# 
# Testing:
# [ ] Test with no arguments
# [ ] Test with filter arguments
# [ ] Test with piped input
# [ ] Test header display (BMA_HEADERS=always/auto/never)
# [ ] Test sorting behavior
# [ ] Test with non-existent resources
# [ ] Test performance with large result sets

# COMMON AWS CLI PATTERNS:
#
# EC2 Instances:
#   aws ec2 describe-instances --query 'Reservations[].Instances[]...'
#
# CloudFormation Stacks:
#   aws cloudformation describe-stacks --query 'Stacks[]...'
#
# S3 Buckets:
#   aws s3api list-buckets --query 'Buckets[]...'
#
# VPC Resources:
#   aws ec2 describe-vpcs --query 'Vpcs[]...'
#
# Auto Scaling Groups:
#   aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[]...'
#
# Lambda Functions:
#   aws lambda list-functions --query 'Functions[]...'
#
# RDS Instances:
#   aws rds describe-db-instances --query 'DBInstances[]...'

# JMESPATH REFERENCE:
#
# Basic field access:     FieldName
# Nested field access:    Parent.Child.Field
# Array access:          Array[0]
# Filter arrays:         Array[?Field==`"value"`]
# Join arrays:           join(`"\t"`, [Field1, Field2])
# Conditional values:    Field || `"default_value"`
# Sort arrays:           sort_by(Array, &Field)
# Length:                length(Array)

# ERROR HANDLING PATTERNS:
#
# Input validation:
#   [[ -z "$required_param" ]] && __bma_usage "param-name" && return 1
#
# AWS CLI error handling:
#   aws service command 2>/dev/null || echo "NO_DATA"
#
# Empty result handling:
#   result=$(aws service command --query '...' --output text)
#   [[ -z "$result" ]] && echo "No resources found" && return 0