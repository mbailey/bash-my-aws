# Claude Code Guide for bash-my-aws

This guide provides specific instructions for working on the bash-my-aws project using Claude Code.

## Project Understanding

### Essential Reading
- **README.md** - Project overview, installation, and usage examples
- **CONVENTIONS.md** - Code style, patterns, and implementation standards
- **docs/function-taxonomy.md** - Complete function type classification
- **docs/developer-guide.md** - Development principles and patterns

### Project Structure
```
bash-my-aws/
├── lib/                          # Core function libraries
│   ├── shared-functions         # Common utilities and helpers
│   ├── instance-functions       # EC2 instance operations
│   ├── stack-functions          # CloudFormation operations  
│   ├── vpc-functions            # VPC networking operations
│   └── [service]-functions      # Other AWS service functions
├── docs/
│   ├── function-templates/      # Implementation templates
│   └── [documentation files]
├── test/                        # Test suites
└── scripts/completions/         # Bash completion scripts
```

## Function Implementation Guidelines

### Using Function Templates
When implementing new functions, ALWAYS use the appropriate template:

```bash
# For resource listing functions (instances, stacks, buckets)
cp docs/function-templates/query-function-template.sh target-location

# For resource attribute functions (instance-state, stack-outputs)  
cp docs/function-templates/detail-function-template.sh target-location

# For resource operation functions (instance-terminate, stack-create)
cp docs/function-templates/action-function-template.sh target-location
```

### Implementation Checklist
1. **Choose appropriate template** based on function purpose
2. **Replace ALL_CAPS placeholders** with actual values
3. **Implement header support** using `__bma_output_header`
4. **Add filtering support** using `__bma_read_filters`
5. **Handle piped input** using `skim-stdin`
6. **Format output** using `columnise`
7. **Add completion support** in `scripts/completions/`
8. **Create test cases** in `test/` directory

### Core Patterns to Follow

#### Header Implementation
```bash
# Always include headers for query functions
__bma_output_header COLUMN1 COLUMN2 COLUMN3

# Use command group pattern for proper alignment
{
  __bma_output_header INSTANCE_ID AMI_ID TYPE STATE
  aws ec2 describe-instances --query '...' --output text
} | columnise
```

#### Input Handling
```bash
# Support both arguments and piped input
local resource_ids=$(skim-stdin "$@")
local filters=$(__bma_read_filters "$@")

# Validate required inputs
[[ -z "$resource_ids" ]] && __bma_usage "resource-id [resource-id]" && return 1
```

#### Error Handling
```bash
# Use project utilities for consistent error handling
__bma_usage "resource-id [optional-param]"     # Usage help
__bma_error "Error message"                    # Error messages

# Handle AWS CLI failures gracefully
aws service command 2>/dev/null || echo "NO_DATA"
```

## Testing Requirements

### Always Test
- Functions with no arguments
- Functions with filter arguments  
- Functions with piped input
- Header display modes (BMA_HEADERS=always/auto/never)
- Error conditions and edge cases

### Running Tests
```bash
# Run specific test suites
make test                          # All tests
./test/test-headers.sh            # Header functionality
./test/test-[library]-headers.sh  # Specific library tests
```

## Header System Details

### Environment Variable Control
```bash
export BMA_HEADERS=always   # Default: always show headers
export BMA_HEADERS=auto     # Headers only in terminal
export BMA_HEADERS=never    # Never show headers
```

### Header Implementation Requirements
- Query functions MUST include headers
- Detail functions MAY include headers for tabular output
- Action functions RARELY need headers
- Headers are comment lines starting with `#`
- Use `__bma_output_header` with multiple arguments (NOT tab-separated strings)

## Library-Specific Guidelines

### lib/shared-functions
- Contains core utilities used by all other libraries
- Key functions: `skim-stdin`, `__bma_output_header`, `__bma_read_filters`
- Changes here affect ALL functions - test thoroughly

### Service Function Libraries
- Each AWS service has its own library file
- Follow established patterns within each library
- Maintain consistent column ordering for related functions
- Use appropriate AWS CLI service names and commands

## Git Workflow

### Branch Naming
- Use descriptive branch names: `feature/add-lambda-functions`
- Include issue numbers when applicable: `fix/issue-123-header-alignment`

### Commit Messages
- Use conventional commit format
- Include context about changes made
- Always include the Claude Code signature:
```
feat: Add comprehensive lambda function support

- Implement lambda-functions library with 12 new functions
- Add query, detail, and action function patterns
- Include comprehensive test suite and completion support

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Pre-commit Requirements
- Ensure all tests pass
- Verify header functionality works correctly
- Check bash completion is updated if needed
- Validate function follows established patterns

## Common Tasks for Claude Code

### Adding New Function Libraries
1. Create new `lib/[service]-functions` file
2. Implement functions using appropriate templates
3. Add completion support in `scripts/completions/`
4. Create test file in `test/test-[service]-headers.sh`
5. Update documentation as needed

### Fixing Header Issues
1. Check `__bma_output_header` usage (no tab-separated strings)
2. Verify command group pattern: `{ header; data } | columnise`
3. Test with different BMA_HEADERS settings
4. Ensure `skim-stdin` skips comment lines properly

### Performance Optimization
1. Optimize AWS CLI queries and JMESPath expressions
2. Minimize number of API calls
3. Use efficient sorting and filtering
4. Consider caching for expensive operations

## Environment Setup

### Required Environment Variables
```bash
# Essential for proper functionality
export BMA_HEADERS=always
export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=true

# Development helpers
export BMA_DEBUG=true                    # Enable debug output
export BMA_LOG_FILE=/tmp/bma-debug.log  # Log operations
```

### Development Tools
- **jq**: Required for JSON processing in some functions
- **column**: Used by `columnise` for output formatting
- **aws-cli**: Obviously required for all AWS operations
- **bash-completion**: For testing completion functionality

## Best Practices for Claude Code

### Code Review
- Always read existing implementations before adding new functions
- Follow established patterns in the target library
- Maintain backward compatibility
- Use consistent naming and parameter ordering

### Documentation
- Update function templates if new patterns emerge
- Add examples to function comments
- Keep CONVENTIONS.md current with any new patterns
- Update completion scripts for new functions

### Safety
- Include confirmation prompts for destructive operations
- Validate input parameters thoroughly
- Handle missing resources gracefully
- Test error conditions extensively

## Troubleshooting Common Issues

### Headers Not Showing
- Check BMA_HEADERS environment variable
- Verify `__bma_output_header` is called correctly
- Ensure command group pattern is used: `{ header; data } | columnise`

### Pipe-skimming Not Working
- Verify `skim-stdin` is used for input handling
- Check that headers start with `#` character
- Ensure `skim-stdin` function is working correctly

### Completion Not Working
- Add function to appropriate completion script
- Source bash_completion.sh after changes
- Test completion with `[command][TAB][TAB]`

### Tests Failing
- Check expected output format matches actual output
- Verify header names match exactly
- Ensure test uses correct BMA_HEADERS setting

Remember: bash-my-aws values simplicity, consistency, and pipe-friendliness. Always prioritize these principles when implementing new functionality.