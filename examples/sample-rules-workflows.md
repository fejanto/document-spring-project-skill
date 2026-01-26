# Common Workflows (Order Management Service)

## Agregar Nuevo Endpoint

1. Crear método en Controller (`@RestController`)
2. Implementar lógica en Service
3. **CRÍTICO**: SIEMPRE publicar eventos de cambio de estado
4. Agregar tests (naming: `whenDoingSomething_givenScenario_shouldResult()`)
5. Actualizar documentación:
   - `CLAUDE.md` si cambia API pública
   - `.claude/rules/` si hay nuevas reglas
   - `/docs/` para detalles exhaustivos

### Patrón de Implementación (OBLIGATORIO)

```java
@PostMapping("/{id}/confirm")
public ResponseEntity<OrderResponse> confirmOrder(@PathVariable String id) {
    // 1. Validar negocio
    Order order = orderService.getOrder(id);
    if (!order.canBeConfirmed()) {
        throw new OrderCannotBeConfirmedException(order.getState());
    }

    // 2. Ejecutar operación
    Order confirmed = orderService.confirmOrder(id);

    // 3. Publicar evento (CRÍTICO)
    eventPublisher.publish(new OrderConfirmedEvent(confirmed));

    // 4. Retornar respuesta
    return ResponseEntity.ok(toResponse(confirmed));
}
```

## Agregar Nueva Entidad

1. Crear clase con `@Entity` y `@Table`
2. Agregar `@Version` para optimistic locking
3. Definir relaciones con otras entidades
4. Crear Repository interface
5. Agregar a documentación:
   - README.md (Domain Model section)
   - `.claude/rules/domain.md`
   - `/docs/domain/{entity}-model.md`

## Modificar State Machine

**PRECAUCIÓN**: Proceso crítico

1. Entender las transiciones actuales
2. Identificar qué transición se añade/modifica
3. Actualizar método `canTransitionTo()`
4. Actualizar evento correspondiente
5. Tests exhaustivos con todos los estados
6. **Review obligatorio** antes de merge

**Archivos clave**:
- `Order.java`
- `OrderState.java`
- `OrderStateMachine.java`
- `OrderEventPublisher.java`

## Documentation Maintenance (OBLIGATORIO)

Después de completar features, SIEMPRE actualizar:

| Cambio | Actualizar en |
|--------|---------------|
| Nuevo tipo de Order | README.md, CLAUDE.md |
| Nuevo estado | README.md, `.claude/rules/domain.md` |
| Nuevo endpoint | README.md, `.claude/rules/workflows.md` |
| Nuevo patrón arquitectónico | `.claude/rules/architecture.md`, `/docs/architecture/` |
| Nueva integración | CLAUDE.md, `.claude/rules/architecture.md` |

## Error Codes Reference

### General

| Código | Descripción |
|--------|-------------|
| `ERROR-001` | Error genérico no especificado |
| `NF-001` | Resource not found |

### Orders (ORD-xxx)

| Código | Descripción |
|--------|-------------|
| `ORD-001` | Order not found |
| `ORD-002` | Order cannot be confirmed (estado inválido) |
| `ORD-003` | Order cannot be cancelled (estado inválido) |
| `ORD-004` | Order modification not allowed (estado != PENDING) |
| `ORD-005` | Order concurrent modification detected |

### Inventory (INV-xxx)

| Código | Descripción |
|--------|-------------|
| `INV-001` | Insufficient stock |
| `INV-002` | Stock reservation failed |

### Payment (PAY-xxx)

| Código | Descripción |
|--------|-------------|
| `PAY-001` | Payment validation failed |
| `PAY-002` | Payment service unavailable |

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

- Todas las transiciones de estado
- Validación de inventario
- Cálculo de penalizaciones
- Timeouts automáticos
- Cache invalidation
- Event publication

**Referencia completa**: `~/.claude/rules/testing-java.md` (global)
