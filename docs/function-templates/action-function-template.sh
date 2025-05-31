#!/bin/bash
#
# Action Function Template
# 
# This template provides a standardized structure for bash-my-aws action functions
# (resource operation functions). Action functions perform operations that create,
# modify, or delete AWS resources.
#
# USAGE INSTRUCTIONS:
# 1. Copy this template to your target library file (e.g., lib/service-functions)
# 2. Replace ALL_CAPS placeholders with actual values
# 3. Customize the AWS CLI command and parameters
# 4. Implement appropriate safety checks and confirmations
# 5. Test the function thoroughly (especially destructive operations)
# 6. Add to bash completion (scripts/completions/)
#
# NAMING CONVENTION: Use singular resource name + action verb (e.g., instance-terminate, stack-create)

resource-action() {
  # BRIEF_DESCRIPTION_OF_WHAT_ACTION_THIS_PERFORMS
  #
  # ACTION_DESCRIPTION for specified RESOURCE_TYPE resources.
  # SAFETY_NOTES_IF_DESTRUCTIVE
  #
  # USAGE:
  #     $ resource-action resource-id [action-parameters]
  #     Action result or status message
  #
  # EXAMPLES:
  #     $ resource-action my-resource
  #     ACTION_VERB my-resource: success
  #
  #     $ resource-action my-resource --parameter value
  #     ACTION_VERB my-resource with parameter: success

  # Parameter handling
  local resource_id="$1"
  local parameter1="$2"
  local parameter2="$3"
  # Add more parameters as needed

  # Input validation
  [[ -z "$resource_id" ]] && __bma_usage "resource-id [parameter1] [parameter2]" && return 1

  # Optional: Validate resource exists before performing action
  if ! aws SERVICE describe-resources --resource-ids "$resource_id" --output text --query 'RESOURCES[0].ID' >/dev/null 2>&1; then
    __bma_error "Resource not found: $resource_id"
    return 1
  fi

  # Optional: Safety confirmation for destructive operations
  # Uncomment and customize for delete/terminate/destroy operations
  # echo "You are about to ACTION_VERB resource: $resource_id"
  # read -p "Type 'yes' to continue: " -r
  # [[ $REPLY != "yes" ]] && echo "Aborted." && return 1

  # Perform the action
  echo "ACTION_VERB $resource_id..."
  
  if aws SERVICE ACTION-COMMAND \
    --resource-id "$resource_id" \
    ${parameter1:+--parameter1 "$parameter1"} \
    ${parameter2:+--parameter2 "$parameter2"} \
    --output text >/dev/null; then
    echo "Successfully ACTION_VERB $resource_id"
  else
    __bma_error "Failed to ACTION_VERB $resource_id"
    return 1
  fi
}

# ALTERNATIVE PATTERNS FOR DIFFERENT SCENARIOS:

# Pattern 1: Create/Launch operations
resource-create() {
  # Create a new RESOURCE_TYPE resource
  #
  # Creates resources with specified configuration and returns the new resource ID

  local resource_name="$1"
  local template_file="$2"
  local parameter_file="$3"

  [[ -z "$resource_name" ]] && __bma_usage "resource-name [template-file] [parameter-file]" && return 1

  # Validate input files exist
  [[ -n "$template_file" && ! -f "$template_file" ]] && 
    __bma_error "Template file not found: $template_file" && return 1
  [[ -n "$parameter_file" && ! -f "$parameter_file" ]] && 
    __bma_error "Parameter file not found: $parameter_file" && return 1

  echo "Creating $resource_name..."

  # Create the resource
  local resource_id
  resource_id=$(aws SERVICE create-resource \
    --resource-name "$resource_name" \
    ${template_file:+--template-body "file://$template_file"} \
    ${parameter_file:+--parameters "file://$parameter_file"} \
    --output text \
    --query 'RESOURCE.ID' 2>&1)

  if [[ $? -eq 0 && -n "$resource_id" ]]; then
    echo "Successfully created $resource_name: $resource_id"
    echo "$resource_id"  # Return the ID for potential piping
  else
    __bma_error "Failed to create $resource_name: $resource_id"
    return 1
  fi
}

