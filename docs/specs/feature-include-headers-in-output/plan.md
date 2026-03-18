# Implementation Plan: Include Headers in Output

## Overview

This plan outlines the phased implementation of comment-based headers for bash-my-aws resource listing functions. The approach prioritizes backwards compatibility while delivering immediate user value.

## Implementation Strategy

### Phase-Based Rollout
1. **Phase 1**: Core infrastructure (1-2 weeks)
2. **Phase 2**: Pilot implementation with simple library file (1-2 weeks)  
3. **Phase 3**: One file at a time rollout (3-5 weeks)
4. **Phase 4**: Future enhancements (ongoing)

### Risk Mitigation
- Comprehensive bats testing framework
- Start with simplest library file to validate approach
- One `lib/*-functions` file at a time
- Document learnings from pilot implementation
- User feedback collection at each phase
- Performance monitoring throughout

## Phase 1: Core Infrastructure (Weeks 1-2)

### 1.1 Enhanced skim-stdin Function

**File**: `lib/shared-functions`

**Current Implementation**:
```bash
skim-stdin() {
  local skimmed_stdin="$([[ -t 0 ]] || awk 'ORS=" " { print $1 }')"
  printf -- '%s %s' "$*" "$skimmed_stdin" | awk '{$1=$1;print}'
}
```

**New Implementation**:
```bash
skim-stdin() {
  # Append first token from each non-comment line of STDIN to argument list
  # Implementation of `pipe-skimming` pattern with comment support
  
  local skimmed_stdin="$([[ -t 0 ]] || awk '
    /^#/ { next }  # Skip comment lines (headers, etc.)
    { print $1 }   # Extract first field from data lines
  ' ORS=" ")"
  
  printf -- '%s %s' "$*" "$skimmed_stdin" |
    awk '{$1=$1;print}'  # trim leading/trailing spaces
}
```

**Testing Requirements**:
```bash
# Test 1: Backwards compatibility
echo -e "i-12345\ni-67890" | skim-stdin
# Expected: "i-12345 i-67890"

# Test 2: Comment skipping
echo -e "# HEADER\ni-12345\ni-67890" | skim-stdin  
# Expected: "i-12345 i-67890"

# Test 3: Mixed input
echo -e "# Comment\ni-12345\n# Another comment\ni-67890" | skim-stdin
# Expected: "i-12345 i-67890"

# Test 4: Empty input
echo "" | skim-stdin
# Expected: ""

# Test 5: Only comments
echo -e "# HEADER\n# Another comment" | skim-stdin
# Expected: ""
```

### 1.2 Header Output Helper Function

**File**: `lib/shared-functions`

**Implementation**:
```bash
__bma_output_header() {
  # Output header comment based on BMA_HEADERS setting
  # Usage: __bma_output_header "COL1	COL2	COL3"
  
  local header="$1"
  [[ -z "$header" ]] && return 1
  
  # Determine if headers should be shown
  local show_headers="false"
  case "${BMA_HEADERS:-auto}" in
    always) 
      show_headers="true" 
      ;;
    never)  
      show_headers="false" 
      ;;
    auto)   
      # Show headers when output goes to terminal
      [[ -t 1 ]] && show_headers="true"
      ;;
    *)
      # Invalid value, default to auto behavior
      [[ -t 1 ]] && show_headers="true"
      ;;
  esac
  
  [[ "$show_headers" == "true" ]] && echo "# $header"
}
```

**Testing Requirements**:
```bash
# Test 1: Auto mode (terminal)
BMA_HEADERS=auto __bma_output_header "A	B	C"
# Expected: "# A	B	C" (if terminal)

# Test 2: Auto mode (pipe)
BMA_HEADERS=auto __bma_output_header "A	B	C" | cat
# Expected: no output

# Test 3: Always mode
BMA_HEADERS=always __bma_output_header "A	B	C" | cat
# Expected: "# A	B	C"

# Test 4: Never mode
BMA_HEADERS=never __bma_output_header "A	B	C"
# Expected: no output

# Test 5: Empty header
__bma_output_header ""
# Expected: no output (return 1)
```

### 1.3 Documentation Updates

**Files to Update**:
- `README.md`: Add BMA_HEADERS environment variable documentation
- `CONVENTIONS.md`: Add header implementation guidelines
- `docs/pipe-skimming.md`: Update with comment support

**Content**:
```markdown
## Environment Variables

### BMA_HEADERS
Controls header output for resource listing functions.

- `auto` (default): Show headers in terminal, hide in pipes
- `always`: Always show headers
- `never`: Never show headers

Examples:
```bash
export BMA_HEADERS=auto    # Default
export BMA_HEADERS=always  # Force headers everywhere
export BMA_HEADERS=never   # Suppress all headers
```

### 1.4 Comprehensive Bats Testing Suite

**File**: `test/headers.bats`

```bash
#!/usr/bin/env bats

load test_helper

setup() {
  source lib/shared-functions
}

