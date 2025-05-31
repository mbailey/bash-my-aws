# Installation Guide

This guide provides detailed installation instructions for bash-my-aws.

## Prerequisites

### Required
- **[AWS CLI](https://aws.amazon.com/cli/)** - The official AWS command line interface
- **[Bash](https://www.gnu.org/software/bash/)** 4.0+ or **[Zsh](https://www.zsh.org/)**
- **[jq](https://stedolan.github.io/jq/)** 1.4+ (for stack-diff and other advanced features)

### Optional
- **[colordiff](https://www.colordiff.org/)** - Colorized diff output for stack-diff
- **[icdiff](https://github.com/jeffkaufman/icdiff)** - Side-by-side colored diff for stack-diff

## Installation Methods

### Method 1: Standard Installation (Recommended)

```bash
# Clone to your preferred location
git clone https://github.com/bash-my-aws/bash-my-aws.git ~/.bash-my-aws

# For Bash users, add to ~/.bashrc
cat >> ~/.bashrc <<'EOF'
export PATH="$PATH:$HOME/.bash-my-aws/bin"
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=true
export BMA_HEADERS=always  # always|auto|never
source $HOME/.bash-my-aws/aliases
source $HOME/.bash-my-aws/bash_completion.sh
EOF

# For Zsh users, add to ~/.zshrc
cat >> ~/.zshrc <<'EOF'
export PATH="$PATH:$HOME/.bash-my-aws/bin"
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=true
export BMA_HEADERS=always  # always|auto|never
source $HOME/.bash-my-aws/aliases
# Enable bash completion compatibility
autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit
source $HOME/.bash-my-aws/bash_completion.sh
EOF

# Reload your shell
exec $SHELL
```

### Method 2: Custom Location

```bash
# Set your preferred location
export BMA_HOME=/opt/bash-my-aws

# Clone and install
git clone https://github.com/bash-my-aws/bash-my-aws.git "$BMA_HOME"

# Add to your shell config (adjust the export BMA_HOME line)
echo 'export BMA_HOME=/opt/bash-my-aws' >> ~/.bashrc
echo 'export PATH="$PATH:$BMA_HOME/bin"' >> ~/.bashrc
echo 'source $BMA_HOME/aliases' >> ~/.bashrc
echo 'source $BMA_HOME/bash_completion.sh' >> ~/.bashrc
```

### Method 3: Development Installation

If you plan to contribute or customize:

```bash
# Fork the repo first, then:
git clone https://github.com/YOUR_USERNAME/bash-my-aws.git ~/.bash-my-aws
cd ~/.bash-my-aws
git remote add upstream https://github.com/bash-my-aws/bash-my-aws.git

# Follow standard installation steps above
```

## Post-Installation

### Verify Installation

```bash
# Check if commands are available
bma
instances
stacks

# Test completion
instance-[TAB][TAB]
```

### Configure AWS CLI

If you haven't already:

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region
# Enter your default output format (recommend: json)
```

### Set Your Default Region

```bash
# See available regions
regions

# Set a region for this session
export AWS_DEFAULT_REGION=us-east-1

# Or make it permanent
echo 'export AWS_DEFAULT_REGION=us-east-1' >> ~/.bashrc
```

## Troubleshooting

### Command not found

If you get "command not found" errors:

1. Check your PATH:
   ```bash
   echo $PATH | grep -q bash-my-aws || echo "bash-my-aws not in PATH"
   ```

2. Ensure you've reloaded your shell:
   ```bash
   source ~/.bashrc  # or source ~/.zshrc
   ```

### Completion not working

For Zsh users, ensure you have these lines before sourcing bash_completion.sh:
```bash
autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit
```

### AWS CLI errors

Ensure AWS CLI is properly configured:
```bash
aws sts get-caller-identity
```

## Next Steps

- Read the [Quick Start Guide](https://bash-my-aws.org/quick-start)
- Explore the [Command Reference](https://bash-my-aws.org/command-reference)
- Learn about [Advanced Usage](https://bash-my-aws.org/advanced-usage)