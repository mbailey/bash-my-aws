# Bash-my-AWS

**Simple but powerful CLI commands for AWS that make your life easier.**

Bash-my-AWS harnesses AWS CLI's power while removing the complexity. Short memorable commands, powerful Unix pipelines, and shell completion for everything.

![screencast](docs/images/bma-02-2.gif)

## Quick Start (2 minutes)

### Install

```bash
# Clone the repo
git clone https://github.com/bash-my-aws/bash-my-aws.git ~/.bash-my-aws

# Add to ~/.bashrc or ~/.zshrc
cat >> ~/.bashrc << 'EOF'
export PATH="$PATH:$HOME/.bash-my-aws/bin"
source $HOME/.bash-my-aws/aliases

# For ZSH users, add these before sourcing:
# autoload -U +X compinit && compinit
# autoload -U +X bashcompinit && bashcompinit

source $HOME/.bash-my-aws/bash_completion.sh
EOF

# Reload your shell
source ~/.bashrc
```

**Prerequisites:** [AWS CLI](https://aws.amazon.com/cli/) and [jq](https://stedolan.github.io/jq/)

### Try It Out

```bash
# List your EC2 instances
instances

# Get IPs for specific instances
instances nginx | instance-ip

# List CloudFormation stacks
stacks

# Delete stacks interactively
stacks postgres | stack-delete
```

That's it! You're using bash-my-aws. 🎉

## The Magic: Unix Pipelines

Bash-my-AWS commands work beautifully together. First token from each line flows through:

```bash
# Find instances, get their IPs
instances web-server | instance-ip
i-07e6d11ab8f77dd74  10.1.2.3    54.1.2.3
i-0a9h4i5e366b6dd5c  10.1.2.4    54.1.2.4

# Stop all test instances
instances test | instance-stop

# Show security groups for production instances  
instances prod | instance-security-groups
```

Commands read from stdin, filter with grep/awk, and complete everything via tab. It's the Unix way! 🐧

## Key Features

**🚀 Short Commands** - `instances` not `aws ec2 describe-instances --query ...`

**🔍 Smart Completion** - Tab complete everything: command names, instance IDs, stack names

**🔗 Pipeline Ready** - Every command inputs/outputs text streams 

**⚡ Convenient Shortcuts** - Built-in filtering, sensible defaults

## Command Examples

```bash
# Resource listing (pluralized names)
buckets               # List S3 buckets
keypairs              # List SSH keypairs  
stacks                # List CloudFormation stacks
instances             # List EC2 instances

# Resource actions (resource-action format)
instance-stop         # Stop instances
instance-ssh          # SSH to instances
stack-diff            # Compare stack templates
keypair-create        # Create new keypair
```

Full reference: [Command Documentation](https://bash-my-aws.org/command-reference/)

## Documentation

📚 **[Complete Documentation](https://bash-my-aws.org/)** - Detailed guides, examples, and reference

- [Command Reference](https://bash-my-aws.org/command-reference/) - All commands with examples
- [Usage Guide](docs/usage-guide.md) - Detailed usage patterns and tips
- [Configuration](docs/configuration.md) - Environment variables and options

## Configuration

Control output with environment variables:

```bash
# Control headers in output (always|auto|never)
export BMA_HEADERS=always  

# Only columnize when outputting to terminal
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=true
```

## Development

Want to contribute? Check out:
- [Developer Guide](docs/developer-guide.md) - Implementation patterns
- [Function Templates](docs/function-templates/) - Templates for new functions
- [Function Taxonomy](docs/function-taxonomy.md) - Naming conventions

## Why Bash-my-AWS?

- **No Learning Curve** - If you know bash and AWS, you already know bash-my-aws
- **Memorable Commands** - `instances` vs `aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output text`
- **Composable** - Combine with grep, awk, sort, and other Unix tools
- **Auto-completion** - Never copy-paste resource IDs again

## License

[MIT License](LICENSE)

---

**Ready for more?** Visit [bash-my-aws.org](https://bash-my-aws.org/) for complete documentation.