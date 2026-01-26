# Order Domain Model

## Overview

El Order (Pedido) es la entidad central del sistema. Representa el ciclo completo desde que un cliente selecciona productos hasta que recibe su pedido en su domicilio.

## Lifecycle

Un Order atraviesa múltiples estados durante su vida:

```
CREATION
   ↓
PENDING (esperando pago)
   ↓
PAYMENT_PENDING (procesando pago)
   ↓
CONFIRMED (pago exitoso)
   ↓
PREPARING (preparando en almacén)
   ↓
SHIPPED (enviado)
   ↓
DELIVERED (entregado)

En cualquier momento antes de SHIPPED puede ir a:
   ↓
CANCELLED (cancelado)
```

## Business Rules

### 1. Creación de Order

Un Order solo puede crearse si:
- El customer_id es válido (existe en customer-service)
- Todos los productos tienen stock disponible
- El monto total es mayor a $0

**Example:**

```java
public Order createOrder(String customerId, List<OrderItem> items) {
    validateCustomer(customerId);
    validateInventory(items);

    Order order = Order.builder()
        .customerId(customerId)
        .items(items)
        .state(OrderState.PENDING)
        .totalAmount(calculateTotal(items))
        .build();

    return orderRepository.save(order);
}
```

### 2. State Transitions

Cada transición tiene precondiciones:

- **PENDING → PAYMENT_PENDING**: El cliente inicia pago
- **PAYMENT_PENDING → CONFIRMED**: El payment-service confirma pago exitoso
- **CONFIRMED → PREPARING**: El sistema asigna almacén automáticamente
- **PREPARING → SHIPPED**: El almacén marca el pedido como enviado
- **SHIPPED → DELIVERED**: El carrier confirma entrega
- **{ANY} → CANCELLED**: Solo antes de SHIPPED, con penalización según estado

### 3. Cancelación Rules

**Constraints:**
- Cancelación gratuita: PENDING, PAYMENT_PENDING, CONFIRMED
- Cancelación con cargo $5: PREPARING
- NO cancelable: SHIPPED, DELIVERED

### 4. Timeout Automático

**Timeout Rules:**
- Si PAYMENT_PENDING > 15 minutos → auto CANCELLED
- Si PENDING > 24 horas → auto CANCELLED

## Relationships

### Many-to-One with Customer

- **Type**: ManyToOne
- **Cardinality**: N orders → 1 customer
- **Description**: Un pedido pertenece a un único cliente, pero un cliente puede tener múltiples pedidos
- **Cascade**: NONE (customer es gestionado por customer-service)

### One-to-Many with OrderItem

- **Type**: OneToMany
- **Cardinality**: 1 order → N items
- **Description**: Un pedido contiene uno o más items (productos con cantidad y precio)
- **Cascade**: ALL (items se crean/eliminan con el order)

## Validation Rules

- **customerId**: NOT NULL, formato UUID
- **state**: NOT NULL, uno de los enum OrderState values
- **totalAmount**: NOT NULL, >= 0
- **createdAt**: NOT NULL, generado automáticamente
- **version**: NOT NULL, para optimistic locking

## Events

This entity publishes the following events:

- **OrderCreatedEvent**: Cuando se crea un nuevo pedido
  - **When**: Después de persistir el order
  - **Payload**: orderId, customerId, items, totalAmount

- **OrderConfirmedEvent**: Cuando se confirma el pago
  - **When**: Transición PAYMENT_PENDING → CONFIRMED
  - **Payload**: orderId, confirmedAt, paymentId

- **OrderShippedEvent**: Cuando se envía el pedido
  - **When**: Transición PREPARING → SHIPPED
  - **Payload**: orderId, trackingNumber, carrier

- **OrderCancelledEvent**: Cuando se cancela el pedido
  - **When**: Transición a CANCELLED
  - **Payload**: orderId, reason, penaltyAmount

## Database Mapping

- **Table**: `orders`
- **Indexes**:
  - `idx_orders_customer_id` on (customer_id) - Para queries frecuentes por cliente
  - `idx_orders_state` on (state) - Para filtrar por estado
  - `idx_orders_created_at` on (created_at DESC) - Para ordenar por fecha
  - `idx_orders_customer_state` on (customer_id, state) - Composite para dashboard del cliente

## Examples

### Creation

```java
Order order = Order.builder()
    .customerId("cust-123")
    .items(List.of(
        OrderItem.of("prod-1", 2, Money.of(10.00)),
        OrderItem.of("prod-2", 1, Money.of(25.00))
    ))
    .state(OrderState.PENDING)
    .build();

order = orderRepository.save(order);
eventPublisher.publish(new OrderCreatedEvent(order));
```

### State Transitions

```java
// Confirmar pedido después de pago exitoso
Order order = orderRepository.findById(orderId)
    .orElseThrow(() -> new OrderNotFoundException(orderId));

if (!order.canBeConfirmed()) {
    throw new OrderCannotBeConfirmedException(order.getState());
}

order.confirm();
orderRepository.save(order);
eventPublisher.publish(new OrderConfirmedEvent(order));
```

## Related Documentation

- [Order Management Service Architecture](../architecture/event-driven-state-machine.md)
- [Database Schema](../database/database-schema.md)
- [Common Workflows](../../.claude/rules/workflows.md)
