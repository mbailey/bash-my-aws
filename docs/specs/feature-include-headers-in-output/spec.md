# Feature Specification: Include Headers in Output

## Overview

Add optional column headers to bash-my-aws resource listing functions to improve usability while maintaining 100% backwards compatibility with the existing pipe-skimming ecosystem.

## Problem Statement

### Current State
bash-my-aws functions output TSV data without headers, making it difficult for new users to understand column meanings:

```bash
$ instances
i-4e15ece1de1a3f869  ami-123456789012  t3.nano  running  nagios  2019-12-10T08:17:18.000Z  ap-southeast-2a  None
```
Users must refer to documentation to understand that columns represent: InstanceId, ImageId, InstanceType, State, Name, LaunchTime, AvailabilityZone, VpcId.

### The Challenge
Adding headers breaks the fundamental `skim-stdin()` pattern that enables bash-my-aws's powerful piping capabilities:

```bash
# This would break if headers were added:
$ instances | instance-stop  # skim-stdin would try to stop "INSTANCE_ID"
```

The project is 10+ years old with established users who depend on current behavior.

## Requirements

### Functional Requirements

1. **Headers Available When Useful**
   - Show column headers when output goes to terminal (human-readable)
   - Include headers when output is redirected to files (for reference)
   - Allow forced header control via environment variable

2. **Backwards Compatibility** 
   - Existing scripts must continue to work unchanged
   - `skim-stdin()` must ignore headers when extracting resource IDs
   - Piping between bash-my-aws functions must work seamlessly

3. **Consistent Behavior**
   - Same header format across all functions
   - Predictable behavior regardless of output destination
   - No surprising differences between terminal and pipe output

4. **Unix Philosophy Compliance**
   - Follow established Unix conventions
   - Make tools more composable, not less
   - Simple, elegant implementation

### Non-Functional Requirements

1. **Performance**: No measurable performance impact
2. **Maintainability**: Simple to understand and modify
3. **Extensibility**: Foundation for future enhancements (JSON output, column selection)
4. **Documentation**: Self-documenting through header content

## Solution Design

### Core Approach: Headers as Comments

Output headers as comment lines prefixed with `#`, following Unix conventions:

```bash
# Before (current)
$ instances
i-4e15ece1de1a3f869  ami-123456789012  t3.nano  running  nagios  2019-12-10T08:17:18.000Z  ap-southeast-2a  None

# After (with headers)
$ instances  
# INSTANCE_ID         AMI_ID            TYPE     STATE    NAME   LAUNCH_TIME               AZ                VPC
i-4e15ece1de1a3f869  ami-123456789012  t3.nano  running  nagios  2019-12-10T08:17:18.000Z  ap-southeast-2a  None
```

### Enhanced skim-stdin Function

Modify `skim-stdin()` to skip comment lines, making it universally useful:

```bash
skim-stdin() {
  # Extract first token from each non-comment line of STDIN
  local skimmed_stdin="$([[ -t 0 ]] || awk '
    /^#/ { next }  # Skip comment lines
    { print $1 }   # Extract first field
  ' ORS=" ")"
  
  printf -- '%s %s' "$*" "$skimmed_stdin" |
    awk '{$1=$1;print}'  # trim leading/trailing spaces
}
```

### Header Control Mechanism

Environment variable `BMA_HEADERS` controls header behavior:

- `auto` (default): Headers in terminal, none in pipes 
- `always`: Headers in all output
- `never`: No headers anywhere

**Note**: Default behavior enables headers for better new user experience. Final default setting will be decided before merging based on user feedback and testing.

```bash
export BMA_HEADERS=auto    # Default: headers in terminal, none in pipes
export BMA_HEADERS=always  # Force headers everywhere
export BMA_HEADERS=never   # Suppress all headers
```

### Implementation Pattern

Standard pattern for all listing functions:

```bash
function_name() {
  local resources=$(skim-stdin)
  local filters=$(__bma_read_filters $@)
  
  # Output header comment
  __bma_output_header "COL1	COL2	COL3	..."
  
  # Existing implementation unchanged
  aws service describe-resources ... | columnise
}
```

## Behavior Specification

### Terminal Output (Human)
```bash
$ instances
# INSTANCE_ID         AMI_ID            TYPE     STATE    NAME   LAUNCH_TIME               AZ                VPC
i-4e15ece1de1a3f869  ami-123456789012  t3.nano  running  nagios  2019-12-10T08:17:18.000Z  ap-southeast-2a  None

$ instances > file.txt
$ head -1 file.txt
# INSTANCE_ID         AMI_ID            TYPE     STATE    NAME   LAUNCH_TIME               AZ                VPC
```