# Pattern 2: Bulk operations on multiple resources
resource-bulk-action() {
  # Perform ACTION on multiple RESOURCE_TYPE resources
  #
  # Accepts resource IDs via arguments or piped input

  local resource_ids=$(skim-stdin "$@")
  local action_parameter="$1"

  [[ -z "$resource_ids" ]] && __bma_usage "resource-id [resource-id] [action-parameter]" && return 1

  # Optional: Confirmation for bulk destructive operations
  local resource_count=$(echo "$resource_ids" | wc -w)
  if [[ "$resource_count" -gt 1 ]]; then
    echo "You are about to ACTION_VERB $resource_count resources:"
    echo "$resource_ids" | tr ' ' '\n' | sed 's/^/  /'
    read -p "Type 'yes' to continue: " -r
    [[ $REPLY != "yes" ]] && echo "Aborted." && return 1
  fi

  # Perform action on each resource
  local success_count=0
  local failure_count=0

  for resource_id in $resource_ids; do
    echo "ACTION_VERB $resource_id..."
    
    if aws SERVICE ACTION-COMMAND \
      --resource-id "$resource_id" \
      ${action_parameter:+--parameter "$action_parameter"} \
      --output text >/dev/null 2>&1; then
      echo "  ✓ Success: $resource_id"
      ((success_count++))
    else
      echo "  ✗ Failed: $resource_id"
      ((failure_count++))
    fi
  done

  echo "Results: $success_count successful, $failure_count failed"
  [[ "$failure_count" -gt 0 ]] && return 1
}

# Pattern 3: Wait for completion operations
resource-wait-action() {
  # Perform ACTION and wait for completion
  #
  # Use for operations that are asynchronous and you want to wait for completion

  local resource_id="$1"
  local timeout="${2:-300}"  # Default 5 minute timeout

  [[ -z "$resource_id" ]] && __bma_usage "resource-id [timeout-seconds]" && return 1

  echo "ACTION_VERB $resource_id..."

  # Start the action
  if ! aws SERVICE ACTION-COMMAND \
    --resource-id "$resource_id" \
    --output text >/dev/null; then
    __bma_error "Failed to start ACTION for $resource_id"
    return 1
  fi

  echo "Waiting for ACTION to complete (timeout: ${timeout}s)..."

  # Wait for completion
  local start_time=$(date +%s)
  local status

  while true; do
    status=$(aws SERVICE describe-resources \
      --resource-ids "$resource_id" \
      --output text \
      --query 'RESOURCES[0].STATUS' 2>/dev/null)

    case "$status" in
      "COMPLETE"|"ACTIVE"|"SUCCESS")
        echo "✓ $resource_id ACTION completed successfully"
        return 0
        ;;
      "FAILED"|"ERROR"|"DELETED")
        __bma_error "$resource_id ACTION failed with status: $status"
        return 1
        ;;
      *)
        # Check timeout
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [[ "$elapsed" -gt "$timeout" ]]; then
          __bma_error "Timeout waiting for $resource_id ACTION (${elapsed}s)"
          return 1
        fi
        
        echo "  Status: $status (${elapsed}s elapsed)"
        sleep 10
        ;;
    esac
  done
}

