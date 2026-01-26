# Database Schema

## Overview

{{DATABASE_OVERVIEW}}

- **Database**: {{DATABASE_TYPE}} {{DATABASE_VERSION}}
- **Schema**: `{{SCHEMA_NAME}}`
- **Total Tables**: {{TABLE_COUNT}}

## Tables

{{#each TABLES}}
### {{name}}

{{description}}

**Columns:**

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
{{#each columns}}
| `{{name}}` | {{type}} | {{nullable}} | {{default}} | {{description}} |
{{/each}}

**Constraints:**

{{#if has_primary_key}}
- **Primary Key**: `{{primary_key}}`
{{/if}}

{{#if has_foreign_keys}}
**Foreign Keys:**
{{#each foreign_keys}}
- `{{column}}` → `{{referenced_table}}.{{referenced_column}}`
{{#if on_delete}}  - ON DELETE: {{on_delete}}{{/if}}
{{#if on_update}}  - ON UPDATE: {{on_update}}{{/if}}
{{/each}}
{{/if}}

{{#if has_unique_constraints}}
**Unique Constraints:**
{{#each unique_constraints}}
- `{{this}}`
{{/each}}
{{/if}}

{{#if has_check_constraints}}
**Check Constraints:**
{{#each check_constraints}}
- {{this}}
{{/each}}
{{/if}}

**Indexes:**

{{#each indexes}}
- `{{name}}`: {{columns}} {{#if is_unique}}(UNIQUE){{/if}}
  - **Purpose**: {{purpose}}
  {{#if notes}}- **Notes**: {{notes}}{{/if}}
{{/each}}

---

{{/each}}

## Relationships

```
{{RELATIONSHIP_DIAGRAM}}
```

{{#each RELATIONSHIPS}}
### {{from_table}} ↔ {{to_table}}

- **Type**: {{relationship_type}}
- **Cardinality**: {{cardinality}}
- **Foreign Key**: `{{from_table}}.{{from_column}}` → `{{to_table}}.{{to_column}}`
{{#if description}}- **Description**: {{description}}{{/if}}

{{/each}}

## Indexes Strategy

{{#each INDEX_STRATEGIES}}
### {{category}}

{{description}}

**Indexes:**
{{#each indexes}}
- `{{name}}` on `{{table}}({{columns}})`
  - **Query Pattern**: {{query_pattern}}
  - **Benefit**: {{benefit}}
{{/each}}

{{/each}}

## Data Types

{{#each CUSTOM_DATA_TYPES}}
### {{name}}

- **Type**: {{type}}
- **Purpose**: {{purpose}}
- **Usage**: {{usage}}

{{/each}}

## Migrations

{{#if HAS_MIGRATIONS}}
### Migration History

{{#each MIGRATIONS}}
- **{{version}}** ({{date}}): {{description}}
  - File: `{{file_path}}`
{{/each}}

### Running Migrations

{{MIGRATION_INSTRUCTIONS}}
{{/if}}

## Performance Tuning

### Query Optimization

{{#each QUERY_OPTIMIZATIONS}}
#### {{title}}

{{description}}

**Before:**
```sql
{{before_query}}
```

**After:**
```sql
{{after_query}}
```

**Impact**: {{impact}}

{{/each}}

### Index Recommendations

{{#each INDEX_RECOMMENDATIONS}}
- **Table**: `{{table}}`
  - **Columns**: `{{columns}}`
  - **Reason**: {{reason}}
  - **Query Pattern**: {{query_pattern}}
{{/each}}

## Maintenance

### Vacuum Strategy

{{VACUUM_STRATEGY}}

### Statistics

{{STATISTICS_NOTES}}

### Backup

{{BACKUP_NOTES}}

## Related Documentation

- [Domain Models](../domain/)
- [Architecture Patterns](../architecture/)
- [Domain Rules](../../.claude/rules/domain.md)
