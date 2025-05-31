# Configuration Guide

## Environment Variables

bash-my-aws can be configured through environment variables to customize its behavior.

### BMA_HEADERS

Controls header output for resource listing functions.

- `always` (default): Always show headers
- `auto`: Show headers in terminal, hide in pipes
- `never`: Never show headers

```bash
# Default behavior - headers shown everywhere
export BMA_HEADERS=always

# Headers only in terminal, hidden in pipes (recommended)
export BMA_HEADERS=auto

# Suppress all headers (maintains legacy behavior)
export BMA_HEADERS=never
```

When headers are enabled, resource listing commands will display column headers as comments:

```shell
$ instances
# INSTANCE_ID          AMI_ID            TYPE     STATE    NAME                        LAUNCH_TIME               AZ               VPC
i-e6f097f6ea4457757  ami-123456789012  t3.nano  running  example-ec2-ap-southeast-2  2019-12-07T08:12:00.000Z  ap-southeast-2a  None
i-b983805b4b254f749  ami-123456789012  t3.nano  running  postfix-prod                2019-12-07T08:26:30.000Z  ap-southeast-2a  None
```

Headers are automatically skipped when piping between commands:

```shell
$ instances | instance-ip
i-e6f097f6ea4457757  10.1.2.3    54.1.2.3
i-b983805b4b254f749  10.1.2.4    54.1.2.4
```

### BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT

Controls whether output is columnized. Set to `true` to only columnize when outputting to a terminal.

```bash
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=true
```

### BMA_HOME

Location of bash-my-aws installation. Defaults to `$HOME/.bash-my-aws`.

```bash
export BMA_HOME=$HOME/.bash-my-aws
```

## AWS CLI Configuration

bash-my-aws uses the AWS CLI for all AWS operations. Configure your credentials using standard AWS CLI methods:

```bash
# Configure default profile
aws configure

# Use named profiles
export AWS_PROFILE=production

# Use environment variables
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_REGION=us-east-1
```

## Shell Configuration

### Bash

Add to `~/.bashrc`:

```bash
export PATH="$PATH:${BMA_HOME:-$HOME/.bash-my-aws}/bin"
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=true
export BMA_HEADERS=auto
source ${BMA_HOME:-$HOME/.bash-my-aws}/aliases
source ${BMA_HOME:-$HOME/.bash-my-aws}/bash_completion.sh
```

### ZSH

Add to `~/.zshrc`:

```bash
export PATH="$PATH:${BMA_HOME:-$HOME/.bash-my-aws}/bin"
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=true
export BMA_HEADERS=auto

# Enable bash completion compatibility
autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit

source ${BMA_HOME:-$HOME/.bash-my-aws}/aliases
source ${BMA_HOME:-$HOME/.bash-my-aws}/bash_completion.sh
```

### Using Functions Instead of Aliases

Bash users who prefer to source functions directly:

```bash
if [ -d ${BMA_HOME:-$HOME/.bash-my-aws} ]; then
  for f in ${BMA_HOME:-$HOME/.bash-my-aws}/lib/*-functions; do source $f; done
fi
```

## Optional Tools

These tools enhance bash-my-aws functionality:

- **[colordiff](https://www.colordiff.org/)** - Colorized output for `stack-diff`
- **[icdiff](https://github.com/jeffkaufman/icdiff)** - Side-by-side colored diffs

Install on macOS:
```bash
brew install colordiff icdiff
```

Install on Ubuntu/Debian:
```bash
sudo apt-get install colordiff
pip install icdiff
```