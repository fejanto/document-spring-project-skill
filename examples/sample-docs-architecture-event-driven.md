# Event-Driven State Machine Pattern

## Problem

En un microservicio de gestión de pedidos, múltiples servicios downstream necesitan ser notificados cuando el estado de un pedido cambia. Usar llamadas síncronas crea acoplamiento fuerte y hace el sistema frágil.

### Symptoms

- Servicios downstream directamente acoplados
- Timeout cascadas cuando un servicio downstream está lento
- Difícil agregar nuevos consumidores de eventos
- Rollback complejo cuando una operación falla
- Estado inconsistente entre servicios

### Why It Matters

En e-commerce, un cambio de estado de pedido puede disparar múltiples acciones:
- Notificar al cliente (notification-service)
- Actualizar inventario (inventory-service)
- Generar factura (billing-service)
- Actualizar dashboard (analytics-service)

Si hacemos esto síncronamente, el tiempo de respuesta crece linealmente con cada integración y cualquier falla bloquea todo el flujo.

## Solution

Usar eventos asíncronos para notificar cambios de estado. Cada transición de estado publica un evento a Kafka, permitiendo que servicios interesados reaccionen independientemente.

### Key Principles

1. **Single Source of Truth**: El servicio de pedidos es el único que modifica el estado del pedido
2. **Publish After Persistence**: Siempre persistir primero, publicar después (evita eventos huérfanos)
3. **Idempotent Consumers**: Los consumidores deben manejar eventos duplicados
4. **Event Enrichment**: Incluir toda la información relevante en el evento (evitar lookups)

## Implementation

### Architecture

```
[Order Service]
      ↓ (persiste estado)
  [Database]
      ↓ (publica evento)
   [Kafka Topic: order-events]
      ↓         ↓         ↓
  [Notif]  [Invent]  [Bill]
```

### Code Structure

```java
// Domain Entity con State Machine
@Entity
public class Order {
    @Id
    private String id;

    @Enumerated(EnumType.STRING)
    private OrderState state;

    @Version
    private Long version;

    // Métodos de transición que retornan eventos
    public OrderConfirmedEvent confirm() {
        if (!canBeConfirmed()) {
            throw new InvalidStateTransitionException(state, OrderState.CONFIRMED);
        }
        this.state = OrderState.CONFIRMED;
        this.confirmedAt = Instant.now();
        return new OrderConfirmedEvent(this);
    }

    private boolean canBeConfirmed() {
        return state == OrderState.PAYMENT_PENDING;
    }
}

// Service coordina persistencia + publicación
@Service
public class OrderService {
    private final OrderRepository orderRepository;
    private final OrderEventPublisher eventPublisher;

    @Transactional
    public Order confirmOrder(String orderId) {
        // 1. Load & validate
        Order order = orderRepository.findById(orderId)
            .orElseThrow(() -> new OrderNotFoundException(orderId));

        // 2. Execute transition (returns event)
        OrderConfirmedEvent event = order.confirm();

        // 3. Persist (within transaction)
        orderRepository.save(order);

        // 4. Publish event (after commit via TransactionalEventListener)
        eventPublisher.publish(event);

        return order;
    }
}
```

### Step-by-Step

#### Step 1: Define Event Classes

```java
public record OrderConfirmedEvent(
    String orderId,
    String customerId,
    BigDecimal totalAmount,
    Instant confirmedAt
) implements OrderEvent {
    public static OrderConfirmedEvent from(Order order) {
        return new OrderConfirmedEvent(
            order.getId(),
            order.getCustomerId(),
            order.getTotalAmount(),
            order.getConfirmedAt()
        );
    }
}
```

**Notes:**
- Use records for immutability
- Include all context needed by consumers (avoid additional lookups)
- Factory method for easy creation from entity

#### Step 2: Implement Event Publisher

```java
@Component
public class OrderEventPublisher {
    private final KafkaTemplate<String, OrderEvent> kafkaTemplate;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void publish(OrderEvent event) {
        String topic = "order-events";
        String key = event.orderId();

        kafkaTemplate.send(topic, key, event)
            .whenComplete((result, ex) -> {
                if (ex != null) {
                    // Log error, trigger retry/DLQ logic
                    log.error("Failed to publish event: {}", event, ex);
                } else {
                    log.info("Published event: {}", event);
                }
            });
    }
}
```

**Notes:**
- Use `@TransactionalEventListener(AFTER_COMMIT)` to ensure event is only sent after DB commit
- Use order ID as Kafka key for ordering guarantees
- Handle publishing failures gracefully (DLQ, retry)

#### Step 3: Domain Methods Return Events

```java
@Entity
public class Order {
    public OrderConfirmedEvent confirm() {
        validateTransition(OrderState.CONFIRMED);
        this.state = OrderState.CONFIRMED;
        this.confirmedAt = Instant.now();
        return OrderConfirmedEvent.from(this);
    }

    public OrderCancelledEvent cancel(String reason) {
        validateTransition(OrderState.CANCELLED);
        this.state = OrderState.CANCELLED;
        this.cancelledAt = Instant.now();
        this.cancellationReason = reason;
        return OrderCancelledEvent.from(this, reason);
    }
}
```

## Benefits

