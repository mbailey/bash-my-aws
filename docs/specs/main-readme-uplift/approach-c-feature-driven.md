# Bash-my-AWS

**Transform complex AWS operations into simple, memorable commands that actually work together.**

![screencast](docs/images/bma-02-2.gif)

Stop writing 200-character AWS CLI commands. With bash-my-aws, you get short commands that pipe seamlessly together, with smart tab completion that reads your AWS account in real-time.

```bash
$ instances | grep prod | instance-terminate
```

## Why bash-my-aws?

### 🚀 **10x Faster Command Entry** - Short commands with real-time completion

```bash
# Before: 
aws ec2 describe-instances --filters "Name=tag:Environment,Values=production" --query "Reservations[].Instances[].InstanceId" --output text | xargs -I {} aws ec2 terminate-instances --instance-ids {}

# After:
instances prod | instance-terminate
```

Your fingers will thank you. Tab completion pulls live data from AWS, so `instance-terminate [TAB]` shows actual instance names.

### 🔗 **Unix Pipeline Magic** - Commands that actually compose

```bash
# Find expensive instances and stop them
instances | grep "t3.2xlarge\|m5.4xlarge" | instance-stop

# Clean up old snapshots across regions
regions | region-each snapshots | grep "2022-" | snapshot-delete

# Tag all production stacks
stacks prod | stack-tag-apply Environment=production Owner=devops
```

First-class pipeline support means every command outputs clean, parseable text that feeds perfectly into the next command.

### 🧠 **Zero Learning Curve** - Discover commands naturally

```bash
$ instance-[TAB][TAB]
instance-asg       instance-ssh       instance-start     instance-terminate
instance-az        instance-state     instance-stop      instance-type
instance-console   instance-tags      instance-userdata  instance-volumes

$ keypair-[TAB]
keypair-create  keypair-delete  keypair-import
```

Resource names are pluralized for listing (`instances`, `stacks`, `buckets`). Actions follow the pattern `resource-action`. It just makes sense.

## Get Started in 60 Seconds

**1. Clone and Configure**

```bash
git clone https://github.com/bash-my-aws/bash-my-aws.git ~/.bash-my-aws

# Add to ~/.bashrc or ~/.zshrc:
export PATH="$PATH:$HOME/.bash-my-aws/bin"
source ~/.bash-my-aws/aliases
source ~/.bash-my-aws/bash_completion.sh

# For ZSH users, add these before sourcing:
# autoload -U +X compinit && compinit
# autoload -U +X bashcompinit && bashcompinit
```

**2. Start Using It**

```bash
$ instances
# INSTANCE_ID          TYPE        STATE    NAME
i-abc123def456789    t3.small    running  web-server
i-def456ghi789012    t3.medium   running  api-server

$ instances web | instance-ssh
```

That's it. No configuration files, no complex setup.

## Command Overview

### Resource Operations
- **EC2**: `instances`, `instance-terminate`, `instance-ssh`, `instance-console`
- **CloudFormation**: `stacks`, `stack-create`, `stack-update`, `stack-diff`
- **S3**: `buckets`, `bucket-objects`, `bucket-remove`
- **VPC**: `vpcs`, `subnets`, `security-groups`
- **IAM**: `users`, `roles`, `policies`
- **Lambda**: `functions`, `function-invoke`, `function-logs`

### Cross-Service Power
- **Multi-region**: `regions`, `region-each <command>`
- **Tagging**: `*-tag-apply`, `*-tag-remove`, `tag-instances`
- **Cost Control**: `instances` → filter by type → `instance-stop`

[Full Command Reference →](https://bash-my-aws.org/command-reference/)

## Advanced Power

### Interactive Confirmation
```bash
$ stacks | grep old | stack-delete
You are about to delete the following stacks:
old-app-stack-1
old-app-stack-2
Are you sure you want to continue? [y/N]
```

### Smart Filtering
```bash
# Built-in grep (columnizes after filtering)
$ instances prod

# Headers adapt to context
export BMA_HEADERS=auto  # Show in terminal, hide in pipes
```

### Parallel Operations
```bash
# Run commands across all regions
$ regions | region-each instances

# Process multiple resources
$ echo "alice bob carol" | keypair-create
```

## Join the Community

- **Documentation**: <https://bash-my-aws.org/>
- **GitHub**: <https://github.com/bash-my-aws/bash-my-aws>
- **Issues/Features**: [GitHub Issues](https://github.com/bash-my-aws/bash-my-aws/issues)
- **Contributing**: See our [Developer Guide](https://bash-my-aws.org/developer-guide/)

Built by AWS practitioners, for AWS practitioners. Simple, powerful, extensible.

---

*Prerequisites: [AWS CLI](https://aws.amazon.com/cli/), [bash](https://www.gnu.org/software/bash/), [jq](https://stedolan.github.io/jq/) • Optional: [colordiff](https://www.colordiff.org/) for colored diffs*