@test "skim-stdin backwards compatibility" {
  result=$(echo -e "i-12345\ni-67890" | skim-stdin)
  [ "$result" = "i-12345 i-67890" ]
}

@test "skim-stdin skips comment lines" {
  result=$(echo -e "# HEADER\ni-12345\ni-67890" | skim-stdin)
  [ "$result" = "i-12345 i-67890" ]
}

@test "skim-stdin handles mixed comments and data" {
  result=$(echo -e "# Comment\ni-12345\n# Another comment\ni-67890" | skim-stdin)
  [ "$result" = "i-12345 i-67890" ]
}

@test "skim-stdin handles empty input" {
  result=$(echo "" | skim-stdin)
  [ "$result" = "" ]
}

@test "__bma_output_header always mode" {
  result=$(BMA_HEADERS=always __bma_output_header "TEST")
  [ "$result" = "# TEST" ]
}

@test "__bma_output_header never mode" {
  result=$(BMA_HEADERS=never __bma_output_header "TEST")
  [ "$result" = "" ]
}

@test "__bma_output_header handles empty input" {
  run __bma_output_header ""
  [ "$status" -eq 1 ]
}
```

## Phase 2: Pilot Implementation (Weeks 3-4)

### 2.1 Target Library Selection

**Objective**: Choose the simplest `lib/*-functions` file to validate the implementation approach.

**Candidates** (in order of simplicity):
1. `lib/keypair-functions` - Simple key-value output
2. `lib/region-functions` - Minimal AWS calls  
3. `lib/sts-functions` - Basic account information
4. `lib/kms-functions` - Straightforward resource listing

**Recommended Start**: `lib/keypair-functions`
- Simple functions like `keypairs()`
- Clear, predictable output format
- Limited complexity for validation

### 2.2 Pilot Implementation Example

**File**: `lib/keypair-functions`

```bash
keypairs() {
  # List EC2 SSH KeyPairs
  #
  # USAGE: keypairs
  
  local keypair_names=$(skim-stdin)
  local filters=$(__bma_read_filters $@)
  
  # Output header comment  
  __bma_output_header "KEYPAIR_NAME	FINGERPRINT"
  
  # Existing implementation unchanged
  aws ec2 describe-key-pairs \
    ${keypair_names/#/'--key-names '} \
    --output text \
    --query "KeyPairs[].[KeyName,KeyFingerprint]" |
  grep -E -- "$filters" |
  columnise
}
```

### 2.3 Pilot Testing Suite

**File**: `test/keypair-headers.bats`

```bash
#!/usr/bin/env bats

load test_helper

setup() {
  source lib/shared-functions
  source lib/keypair-functions
}

@test "keypairs shows header in terminal" {
  # Mock terminal output
  BMA_HEADERS=always run keypairs
  [[ "${lines[0]}" =~ ^#.*KEYPAIR_NAME ]]
}

@test "keypairs piping still works" {
  # Test that skim-stdin ignores headers
  result=$(echo -e "# KEYPAIR_NAME\tFINGERPRINT\ntest-key\t12:34:56" | skim-stdin)
  [ "$result" = "test-key" ]
}

@test "keypairs backwards compatibility" {
  # Ensure existing workflows don't break
  BMA_HEADERS=never run keypairs
  [[ ! "${lines[0]}" =~ ^# ]]
}
```

### 2.4 Document Learnings

After successful pilot implementation, create detailed documentation:

**File**: `docs/implementing-headers-guide.md`

Content should include:
- Step-by-step implementation process
- Common gotchas and solutions  
- Testing patterns that work
- Code review checklist
- Performance considerations
- Backwards compatibility verification steps

This documentation will guide implementation of remaining library files.

## Phase 3: One File at a Time Rollout (Weeks 5-8)

### 3.1 Implementation Order

Following the pilot success with `lib/keypair-functions`, implement headers one library file at a time:

**Priority Order**:
1. `lib/region-functions` - Simple, minimal complexity
2. `lib/sts-functions` - Basic account info  
3. `lib/s3-functions` - High-value bucket operations
4. `lib/vpc-functions` - Core networking functions
5. `lib/instance-functions` - Most complex, highest impact
6. `lib/stack-functions` - CloudFormation operations
7. `lib/asg-functions` - Auto Scaling operations
8. Remaining files as needed

### 3.2 Per-File Implementation Process

For each `lib/*-functions` file:

1. **Analysis Phase**
   - Identify all listing functions (functions outputting tabular data)
   - Define appropriate headers for each function
   - Review function complexity and edge cases

2. **Implementation Phase**  
   - Add `__bma_output_header` calls to listing functions
   - Follow the pilot implementation pattern
   - Maintain existing function logic unchanged

3. **Testing Phase**
   - Create `test/{library}-headers.bats` file
   - Test backwards compatibility
   - Test header output in different modes
   - Validate skim-stdin behavior

4. **Documentation Phase**
   - Update function comments with header information
   - Add to implementation guide based on learnings

### 3.3 Key Function Headers

**Core Resource Listing Functions**:
```bash
# lib/instance-functions
instances: "INSTANCE_ID	AMI_ID	TYPE	STATE	NAME	LAUNCH_TIME	AZ	VPC"
instance-dns: "INSTANCE_ID	PRIVATE_DNS	PUBLIC_DNS"
instance-ip: "INSTANCE_ID	PRIVATE_IP	PUBLIC_IP"

# lib/stack-functions  
stacks: "STACK_NAME	STATUS	CREATION_TIME	LAST_UPDATED	NESTED"

# lib/s3-functions
buckets: "BUCKET_NAME	CREATION_DATE"
bucket-size: "BUCKET_NAME	SIZE_STANDARD	SIZE_IA	SIZE_GLACIER"

# lib/vpc-functions
vpcs: "VPC_ID	DEFAULT	NAME	CIDR	STACK	VERSION"
subnets: "SUBNET_ID	VPC_ID	AZ	CIDR	NAME"

# lib/asg-functions
asgs: "ASG_NAME	NAME_TAG	CREATED_TIME	AVAILABILITY_ZONES"
```

### 3.4 Quality Assurance

**Automated Testing**:
```bash
# Test all functions with headers
for func in instances stacks buckets vpcs asgs subnets; do
  echo "Testing $func..."
  
  # Test header presence in always mode
  BMA_HEADERS=always $func 2>/dev/null | head -1 | grep -q "^#" || {
    echo "FAIL: $func missing header in always mode"
  }
  
  # Test no headers in never mode
  BMA_HEADERS=never $func 2>/dev/null | head -1 | grep -q "^#" && {
    echo "FAIL: $func shows header in never mode"
  }
done
```

**Manual Testing Checklist**:
- [ ] All functions show headers in terminal
- [ ] No headers appear in pipes by default
- [ ] BMA_HEADERS environment variable works
- [ ] Existing scripts continue working
- [ ] Performance is acceptable
- [ ] Tab completion still works
- [ ] Documentation is accurate

## Phase 4: Future Enhancements (Ongoing)

### 4.1 Advanced Output Formats

**JSON Output Support**:
```bash
instances-json() {
  BMA_OUTPUT_FORMAT=json instances "$@"
}

# Or via environment
BMA_OUTPUT_FORMAT=json instances
```

### 4.2 Schema Discovery

**Schema Command**:
```bash
bma-schema() {
  local func="$1"
  case "$func" in
    instances) echo "instance_id ami_id type state name launch_time az vpc" ;;
    stacks) echo "stack_name status creation_time last_updated nested" ;;
    *) echo "Unknown function: $func" >&2; return 1 ;;
  esac
}
```

### 4.3 Column Selection

**Column Filtering**:
```bash
instances --columns instance_id,name,state
```

## Risk Management

### Backwards Compatibility Risks

**Risk**: Existing scripts break due to skim-stdin changes
**Mitigation**: 
- Comprehensive test suite covering all known usage patterns
- Gradual rollout with monitoring
- Quick rollback plan

**Risk**: Performance degradation
**Mitigation**:
- Benchmark testing before/after
- Single regex check has negligible overhead
- Monitor production usage

### User Adoption Risks

**Risk**: Users don't discover new headers
**Mitigation**:
- Update documentation prominently
- Blog post about new feature
- Social media announcement

**Risk**: Headers interfere with existing workflows
**Mitigation**:
- BMA_HEADERS=never provides escape hatch
- Default behavior (auto) is conservative

## Success Metrics

### Technical Metrics
- [ ] Zero existing workflow breakage
- [ ] <1ms performance impact per function call
- [ ] 100% test coverage for new functionality

### User Metrics  
- [ ] Positive user feedback on headers
- [ ] No complaints about broken workflows
- [ ] Documentation clarity confirmed

### Quality Metrics
- [ ] Code review approval
- [ ] No regressions in CI/CD
- [ ] Successful deployment to production

## Rollback Plan

If issues arise:

1. **Immediate**: Set `BMA_HEADERS=never` in documentation
2. **Short-term**: Revert skim-stdin changes
3. **Long-term**: Redesign approach based on lessons learned

The comment-based approach minimizes rollback complexity since headers are purely additive.

## Timeline Summary

| Week | Phase | Deliverables |
|------|-------|-------------|
| 1-2  | Infrastructure | skim-stdin, header helper, bats tests |
| 3-4  | Pilot Implementation | lib/keypair-functions, learnings documentation |
| 5-6  | One-file rollout 1 | lib/region-functions, lib/sts-functions |
| 7-8  | One-file rollout 2 | lib/s3-functions, lib/vpc-functions |
| 9-10 | High-impact files | lib/instance-functions, lib/stack-functions |
| 11+  | Complete & enhance | Remaining files, JSON output, schema discovery |

This plan delivers immediate value while maintaining the elegance and reliability that bash-my-aws users expect. The one-file-at-a-time approach ensures thorough validation and allows for iterative improvement of the implementation process based on learnings from each library file.