# Order Management Service

Microservicio de gestión de pedidos para plataforma e-commerce.

## Stack

- Java 21 + Spring Boot 3.2
- PostgreSQL 15
- Apache Kafka 3.6
- Redis (cache)

## Responsabilidades del Servicio

### HACE:

- Gestión del ciclo de vida de pedidos (PENDING → CONFIRMED → SHIPPED → DELIVERED)
- Validación de inventario antes de confirmar
- Integración con servicio de pagos
- Publicación de eventos de cambio de estado
- Cache de pedidos activos

### NO HACE:

- Procesamiento de pagos (payment-service)
- Gestión de inventario (inventory-service)
- Cálculo de envíos (shipping-service)
- Notificaciones al cliente (notification-service)

## Dependencias de Integración

### Críticas (el servicio falla sin ellas):

- **PostgreSQL**: Persistencia de pedidos
- **payment-service**: Validación de pagos

### Importantes:

- **Kafka**: Publicación de eventos de pedidos
- **inventory-service**: Verificación de stock

### Opcionales:

- **Redis**: Cache de pedidos (mejora performance)

## Reglas de Desarrollo

Las reglas detalladas están organizadas en `.claude/rules/`:
- **architecture.md** - Patrones arquitectónicos críticos
- **domain.md** - Reglas de negocio del dominio
- **workflows.md** - Tareas comunes y procedimientos

## Documentación Extendida

Para detalles exhaustivos, consultar `/docs/`:
- `/docs/architecture/` - Patrones con diagramas completos
- `/docs/domain/` - Documentación de dominio extendida
- `/docs/database/` - Schema y migraciones
- `/docs/plans/` - Planes de implementación históricos

## Quick Start

Ver `.claude/rules/workflows.md` para tareas comunes como:
- Agregar nuevo endpoint
- Agregar nueva transición de estado
- Modificar lógica de validación
