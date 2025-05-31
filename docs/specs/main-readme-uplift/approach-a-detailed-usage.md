# Detailed Usage Guide

This guide provides comprehensive examples and patterns for using bash-my-aws effectively.

## Table of Contents

- [Command Patterns](#command-patterns)
- [Pipeline Examples](#pipeline-examples)
- [Filtering and Selection](#filtering-and-selection)
- [Advanced Workflows](#advanced-workflows)
- [Shell Integration](#shell-integration)
- [Tips and Tricks](#tips-and-tricks)

## Command Patterns

### Resource Listing Commands

Resource listing commands follow a simple pattern - they're the plural form of the resource:

```bash
instances     # List EC2 instances
stacks        # List CloudFormation stacks  
buckets       # List S3 buckets
keypairs      # List SSH keypairs
images        # List AMIs
volumes       # List EBS volumes
vpcs          # List VPCs
subnets       # List subnets
```

Each returns columnar output perfect for human reading and pipeline processing.

### Resource Action Commands

Action commands follow the pattern `resource-action`:

```bash
instance-terminate    # Terminate instances
instance-stop         # Stop instances
instance-start        # Start instances
instance-ssh          # SSH to instances
instance-ip           # Get instance IPs
instance-tags         # Get instance tags
instance-tag          # Add tags to instances

stack-create          # Create stacks
stack-delete          # Delete stacks
stack-update          # Update stacks
stack-outputs         # Get stack outputs
stack-diff            # Compare stack template changes
```

### Resource Detail Commands

Detail commands extract specific information:

```bash
instance-state        # Get instance state
instance-type         # Get instance type
instance-vpc          # Get instance VPC
instance-az           # Get availability zone
instance-volumes      # Get attached volumes
instance-userdata     # Get user data

stack-status          # Get stack status
stack-resources       # List stack resources
stack-template        # Get stack template
```

## Pipeline Examples

The real power of bash-my-aws comes from chaining commands:

### Basic Pipeline

```bash
# Get IPs of running instances
instances | grep running | instance-ip

# SSH to a specific instance
instances webserver | instance-ssh

# Check all production instance types
instances prod | instance-type
```

### Multi-Step Operations

```bash
# Find instances without proper tags and tag them
instances | instance-tags | grep -v Environment | instance-tag Environment=unknown

# Stop all development instances
instances dev | instance-stop

# Get IPs of instances in a specific VPC
vpcs | grep MyVPC | vpc-instances | instance-ip
```

### Complex Workflows

```bash
# Find orphaned volumes (not attached to any instance)
volumes | grep available | volume-delete

# List instances that aren't in any CloudFormation stack
comm -23 <(instances | cut -f1 | sort) <(stacks | stack-resources | grep AWS::EC2::Instance | cut -f1 | sort)

# Copy tags from one instance to others
instance-tags i-abc123 | grep -E "^(Environment|Team|Owner)" > tags.txt
instances new-cluster | while read instance; do
  cat tags.txt | sed "s/^/$instance\t/" | instance-tag
done
```

## Filtering and Selection

### Built-in Filtering

Most listing commands accept a filter as the first argument:

```bash
instances prod           # Only production instances
stacks website          # Only stacks with 'website' in name
buckets backup          # Only backup buckets
```

### Combining Filters

```bash
# Using bash-my-aws filter + grep
instances prod | grep running

# Multiple grep patterns
instances | grep -E "(prod|staging)" | grep -v terminated
```

### Selecting Specific Resources

```bash
# Select by position
instances | head -5 | instance-terminate    # First 5
instances | tail -3 | instance-stop         # Last 3

# Select by pattern
instances | grep -E "web-[0-9]+" | instance-restart

# Select interactively (requires fzf)
instances | fzf -m | instance-terminate
```

## Advanced Workflows

### Batch Operations

```bash
# Update all instances in an ASG
asgs my-asg | asg-instances | instance-terminate

# Rolling restart
instances webserver | while read instance; do
  echo "Restarting $instance"
  echo $instance | instance-stop
  sleep 30
  echo $instance | instance-start
  sleep 60
done
```

### Monitoring and Alerting

```bash
# Check for stopped instances
if instances | grep -q stopped; then
  echo "Warning: Found stopped instances"
  instances | grep stopped
fi

# Monitor stack creation
stack_name="my-new-stack"
stack-create $stack_name template.yml params.json
while true; do
  status=$(stacks $stack_name | cut -f2)
  echo "Status: $status"
  [[ $status =~ COMPLETE ]] && break
  [[ $status =~ FAILED ]] && exit 1
  sleep 10
done
```

### Cross-Region Operations

```bash
# List instances across all regions
regions | while read region; do
  echo "=== $region ==="
  AWS_DEFAULT_REGION=$region instances
done

# Find AMI in all regions
image_name="my-golden-ami"
regions | while read region; do
  AWS_DEFAULT_REGION=$region images | grep $image_name
done
```

## Shell Integration

### Aliases for Common Operations

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Quick SSH to bastion
alias bastion='instances bastion | head -1 | instance-ssh'

# List production instances
alias prod-instances='instances prod'

# Clean up failed stacks
alias cleanup-stacks='stacks | grep -E "(DELETE_FAILED|ROLLBACK_COMPLETE)" | stack-delete'
```

### Functions for Complex Operations

```bash
# Function to find instances missing a tag
missing-tag() {
  local tag_key=$1
  instances | while read line; do
    instance=$(echo $line | cut -f1)
    if ! instance-tags $instance | grep -q "^$tag_key"; then
      echo $line
    fi
  done
}

# Function to wait for instance to be running
wait-for-instance() {
  local instance=$1
  while true; do
    state=$(echo $instance | instance-state)
    echo "Instance state: $state"
    [[ $state == "running" ]] && break
    sleep 5
  done
}
```

### Integration with Other Tools

```bash
# Use with jq for JSON processing
stack-outputs my-stack | jq -r '.[] | select(.OutputKey=="WebsiteURL") | .OutputValue'

# Use with GNU parallel for speed
instances | parallel -j 10 instance-state {}

# Use with tmux for monitoring
tmux new-window "watch 'instances | grep -v running'"
```

## Tips and Tricks

### Performance Optimization

```bash
# Cache results for repeated operations
instances > /tmp/instances.cache
grep prod /tmp/instances.cache | instance-ip
grep web /tmp/instances.cache | instance-state

# Use process substitution to avoid temporary files
comm -23 <(instances | cut -f1 | sort) <(terminated-instances | sort)
```

### Error Handling

```bash
# Check command success
if instances prod | instance-stop; then
  echo "All production instances stopped"
else
  echo "Failed to stop some instances"
fi

# Defensive scripting
instance_id=$(instances myapp | head -1 | cut -f1)
if [[ -z $instance_id ]]; then
  echo "Error: No instance found"
  exit 1
fi
echo $instance_id | instance-terminate
```

### Debugging

```bash
# See what commands are being run
set -x
instances prod | instance-ip
set +x

# Check function definition
bma type instance-ip

# Test with dry-run (where supported)
AWS_CLI_DRY_RUN=true instance-terminate i-abc123
```

### Output Formatting

```bash
# Get specific columns
instances | awk '{print $1, $5}'  # ID and name only

# Format as CSV
instances | tr -s ' ' ',' > instances.csv

# Pretty JSON output
stack-outputs my-stack | jq '.'

# Custom formatting
instances | while read id ami type state name _; do
  printf "%-20s %-10s %s\n" "$name" "$state" "$id"
done
```

### Safety Patterns

```bash
# Always preview before destructive operations
instances old | tee /tmp/to-delete.txt | less
cat /tmp/to-delete.txt | instance-terminate

# Use confirmation prompts
instances | grep -v prod | instance-terminate  # Will prompt

# Backup before changes
stack-template my-stack > my-stack-backup.json
stack-update my-stack new-template.json
```

## Common Use Cases

### Development Workflow

```bash
# Morning startup
instances dev | instance-start
instances dev | instance-ip

# End of day shutdown  
instances dev | instance-stop

# Weekend cleanup
instances | grep -E "temp|test" | instance-terminate
```

### Production Operations

```bash
# Health check
instances prod | instance-state | grep -v running

# Deployment
new_ami=$(images | grep "release-" | head -1 | cut -f1)
instances blue | instance-ami $new_ami
instances blue | instance-restart

# Disaster recovery
snapshots | grep $(date +%Y-%m-%d) | snapshot-restore
```

### Cost Optimization

```bash
# Find large instances
instances | instance-type | grep -E "x1|p3|i3"

# Find unattached volumes
volumes | grep available

# Find old snapshots
snapshots | awk '$3 < "'$(date -d '30 days ago' '+%Y-%m-%d')'"'
```

---

For more examples and patterns, see the [Command Reference](https://bash-my-aws.org/command-reference/) and join our [community discussions](https://github.com/bash-my-aws/bash-my-aws/discussions).