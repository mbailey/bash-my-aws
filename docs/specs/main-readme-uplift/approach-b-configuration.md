# Configuration Guide

bash-my-aws behavior can be customized through environment variables.

## Environment Variables

### BMA_HEADERS

Controls when column headers are displayed in command output.

```bash
export BMA_HEADERS=always  # Default: always show headers
export BMA_HEADERS=auto    # Show headers in terminal, hide in pipes
export BMA_HEADERS=never   # Never show headers
```

**Examples:**

```bash
# With BMA_HEADERS=always (default)
$ instances
# INSTANCE_ID          AMI_ID            TYPE     STATE    NAME      LAUNCH_TIME               AZ               VPC
i-e6f097f6ea4457757  ami-123456789012  t3.nano  running  web-prod  2019-12-07T08:12:00.000Z  ap-southeast-2a  None

# With BMA_HEADERS=auto (headers hidden in pipes)
$ instances | grep prod
i-e6f097f6ea4457757  ami-123456789012  t3.nano  running  web-prod  2019-12-07T08:12:00.000Z  ap-southeast-2a  None

# With BMA_HEADERS=never
$ instances
i-e6f097f6ea4457757  ami-123456789012  t3.nano  running  web-prod  2019-12-07T08:12:00.000Z  ap-southeast-2a  None
```

### BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT

Controls output formatting - whether to align columns.

```bash
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=true   # Recommended
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=false  # Always columnize
```

When set to `true`:
- Terminal output: Nicely aligned columns
- Piped output: Tab-separated for easy parsing

### BMA_HOME

Location of bash-my-aws installation (defaults to `~/.bash-my-aws`).

```bash
export BMA_HOME=/opt/bash-my-aws
```

## AWS Configuration

### AWS_DEFAULT_REGION

Set your default AWS region:

```bash
export AWS_DEFAULT_REGION=us-east-1

# Or use the regions command
$ regions
$ export AWS_DEFAULT_REGION=eu-west-1
```

### AWS_PROFILE

Use different AWS profiles:

```bash
export AWS_PROFILE=production
instances  # Lists production instances

export AWS_PROFILE=development
instances  # Lists development instances
```

### AWS CLI Environment Variables

bash-my-aws respects all standard AWS CLI environment variables:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`
- `AWS_DEFAULT_OUTPUT`
- `AWS_CA_BUNDLE`
- `AWS_CLI_FILE_ENCODING`
- `AWS_CONFIG_FILE`
- `AWS_SHARED_CREDENTIALS_FILE`

## Shell-Specific Configuration

### Bash Configuration

Add to `~/.bashrc`:

```bash
# bash-my-aws configuration
export PATH="$PATH:$HOME/.bash-my-aws/bin"
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=true
export BMA_HEADERS=auto
export AWS_DEFAULT_REGION=us-east-1

# Load aliases and completion
source $HOME/.bash-my-aws/aliases
source $HOME/.bash-my-aws/bash_completion.sh
```

### Zsh Configuration

Add to `~/.zshrc`:

```bash
# bash-my-aws configuration
export PATH="$PATH:$HOME/.bash-my-aws/bin"
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=true
export BMA_HEADERS=auto
export AWS_DEFAULT_REGION=us-east-1

# Enable bash completion compatibility
autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit

# Load aliases and completion
source $HOME/.bash-my-aws/aliases
source $HOME/.bash-my-aws/bash_completion.sh
```

## Performance Optimization

### Using Functions Instead of Aliases

For faster startup times, you can source functions directly:

```bash
# Instead of aliases (slower startup, better compatibility)
source $HOME/.bash-my-aws/aliases

# Use functions directly (faster startup, bash only)
for f in $HOME/.bash-my-aws/lib/*-functions; do source $f; done
```

### Caching AWS Calls

For frequently used commands, consider using cache-based wrappers:

```bash
# Example: Cache instance list for 5 minutes
alias instances-cached='cache-command 300 instances'

cache-command() {
  local ttl=$1; shift
  local cache_file="/tmp/bma-cache-$*"
  if [[ ! -f "$cache_file" ]] || [[ $(find "$cache_file" -mmin +$ttl 2>/dev/null) ]]; then
    "$@" > "$cache_file"
  fi
  cat "$cache_file"
}
```

## Common Configurations

### Development Environment

```bash
export BMA_HEADERS=always
export AWS_PROFILE=development
export AWS_DEFAULT_REGION=us-east-1
```

### Production Environment

```bash
export BMA_HEADERS=auto
export AWS_PROFILE=production
export AWS_DEFAULT_REGION=us-east-1
# Add safety aliases
alias instance-terminate='echo "WARNING: Production environment!" && instance-terminate'
```

### CI/CD Environment

```bash
export BMA_HEADERS=never
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=false
# Use specific credentials
export AWS_ACCESS_KEY_ID=$CI_AWS_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$CI_AWS_SECRET_KEY
```