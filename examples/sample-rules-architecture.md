# Architecture Patterns (Order Management Service)

## 1. Event-Driven State Transitions (CRÍTICO)

### Cuándo Usar

- SIEMPRE para cambios de estado de pedidos
- Cualquier operación que afecte el ciclo de vida del pedido
- Integraciones con servicios downstream

### Cómo Usar

```java
// ✅ CORRECTO - Publica evento después de cambio de estado
public void confirmOrder(String orderId) {
    Order order = orderRepository.findById(orderId)
        .orElseThrow(() -> new OrderNotFoundException(orderId));

    order.confirm();
    orderRepository.save(order);

    // Publicar evento DESPUÉS de persistir
    eventPublisher.publish(new OrderConfirmedEvent(order));
}

// ❌ INCORRECTO - No publica evento
public void confirmOrder(String orderId) {
    Order order = orderRepository.findById(orderId);
    order.confirm();
    orderRepository.save(order);
    // ❌ Falta publicación de evento
}
```

### NUNCA

- Cambiar estado sin publicar evento correspondiente
- Publicar evento ANTES de persistir (puede fallar el save)
- Usar transacciones distribuidas (usar eventos + compensación)

**Referencia completa**: `/docs/architecture/event-driven-state-machine.md`

---

## 2. Optimistic Locking para Concurrencia (IMPORTANTE)

### Problema Resuelto

Race conditions cuando múltiples requests intentan modificar el mismo pedido.

### Patrón

```java
@Entity
public class Order {
    @Version
    private Long version;  // ← Hibernate maneja automáticamente

    // ... resto de la entidad
}
```

### Manejo de Conflictos

```java
try {
    order.confirm();
    orderRepository.save(order);
} catch (OptimisticLockException e) {
    // Reintentar operación con estado fresco
    throw new OrderConcurrencyException("Order was modified by another request");
}
```

**Referencia completa**: `/docs/architecture/optimistic-locking.md`

---

## 3. Cache-Aside Pattern con Redis (IMPORTANTE)

### Cuándo Usar

- Lectura de pedidos activos (estado != COMPLETED)
- Queries frecuentes por customerId
- NO para escrituras críticas

### Patrón

```java
// ✅ CORRECTO - Cache-aside
public Order getOrder(String orderId) {
    // 1. Intentar desde cache
    Order cached = redisCache.get(orderId);
    if (cached != null) {
        return cached;
    }

    // 2. Si no está, traer de DB
    Order order = orderRepository.findById(orderId)
        .orElseThrow(() -> new OrderNotFoundException(orderId));

    // 3. Guardar en cache (solo si está activo)
    if (!order.isCompleted()) {
        redisCache.put(orderId, order, Duration.ofMinutes(15));
    }

    return order;
}
```

### Invalidación

```java
// Invalidar cache después de UPDATE/DELETE
public void updateOrder(Order order) {
    orderRepository.save(order);
    redisCache.evict(order.getId());  // ← IMPORTANTE
}
```

**Referencia completa**: `/docs/architecture/cache-aside-pattern.md`

---

## Performance Considerations

- Cache TTL: 15 minutos para pedidos activos
- Índices en (customer_id, state) para queries frecuentes
- Paginación obligatoria en listados (max 100 items)

## ⚠️ CRITICAL WARNINGS

### NUNCA Modificar Estado Directamente

```java
// ❌ PROHIBIDO - Bypass de state machine
order.setState(OrderState.CONFIRMED);
orderRepository.save(order);

// ✅ CORRECTO - Usar métodos de dominio
order.confirm();
orderRepository.save(order);
eventPublisher.publish(new OrderConfirmedEvent(order));
```

**Razón**: Los métodos de dominio validan transiciones y aplican business rules.
