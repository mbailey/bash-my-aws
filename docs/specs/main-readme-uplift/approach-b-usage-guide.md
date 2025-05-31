# Bash-my-AWS Usage Guide

This guide provides detailed examples and patterns for using bash-my-aws effectively.

## Table of Contents
- [Basic Patterns](#basic-patterns)
- [Advanced Piping](#advanced-piping)
- [Resource Filtering](#resource-filtering)
- [Batch Operations](#batch-operations)
- [Safety Features](#safety-features)
- [Troubleshooting](#troubleshooting)

## Basic Patterns

### Listing Resources

All resource types follow a consistent pattern - use the plural form:

```bash
instances     # List all EC2 instances
stacks        # List all CloudFormation stacks
buckets       # List all S3 buckets
keypairs      # List all SSH keypairs
images        # List all AMIs
vpcs          # List all VPCs
```

### Filtering Resources

Each listing command accepts a filter argument:

```bash
instances prod          # List instances with 'prod' in any field
stacks test            # List stacks with 'test' in the name
buckets backup         # List buckets with 'backup' in the name
```

### Getting Resource Details

Use hyphenated commands to get specific information:

```bash
instance-state i-12345678      # Get state of specific instance
stack-outputs my-stack         # Get CloudFormation outputs
instance-ip i-12345678         # Get public/private IPs
```

## Advanced Piping

### The Power of First Token

Commands extract the first token from each line as the resource ID:

```bash
# These all work the same way
instances | instance-ip
instances | grep prod | instance-ip
instances | awk '{print $1, $5}' | instance-ip
```

### Multi-Stage Pipelines

Build complex operations step by step:

```bash
# Find expensive instances and check their usage
instances | grep -E "m5.x?large" | instance-tags | grep -i owner

# Stop all instances in a specific VPC
vpcs | grep vpc-12345 | vpc-instances | instance-stop
```

### Combining with Unix Tools

```bash
# Count instances by type
instances | awk '{print $3}' | sort | uniq -c

# Find instances launched more than 30 days ago
instances | awk -v date="$(date -d '30 days ago' +%Y-%m-%d)" '$6 < date'

# Generate CSV report
instances | awk -F'\t' '{print $1","$4","$5}' > instances.csv
```

## Resource Filtering

### Built-in Filtering

Prefer built-in filtering for better column alignment:

```bash
# Good - columns align properly
instances web

# Less optimal - columns might misalign
instances | grep web
```

### Complex Filtering

For complex filters, use grep with the listing command:

```bash
# Find running instances NOT in production
instances | grep running | grep -v prod

# Find stacks created in 2024
stacks | grep "2024-"
```

## Batch Operations

### Safe Batch Operations

Most destructive commands ask for confirmation:

```bash
# Delete multiple stacks
stacks test | stack-delete
# Prompts: "You are about to delete the following stacks..."

# Terminate instances
instances | grep terminated | instance-terminate
# Prompts for confirmation
```

### Bypassing Confirmations

For automation, use standard unix patterns:

```bash
# Auto-confirm with yes
yes | instances test | instance-terminate

# Or use echo
echo "y" | stacks old | stack-delete
```

### Parallel Operations

Use xargs for parallel execution:

```bash
# Stop instances in parallel
instances test | xargs -P 4 -n 1 instance-stop

# Tag multiple resources
instances prod | xargs -P 10 -n 1 -I {} instance-tag {} Environment=Production
```

## Safety Features

### Dry Run Support

Many commands support dry-run mode:

```bash
# See what would be terminated
instances test | instance-terminate --dry-run

# Preview stack deletion
stack-delete my-stack --dry-run
```

### Confirmation Prompts

Destructive operations always confirm:
- instance-terminate
- stack-delete
- bucket-remove
- keypair-delete

### Resource Protection

Enable termination protection:

```bash
# Protect production instances
instances prod | instance-termination-protection-enable

# Check protection status
instances | instance-termination-protection
```

## Troubleshooting

### Debug Mode

See actual AWS CLI commands:

```bash
# Enable debug output
export BMA_DEBUG=true
instances

# Or for a single command
BMA_DEBUG=true stack-create my-stack template.yml
```

### Common Issues

**No output from commands**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check region
echo $AWS_DEFAULT_REGION
```

**Completion not working**
```bash
# Ensure completion is sourced
source ~/.bash-my-aws/bash_completion.sh

# For zsh, ensure compatibility mode
autoload -U +X bashcompinit && bashcompinit
```

**Column alignment issues**
```bash
# Force column alignment
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=false

# Or use built-in filtering
instances prod  # Instead of: instances | grep prod
```

## Environment Variables

### BMA_HEADERS
Control header display in output:

```bash
export BMA_HEADERS=always   # Always show headers (default)
export BMA_HEADERS=auto     # Show in terminal, hide in pipes  
export BMA_HEADERS=never    # Never show headers
```

### Custom Configuration

```bash
# Set custom home directory
export BMA_HOME=/opt/bash-my-aws

# Disable color output
export NO_COLOR=1

# Custom AWS profile
export AWS_PROFILE=production
```

## Real-World Examples

### Daily Operations

```bash
# Morning health check
instances | instance-state | grep -v running

# Find unused resources
images | grep -v ami-

# Check stack drift
stacks | while read stack rest; do 
  echo "Checking $stack..."
  stack-diff "$stack"
done
```

### Cost Optimization

```bash
# Find stopped instances (potential waste)
instances | grep stopped | instance-launch-time | sort -k2

# Find old snapshots
snapshots | awk -v date="$(date -d '90 days ago' +%Y-%m-%d)" '$3 < date'

# List unused elastic IPs
eips | grep -v associated
```

### Security Audits

```bash
# Find instances without proper tags
instances | while read id rest; do
  tags=$(instance-tags "$id")
  [[ -z "$tags" ]] && echo "Untagged: $id"
done

# Check security group usage
security-groups | while read sg rest; do
  echo "=== $sg ==="
  security-group-instances "$sg"
done
```

## Tips and Tricks

### Command Aliases

Create your own shortcuts:

```bash
# Add to ~/.bashrc
alias running='instances | grep running'
alias stop-test='instances test | instance-stop'
alias clean-stacks='stacks | grep -E "test|temp" | stack-delete'
```

### Function Composition

Build reusable functions:

```bash
# Function to find instances by tag
find-by-tag() {
  local tag_key="$1"
  local tag_value="$2"
  instances | while read instance rest; do
    instance-tags "$instance" | grep -q "${tag_key}.*${tag_value}" && echo "$instance $rest"
  done
}

# Usage
find-by-tag Environment Production
```

### Integration with Other Tools

```bash
# Send alerts
instances | grep stopped | mail -s "Stopped Instances" ops@example.com

# Generate documentation  
instances | pandoc -t markdown > instances.md

# Create Jira tickets
stacks | grep FAILED | while read stack rest; do
  jira create -p OPS -t Bug -s "Stack failed: $stack"
done
```

Remember: The power of bash-my-aws comes from its simplicity and composability. Start with basic commands and gradually build more complex pipelines as you become comfortable with the patterns.