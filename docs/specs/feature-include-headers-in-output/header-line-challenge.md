# Header Line Challenge for bash-my-aws Resource Listing Functions

## Background

bash-my-aws is a popular 10+ year old project that provides CLI commands for managing AWS resources. The project follows consistent patterns for listing resources but currently does not include header lines in its output.

## Current Implementation

### Output Format
- Functions output TSV (Tab-Separated Values) by default
- The `columnise` function converts TSV to fixed-width columns when stdout is a terminal
- No headers are included in the output

### Example Output
```bash
$ instances
i-4e15ece1de1a3f869  ami-123456789012  t3.nano  running  nagios          2019-12-10T08:17:18.000Z  ap-southeast-2a  None
i-89cefa9403373d7a5  ami-123456789012  t3.nano  running  postgres1       2019-12-10T08:17:20.000Z  ap-southeast-2a  None
```

## The Challenge

We want to add header lines to resource listing functions to improve usability, but face several constraints:

### 1. **skim-stdin() Compatibility**
The `skim-stdin()` function is fundamental to bash-my-aws's pipe-friendly design. It extracts the first token from each line of stdin and appends it to the argument list. Headers would be interpreted as resource IDs, breaking this pattern.

Example of the problem:
```bash
# If instances had headers:
$ instances | instance-stop
# Would try to stop an instance with ID "InstanceId" (the header)
```

### 2. **Backwards Compatibility**
- The project is over 10 years old with an established user base
- Scripts and automation depend on the current output format
- Breaking changes would impact many users

### 3. **Consistency Across Output Modes**
- Output should be predictable whether piped or displayed in terminal
- Showing headers only when stdout is a terminal would surprise users
- Example: `instances > file.txt` would have different format than `instances`

### 4. **stderr is Not Suitable**
- Sending headers to stderr was considered but rejected
- stderr is for errors and diagnostics, not data formatting
- Would complicate piping and redirection

## Requirements for a Solution

1. **Must not break skim-stdin()** - The pipe-skimming pattern must continue to work
2. **Backwards compatible** - Existing scripts must not break
3. **Consistent behavior** - Same output format regardless of terminal/pipe
4. **Clean implementation** - Should fit with bash-my-aws design philosophy
5. **Opt-in or smart detection** - Headers should not appear by default if they break existing usage

## Potential Solution Directions

### 1. **Metadata/Header Mode**
- Add a flag or environment variable to enable headers
- When enabled, functions could output headers before data
- skim-stdin could be made header-aware

### 2. **Alternative Output Formats**
- Support different output formats (json, yaml, table)
- Headers would be natural in structured formats
- Maintain TSV as default for compatibility

### 3. **Smart Header Detection**
- Detect when output is being used by bash-my-aws functions
- Skip headers when piping between bash-my-aws commands
- Include headers for direct terminal output

### 4. **Header-aware skim-stdin**
- Enhance skim-stdin to detect and skip header lines
- Could use special markers or patterns
- Maintains compatibility while adding functionality

## Questions to Explore

1. How do other CLI tools handle this problem?
2. What patterns exist for backwards-compatible enhancements?
3. Can we detect bash-my-aws function chains vs external usage?
4. What would be the minimal change for maximum benefit?
5. Could we use a progressive enhancement approach?

## Success Criteria

A successful solution would:
- Allow new users to see helpful headers
- Not break any existing workflows
- Be simple to implement and maintain
- Feel natural within the bash-my-aws ecosystem
- Potentially inspire similar improvements in other functions