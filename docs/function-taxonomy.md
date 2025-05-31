# bash-my-aws Function Taxonomy

This document provides a comprehensive classification of function types in bash-my-aws, their characteristics, naming conventions, and usage patterns.

## Function Classification Overview

bash-my-aws functions are categorized into **three primary types** based on their purpose and behavior:

| Type | Purpose | Naming Pattern | Input | Output | Headers |
|------|---------|----------------|-------|--------|---------|
| **Query** | List resources | `resources()` (plural) | Optional filters | Tabular data | Always |
| **Detail** | Resource attributes | `resource-attribute()` | Resource IDs | Specific data | Sometimes |
| **Action** | Modify resources | `resource-action()` | Varies | Status/results | Rarely |

## 1. Query Functions (Resource Listing)

**Purpose:** List AWS resources with their key identifying attributes and metadata.

### Characteristics
- **Naming:** Plural resource name (e.g., `instances`, `stacks`, `vpcs`, `buckets`)
- **Input:** Optional filter arguments
- **Output:** Tabular data with aligned columns
- **Headers:** Always include column headers via `__bma_output_header`
- **Filtering:** Support grep-style filtering on output
- **Sorting:** Typically sorted by meaningful field (launch time, name, etc.)

### Examples
```bash
instances              # List all EC2 instances
instances web          # Filter instances containing "web"
stacks                 # List all CloudFormation stacks
buckets                # List all S3 buckets
vpcs                   # List all VPCs
```

### Standard Output Format
```
# INSTANCE_ID           AMI_ID        TYPE        STATE      NAME           LAUNCH_TIME
i-1234567890abcdef0    ami-12345678  t3.micro    running    web-server     2024-01-15T10:30:00
i-0987654321fedcba0    ami-87654321  t3.small    stopped    db-server      2024-01-14T15:45:00
```

### Implementation Pattern
- Use `skim-stdin` for input handling
- Include `__bma_output_header` with column names
- Apply filters with `grep -E -- "$filters"`
- Sort output appropriately
- Format with `columnise`

## 2. Detail Functions (Resource Attributes)

**Purpose:** Provide specific attributes or detailed information about identified resources.

### Characteristics
- **Naming:** Singular resource name + attribute (e.g., `instance-state`, `stack-outputs`)
- **Input:** Resource IDs (via arguments or stdin)
- **Output:** Specific attribute values or structured data
- **Headers:** Include when output is tabular
- **Scope:** Single attribute or related group of attributes

### Examples
```bash
instance-state i-123456789        # Get instance state
instance-iam-role i-123456789     # Get instance IAM role
stack-outputs my-stack            # Get stack outputs
bucket-size my-bucket             # Get bucket size
vpc-endpoints vpc-123456789       # Get VPC endpoints
```

### Output Formats
**Simple Values:**
```bash
$ instance-state i-1234567890abcdef0
running
```

**Tabular Data:**
```
# OUTPUT_KEY             OUTPUT_VALUE                    DESCRIPTION
DatabaseEndpoint        mydb.123456789.us-east-1.rds   RDS endpoint
DatabasePort            3306                            Database port
```

### Implementation Pattern
- Validate required resource IDs
- Use `skim-stdin` when accepting piped input
- Include headers for tabular output
- Handle missing or invalid resources gracefully

## 3. Action Functions (Resource Operations)

**Purpose:** Perform operations that create, modify, or delete AWS resources.

### Characteristics
- **Naming:** Singular resource name + action (e.g., `instance-terminate`, `stack-create`)
- **Input:** Resource IDs and operation parameters
- **Output:** Operation status, results, or confirmation
- **Headers:** Rarely needed (not listing data)
- **Side Effects:** Modify AWS resources

### Examples
```bash
instance-terminate i-123456789           # Terminate instance
instance-start i-123456789               # Start instance
stack-create my-stack template.yml       # Create stack
stack-delete my-stack                    # Delete stack
asg-suspend my-asg                       # Suspend auto scaling
```

### Output Formats
**Status Messages:**
```bash
$ instance-terminate i-1234567890abcdef0
Terminating instance i-1234567890abcdef0
```

**Confirmation Prompts:**
```bash
$ stack-delete my-stack
You are about to delete stack: my-stack
Type 'yes' to continue: 
```

### Implementation Pattern
- Validate required parameters
- Include safety confirmations for destructive operations
- Provide clear status feedback
- Handle errors gracefully with meaningful messages

## Function Naming Conventions

### Resource Name Mapping
| AWS Service | bash-my-aws Prefix | Examples |
|-------------|-------------------|----------|
| EC2 Instances | `instance` | `instances`, `instance-state` |
| Auto Scaling Groups | `asg` | `asgs`, `asg-suspend` |
| CloudFormation | `stack` | `stacks`, `stack-create` |
| VPC | `vpc` | `vpcs`, `vpc-subnets` |
| S3 | `bucket` | `buckets`, `bucket-size` |
| ELB | `elb` | `elbs`, `elb-instances` |
| RDS | `rds` | `rds-instances`, `rds-snapshots` |

### Naming Rules
1. **Query Functions:** Use plural resource name
2. **Detail Functions:** Use singular resource name + descriptive attribute
3. **Action Functions:** Use singular resource name + verb
4. **Compound Resources:** Use clear, unambiguous names (e.g., `vpc-subnets`, `elb-instances`)

## Input/Output Patterns

### Input Handling Standards
- **Pipe Support:** Use `skim-stdin` to accept both piped input and arguments
- **Filter Support:** Use `__bma_read_filters` for grep-style filtering
- **Validation:** Check for required parameters and provide usage help

### Output Formatting Standards
- **Headers:** Use `__bma_output_header` with space-separated column names
- **Alignment:** Use `columnise` for tabular output
- **Sorting:** Sort by meaningful fields (time, name, ID)
- **Consistency:** Maintain consistent column ordering across related functions

### Error Handling Standards
- **Usage Help:** Use `__bma_usage` for parameter errors
- **Error Messages:** Use `__bma_error` for operational errors
- **Exit Codes:** Return non-zero for failures

## Function Discovery and Organization

### Library Organization
Functions are organized by AWS service in `lib/` directory:
- `lib/instance-functions` - EC2 instance operations
- `lib/stack-functions` - CloudFormation operations
- `lib/vpc-functions` - VPC networking operations
- `lib/s3-functions` - S3 bucket operations
- `lib/asg-functions` - Auto Scaling operations

### Function Templates
See `docs/function-templates/` for copy-paste templates:
- `query-function-template.sh` - For listing resources
- `detail-function-template.sh` - For resource attributes
- `action-function-template.sh` - For resource operations

## Best Practices

### Design Principles
1. **Composability:** Functions should work well in pipes
2. **Consistency:** Follow established patterns and naming
3. **Simplicity:** Prefer simple, focused functions over complex ones
4. **Discoverability:** Use clear, predictable names
5. **Reliability:** Handle errors gracefully and provide useful feedback

### Implementation Guidelines
1. **Test Early:** Create test cases for new functions
2. **Document Examples:** Include usage examples in function comments
3. **Handle Edge Cases:** Consider empty results, missing resources, etc.
4. **Performance:** Optimize AWS CLI queries for efficiency
5. **Backward Compatibility:** Maintain existing function signatures

## Related Documentation
- [Developer Guide](developer-guide.md) - Implementation details and patterns
- [Function Templates](function-templates/) - Copy-paste ready templates
- [Implementing Headers Guide](implementing-headers-guide.md) - Header implementation
- [CONVENTIONS.md](../CONVENTIONS.md) - Code style and patterns