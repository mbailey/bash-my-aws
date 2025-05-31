#!/bin/bash
#
# Detail Function Template
# 
# This template provides a standardized structure for bash-my-aws detail functions
# (resource attribute functions). Detail functions provide specific attributes or
# detailed information about identified AWS resources.
#
# USAGE INSTRUCTIONS:
# 1. Copy this template to your target library file (e.g., lib/service-functions)
# 2. Replace ALL_CAPS placeholders with actual values
# 3. Customize the AWS CLI command and JMESPath query
# 4. Test the function thoroughly
# 5. Add to bash completion (scripts/completions/)
#
# NAMING CONVENTION: Use singular resource name + attribute (e.g., instance-state, stack-outputs)

resource-attribute() {
  # BRIEF_DESCRIPTION_OF_WHAT_ATTRIBUTE_THIS_RETURNS
  #
  # Returns the ATTRIBUTE_NAME for specified RESOURCE_TYPE resources.
  # Accepts resource IDs via command line arguments or piped input.
  #
  # USAGE:
  #     $ resource-attribute resource-id [resource-id ...]
  #     attribute-value-1
  #     attribute-value-2
  #
  #     $ resources | resource-attribute
  #     attribute-value-1
  #     attribute-value-2
  #
  # EXAMPLES:
  #     $ resource-attribute my-resource
  #     active
  #
  #     $ echo "my-resource" | resource-attribute
  #     active
  #
  #     $ resources production | resource-attribute
  #     active
  #     pending
  #     inactive

  # Handle input: accept both arguments and piped input
  local resource_ids=$(skim-stdin "$@")

  # Validate required input
  [[ -z "$resource_ids" ]] && __bma_usage "resource-id [resource-id]" && return 1

  # AWS CLI command to get the specific attribute
  # CUSTOMIZE THIS SECTION:
  # 1. Replace 'service' with actual AWS service
  # 2. Replace 'describe-resource-attribute' with actual API call
  # 3. Update the JMESPath query to extract the desired attribute
  # 4. Handle cases where the attribute might not exist
  aws SERVICE describe-resource-attribute \
    --resource-ids $resource_ids \
    --output text \
    --query 'RESOURCES[].ATTRIBUTE_FIELD || `"NO_VALUE"`'
}

# ALTERNATIVE PATTERNS FOR DIFFERENT SCENARIOS:

# Pattern 1: Simple single-value attribute
resource-simple-attribute() {
  # Returns a single simple value for each resource
  #
  # Use this pattern for attributes that return a single scalar value
  # like state, status, type, etc.

  local resource_ids=$(skim-stdin "$@")
  [[ -z "$resource_ids" ]] && __bma_usage "resource-id [resource-id]" && return 1

  # For simple attributes, often no headers needed
  aws SERVICE describe-resources \
    --resource-ids $resource_ids \
    --output text \
    --query 'RESOURCES[].SIMPLE_FIELD'
}

# Pattern 2: Structured attribute with headers
resource-structured-attribute() {
  # Returns structured data with multiple columns
  #
  # Use this pattern when the attribute contains multiple related fields
  # that should be displayed in a tabular format

  local resource_ids=$(skim-stdin "$@")
  [[ -z "$resource_ids" ]] && __bma_usage "resource-id [resource-id]" && return 1

  # Include headers for structured output
  {
    __bma_output_header RESOURCE_ID ATTRIBUTE_FIELD1 ATTRIBUTE_FIELD2 ATTRIBUTE_FIELD3
    aws SERVICE describe-resources \
      --resource-ids $resource_ids \
      --output text \
      --query 'RESOURCES[].join(`"\t"`,[
        ID,
        ATTRIBUTE.FIELD1 || `"NO_VALUE"`,
        ATTRIBUTE.FIELD2 || `"NO_VALUE"`,
        ATTRIBUTE.FIELD3 || `"NO_VALUE"`
      ])'
  } |
  columnise
}

