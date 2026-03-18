# Header Comment Implementation for bash-my-aws

## Overview

This document outlines the implementation of headers as comments for bash-my-aws resource listing functions. This approach maintains 100% backwards compatibility while improving usability.

## Core Implementation

### 1. Enhanced skim-stdin Function

```bash
skim-stdin() {
  # Append first token from each line of STDIN to argument list
  # Now ignores comment lines starting with #
  
  local skimmed_stdin="$([[ -t 0 ]] || awk '
    /^#/ { next }  # Skip comment lines (headers)
    { print $1 }   # Extract first field
  ' ORS=" ")"
  
  printf -- '%s %s' "$*" "$skimmed_stdin" |
    awk '{$1=$1;print}'  # trim leading/trailing spaces
}
```

### 2. Header Output Helper

```bash
# Add to shared-functions
__bma_output_header() {
  local header="$1"
  
  # Determine if headers should be shown
  local show_headers="false"
  case "${BMA_HEADERS:-auto}" in
    always) show_headers="true" ;;
    never)  show_headers="false" ;;
    auto)   [[ -t 1 ]] && show_headers="true" ;;
  esac
  
  [[ "$show_headers" == "true" ]] && echo "# $header"
}
```

### 3. Updated Function Example

```bash
instances() {
  # List EC2 Instances
  
  local instances=$(skim-stdin)
  local filters=$(__bma_read_filters $@)
  
  # Output header comment
  __bma_output_header "INSTANCE_ID	AMI_ID	TYPE	STATE	NAME	LAUNCH_TIME	AZ	VPC"
  
  aws ec2 describe-instances \
    ${instances/#/'--instance-ids '} \
    --output text \
    --query "
      Reservations[].Instances[][
        InstanceId,
        ImageId,
        InstanceType,
        State.Name,
        [Tags[?Key=='Name'].Value][0][0],
        LaunchTime,
        Placement.AvailabilityZone,
        VpcId
      ]" |
  grep -E -- "$filters" |
  LC_ALL=C sort -t$'\t' -k 6 |
  columnise
}
```

## Usage Examples

### Default Behavior (auto mode)

```bash
# Terminal: shows headers
$ instances
# INSTANCE_ID         AMI_ID            TYPE     STATE    NAME       LAUNCH_TIME               AZ                VPC
i-4e15ece1de1a3f869  ami-123456789012  t3.nano  running  nagios     2019-12-10T08:17:18.000Z  ap-southeast-2a  None

# Pipe: no headers, skim-stdin ignores comment
$ instances | instance-state
i-4e15ece1de1a3f869  running
```

### Forced Headers

```bash
# Always show headers, even in pipes
$ BMA_HEADERS=always instances | head -2
# INSTANCE_ID         AMI_ID            TYPE     STATE    NAME       LAUNCH_TIME               AZ                VPC
i-4e15ece1de1a3f869  ami-123456789012  t3.nano  running  nagios     2019-12-10T08:17:18.000Z  ap-southeast-2a  None
```

### No Headers

```bash
# Never show headers, even in terminal
$ BMA_HEADERS=never instances
i-4e15ece1de1a3f869  ami-123456789012  t3.nano  running  nagios     2019-12-10T08:17:18.000Z  ap-southeast-2a  None
```

## Implementation Checklist

### Phase 1: Core Changes
- [ ] Update `skim-stdin` in `lib/shared-functions`
- [ ] Add `__bma_output_header` helper function
- [ ] Test backwards compatibility with existing scripts
- [ ] Document BMA_HEADERS environment variable

### Phase 2: Update High-Value Functions
- [ ] `instances()` - lib/instance-functions
- [ ] `stacks()` - lib/stack-functions  
- [ ] `buckets()` - lib/s3-functions
- [ ] `vpcs()` - lib/vpc-functions
- [ ] `asgs()` - lib/asg-functions

### Phase 3: Complete Rollout
- [ ] Update all remaining listing functions
- [ ] Add header information to function documentation
- [ ] Update README with header feature
- [ ] Create migration guide for users

## Headers for Key Functions

```bash
# instances
INSTANCE_ID	AMI_ID	TYPE	STATE	NAME	LAUNCH_TIME	AZ	VPC

# stacks  
STACK_NAME	STATUS	CREATION_TIME	LAST_UPDATED	NESTED

# buckets
BUCKET_NAME	CREATION_DATE

# vpcs
VPC_ID	DEFAULT	NAME	CIDR	STACK	VERSION

# asgs
ASG_NAME	NAME_TAG	CREATED_TIME	AVAILABILITY_ZONES

# subnets
SUBNET_ID	VPC_ID	AZ	CIDR	NAME

# keypairs
KEYPAIR_NAME	FINGERPRINT

# images
IMAGE_ID	CREATED	NAME	DESCRIPTION

# volumes
VOLUME_ID	STATE	SIZE	TYPE	CREATED	NAME
```

## Testing Strategy

### Backwards Compatibility Tests

```bash
# Test 1: Existing pipe behavior unchanged
instances | head -1 | grep -q "^i-" || echo "FAIL: First line should be instance ID"

# Test 2: skim-stdin ignores comments
echo -e "# HEADER\ni-12345" | skim-stdin | grep -q "i-12345" || echo "FAIL: Should extract instance ID"

# Test 3: No headers in pipe by default
instances | grep -q "^# INSTANCE_ID" && echo "FAIL: Headers shown in pipe"

# Test 4: Headers shown in terminal
BMA_HEADERS=always instances | grep -q "^# INSTANCE_ID" || echo "FAIL: Headers not shown"
```

### User Acceptance Tests

```bash
# Test 1: Headers improve readability
instances  # Should show column headers

# Test 2: Piping still works
instances | instance-state  # Should not break

# Test 3: File output includes headers for reference
instances > /tmp/instances.txt
head -1 /tmp/instances.txt  # Should show header comment
```

## Benefits

1. **Zero Breaking Changes** - Existing scripts continue to work
2. **Self-Documenting** - Headers explain column meanings
3. **Standard Unix Pattern** - Comments are universally understood
4. **Flexible Control** - Users can force headers on/off
5. **Clean Implementation** - Minimal code changes required

## Future Enhancements

Once headers are implemented, we could add:

1. **Column Selection**
   ```bash
   instances --columns instance_id,name,state
   ```

2. **Format Options**
   ```bash
   instances --format json
   instances --format csv
   ```

3. **Schema Discovery**
   ```bash
   bma-schema instances
   ```

The comment-based header approach provides a solid foundation for these future features while solving the immediate usability need.