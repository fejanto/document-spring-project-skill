# Domain Business Rules (Order Management Service)

## Order Lifecycle

```
Order States:
PENDING → PAYMENT_PENDING → CONFIRMED → PREPARING → SHIPPED → DELIVERED
                                      ↓
                                   CANCELLED
```

## Estados de Order

### Estados Principales

| Estado | Descripción | Puede Cancelar | Puede Modificar |
|--------|-------------|----------------|-----------------|
| **PENDING** | Recién creado, esperando pago | ✅ Sí | ✅ Sí |
| **PAYMENT_PENDING** | Esperando confirmación de pago | ✅ Sí | ❌ No |
| **CONFIRMED** | Pago confirmado, listo para preparar | ✅ Sí | ❌ No |
| **PREPARING** | En preparación en almacén | ⚠️ Con penalización | ❌ No |
| **SHIPPED** | Enviado al cliente | ❌ No | ❌ No |
| **DELIVERED** | Entregado al cliente | ❌ No | ❌ No |
| **CANCELLED** | Cancelado por usuario o sistema | N/A | ❌ No |

## Reglas Críticas

### 1. Validación de Inventario (NO MODIFICAR SIN REVIEW)

- SIEMPRE verificar stock ANTES de confirmar pedido
- Si no hay stock: mover a PENDING y notificar al cliente
- Reservar stock al confirmar (evento → inventory-service)
- Liberar stock al cancelar

```java
// ✅ CORRECTO
public void confirmOrder(String orderId) {
    Order order = getOrder(orderId);

    // 1. Validar stock primero
    boolean hasStock = inventoryClient.checkStock(order.getItems());
    if (!hasStock) {
        throw new InsufficientStockException();
    }

    // 2. Confirmar pedido
    order.confirm();
    save(order);

    // 3. Reservar stock
    eventPublisher.publish(new StockReservationRequested(order));
}
```

### 2. Cancelación con Penalización

- Pedidos en PENDING/PAYMENT_PENDING: cancelación gratuita
- Pedidos en CONFIRMED: sin penalización (no se preparó)
- Pedidos en PREPARING: penalización de $5 (ya se asignó personal)
- Pedidos en SHIPPED/DELIVERED: NO se pueden cancelar

```java
public void cancelOrder(String orderId, String reason) {
    Order order = getOrder(orderId);

    if (!order.canBeCancelled()) {
        throw new OrderCannotBeCancelledException(order.getState());
    }

    BigDecimal penalty = calculateCancellationPenalty(order);
    order.cancel(reason, penalty);
    save(order);
}

private BigDecimal calculateCancellationPenalty(Order order) {
    return switch (order.getState()) {
        case PENDING, PAYMENT_PENDING, CONFIRMED -> BigDecimal.ZERO;
        case PREPARING -> new BigDecimal("5.00");
        default -> throw new IllegalStateException("Cannot calculate penalty");
    };
}
```

### 3. Timeout Automático

- PAYMENT_PENDING: timeout después de 15 minutos → CANCELLED
- PENDING: timeout después de 24 horas → CANCELLED
- Job scheduled ejecuta cada 5 minutos

### 4. Modificación de Pedidos

- SOLO permitido en estado PENDING
- NO se puede modificar después de PAYMENT_PENDING
- Si el cliente quiere cambiar: cancelar y crear nuevo

## State Machine

- SIEMPRE verificar `order.canTransitionTo(newState)` antes de transiciones
- Transiciones inválidas lanzan `InvalidStateTransitionException`
- Log de transiciones se guarda en `order_state_log` table

### Transiciones Críticas

```
PENDING → PAYMENT_PENDING           (submitPayment)
PAYMENT_PENDING → CONFIRMED         (confirmPayment)
CONFIRMED → PREPARING               (startPreparation)
PREPARING → SHIPPED                 (ship)
SHIPPED → DELIVERED                 (markDelivered)
{ANY} → CANCELLED                   (cancel, si canBeCancelled())
```

## Database Schema Quick Reference

### Tablas Principales

- **orders**: id, customer_id, state, total_amount, version
- **order_items**: id, order_id, product_id, quantity, price
- **order_state_log**: order_id, from_state, to_state, transitioned_at

## Performance Considerations

- Cache de pedidos activos (Redis, TTL 15min)
- Índice en (customer_id, state) para queries comunes
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