# Pattern 4: Interactive configuration operations
resource-configure() {
  # Interactively configure RESOURCE_TYPE resource
  #
  # Use for complex configuration operations that benefit from user interaction

  local resource_id="$1"
  [[ -z "$resource_id" ]] && __bma_usage "resource-id" && return 1

  # Verify resource exists
  local current_config
  current_config=$(aws SERVICE describe-resources \
    --resource-ids "$resource_id" \
    --output json 2>/dev/null)

  if [[ -z "$current_config" ]]; then
    __bma_error "Resource not found: $resource_id"
    return 1
  fi

  echo "Configuring $resource_id..."
  echo "Current configuration:"
  echo "$current_config" | jq -r '.RESOURCES[0].CONFIGURATION'

  # Interactive prompts for configuration
  echo
  read -p "Enter new configuration value 1 [current: $(echo "$current_config" | jq -r '.RESOURCES[0].CONFIG1')]: " new_value1
  read -p "Enter new configuration value 2 [current: $(echo "$current_config" | jq -r '.RESOURCES[0].CONFIG2')]: " new_value2

  # Build update parameters
  local update_params=()
  [[ -n "$new_value1" ]] && update_params+=(--config1 "$new_value1")
  [[ -n "$new_value2" ]] && update_params+=(--config2 "$new_value2")

  if [[ ${#update_params[@]} -eq 0 ]]; then
    echo "No changes specified."
    return 0
  fi

  # Apply configuration
  echo "Applying configuration changes..."
  if aws SERVICE update-resource-configuration \
    --resource-id "$resource_id" \
    "${update_params[@]}" \
    --output text >/dev/null; then
    echo "✓ Configuration updated successfully"
  else
    __bma_error "Failed to update configuration"
    return 1
  fi
}

# Pattern 5: Validation and dry-run operations
resource-validate-action() {
  # Validate ACTION parameters without performing the action
  #
  # Use for operations that support dry-run or validation modes

  local resource_id="$1"
  local parameter1="$2"
  local dry_run="${3:-true}"  # Default to dry-run mode

  [[ -z "$resource_id" ]] && __bma_usage "resource-id parameter1 [dry-run]" && return 1

  if [[ "$dry_run" == "true" ]]; then
    echo "Validating ACTION for $resource_id (dry-run mode)..."
    local dry_run_flag="--dry-run"
  else
    echo "Performing ACTION for $resource_id..."
    local dry_run_flag=""
  fi

  # Perform validation or actual action
  local output
  output=$(aws SERVICE ACTION-COMMAND \
    --resource-id "$resource_id" \
    --parameter1 "$parameter1" \
    $dry_run_flag \
    --output json 2>&1)

  local exit_code=$?

  if [[ "$dry_run" == "true" ]]; then
    if [[ $exit_code -eq 0 ]]; then
      echo "✓ Validation successful - ACTION would succeed"
      echo "$output" | jq -r '.VALIDATION_RESULTS // "No validation details"'
    else
      echo "✗ Validation failed - ACTION would fail"
      echo "$output"
      return 1
    fi
  else
    if [[ $exit_code -eq 0 ]]; then
      echo "✓ ACTION completed successfully"
      echo "$output" | jq -r '.RESULT_MESSAGE // "No result details"'
    else
      __bma_error "ACTION failed: $output"
      return 1
    fi
  fi
}

# CUSTOMIZATION CHECKLIST:
# 
# Required Changes:
# [ ] Replace resource-action with actual function name
# [ ] Replace BRIEF_DESCRIPTION with actual description
# [ ] Replace ACTION_DESCRIPTION with what the action does
# [ ] Replace RESOURCE_TYPE with actual resource type
# [ ] Replace ACTION_VERB with actual action verb
# [ ] Replace SERVICE with actual AWS service name
# [ ] Replace ACTION-COMMAND with actual AWS CLI command
# [ ] Update parameter handling for your specific needs
# [ ] Update usage examples with real examples
# 
# Security & Safety:
# [ ] Add confirmation prompts for destructive operations
# [ ] Implement resource existence validation
# [ ] Add parameter validation and sanitization
# [ ] Consider rate limiting for bulk operations
# [ ] Add logging for audit trail
# 
# Optional Enhancements:
# [ ] Add dry-run/validation mode
# [ ] Add progress indication for long operations
# [ ] Add rollback capability for complex operations
# [ ] Add completion support in scripts/completions/
# [ ] Add test cases in test/ directory
# 
# Testing:
# [ ] Test with valid parameters
# [ ] Test with invalid parameters
# [ ] Test error conditions (resource not found, permission denied)
# [ ] Test confirmation prompts (if applicable)
# [ ] Test bulk operations (if applicable)
# [ ] Test timeout scenarios (for wait operations)

# COMMON ACTION FUNCTION PATTERNS:

# Create operations:
#   stack-create, instance-launch, bucket-create
#   vpc-create, security-group-create
#
# Delete operations:
#   stack-delete, instance-terminate, bucket-delete
#   vpc-delete, security-group-delete
#
# State change operations:
#   instance-start, instance-stop, instance-reboot
#   asg-suspend, asg-resume
#
# Configuration operations:
#   stack-update, instance-modify, bucket-configure
#   security-group-update, elb-configure

# PARAMETER HANDLING PATTERNS:

# Required positional parameters:
#   local resource_id="$1"
#   [[ -z "$resource_id" ]] && __bma_usage "resource-id" && return 1
#
# Optional parameters with defaults:
#   local timeout="${2:-300}"
#   local format="${3:-json}"
#
# Multiple resource IDs:
#   local resource_ids=$(skim-stdin "$@")
#
# Key-value parameters:
#   while [[ $# -gt 0 ]]; do
#     case "$1" in
#       --key) key="$2"; shift 2 ;;
#       --value) value="$2"; shift 2 ;;
#       *) resource_id="$1"; shift ;;
#     esac
#   done

# SAFETY AND CONFIRMATION PATTERNS:

# Simple confirmation:
#   read -p "Are you sure? (yes/no): " -r
#   [[ $REPLY != "yes" ]] && echo "Aborted." && return 1
#
# Resource listing confirmation:
#   echo "You are about to delete the following resources:"
#   echo "$resource_ids" | tr ' ' '\n' | sed 's/^/  /'
#   read -p "Type 'DELETE' to confirm: " -r
#   [[ $REPLY != "DELETE" ]] && echo "Aborted." && return 1
#
# Environment-based safety:
#   if [[ "${BMA_ENVIRONMENT:-}" == "production" ]]; then
#     echo "DANGER: This is a production environment!"
#     read -p "Type the resource name to confirm: " -r
#     [[ $REPLY != "$resource_id" ]] && echo "Aborted." && return 1
#   fi

# ERROR HANDLING AND LOGGING:

# AWS CLI error capture:
#   local output
#   output=$(aws service command 2>&1)
#   local exit_code=$?
#   [[ $exit_code -ne 0 ]] && __bma_error "Operation failed: $output" && return 1
#
# Operation logging:
#   echo "$(date -Iseconds) ACTION $resource_id by $(whoami)" >> "$BMA_LOG_FILE"
#
# Rollback on failure:
#   trap 'rollback_operation "$resource_id"' ERR