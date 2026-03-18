# Coding Conventions

This document outlines the coding conventions used in our project, particularly for bash scripts and AWS CLI commands.

## Bash Scripts

### Function Naming
- Use lowercase with hyphens for function names (e.g., `vpc-subnets`, `vpc-route-tables`).
- Function names should be descriptive of their purpose.
- For AWS resource-related functions, use the format `resource-type-action` (e.g., `vpc-igw`, `vpc-nat-gateways`).

### Comments
- Use `#` for single-line comments.
- Include a brief description of the function's purpose immediately after the function name.
- For complex functions, add usage examples in the comments.

### AWS CLI Commands
- Use `aws` followed by the service name (e.g., `aws ec2`, `aws rds`).
- Prefer `--output text` for consistent and easily parseable output.
- Use `--query` with JMESPath expressions for filtering and formatting output.

### Output Formatting
- Use `columnise` (a custom function) to format output into columns.
- Sort output when appropriate (e.g., `sort -k 5`).
- For listing functions, output should typically include resource IDs and names.
- Include 'NO_NAME' for resources without a Name tag.

### Error Handling
- Check for required arguments using `[[ -z "$vpc_ids" ]] && __bma_usage "vpc-id [vpc-id]" && return 1`.

### Looping
- Use `for` loops to iterate over multiple VPC IDs or other resources.

### Variable Naming
- Use lowercase for local variables (e.g., `local vpc_ids`, `local filters`).
- Use uppercase for environment variables or constants (e.g., `$AWS_DEFAULT_REGION`).

### Input Handling
- Use `skim-stdin` (a custom function) to handle both piped input and arguments.
- Allow functions to accept input from both command-line arguments and piped input.

#### skim-stdin

The `skim-stdin` function is a utility function that allows functions to accept input from both command-line arguments and piped input. It appends the first token from each line of STDIN to the argument list.

```bash
skim-stdin() {

  # Append first token from each line of STDIN to argument list
  #
  # Implementation of `pipe-skimming` pattern.
  #
  #     $ stacks | skim-stdin foo bar
  #     foo bar huginn mastodon grafana
  #
  #     $ stacks
  #     huginn    CREATE_COMPLETE  2020-01-11T06:18:46.905Z  NEVER_UPDATED  NOT_NESTED
  #     mastodon  CREATE_COMPLETE  2020-01-11T06:19:31.958Z  NEVER_UPDATED  NOT_NESTED
  #     grafana   CREATE_COMPLETE  2020-01-11T06:19:47.001Z  NEVER_UPDATED  NOT_NESTED
  #
  # Typical usage within Bash-my-AWS functions:
  #
  #     local asg_names=$(skim-stdin "$@") # Append to arg list
  #     local asg_names=$(skim-stdin)      # Only draw from STDIN

  local skimmed_stdin="$([[ -t 0 ]] || awk 'ORS=" " { print $1 }')"

  printf -- '%s %s' "$*" "$skimmed_stdin" |
    awk '{$1=$1;print}'  # trim leading/trailing spaces

}
```

### Function Structure
- Start with input validation and error handling.
- Use local variables to store intermediate results.
- Prefer using AWS CLI with appropriate filters and queries over post-processing with grep/awk when possible.

## AWS Resource Conventions

### Resource Listing
- Functions that list resources should follow a consistent output format.
- Include relevant identifiers (e.g., VPC ID, Subnet ID) in the output.
- Include resource names when available, use 'NO_NAME' for unnamed resources.

### Resource Manipulation
- Functions that modify resources should include safety checks.
- For destructive actions, include comments or echo statements explaining the process.

## Security Considerations
- Be cautious with functions that perform destructive actions (e.g., `vpc-default-delete`).
- Include safety checks before performing destructive actions.
- When dealing with sensitive information, use appropriate AWS CLI options to handle credentials securely.

## Utility Functions
- Create and use utility functions for common operations (e.g., `__bma_read_filters`, `__bma_usage`).
- Prefix internal utility functions with double underscores (e.g., `__bma_error`).

## Documentation
- Include a brief description of each function's purpose in comments.
- For complex functions or those with multiple options, include usage examples in the comments.

## Consistency
- Maintain consistent indentation (prefer 2 spaces).
- Use consistent naming conventions across all functions.

## Shared Functions

### skim-stdin
The `skim-stdin` function is a crucial utility for handling input in our scripts. It allows functions to accept input from both command-line arguments and piped input, providing flexibility in how users interact with our tools.