- **Loose Coupling**: Servicios no conocen entre sí directamente
- **Scalability**: Agregar nuevos consumidores sin modificar el productor
- **Resilience**: Falla de un consumidor no afecta otros
- **Audit Trail**: Todos los cambios de estado quedan registrados en Kafka
- **Replay**: Posibilidad de reconstruir estado desde eventos

## Trade-offs

- **Eventual Consistency**: Los consumidores no ven cambios inmediatamente
- **Complexity**: Debugging distribuido es más difícil
- **Ordering**: Garantizar orden de eventos requiere cuidado (usar Kafka keys)
- **Duplicate Events**: Consumidores deben ser idempotentes

## When to Use

✅ Cuando múltiples servicios necesitan reaccionar a cambios de estado
✅ Cuando el sistema debe escalar horizontalmente
✅ Cuando se requiere audit trail de cambios
✅ Cuando eventual consistency es aceptable

## When NOT to Use

❌ Cuando se requiere consistencia inmediata (transacciones ACID)
❌ Cuando el flujo es simple (un solo consumidor)
❌ Cuando el equipo no tiene experiencia con sistemas distribuidos

## Common Pitfalls

### 1. Publishing Before Persisting

**Problem**: Si publicamos el evento antes de persistir y el save falla, el evento queda huérfano.

**Solution**: Siempre persistir primero, publicar después usando `@TransactionalEventListener`.

```java
// ❌ WRONG - Event can be orphaned
public void confirmOrder(String id) {
    Order order = orderRepository.findById(id).orElseThrow();
    OrderConfirmedEvent event = order.confirm();

    eventPublisher.publish(event);  // ← Event sent first
    orderRepository.save(order);    // ← This might fail!
}

// ✅ CORRECT - Persist first, publish after commit
@Transactional
public void confirmOrder(String id) {
    Order order = orderRepository.findById(id).orElseThrow();
    OrderConfirmedEvent event = order.confirm();

    orderRepository.save(order);    // ← Persist first
    eventPublisher.publish(event);  // ← @TransactionalEventListener ensures this runs after commit
}
```

### 2. Missing Event Information

**Problem**: Evento solo incluye ID, consumidores hacen llamadas síncronas para obtener detalles.

**Solution**: Enriquecer evento con toda la información necesaria.

```java
// ❌ WRONG - Forces consumers to fetch details
public record OrderConfirmedEvent(String orderId) {}

// ✅ CORRECT - Self-contained event
public record OrderConfirmedEvent(
    String orderId,
    String customerId,
    List<OrderItemDto> items,
    BigDecimal totalAmount,
    Instant confirmedAt
) {}
```

### 3. Non-Idempotent Consumers

**Problem**: Consumidor procesa el mismo evento dos veces con efectos secundarios diferentes.

**Solution**: Hacer consumidores idempotentes usando deduplicación o design idempotente.

```java
// ✅ CORRECT - Idempotent consumer
@KafkaListener(topics = "order-events")
public void handle(OrderConfirmedEvent event) {
    // Check if already processed
    if (processedEventRepository.exists(event.eventId())) {
        log.info("Event {} already processed, skipping", event.eventId());
        return;
    }

    // Process event
    sendNotification(event);

    // Mark as processed
    processedEventRepository.save(event.eventId());
}
```

## Performance Considerations

- **Batch Publishing**: Agrupar eventos para reducir overhead de red
- **Compression**: Habilitar compresión en Kafka producer (gzip, snappy)
- **Partitioning**: Usar keys apropiados para distribución balanceada
- **Async Send**: Usar send asíncrono para no bloquear request thread

## Testing Strategy

Testear publicación de eventos:

```java
@SpringBootTest
class OrderServiceTest {
    @MockBean
    private OrderEventPublisher eventPublisher;

    @Test
    void whenConfirmingOrder_givenValidOrder_shouldPublishEvent() {
        // given
        Order order = createPendingOrder();

        // when
        orderService.confirmOrder(order.getId());

        // then
        ArgumentCaptor<OrderConfirmedEvent> eventCaptor =
            ArgumentCaptor.forClass(OrderConfirmedEvent.class);
        verify(eventPublisher).publish(eventCaptor.capture());

        OrderConfirmedEvent event = eventCaptor.getValue();
        assertThat(event.orderId()).isEqualTo(order.getId());
        assertThat(event.customerId()).isEqualTo(order.getCustomerId());
    }
}
```

## Related Patterns

- **Saga Pattern**: Para orquestación de transacciones distribuidas
- **Outbox Pattern**: Para garantizar entrega de eventos (at-least-once)
- **Event Sourcing**: Almacenar todos los cambios como secuencia de eventos

## References

- [Domain Model](../domain/order-model.md)
- [Common Workflows](../../.claude/rules/workflows.md)
- [Architecture Rules](../../.claude/rules/architecture.md)

## Examples from Codebase

### Order Confirmation Flow

**File**: `OrderService.java:45-67`

Complete flow desde request HTTP hasta publicación de evento:

```java
@PostMapping("/{id}/confirm")
public ResponseEntity<OrderResponse> confirmOrder(@PathVariable String id) {
    Order order = orderService.confirmOrder(id);
    return ResponseEntity.ok(OrderResponse.from(order));
}

@Service
class OrderService {
    @Transactional
    public Order confirmOrder(String id) {
        Order order = orderRepository.findById(id).orElseThrow();
        OrderConfirmedEvent event = order.confirm();
        orderRepository.save(order);
        eventPublisher.publish(event);
        return order;
    }
}
```
