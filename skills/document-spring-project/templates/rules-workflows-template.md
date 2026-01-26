# Common Workflows ({{SERVICE_NAME}})

## Agregar Nuevo Endpoint

1. Crear método en Controller (`@RestController`)
2. Implementar lógica en Service
3. **CRÍTICO**: {{SERVICE_SPECIFIC_GUIDELINE}}
4. Agregar tests (naming: `whenDoingSomething_givenScenario_shouldResult()`)
5. Actualizar documentación:
   - `CLAUDE.md` si cambia API pública
   - `.claude/rules/` si hay nuevas reglas
   - `/docs/` para detalles exhaustivos

{{#if HAS_PATTERN_EXAMPLE}}
### Patrón de Implementación (OBLIGATORIO)

```java
{{IMPLEMENTATION_PATTERN_EXAMPLE}}
```
{{/if}}

## Agregar Nueva Entidad

{{#each ADD_ENTITY_STEPS}}
{{index}}. {{this}}
{{/each}}

{{#if HAS_CRITICAL_COMPONENT}}
## Modificar {{CRITICAL_COMPONENT_NAME}}

**PRECAUCIÓN**: Proceso crítico

{{#each CRITICAL_COMPONENT_STEPS}}
{{index}}. {{this}}
{{/each}}

**Archivos clave**:
{{#each CRITICAL_COMPONENT_FILES}}
- {{this}}
{{/each}}
{{/if}}

## Documentation Maintenance (OBLIGATORIO)

Después de completar features, SIEMPRE actualizar:

| Cambio | Actualizar en |
|--------|---------------|
{{#each DOC_UPDATE_RULES}}
| {{change}} | {{update_location}} |
{{/each}}

## Error Codes Reference

### General

| Código | Descripción |
|--------|-------------|
{{#each GENERAL_ERROR_CODES}}
| `{{code}}` | {{description}} |
{{/each}}

{{#each ERROR_CODE_CATEGORIES}}
### {{category}} ({{prefix}}-xxx)

| Código | Descripción |
|--------|-------------|
{{#each codes}}
| `{{code}}` | {{description}} |
{{/each}}

{{/each}}

## Testing Requirements

### Naming Convention

```java
whenDoingSomething_givenScenario_shouldResult()
```

### Structure

- Nunca usar comments para declare steps (given/when/then)
- Usar líneas en blanco para separar bloques
- Cada test instancia sus propios mocks (no shared state)
- Preferir objetos reales sobre mocks para POJOs

### What to Test

{{#each TEST_REQUIREMENTS}}
- {{this}}
{{/each}}

**Referencia completa**: `~/.claude/rules/testing-java.md` (global)
