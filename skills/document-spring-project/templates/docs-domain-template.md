# {{ENTITY_NAME}} Domain Model

## Overview

{{ENTITY_OVERVIEW}}

## Lifecycle

{{ENTITY_LIFECYCLE_DESCRIPTION}}

```
{{LIFECYCLE_DIAGRAM}}
```

## Business Rules

{{#each BUSINESS_RULES}}
### {{index}}. {{title}}

{{description}}

{{#if has_example}}
**Example:**

```java
{{example}}
```
{{/if}}

{{#if has_constraints}}
**Constraints:**
{{#each constraints}}
- {{this}}
{{/each}}
{{/if}}

{{/each}}

## Relationships

{{#each RELATIONSHIPS}}
### {{type}} with {{target_entity}}

- **Type**: {{relationship_type}}
- **Cardinality**: {{cardinality}}
- **Description**: {{description}}
{{#if cascade_operations}}
- **Cascade**: {{cascade_operations}}
{{/if}}

{{/each}}

## Validation Rules

{{#each VALIDATION_RULES}}
- **{{field}}**: {{rule}}
{{/each}}

## Events

{{#if PUBLISHES_EVENTS}}
This entity publishes the following events:

{{#each PUBLISHED_EVENTS}}
- **{{event_name}}**: {{description}}
  - **When**: {{trigger}}
  - **Payload**: {{payload_description}}
{{/each}}
{{/if}}

## Database Mapping

- **Table**: `{{TABLE_NAME}}`
{{#if HAS_INDEXES}}
- **Indexes**:
{{#each INDEXES}}
  - {{this}}
{{/each}}
{{/if}}

## Examples

### Creation

```java
{{CREATION_EXAMPLE}}
```

### State Transitions

```java
{{STATE_TRANSITION_EXAMPLE}}
```

## Related Documentation

- [{{SERVICE_NAME}} Architecture](../architecture/)
- [Database Schema](../database/database-schema.md)
- [Common Workflows](../../.claude/rules/workflows.md)
