# Bash-my-AWS Usage Guide

This guide covers detailed usage patterns, tips, and examples for bash-my-aws.

## Table of Contents

- [Discovering Commands](#discovering-commands)
- [Working with Pipelines](#working-with-pipelines)
- [Filtering and Searching](#filtering-and-searching)
- [Shell Completion](#shell-completion)
- [Advanced Patterns](#advanced-patterns)
- [Working with Headers](#working-with-headers)
- [Alternative Installation Methods](#alternative-installation-methods)

## Discovering Commands

Commands follow consistent naming patterns:

### Resource Listing Commands (Pluralized)

```bash
instances             # List EC2 instances
stacks               # List CloudFormation stacks
buckets              # List S3 buckets
keypairs             # List SSH keypairs
images               # List AMIs
vpcs                 # List VPCs
subnets              # List subnets
security-groups      # List security groups
```

### Resource Action Commands (resource-action)

```bash
instance-[TAB][TAB]  # Shows all instance-related commands
stack-[TAB][TAB]     # Shows all stack-related commands
keypair-[TAB][TAB]   # Shows all keypair-related commands
```

## Working with Pipelines

The real power comes from combining commands:

### Basic Pipeline Examples

```bash
# Get IPs for all running instances
instances | grep running | instance-ip

# SSH to instances with specific name
instances webserver | instance-ssh

# Delete terminated instances
instances | grep terminated | instance-terminate
```

### Multi-Stage Pipelines

```bash
# Find instances in specific VPC and get their security groups
vpcs | grep production | vpc-instances | instance-security-groups

# Get all instances for a stack and show their states
stacks myapp | stack-instances | instance-state
```

## Filtering and Searching

### Built-in Filtering

Most listing commands accept a filter as first argument:

```bash
instances nginx          # Only instances with 'nginx' in output
stacks prod             # Only stacks with 'prod' in output
buckets backup          # Only buckets with 'backup' in output
```

### Why Built-in Filtering?

It produces cleaner output because columnization happens after filtering:

```bash
# Without filter - columnization happens first
$ instances | grep nginx
i-12345678  ami-987654  t2.micro  running  nginx-prod     2021-01-01T00:00:00Z  us-east-1a  vpc-abcd

# With filter - cleaner columns
$ instances nginx
i-12345678  ami-987654  t2.micro  running  nginx-prod  2021-01-01T00:00:00Z  us-east-1a  vpc-abcd
```

## Shell Completion

Tab completion works for:

### Command Names

```bash
inst[TAB]
# Completes to: instance-

instance-[TAB][TAB]
# Shows all instance commands
```

### Resource IDs

```bash
instance-terminate i-[TAB]
# Shows all instance IDs starting with i-

stack-delete my[TAB]
# Shows all stacks starting with 'my'
```

### Multiple Resources

```bash
keypair-delete alice b[TAB]
# Completes 'bob' if that keypair exists
```

## Advanced Patterns

### Reading from Files

Commands read from stdin, so you can use files:

```bash
# File with instance IDs
echo "i-12345678" > instances.txt
echo "i-87654321" >> instances.txt

# Terminate instances from file
cat instances.txt | instance-terminate
```

### Saving Command Output

```bash
# Save instance list for later
instances > prod-instances.txt

# Use saved list
cat prod-instances.txt | instance-stop
```

### Complex Filtering with AWK

```bash
# Get instances launched more than 30 days ago
instances | awk '{
  launch_date = $6
  # Compare dates and print old instances
}' | instance-terminate
```

### Combining with Other Tools

```bash
# Count instances per type
instances | awk '{print $3}' | sort | uniq -c

# Monitor instance states
watch -n 5 'instances | grep -c running'
```

## Working with Headers

Headers help identify columns in output:

```bash
$ export BMA_HEADERS=always
$ instances
# INSTANCE_ID          AMI_ID            TYPE      STATE    NAME   LAUNCH_TIME               AZ               VPC
i-e6f097f6ea4457757  ami-123456789012  t3.nano  running  web-1  2019-12-07T08:12:00.000Z  ap-southeast-2a  vpc-123
```

### Header Modes

- `always` - Show headers everywhere (default)
- `auto` - Show in terminal, hide in pipes
- `never` - Never show headers

### Headers in Pipelines

Headers are automatically filtered when piping between bash-my-aws commands:

```bash
$ instances | instance-ip
# No headers shown - clean output for further processing
i-e6f097f6ea4457757  10.1.2.3  54.1.2.3
```

## Alternative Installation Methods

### For Bash Users - Direct Function Loading

```bash
# Source functions directly instead of using aliases
if [ -d ${BMA_HOME:-$HOME/.bash-my-aws} ]; then
  for f in ${BMA_HOME:-$HOME/.bash-my-aws}/lib/*-functions; do source $f; done
fi
```

### Using the BMA Wrapper

Sometimes required with restrictive auth tools:

```bash
# Instead of direct command
instances

# Use bma wrapper
bma instances
```

### Custom Installation Location

```bash
export BMA_HOME=/opt/bash-my-aws
git clone https://github.com/bash-my-aws/bash-my-aws.git $BMA_HOME
```

## Tips and Tricks

### Speed Up Large Outputs

```bash
# Disable columnization for scripts
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=true
```

### Create Custom Aliases

```bash
# Add to your .bashrc
alias prod-instances='instances prod'
alias stop-test='instances test | instance-stop'
```

### Debugging Commands

```bash
# See the actual AWS CLI command
bma type instances

# Run with AWS debug output
export AWS_DEBUG=1
instances
```

### Working with Multiple Accounts

```bash
# Use AWS profiles
export AWS_PROFILE=production
instances

# Or with aws-vault
aws-vault exec prod -- instances
```

## Common Workflows

### Instance Management

```bash
# Launch instances from a specific AMI
images ubuntu | head -1 | image-launch -t t3.micro -k mykey

# Restart all web servers
instances web | instance-stop
sleep 30
instances web | instance-start
```

### Stack Operations

```bash
# Update all stacks with specific template
stacks app | stack-update -t new-template.yml

# Delete all test stacks
stacks test | stack-delete
```

### Security Audit

```bash
# Find instances without specific security group
instances | instance-security-groups | grep -v sg-required

# List all public IPs
instances | instance-ip | awk '$3 != "None" {print $3}'
```

## Troubleshooting

### Commands Not Found

```bash
# Check PATH
echo $PATH | grep -q bash-my-aws || echo "PATH not set correctly"

# Check if aliases are loaded
alias | grep -q instances || echo "Aliases not loaded"
```

### Completion Not Working

```bash
# For bash
source ${BMA_HOME:-$HOME/.bash-my-aws}/bash_completion.sh

# For zsh (add before sourcing completion)
autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit
```

### Performance Issues

```bash
# Check if columnization is slowing things down
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=true

# For very large result sets, skip bash-my-aws formatting
aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --output text
```