# Pattern 3: Key-value pairs (like tags or outputs)
resource-key-values() {
  # Returns key-value pairs associated with resources
  #
  # Common pattern for tags, stack outputs, environment variables, etc.

  local resource_ids=$(skim-stdin "$@")
  [[ -z "$resource_ids" ]] && __bma_usage "resource-id [resource-id]" && return 1

  {
    __bma_output_header RESOURCE_ID KEY VALUE DESCRIPTION
    for resource_id in $resource_ids; do
      aws SERVICE describe-resource-details \
        --resource-id "$resource_id" \
        --output text \
        --query 'RESOURCE.KEY_VALUE_ARRAY[].join(`"\t"`,[
          `"'"$resource_id"'"`,
          KEY,
          VALUE,
          DESCRIPTION || `""`
        ])' 2>/dev/null || echo -e "$resource_id\tNO_DATA\t\t"
    done
  } |
  columnise
}

# Pattern 4: Filtered attribute lookup
resource-filtered-attribute() {
  # Returns attributes with filtering or transformation
  #
  # Use when you need to filter, transform, or validate the attribute data

  local resource_ids=$(skim-stdin "$@")
  local filter_pattern="$1"  # Optional filter for attribute values
  shift
  
  [[ -z "$resource_ids" ]] && __bma_usage "resource-id [filter-pattern]" && return 1

  aws SERVICE describe-resources \
    --resource-ids $resource_ids \
    --output text \
    --query 'RESOURCES[].ATTRIBUTE_FIELD' |
  while read -r attribute_value; do
    # Apply filtering or transformation
    if [[ -z "$filter_pattern" ]] || [[ "$attribute_value" == *"$filter_pattern"* ]]; then
      echo "$attribute_value"
    fi
  done
}

# Pattern 5: Attribute with fallback/default handling
resource-attribute-with-fallback() {
  # Returns attribute with intelligent fallback handling
  #
  # Use when the attribute might not exist and you want to provide
  # meaningful defaults or alternative lookups

  local resource_ids=$(skim-stdin "$@")
  [[ -z "$resource_ids" ]] && __bma_usage "resource-id [resource-id]" && return 1

  for resource_id in $resource_ids; do
    # Try primary attribute source
    attribute_value=$(aws SERVICE describe-resources \
      --resource-ids "$resource_id" \
      --output text \
      --query 'RESOURCES[0].PRIMARY_ATTRIBUTE' 2>/dev/null)
    
    # Fallback to alternative source if primary is empty
    if [[ -z "$attribute_value" || "$attribute_value" == "None" ]]; then
      attribute_value=$(aws SERVICE describe-resource-alternative \
        --resource-id "$resource_id" \
        --output text \
        --query 'RESOURCE.FALLBACK_ATTRIBUTE' 2>/dev/null || echo "NO_VALUE")
    fi
    
    echo "$attribute_value"
  done
}

# Pattern 6: Complex multi-step attribute resolution
resource-complex-attribute() {
  # Returns attributes that require multiple API calls or complex logic
  #
  # Use for attributes that need data from multiple services or
  # require complex processing

  local resource_ids=$(skim-stdin "$@")
  [[ -z "$resource_ids" ]] && __bma_usage "resource-id [resource-id]" && return 1

  {
    __bma_output_header RESOURCE_ID COMPUTED_ATTRIBUTE STATUS DETAILS
    for resource_id in $resource_ids; do
      # Step 1: Get basic resource info
      resource_info=$(aws SERVICE describe-resources \
        --resource-ids "$resource_id" \
        --output json 2>/dev/null)
      
      if [[ -n "$resource_info" ]]; then
        # Step 2: Extract required fields
        status=$(echo "$resource_info" | jq -r '.RESOURCES[0].STATUS // "UNKNOWN"')
        reference_id=$(echo "$resource_info" | jq -r '.RESOURCES[0].REFERENCE_ID // ""')
        
        # Step 3: Get additional data if reference exists
        if [[ -n "$reference_id" && "$reference_id" != "null" ]]; then
          details=$(aws OTHER_SERVICE describe-reference \
            --reference-id "$reference_id" \
            --output text \
            --query 'REFERENCE.DETAILS' 2>/dev/null || echo "NO_DETAILS")
        else
          details="NO_REFERENCE"
        fi
        
        # Step 4: Compute final attribute
        computed_attribute="$status-$details"
        
        printf "%s\t%s\t%s\t%s\n" "$resource_id" "$computed_attribute" "$status" "$details"
      else
        printf "%s\t%s\t%s\t%s\n" "$resource_id" "ERROR" "NOT_FOUND" "Resource not found"
      fi
    done
  } |
  columnise
}

