# Header Implementation Checklist

Quick reference for implementing headers in bash-my-aws functions.

## Pre-Implementation
- [ ] Read `docs/implementing-headers-guide.md` for detailed instructions
- [ ] Check that enhanced `skim-stdin` and `__bma_output_header` are in `lib/shared-functions`
- [ ] Understand the command group pattern `{ header; data } | columnise`

## For Each Function
1. **Identify Resource Listing Functions**
   - Look for functions that output tabular data
   - Check for functions using `columnise`
   - Skip functions that output single values or perform actions

2. **Implementation Pattern**
   ```bash
   function_name() {
     local vars=$(skim-stdin)
     local filters=$(__bma_read_filters $@)
     
     {
       __bma_output_header "COL1	COL2	COL3"  # Use tabs!
       aws command ... |
       grep -E -- "$filters"
     } | columnise
   }
   ```

3. **Column Headers**
   - Use UPPERCASE_WITH_UNDERSCORES
   - Separate with tabs, not spaces
   - Match the exact number of data columns
   - Keep names concise but descriptive

4. **Update Documentation**
   - Add `# HEADER_LINE` to function examples
   - Ensure examples show realistic output

5. **Testing**
   ```bash
   # Create test file: test/test-{library}-headers.sh
   # Test 1: Headers show with BMA_HEADERS=always
   # Test 2: Headers hidden with BMA_HEADERS=never  
   # Test 3: Pipe-skimming still works
   # Test 4: Backwards compatibility maintained
   ```

## Common Patterns

### Simple Single Query
```bash
{
  __bma_output_header "ID	NAME	STATUS"
  aws service describe-things \
    --query 'Things[].[Id,Name,Status]' \
    --output text |
  grep -E -- "$filters"
} | columnise
```

### Functions with Loops
```bash
{
  __bma_output_header "ID	TYPE	NAME"
  for item in $items; do
    aws service describe-thing \
      --thing-id "$item" \
      --query '[Id,Type,Name]' \
      --output text
  done
} | columnise
```

### Multiple Column Sets
```bash
{
  case "$type" in
    type1)
      __bma_output_header "ID	NAME"
      # query for type1
      ;;
    type2)
      __bma_output_header "ID	SIZE	REGION"
      # query for type2
      ;;
  esac
} | columnise
```

## Gotchas to Avoid
- ❌ Don't put `columnise` inside the command group
- ❌ Don't use spaces between columns (use tabs)
- ❌ Don't forget to update documentation examples
- ❌ Don't add headers to non-tabular output functions
- ❌ Don't break functions that call other functions

## Quick Test Commands
```bash
# Test your implementation
export BMA_HEADERS=always
source lib/shared-functions
source lib/your-functions
your-function  # Should show headers

# Test pipe-skimming
your-function | head -1  # Should show header
your-function | grep -v '^#' | head -1  # Should show first data line
```

## Files to Reference
- `lib/shared-functions` - Core header functionality
- `lib/keypair-functions` - Simple implementation example
- `lib/stack-functions` - Complex implementation example
- `docs/implementing-headers-guide.md` - Detailed guide
- `test/test-headers.sh` - Core functionality tests