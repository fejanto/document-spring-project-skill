# {{PATTERN_NAME}} Pattern

## Problem

{{PROBLEM_DESCRIPTION}}

### Symptoms

{{#each SYMPTOMS}}
- {{this}}
{{/each}}

### Why It Matters

{{WHY_IT_MATTERS}}

## Solution

{{SOLUTION_DESCRIPTION}}

### Key Principles

{{#each KEY_PRINCIPLES}}
{{index}}. **{{title}}**: {{description}}
{{/each}}

## Implementation

### Architecture

```
{{ARCHITECTURE_DIAGRAM}}
```

### Code Structure

```java
{{CODE_STRUCTURE_EXAMPLE}}
```

### Step-by-Step

{{#each IMPLEMENTATION_STEPS}}
#### Step {{index}}: {{title}}

{{description}}

```java
{{code_example}}
```

{{#if has_notes}}
**Notes:**
{{#each notes}}
- {{this}}
{{/each}}
{{/if}}

{{/each}}

## Benefits

{{#each BENEFITS}}
- **{{title}}**: {{description}}
{{/each}}

## Trade-offs

{{#each TRADEOFFS}}
- **{{title}}**: {{description}}
{{/each}}

## When to Use

{{#each WHEN_TO_USE}}
✅ {{this}}
{{/each}}

## When NOT to Use

{{#each WHEN_NOT_TO_USE}}
❌ {{this}}
{{/each}}

## Common Pitfalls

{{#each COMMON_PITFALLS}}
### {{index}}. {{title}}

**Problem**: {{problem}}

**Solution**: {{solution}}

```java
// ❌ WRONG
{{wrong_example}}

// ✅ CORRECT
{{correct_example}}
```

{{/each}}

## Performance Considerations

{{#each PERFORMANCE_CONSIDERATIONS}}
- {{this}}
{{/each}}

## Testing Strategy

{{TESTING_STRATEGY_DESCRIPTION}}

```java
{{TESTING_EXAMPLE}}
```

## Related Patterns

{{#each RELATED_PATTERNS}}
- **{{name}}**: {{relationship}}
{{/each}}

## References

- [Domain Model](../domain/)
- [Common Workflows](../../.claude/rules/workflows.md)
- [Architecture Rules](../../.claude/rules/architecture.md)

## Examples from Codebase

{{#each CODEBASE_EXAMPLES}}
### {{title}}

**File**: `{{file_path}}`

{{description}}

```java
{{code_snippet}}
```

{{/each}}
