# {{SERVICE_NAME}}

{{ONE_LINE_DESCRIPTION}}

## Stack

- Java {{JAVA_VERSION}} + Spring Boot {{SPRING_BOOT_VERSION}}
{{#if HAS_POSTGRESQL}}- PostgreSQL{{/if}}
{{#if HAS_MONGODB}}- MongoDB{{/if}}
{{#if HAS_KAFKA}}- Apache Kafka{{/if}}
{{#if HAS_RABBITMQ}}- RabbitMQ{{/if}}
{{#if HAS_REDIS}}- Redis{{/if}}
{{#if USES_DDD}}- Patrón DDD con entidades ricas{{/if}}

## Responsabilidades del Servicio

### HACE:

{{#each RESPONSIBILITIES}}
- {{this}}
{{/each}}

### NO HACE:

{{#each ANTI_RESPONSIBILITIES}}
- {{this}}
{{/each}}

## Dependencias de Integración

### Críticas (el servicio falla sin ellas):

{{#each CRITICAL_DEPENDENCIES}}
- **{{name}}**: {{purpose}}
{{/each}}

### Importantes:

{{#each IMPORTANT_DEPENDENCIES}}
- **{{name}}**: {{purpose}}
{{/each}}

### Opcionales:

{{#each OPTIONAL_DEPENDENCIES}}
- **{{name}}**: {{purpose}}
{{/each}}

## Reglas de Desarrollo

Las reglas detalladas están organizadas en `.claude/rules/`:
- **architecture.md** - Patrones arquitectónicos críticos
- **domain.md** - Reglas de negocio del dominio
- **workflows.md** - Tareas comunes y procedimientos
{{#if HAS_CUSTOM_PERSISTENCE}}- **persistence.md** - Patrones de persistencia específicos{{/if}}

## Documentación Extendida

Para detalles exhaustivos, consultar `/docs/`:
- `/docs/architecture/` - Patrones con diagramas completos
- `/docs/domain/` - Documentación de dominio extendida
- `/docs/database/` - Schema y migraciones
- `/docs/plans/` - Planes de implementación históricos

## Quick Start

Ver `.claude/rules/workflows.md` para tareas comunes como:
{{#each COMMON_TASKS}}
- {{this}}
{{/each}}
