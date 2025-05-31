# Bash-my-AWS

**Powerful AWS CLI commands that fit naturally into your workflow**

Bash-my-AWS transforms verbose AWS CLI operations into memorable commands while maintaining full unix pipeline compatibility.

![screencast](docs/images/bma-02-2.gif)

## 🚀 30-Second Demo

```bash
# List instances with a simple command
$ instances
# INSTANCE_ID          TYPE     STATE    NAME        
i-e6f097f6  t3.nano  running  web-server  
i-b9838054  t3.nano  running  postgres    

# Find and connect via SSH in one line
$ instances postgres | instance-ssh
Welcome to Ubuntu 20.04.3 LTS
ubuntu@postgres:~$ 

# Delete test stacks with confidence
$ stacks | grep test | stack-delete
You are about to delete the following stacks:
test-stack-01
test-stack-02
Are you sure you want to continue? [y/N]
```

## 📦 Installation

### Quick Install (Recommended)

```bash
# Clone the repository
git clone https://github.com/bash-my-aws/bash-my-aws.git ~/.bash-my-aws

# Add to your shell config (~/.bashrc or ~/.zshrc)
cat >> ~/.bashrc << 'EOF'
export PATH="$PATH:$HOME/.bash-my-aws/bin"
source $HOME/.bash-my-aws/aliases
source $HOME/.bash-my-aws/bash_completion.sh
EOF

# Reload your shell
source ~/.bashrc
```

### Prerequisites
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- [jq](https://stedolan.github.io/jq/) (for JSON processing)
- bash 4+ or zsh

<details>
<summary>📋 Detailed Installation Options</summary>

#### For ZSH Users
```bash
# Add these lines before sourcing bash_completion.sh
autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit
```

#### Optional Enhancements
- `colordiff` - Colorized stack diffs
- `icdiff` - Side-by-side colored diffs

#### Environment Variables
```bash
export BMA_HEADERS=always  # Show column headers (always|auto|never)
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=true
```

</details>

## 🎯 Essential Commands

### Resource Listing
| Command | Description | Example |
|---------|-------------|---------|
| `instances` | List EC2 instances | `instances web` |
| `stacks` | List CloudFormation stacks | `stacks prod` |
| `buckets` | List S3 buckets | `buckets backup` |
| `keypairs` | List SSH keypairs | `keypairs` |
| `images` | List AMIs | `images ubuntu` |
| `vpcs` | List VPCs | `vpcs` |

### Resource Actions
| Command | Description | Example |
|---------|-------------|---------|
| `instance-ssh` | SSH to instance | `instances web \| instance-ssh` |
| `instance-stop` | Stop instances | `instances test \| instance-stop` |
| `stack-delete` | Delete stacks | `stacks old \| stack-delete` |
| `bucket-remove` | Remove buckets | `buckets temp \| bucket-remove` |

### Information Commands
| Command | Description | Example |
|---------|-------------|---------|
| `instance-ip` | Get instance IPs | `instances \| instance-ip` |
| `stack-outputs` | Show stack outputs | `stacks app \| stack-outputs` |
| `instance-state` | Check instance states | `instances \| instance-state` |

## 💡 Key Features

<details>
<summary>🔗 Unix Pipeline Magic</summary>

Chain commands naturally:
```bash
# Stop all test instances
instances test | instance-stop

# Get IPs of running web servers  
instances | grep running | grep web | instance-ip

# Delete stacks created before 2023
stacks | awk '$3 < "2023"' | stack-delete
```
</details>

<details>
<summary>🎹 Smart Tab Completion</summary>

```bash
# Complete commands
$ instance-[TAB][TAB]
instance-asg            instance-ssh
instance-ip             instance-start  
instance-state          instance-stop

# Complete resource names
$ instance-ssh [TAB][TAB]
web-server-01    web-server-02    database-prod
```
</details>

<details>
<summary>⚡ Powerful Shortcuts</summary>

```bash
# Filter without grep
instances web         # same as: instances | grep web
stacks prod          # same as: stacks | grep prod

# Multi-resource operations
instances web | instance-terminate    # terminates all web instances
```
</details>

## 📚 Learn More

- **[Full Documentation](https://bash-my-aws.org/)** - Comprehensive guides and examples
- **[Command Reference](https://bash-my-aws.org/command-reference/)** - All available commands
- **[Usage Examples](https://bash-my-aws.org/usage-guide/)** - Real-world scenarios
- **[Developer Guide](https://bash-my-aws.org/developer-guide/)** - Contribute new functions

## 🛠️ Advanced Usage

<details>
<summary>Working with CloudFormation</summary>

```bash
# Create stack from template
stack-create my-app cloudformation/app.yml

# Watch stack events
stack-events my-app

# Compare stack changes
stack-diff my-app cloudformation/app.yml
```
</details>

<details>
<summary>EC2 Instance Management</summary>

```bash
# Launch instances
instance-launch ami-12345678 --type t3.micro --count 3

# Attach volumes
instance-volumes i-12345678 | volume-attach i-87654321

# Enable termination protection
instances prod | instance-termination-protection-enable
```
</details>

## 🤝 Contributing

Bash-my-AWS welcomes contributions! Each command is a simple bash function wrapping AWS CLI calls.

```bash
# See how a command works
$ bma type instances

# Find the source
$ grep -n "instances()" ~/.bash-my-aws/lib/*
```

See our [Developer Guide](https://bash-my-aws.org/developer-guide/) for patterns and templates.

## 📄 License

[MIT License](LICENSE) - Use freely in personal and commercial projects.

---

**Need help?** Check the [documentation](https://bash-my-aws.org/) or open an [issue](https://github.com/bash-my-aws/bash-my-aws/issues).