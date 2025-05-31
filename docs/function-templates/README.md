# bash-my-aws Function Templates

This directory contains comprehensive templates for implementing bash-my-aws functions. Each template includes complete examples, common patterns, customization checklists, and implementation guidance.

## Templates Overview

### [query-function-template.sh](query-function-template.sh)
**For resource listing functions** (e.g., `instances`, `stacks`, `buckets`)

- Lists AWS resources with key attributes
- Includes header support via `__bma_output_header`
- Supports filtering with grep-style patterns
- Handles piped input with `skim-stdin`
- Formats output with `columnise`
- Examples: Multiple patterns for different query scenarios

### [detail-function-template.sh](detail-function-template.sh)
**For resource attribute functions** (e.g., `instance-state`, `stack-outputs`)

- Provides specific attributes about resources
- Accepts resource IDs via arguments or stdin
- Includes patterns for simple values and structured data
- Handles key-value pairs (tags, outputs)
- Multiple fallback and validation strategies
- Examples: Complex multi-step attribute resolution

### [action-function-template.sh](action-function-template.sh)
**For resource operation functions** (e.g., `instance-terminate`, `stack-create`)

- Performs operations that modify AWS resources
- Includes safety confirmations for destructive operations
- Supports bulk operations with progress tracking
- Implements wait-for-completion patterns
- Interactive configuration examples
- Validation and dry-run operation support

## Usage Instructions

1. **Choose the appropriate template** based on your function's purpose:
   - **Query**: List resources → use query template
   - **Detail**: Get resource attributes → use detail template  
   - **Action**: Modify resources → use action template

2. **Copy the template** to your target library file (e.g., `lib/service-functions`)

3. **Replace ALL_CAPS placeholders** with actual values:
   - Function names, descriptions, AWS services
   - Column names, field names, parameters
   - Usage examples and documentation

4. **Customize the AWS CLI commands** and JMESPath queries for your specific use case

5. **Test thoroughly** and add test cases to the `test/` directory

6. **Add completion support** in `scripts/completions/`

## Template Features

### Common Patterns Included
- Input handling with `skim-stdin`
- Header output with `__bma_output_header`
- Filtering with `__bma_read_filters`
- Error handling and validation
- Usage help with `__bma_usage`
- Output formatting with `columnise`

### Safety Features
- Input validation and sanitization
- Confirmation prompts for destructive operations
- Resource existence checking
- Graceful error handling
- Timeout management for long operations

### Advanced Patterns
- Bulk operations with progress tracking
- Complex multi-service queries
- Interactive configuration
- Wait-for-completion operations
- Dry-run and validation modes

## Customization Checklists

Each template includes a comprehensive checklist covering:

- **Required Changes**: Must be customized for your function
- **Optional Changes**: Enhancements and additional features
- **Testing**: Scenarios to test before deployment
- **Safety**: Security and error handling considerations

## Related Documentation

- [Function Taxonomy](../function-taxonomy.md) - Classification and naming conventions
- [Developer Guide](../developer-guide.md) - Overall development principles
- [CONVENTIONS.md](../../CONVENTIONS.md) - Code style and patterns
- [Header Implementation Guide](../implementing-headers-guide.md) - Header support details

## Examples in Codebase

Study existing functions for real-world implementations:

- **Query**: `instances()`, `stacks()`, `vpcs()` in respective lib files
- **Detail**: `instance-state()`, `stack-outputs()`, `bucket-size()`
- **Action**: `instance-terminate()`, `stack-create()`, `asg-suspend()`

These templates are designed to ensure consistency, reliability, and maintainability across all bash-my-aws functions.