# Bash-my-AWS Configuration

This guide covers all configuration options and environment variables for bash-my-aws.

## Environment Variables

### BMA_HEADERS

Controls whether column headers are displayed in command output.

**Values:**
- `always` (default) - Always show headers
- `auto` - Show headers in terminal, hide in pipes
- `never` - Never show headers

**Example:**
```bash
# Always show headers (default)
export BMA_HEADERS=always
$ instances
# INSTANCE_ID          AMI_ID            TYPE     STATE    NAME  LAUNCH_TIME               AZ               VPC
i-e6f097f6ea4457757  ami-123456789012  t3.nano  running  web   2019-12-07T08:12:00.000Z  ap-southeast-2a  None

# Auto mode - headers only in terminal
export BMA_HEADERS=auto
$ instances                    # Shows headers
$ instances | grep running     # No headers

# Never show headers
export BMA_HEADERS=never
$ instances                    # No headers
```

### BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT

Controls when output is formatted into columns.

**Values:**
- `true` - Only columnize when outputting to terminal
- `false` (default) - Always columnize

**Example:**
```bash
# Enable smart columnization
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=true

# Terminal output is columnized
$ instances
i-12345678  ami-98765432  t2.micro  running  webserver  2021-01-01T00:00:00Z  us-east-1a  vpc-abcdef

# Pipe output is not columnized (faster for scripts)
$ instances | grep web
i-12345678 ami-98765432 t2.micro running webserver 2021-01-01T00:00:00Z us-east-1a vpc-abcdef
```

### BMA_HOME

Sets the installation directory for bash-my-aws.

**Default:** `$HOME/.bash-my-aws`

**Example:**
```bash
# Custom installation location
export BMA_HOME=/opt/bash-my-aws
```

### AWS Environment Variables

Bash-my-aws respects all standard AWS CLI environment variables:

```bash
# AWS credentials
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# AWS region
export AWS_DEFAULT_REGION=us-west-2
export AWS_REGION=us-west-2

# AWS profile
export AWS_PROFILE=production

# Assume role
export AWS_ROLE_ARN=arn:aws:iam::123456789012:role/MyRole
export AWS_ROLE_SESSION_NAME=MySession
```

## Shell Configuration

### Bash Configuration

Add to `~/.bashrc`:

```bash
# Basic setup
export PATH="$PATH:${BMA_HOME:-$HOME/.bash-my-aws}/bin"
source ${BMA_HOME:-$HOME/.bash-my-aws}/aliases
source ${BMA_HOME:-$HOME/.bash-my-aws}/bash_completion.sh

# Optional: Load functions directly (instead of aliases)
# for f in ${BMA_HOME:-$HOME/.bash-my-aws}/lib/*-functions; do source $f; done

# Configuration options
export BMA_HEADERS=always
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=true
```

### Zsh Configuration

Add to `~/.zshrc`:

```bash
# Enable bash completion compatibility
autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit

# Basic setup
export PATH="$PATH:${BMA_HOME:-$HOME/.bash-my-aws}/bin"
source ${BMA_HOME:-$HOME/.bash-my-aws}/aliases
source ${BMA_HOME:-$HOME/.bash-my-aws}/bash_completion.sh

# Configuration options
export BMA_HEADERS=always
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=true
```

## Advanced Configuration

### Custom Command Aliases

Create project-specific aliases:

```bash
# ~/.bashrc or project-specific shell file
alias prod='export AWS_PROFILE=production'
alias dev='export AWS_PROFILE=development'
alias prod-instances='AWS_PROFILE=production instances'
alias stop-all-test='instances test | instance-stop'
```

### Function Overrides

Override default functions with custom behavior:

```bash
# ~/.bashrc - after sourcing bash-my-aws
instances_original=$(declare -f instances)
instances() {
    echo "Running custom instances function..."
    eval "$instances_original"
    echo "Total: $(instances | wc -l) instances"
}
```

### Output Formatting

Customize output with standard Unix tools:

```bash
# Always show instances in specific format
alias myinstances='instances | awk "{printf \"%-20s %-10s %-15s\\n\", \$1, \$4, \$5}"'

# Color output
alias instances-color='instances | grep --color=auto -E "running|$"'
```

## Integration with Other Tools

### AWS Vault

```bash
# Use with aws-vault
alias bma-prod='aws-vault exec production -- bma'
aws-vault exec production -- instances
```

### Direnv

Create `.envrc` files for project-specific settings:

```bash
# .envrc
export AWS_PROFILE=myproject
export AWS_REGION=us-west-2
export BMA_HEADERS=auto
```

### Docker

Run bash-my-aws in a container:

```bash
# Dockerfile
FROM amazon/aws-cli:latest
RUN yum install -y git bash jq
RUN git clone https://github.com/bash-my-aws/bash-my-aws.git /opt/bash-my-aws
ENV PATH="/opt/bash-my-aws/bin:${PATH}"
ENV BMA_HOME=/opt/bash-my-aws
```

## Performance Tuning

### Large Result Sets

```bash
# Disable columnization for large outputs
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=true

# Skip headers
export BMA_HEADERS=never

# Use AWS CLI directly for maximum performance
aws ec2 describe-instances --output text --query 'Reservations[].Instances[].InstanceId'
```

### Caching

While bash-my-aws doesn't cache by default, you can implement caching:

```bash
# Simple file-based cache
cache_dir="${HOME}/.cache/bash-my-aws"
mkdir -p "$cache_dir"

cached_instances() {
    local cache_file="$cache_dir/instances-$(date +%Y%m%d%H)"
    if [ -f "$cache_file" ]; then
        cat "$cache_file"
    else
        instances | tee "$cache_file"
    fi
}
```

## Debugging

### Enable Debug Output

```bash
# Show AWS CLI commands being executed
set -x
instances
set +x

# AWS CLI debug mode
export AWS_DEBUG=1
```

### Check Configuration

```bash
# Show current configuration
env | grep -E '^(BMA_|AWS_)'

# Test specific functions
bma type instances
```

## Security Best Practices

### Credential Management

```bash
# Never hardcode credentials
# Bad:
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE

# Good - use profiles:
export AWS_PROFILE=production

# Better - use temporary credentials:
aws-vault exec production -- instances
```

### Audit Trail

```bash
# Enable CloudTrail logging for all API calls
# Log bash-my-aws commands
export HISTFILE=~/.bash_my_aws_history
export HISTTIMEFORMAT='%F %T '
```

## Frequently Asked Questions

### How do I use multiple AWS accounts?

```bash
# Using profiles
export AWS_PROFILE=account1
instances

export AWS_PROFILE=account2
instances

# Using functions
account1-instances() { AWS_PROFILE=account1 instances "$@"; }
account2-instances() { AWS_PROFILE=account2 instances "$@"; }
```

### Can I change the output format?

```bash
# Use jq for JSON output
instances() {
    aws ec2 describe-instances --output json | jq '.Reservations[].Instances[]'
}

# Custom column selection
instances | awk '{print $1, $4, $5}'
```

### How do I add custom completions?

```bash
# Add to ~/.bashrc after sourcing bash-my-aws
complete -W "start stop restart" my-service-command
```