```bash
skim-stdin() {
  # Append first token from each line of STDIN to argument list
  #
  # Implementation of `pipe-skimming` pattern.
  #
  #     $ stacks | skim-stdin foo bar
  #     foo bar huginn mastodon grafana
  #
  #     $ stacks
  #     huginn    CREATE_COMPLETE  2020-01-11T06:18:46.905Z  NEVER_UPDATED  NOT_NESTED
  #     mastodon  CREATE_COMPLETE  2020-01-11T06:19:31.958Z  NEVER_UPDATED  NOT_NESTED
  #     grafana   CREATE_COMPLETE  2020-01-11T06:19:47.001Z  NEVER_UPDATED  NOT_NESTED

  local skimmed_stdin="$([[ -t 0 ]] || awk 'ORS=" " { print $1 }')"

  printf -- '%s %s' "$*" "$skimmed_stdin" |
    awk '{$1=$1;print}'  # trim leading/trailing spaces
}
```

Usage:
- Place `local resource_ids=$(skim-stdin "$@")` at the beginning of functions to handle both piped input and arguments.
- This allows users to either pipe in resource IDs or provide them as arguments.

### columnise
The `columnise` function is used to format output into aligned columns, improving readability:

```bash
columnise() {
  if [[ $BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT == 'true' ]] && ! [[ -t 1 ]]; then
    cat
  else
    column -t -s $'\t'
  fi
}
```

Usage:
- Pipe the output of AWS CLI commands through `columnise` to format it into aligned columns.
- Example: `aws ec2 describe-vpcs ... | columnise`

These shared functions enhance the consistency and usability of our scripts across the project.

## Examples

### Example 1: Listing a Resource (VPCs)

The `vpcs` function is an example of listing a resource type. It demonstrates how to query and format the output for VPCs:

```bash
vpcs() {
  # List VPCs
  #
  #     $ vpcs
  #     vpc-018d9739  default-vpc  NO_NAME  172.31.0.0/16  NO_STACK  NO_VERSION

  local vpc_ids=$(skim-stdin)
  local filters=$(__bma_read_filters $@)

  aws ec2 describe-vpcs       \
    ${vpc_ids/#/'--vpc-ids '} \
    --output text             \
    --query '
      Vpcs[].[
        VpcId,
        ((IsDefault==`false`)&&`not-default`)||`default-vpc`,
        join(`,`, [Tags[?Key==`Name`].Value || `NO_NAME`][]),
        CidrBlock,
        join(`,`, [Tags[?Key==`aws:cloudformation:stack-name`].Value || `NO_STACK`][]),
        join(`,`, [Tags[?Key==`version`].Value || `NO_VERSION`][])
      ]'                |
  grep -E -- "$filters" |
    columnise
}
```

This function showcases:
- Using `skim-stdin` to handle both piped input and arguments
- Applying filters with `__bma_read_filters`
- Using AWS CLI with a complex query to format the output
- Using `columnise` for consistent output formatting

### Example 2: Listing Associated Resources (VPC Subnets)

The `vpc-subnets` function is an example of listing resources associated with another resource. It demonstrates how to query and format the output for subnets associated with specific VPCs:

```bash
vpc-subnets() {
  # List subnets for a specific VPC
  #
  # USAGE: vpc-subnets vpc-id [vpc-id]
  #
  # EXAMPLE:
  #     $ vpc-subnets vpc-018d9739
  #     subnet-34fd9cfa  vpc-018d9739  ap-southeast-2c  172.31.32.0/20  NO_NAME
  #     subnet-8bb774fe  vpc-018d9739  ap-southeast-2a  172.31.0.0/20   NO_NAME
  #     subnet-9eea2c07  vpc-018d9739  ap-southeast-2b  172.31.16.0/20  NO_NAME

  local vpc_ids=$(skim-stdin "$@")
  [[ -z "$vpc_ids" ]] && __bma_usage "vpc-id [vpc-id]" && return 1

  local vpc_id
  for vpc_id in $vpc_ids; do
    aws ec2 describe-subnets                            \
      --output text                                     \
      --query "
        Subnets[?VpcId=='$vpc_id'].[
          SubnetId,
          VpcId,
          AvailabilityZone,
          CidrBlock,
          join(',', [Tags[?Key=='Name'].Value || 'NO_NAME'][])
        ]"
  done |
  columnise
}
```

This function showcases:
- Handling multiple VPC IDs
- Error checking for empty input
- Looping through VPC IDs to query associated subnets
- Formatting output consistently with `columnise`

These examples illustrate the consistent patterns used across the project for querying AWS resources and formatting the output.