# CUSTOMIZATION CHECKLIST:
# 
# Required Changes:
# [ ] Replace resource-attribute with actual function name
# [ ] Replace BRIEF_DESCRIPTION with actual description
# [ ] Replace RESOURCE_TYPE with actual resource type
# [ ] Replace ATTRIBUTE_NAME with actual attribute name
# [ ] Replace SERVICE with actual AWS service name
# [ ] Replace describe-resource-attribute with actual AWS CLI command
# [ ] Replace ATTRIBUTE_FIELD with actual JMESPath field
# [ ] Update usage examples with real examples
# 
# Optional Changes:
# [ ] Add input validation for specific resource ID formats
# [ ] Add error handling for non-existent resources
# [ ] Add support for additional output formats
# [ ] Add completion support in scripts/completions/
# [ ] Add test cases in test/ directory
# 
# Testing:
# [ ] Test with single resource ID
# [ ] Test with multiple resource IDs
# [ ] Test with piped input
# [ ] Test with non-existent resources
# [ ] Test with resources missing the attribute
# [ ] Test error conditions and edge cases

# COMMON DETAIL FUNCTION PATTERNS:

# Instance attributes:
#   instance-state, instance-type, instance-subnet, instance-vpc
#   instance-security-groups, instance-iam-role
#
# Stack attributes:
#   stack-status, stack-outputs, stack-parameters, stack-resources
#   stack-events, stack-template
#
# VPC attributes:
#   vpc-subnets, vpc-route-tables, vpc-security-groups
#   vpc-endpoints, vpc-peering-connections
#
# S3 attributes:
#   bucket-size, bucket-policy, bucket-versioning
#   bucket-encryption, bucket-website
#
# Load balancer attributes:
#   elb-instances, elb-subnets, elb-security-groups
#   elb-health-check, elb-listeners

# JMESPATH PATTERNS FOR DETAIL FUNCTIONS:

# Simple field extraction:
#   .RESOURCES[].STATUS
#   .RESOURCES[0].ATTRIBUTE_NAME
#
# Nested attribute access:
#   .RESOURCES[].CONFIG.NESTED_FIELD
#   .RESOURCES[].METADATA.ATTRIBUTE
#
# Array handling:
#   .RESOURCES[].TAGS[?KEY==`"Name"`].VALUE | [0]
#   .RESOURCES[].SECURITY_GROUPS[].GROUP_ID
#
# Conditional extraction:
#   .RESOURCES[].FIELD || `"DEFAULT_VALUE"`
#   .RESOURCES[].[FIELD1, FIELD2 || `"NO_VALUE"`]

# ERROR HANDLING FOR DETAIL FUNCTIONS:

# Resource not found:
#   aws service command 2>/dev/null || echo "RESOURCE_NOT_FOUND"
#
# Attribute doesn't exist:
#   --query 'FIELD || `"ATTRIBUTE_NOT_SET"`'
#
# Service unavailable:
#   result=$(aws service command 2>&1)
#   [[ $? -ne 0 ]] && echo "SERVICE_ERROR: $result" && return 1
#
# Multiple resources with some failures:
#   for resource_id in $resource_ids; do
#     result=$(aws service command --resource-id "$resource_id" 2>/dev/null)
#     echo "${result:-ERROR: Failed to get attribute for $resource_id}"
#   done

# INPUT VALIDATION PATTERNS:

# Resource ID format validation:
#   [[ ! "$resource_id" =~ ^[a-z]+-[0-9a-f]{8,17}$ ]] && 
#     __bma_error "Invalid resource ID format: $resource_id" && return 1
#
# Required parameter check:
#   [[ -z "$required_param" ]] && 
#     __bma_usage "resource-id [optional-param]" && return 1
#
# Resource existence check:
#   aws service describe-resources --resource-ids "$resource_id" \
#     --query 'length(RESOURCES)' --output text 2>/dev/null | 
#     grep -q '^[1-9]' || {
#       __bma_error "Resource not found: $resource_id" && return 1
#     }