# Advanced Usage Guide

This guide covers advanced bash-my-aws techniques for power users.

## Advanced Piping Patterns

### Multi-Stage Pipelines

Chain multiple commands for complex operations:

```bash
# Find instances in a specific VPC and get their security groups
$ vpcs | grep prod | vpc-instances | instance-security-groups

# Get all running instances across multiple regions
$ for region in $(regions); do 
    export AWS_DEFAULT_REGION=$region
    instances | grep running | sed "s/^/$region /"
  done

# Find unutilized volumes
$ volumes | grep available | volume-delete --dry-run
```

### Conditional Operations

Use bash conditionals with bash-my-aws commands:

```bash
# Only terminate if instance count exceeds threshold
[[ $(instances test | wc -l) -gt 5 ]] && instances test | head -3 | instance-terminate

# Check stack status before updating
stack_status=$(stacks my-app | awk '{print $2}')
[[ "$stack_status" == "CREATE_COMPLETE" ]] && stack-update my-app template.yml
```

### Parallel Processing

Process resources in parallel for speed:

```bash
# Check multiple instances simultaneously
instances | while read instance_id _; do
  (instance-state $instance_id &)
done | wait

# Parallel stack deletion
stacks | grep DELETE_FAILED | xargs -P 4 -I {} bash -c 'stack-delete {}'
```

## Complex Filtering

### Regular Expressions

Most listing commands support regex filtering:

```bash
# Find instances with names matching pattern
instances '^(web|app)-prod-[0-9]+$'

# Stacks created in 2023
stacks | grep '2023-'

# Buckets with specific naming convention
buckets '^[a-z]+-backup-[0-9]{8}$'
```

### JQ Integration

Combine with jq for advanced JSON processing:

```bash
# Get instance details as JSON
aws ec2 describe-instances --instance-ids $(instances app | awk '{print $1}' | tr '\n' ' ') | 
  jq '.Reservations[].Instances[] | {id: .InstanceId, ip: .PrivateIpAddress, state: .State.Name}'

# Stack outputs as JSON
stack-outputs my-stack | jq -R 'split("\t") | {(.[0]): .[1]}' | jq -s add
```

## Scripting with bash-my-aws

### Error Handling

Build robust scripts:

```bash
#!/bin/bash
set -euo pipefail

# Load bash-my-aws
source ~/.bash-my-aws/aliases

# Function with error handling
deploy_stack() {
  local stack_name=$1
  local template=$2
  
  if ! stacks | grep -q "^$stack_name"; then
    echo "Creating stack: $stack_name"
    stack-create "$stack_name" "$template" || {
      echo "Stack creation failed"
      return 1
    }
  else
    echo "Updating stack: $stack_name"
    stack-update "$stack_name" "$template"
  fi
  
  # Wait for completion
  while true; do
    status=$(stacks "$stack_name" | awk '{print $2}')
    case "$status" in
      *COMPLETE) echo "Stack operation completed"; break ;;
      *FAILED) echo "Stack operation failed"; return 1 ;;
      *) echo "Waiting... ($status)"; sleep 10 ;;
    esac
  done
}
```

### Batch Operations

Process multiple resources efficiently:

```bash
# Backup all databases
backup_all_databases() {
  local date=$(date +%Y%m%d)
  
  rds-instances | while read db_id _; do
    echo "Backing up $db_id"
    aws rds create-db-snapshot \
      --db-instance-identifier "$db_id" \
      --db-snapshot-identifier "$db_id-backup-$date"
  done
}

# Tag resources in bulk
tag_resources() {
  local tag_key=$1
  local tag_value=$2
  shift 2
  
  for resource in "$@"; do
    aws ec2 create-tags \
      --resources "$resource" \
      --tags "Key=$tag_key,Value=$tag_value"
  done
}

# Usage
instances prod | awk '{print $1}' | xargs tag_resources Environment Production
```

## Custom Functions

### Extending bash-my-aws

Create your own functions:

