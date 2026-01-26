# Domain Business Rules ({{SERVICE_NAME}})

{{#if HAS_ENTITY_HIERARCHY}}
## {{MAIN_ENTITY}} Hierarchy

```
{{ENTITY_HIERARCHY_DIAGRAM}}
```
{{/if}}

## Estados de {{MAIN_ENTITY}}

### Estados Principales

| Estado | Metadata | Descripción |
|--------|----------|-------------|
{{#each ENTITY_STATES}}
| **{{name}}** | {{metadata}} | {{description}} |
{{/each}}

### Metadatos de Estado

{{#each STATE_METADATA}}
- **{{key}}**: {{description}}
{{/each}}

## Reglas Críticas

{{#each CRITICAL_BUSINESS_RULES}}
### {{index}}. {{name}} ({{review_required}})

{{#each details}}
- {{this}}
{{/each}}

{{#if has_code_example}}
```java
{{code_example}}
```
{{/if}}

{{/each}}

{{#if HAS_STATE_MACHINE}}
## State Machine

- SIEMPRE verificar `stateMachine.can(action)` antes de transiciones
- Transiciones inválidas lanzan `{{STATE_MACHINE_EXCEPTION}}`
- Log de transiciones se guarda para auditoría

### Transiciones Críticas

```
{{#each STATE_TRANSITIONS}}
{{from}} → {{to}}  ({{action}})
{{/each}}
```
{{/if}}

## Database Schema Quick Reference

### Tablas Principales

{{#each DATABASE_TABLES}}
- **{{name}}**: {{description}}
{{/each}}

## Performance Considerations

{{#each DOMAIN_PERFORMANCE_NOTES}}
- {{this}}
{{/each}}

## ⚠️ CRITICAL WARNINGS

{{#each DOMAIN_CRITICAL_WARNINGS}}
### {{title}}

```java
// ❌ PROHIBIDO
{{bad_example}}

// ✅ CORRECTO
{{good_example}}
```

**Razón**: {{reason}}
{{/each}}
