# Architecture Patterns ({{SERVICE_NAME}})

{{#each ARCHITECTURE_PATTERNS}}
## {{index}}. {{name}} ({{criticality}})

### Cuándo Usar

{{#each when_to_use}}
- {{this}}
{{/each}}

### Cómo Usar

```java
// ✅ CORRECTO
{{correct_example}}

// ❌ INCORRECTO
{{incorrect_example}}
```

### NUNCA

{{#each never_do}}
- {{this}}
{{/each}}

**Referencia completa**: `/docs/architecture/{{slug}}.md`

---

{{/each}}

## Performance Considerations

{{#each PERFORMANCE_NOTES}}
- {{this}}
{{/each}}

## ⚠️ CRITICAL WARNINGS

{{#each CRITICAL_WARNINGS}}
### {{title}}

```java
// ❌ PROHIBIDO
{{bad_example}}

// ✅ CORRECTO
{{good_example}}
```

**Razón**: {{reason}}
{{/each}}