```bash
# ~/.bash-my-aws-custom

# List instances with their costs (requires Cost Explorer API)
instance-costs() {
  local instance_ids=$(instances "$@" | awk '{print $1}')
  
  for id in $instance_ids; do
    local instance_type=$(instance-type $id)
    local hourly_cost=$(aws pricing get-products \
      --service-code AmazonEC2 \
      --filters "Type=TERM_MATCH,Field=instanceType,Value=$instance_type" \
      --query 'PriceList[0]' | jq -r '.terms.OnDemand[].priceDimensions[].pricePerUnit.USD' | head -1)
    
    echo "$id $instance_type \$$hourly_cost/hour"
  done
}

# Find orphaned snapshots
orphaned-snapshots() {
  local all_snapshots=$(aws ec2 describe-snapshots --owner-ids self --query 'Snapshots[].SnapshotId' --output text)
  local all_volumes=$(volumes | awk '{print $1}')
  
  for snapshot in $all_snapshots; do
    local volume_id=$(aws ec2 describe-snapshots --snapshot-ids $snapshot --query 'Snapshots[0].VolumeId' --output text)
    if ! echo "$all_volumes" | grep -q "$volume_id"; then
      echo "$snapshot (volume: $volume_id - NOT FOUND)"
    fi
  done
}

# Source custom functions
source ~/.bash-my-aws-custom
```

## Performance Tips

### 1. Use Native Filtering

Filter at the source when possible:

```bash
# Good - filters at AWS API level
instances --filters "Name=instance-state-name,Values=running"

# Less efficient - filters after retrieval
instances | grep running
```

### 2. Cache Repeated Calls

For scripts that make repeated calls:

```bash
# Cache instance list for script duration
INSTANCE_CACHE=$(instances)

# Use cache
echo "$INSTANCE_CACHE" | grep prod
echo "$INSTANCE_CACHE" | wc -l
```

### 3. Minimize API Calls

Batch operations when possible:

```bash
# Instead of multiple calls
for i in i-123 i-456 i-789; do
  instance-terminate $i
done

# Use single call
instance-terminate i-123 i-456 i-789
```

## Integration Examples

### CI/CD Pipeline

```bash
#!/bin/bash
# deploy.sh - CI/CD deployment script

source ~/.bash-my-aws/aliases

# Configuration
STACK_NAME="myapp-${ENVIRONMENT}"
TEMPLATE="cloudformation/app.yml"

# Check if stack exists
if stacks | grep -q "^${STACK_NAME}"; then
  echo "Updating existing stack"
  stack-update "${STACK_NAME}" "${TEMPLATE}"
else
  echo "Creating new stack"
  stack-create "${STACK_NAME}" "${TEMPLATE}"
fi

# Wait for completion
stack-wait "${STACK_NAME}"

# Get outputs
LOAD_BALANCER_URL=$(stack-outputs "${STACK_NAME}" | grep LoadBalancerURL | awk '{print $2}')
echo "Application deployed to: ${LOAD_BALANCER_URL}"
```

### Monitoring Script

```bash
#!/bin/bash
# monitor.sh - Check instance health

source ~/.bash-my-aws/aliases

# Check all production instances
instances prod | while read instance_id _ _ state name _; do
  if [[ "$state" != "running" ]]; then
    echo "ALERT: Instance $name ($instance_id) is $state"
    # Send notification
    aws sns publish \
      --topic-arn "$SNS_TOPIC" \
      --message "Instance $name is not running"
  fi
done
```

## Tips and Tricks

### 1. Aliases for Common Patterns

```bash
# Add to ~/.bashrc
alias prod-instances='AWS_PROFILE=production instances'
alias dev-instances='AWS_PROFILE=development instances'
alias running='grep running'
alias stopped='grep stopped'

# Usage
prod-instances | running
```

### 2. Function Composition

```bash
# Create reusable building blocks
get-prod-instances() { instances prod "$@"; }
get-instance-ips() { instance-ip "$@"; }
format-as-hosts() { awk '{print $3 " # " $1}'; }

# Compose them
get-prod-instances | get-instance-ips | format-as-hosts >> /etc/hosts
```

### 3. Debug Mode

See what's happening under the hood:

```bash
# Enable debug output
set -x
instances
set +x

# Or inspect the function
type instances
```