### Piped Output (Machine)
```bash
$ instances | instance-state
i-4e15ece1de1a3f869  running  # Headers automatically ignored by skim-stdin

$ instances | head -1
# INSTANCE_ID         AMI_ID            TYPE     STATE    NAME   LAUNCH_TIME               AZ                VPC

$ instances | grep -v '^#' | head -1  # User can filter headers if needed
i-4e15ece1de1a3f869  ami-123456789012  t3.nano  running  nagios  2019-12-10T08:17:18.000Z  ap-southeast-2a  None
```

### Environment Variable Control
```bash
$ BMA_HEADERS=never instances
i-4e15ece1de1a3f869  ami-123456789012  t3.nano  running  nagios  2019-12-10T08:17:18.000Z  ap-southeast-2a  None

$ BMA_HEADERS=always instances | head -2
# INSTANCE_ID         AMI_ID            TYPE     STATE    NAME   LAUNCH_TIME               AZ                VPC
i-4e15ece1de1a3f869  ami-123456789012  t3.nano  running  nagios  2019-12-10T08:17:18.000Z  ap-southeast-2a  None
```

## Header Definitions

### Core Resources

**instances()**
```
INSTANCE_ID	AMI_ID	TYPE	STATE	NAME	LAUNCH_TIME	AZ	VPC
```

**stacks()**
```
STACK_NAME	STATUS	CREATION_TIME	LAST_UPDATED	NESTED
```

**buckets()**
```
BUCKET_NAME	CREATION_DATE
```

**vpcs()**
```
VPC_ID	DEFAULT	NAME	CIDR	STACK	VERSION
```

**asgs()**
```
ASG_NAME	NAME_TAG	CREATED_TIME	AVAILABILITY_ZONES
```

**subnets()**
```
SUBNET_ID	VPC_ID	AZ	CIDR	NAME
```

### Detailed Resources

**instance-dns()**
```
INSTANCE_ID	PRIVATE_DNS	PUBLIC_DNS
```

**instance-ip()**
```
INSTANCE_ID	PRIVATE_IP	PUBLIC_IP
```

**vpc-subnets()**
```
SUBNET_ID	VPC_ID	AZ	CIDR	NAME
```

## Benefits

### For New Users
- Immediate understanding of output columns
- Self-documenting interface
- Reduced need to reference documentation

### For Existing Users  
- Zero breaking changes to existing workflows
- Headers available when useful (terminal/files)
- Invisible when piping (machine processing)

### For the Ecosystem
- `skim-stdin()` becomes more universally useful
- Works with any commented data, not just bash-my-aws
- Follows Unix conventions (# for comments)
- Foundation for future enhancements

## Edge Cases & Considerations

### Backwards Compatibility Testing
```bash
# All existing patterns must continue working
instances | instance-state
instances | head -5 | instance-terminate
echo "i-12345" | instances
stacks | stack-delete
```

### Mixed Input Sources
```bash
# skim-stdin works with external commented data
$ cat <<EOF | skim-stdin
# Custom headers
vpc-123 production  
vpc-456 staging
EOF
# Output: vpc-123 vpc-456
```

### Performance Impact
- Single regex check `/^#/` per line in awk
- Negligible performance impact
- No additional external processes

### Security Considerations
- Headers contain no sensitive information
- Comment format cannot be exploited for injection
- No additional attack surface introduced

## Future Enhancements

This foundation enables:

1. **Structured Output Formats**
   ```bash
   instances --format json
   instances --format csv
   ```

2. **Column Selection**
   ```bash
   instances --columns instance_id,name,state
   ```

3. **Schema Discovery**
   ```bash
   bma-schema instances  # Show available columns
   ```

4. **Enhanced Tooling**
   ```bash
   instances --filter state=running
   instances --sort name
   ```

## Implementation Approach

### Incremental Rollout Strategy

1. **Start Simple**: Begin with a straightforward `lib/*-functions` file to validate the approach
2. **One File at a Time**: Complete each library file fully before moving to the next
3. **Document Learnings**: Capture insights from the first implementation to guide subsequent work
4. **Improve Guidance**: Create clear instructions for developers/agents working on other files

### Testing Strategy

- **Bats Tests**: Comprehensive test suite using the bats testing framework
- **Backwards Compatibility**: Ensure all existing workflows continue working
- **Performance Testing**: Verify no measurable performance degradation
- **User Acceptance**: Validate improved user experience with headers

## Success Criteria

1.  Zero existing scripts break
2.  New users see helpful headers by default  
3.  Headers disappear automatically in pipes
4.  File output includes headers for reference
5.  `skim-stdin()` works with any commented data
6.  Implementation is simple and maintainable
7.  Performance impact is negligible
8.  Foundation for future enhancements

9. Comprehensive bats test coverage
10. Clear documentation for contributors

## Rejection Criteria

The feature should be rejected if:
- Any existing bash-my-aws workflow breaks
- Performance degrades measurably
- Implementation becomes complex or magical
- Unix philosophy is violated
- User control is insufficient