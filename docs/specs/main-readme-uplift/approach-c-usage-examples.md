# Usage Examples

## Common Workflows

### Instance Management

**List all instances with details**
```bash
$ instances
# INSTANCE_ID          AMI_ID            TYPE     STATE    NAME                        LAUNCH_TIME               AZ               VPC
i-e6f097f6ea4457757  ami-123456789012  t3.nano  running  example-ec2-ap-southeast-2  2019-12-07T08:12:00.000Z  ap-southeast-2a  None
i-b983805b4b254f749  ami-123456789012  t3.nano  running  postfix-prod                2019-12-07T08:26:30.000Z  ap-southeast-2a  None
```

**Filter instances by name pattern**
```bash
$ instances prod
i-b983805b4b254f749  ami-123456789012  t3.nano  running  postfix-prod  2019-12-07T08:26:30.000Z  ap-southeast-2a  None
i-fed39ebe7204dfd37  ami-123456789012  t3.nano  running  nginx-prod    2019-12-07T08:26:34.000Z  ap-southeast-2a  None
```

**Get instance IPs**
```bash
$ instances prod | instance-ip
i-b983805b4b254f749  10.190.1.70    54.214.71.51
i-fed39ebe7204dfd37  10.135.204.82  54.214.26.190
```

**SSH to instances**
```bash
# SSH to a single instance
$ instance-ssh i-b983805b4b254f749

# SSH to instances by name pattern
$ instances web-server | instance-ssh
```

**Stop/Start instances**
```bash
# Stop all development instances
$ instances dev | instance-stop

# Start specific instances
$ echo "i-abc123 i-def456" | instance-start
```

### Stack Management

**List CloudFormation stacks**
```bash
$ stacks
nagios      CREATE_COMPLETE  2011-05-23T15:47:44Z  NEVER_UPDATED  NOT_NESTED
postgres01  CREATE_COMPLETE  2011-05-23T15:47:44Z  NEVER_UPDATED  NOT_NESTED
prometheus  CREATE_COMPLETE  2011-05-23T15:47:44Z  NEVER_UPDATED  NOT_NESTED
```

**Create a stack**
```bash
$ stack-create my-app-stack cloudformation/my-app.yml
```

**Update a stack with parameter file**
```bash
$ stack-update my-app-stack cloudformation/my-app.yml cloudformation/params/prod.json
```

**View stack outputs**
```bash
$ stack-outputs my-app-stack
LoadBalancerDNS  my-app-123456.us-east-1.elb.amazonaws.com
DatabaseEndpoint database.my-app.internal
```

**Diff stack changes**
```bash
$ stack-diff my-app-stack cloudformation/my-app-updated.yml
```

**Delete stacks**
```bash
# Delete specific stacks
$ echo "old-stack-1 old-stack-2" | stack-delete

# Delete stacks matching pattern
$ stacks | grep obsolete | stack-delete
```

### S3 Operations

**List buckets with creation dates**
```bash
$ buckets
example-assets   2019-12-08  02:35:44.758551
example-logs     2019-12-08  02:35:52.669771
example-backups  2019-12-08  02:35:56.579434
```

**List bucket contents**
```bash
$ bucket-objects example-assets
2021-01-15 13:45:22    1234567 images/logo.png
2021-01-15 13:45:23     987654 css/styles.css
```

**Remove buckets**
```bash
# Remove empty bucket
$ bucket-remove old-bucket

# Remove bucket and all contents (use with caution!)
$ bucket-remove-force old-bucket
```

### Multi-Region Operations

**List all regions**
```bash
$ regions
us-east-1
us-west-2
eu-west-1
ap-southeast-2
```

**Run command in all regions**
```bash
# List instances in all regions
$ regions | region-each instances

# Find specific resources across regions
$ regions | region-each "stacks | grep production"
```

### Cost Optimization

**Find and stop expensive instances**
```bash
# Stop all GPU instances
$ instances | grep "p3\|g4" | instance-stop

# Terminate instances older than 30 days
$ instances | awk '$6 < "'$(date -d '30 days ago' '+%Y-%m-%d')'"' | instance-terminate
```

**Clean up unused resources**
```bash
# Delete unattached volumes
$ volumes | grep available | volume-delete

# Remove old snapshots
$ snapshots | grep "2020-\|2021-" | snapshot-delete
```

### Tagging Operations

**Apply tags to resources**
```bash
# Tag all production instances
$ instances prod | instance-tag-apply Environment=production Team=platform

# Tag stacks
$ stacks | grep api | stack-tag-apply Service=api Version=2.0
```

**Filter by tags**
```bash
# Find instances with specific tag
$ instances | instance-tags | grep "Team=security"
```

### Security Group Management

**List security groups**
```bash
$ security-groups
sg-12345678  default     Default security group  vpc-abcd1234
sg-87654321  web-server  Web server security     vpc-abcd1234
```

**View security group rules**
```bash
$ security-group-rules sg-87654321
```

### Pipeline Examples

**Complex filtering and actions**
```bash
# Stop all instances in specific VPC that aren't production
$ instances | grep vpc-12345 | grep -v prod | instance-stop

# Get IPs of running instances with specific AMI
$ instances | grep ami-12345 | grep running | instance-ip

# SSH to first matching instance
$ instances nginx | head -1 | instance-ssh
```

**Batch operations**
```bash
# Create multiple keypairs
$ echo "alice bob carol dave" | tr ' ' '\n' | keypair-create

# Delete multiple stacks
$ cat stacks-to-delete.txt | stack-delete
```

## Tips and Tricks

### Use Built-in Filtering
```bash
# This is more efficient than piping to grep
$ instances prod

# Than this
$ instances | grep prod
```

### Combine with Standard Unix Tools
```bash
# Count instances by type
$ instances | awk '{print $3}' | sort | uniq -c

# Get total EBS volume size
$ volumes | awk '{sum+=$3} END {print sum " GB"}'
```

### Save Common Queries
```bash
# Create aliases for common operations
alias prod-instances='instances prod'
alias stop-dev='instances dev | instance-stop'
alias clean-snapshots='snapshots | grep -v "keep\|production" | snapshot-delete'
```

### Interactive Safety
```bash
# Commands that modify resources ask for confirmation
$ instances test | instance-terminate
You are about to terminate the following instances:
i-1234567890abcdef0 (test-server-1)
i-0987654321fedcba0 (test-server-2)
Are you sure you want to continue? [y/N]
```