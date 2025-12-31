# .claude/instructions.md Template

Use this template structure when generating .claude/instructions.md files for Spring Boot services.

---

```markdown
# Claude Instructions for {Service Name}

> Guidelines for AI assistants working with this codebase

## Business Domain

### Service Purpose
{2-3 sentences explaining what this service does in business terms}

### Domain Context
{Explain the business domain - e.g., "This is part of a lending platform that processes loan applications..."}

### Key Terminology
- **{Term 1}**: {Definition and context}
- **{Term 2}**: {Definition and context}
- **{Term 3}**: {Definition and context}

### Business Rules Summary
1. {Critical rule 1 - e.g., "Loan amounts must be between $1,000 and $50,000"}
2. {Critical rule 2 - e.g., "Applications require credit score > 600 to proceed"}
3. {Critical rule 3}

---

## Service Responsibilities

### This Service DOES:
- {Responsibility 1}
- {Responsibility 2}
- {Responsibility 3}

### This Service DOES NOT:
- {Out of scope 1}
- {Out of scope 2}

### Bounded Context
- **Owns**: {entities/concepts this service is authoritative for}
- **Consumes**: {entities/concepts owned by other services}
- **Publishes**: {events/data shared with other services}

---

## Integration Dependencies

### Critical Dependencies (Must Consider)

#### {Upstream Service 1}
- **Type**: Kafka Consumer
- **Topic**: `{topic-name}`
- **Event Types**: `{EventType1}`, `{EventType2}`
- **Contract**: {link to schema or description}
- **Failure Impact**: {what happens if events stop}

#### {Upstream Service 2}
- **Type**: HTTP Client (Feign)
- **Endpoints Called**: `GET /api/v1/{resource}`
- **Timeout**: {configured timeout}
- **Fallback Behavior**: {what happens on failure}

### Downstream Consumers

#### {Downstream Service 1}
- **Type**: Kafka Producer
- **Topic**: `{topic-name}`
- **Event Types**: `{EventType1}`
- **Consumers**: {who listens}
- **Breaking Change Risk**: HIGH - {why}

### Event Contracts

#### Consumed Events
| Event | Source | Handler | Idempotency |
|-------|--------|---------|-------------|
| `{EventType}` | {service} | `{HandlerClass}` | {how ensured} |

#### Produced Events
| Event | Topic | Trigger | Consumers |
|-------|-------|---------|-----------|
| `{EventType}` | `{topic}` | {when} | {who} |

---

## Architecture Patterns

### Patterns in Use
- **{Pattern 1}** (e.g., CQRS): {How it's implemented here}
- **{Pattern 2}** (e.g., Event Sourcing): {How it's implemented here}
- **{Pattern 3}** (e.g., Repository Pattern): {Standard Spring Data usage}

### Package Structure
```
src/main/java/{base.package}/
├── controller/     # REST endpoints, request/response handling
├── service/        # Business logic, orchestration
├── domain/         # Entities, value objects, domain events
├── repository/     # Data access interfaces
├── client/         # External service clients (Feign)
├── kafka/          # Kafka consumers and producers
├── config/         # Spring configuration classes
├── exception/      # Custom exceptions and handlers
└── dto/            # Data transfer objects
```

### Layer Responsibilities
| Layer | Responsibility | May Call |
|-------|----------------|----------|
| Controller | HTTP handling, validation, mapping | Service |
| Service | Business logic, transactions | Repository, Client, Kafka |
| Repository | Data persistence | - |
| Client | External HTTP calls | - |

---

## Code Organization

### Naming Conventions
- **Controllers**: `{Resource}Controller.java`
- **Services**: `{Domain}Service.java` (interface) + `{Domain}ServiceImpl.java`
- **Repositories**: `{Entity}Repository.java`
- **DTOs**: `{Action}{Resource}Request.java`, `{Resource}Response.java`
- **Events**: `{Entity}{Action}Event.java`
- **Exceptions**: `{Domain}{Problem}Exception.java`

### File Locations
| Type | Location | Example |
|------|----------|---------|
| REST endpoint | `controller/` | `OrderController.java` |
| Business logic | `service/` | `OrderService.java` |
| JPA entity | `domain/entity/` | `Order.java` |
| Kafka handler | `kafka/consumer/` | `OrderEventHandler.java` |
| Feign client | `client/` | `InventoryClient.java` |
| Custom exception | `exception/` | `OrderNotFoundException.java` |

---

## Exception Handling

### Exception Hierarchy
```
{ServiceName}Exception (base)
├── {Domain}ValidationException
│   └── handled by: GlobalExceptionHandler → 400 Bad Request
├── {Entity}NotFoundException
│   └── handled by: GlobalExceptionHandler → 404 Not Found
├── {Domain}BusinessException
│   └── handled by: GlobalExceptionHandler → 422 Unprocessable Entity
└── {Integration}Exception
    └── handled by: GlobalExceptionHandler → 502/503
```

### When to Throw Which Exception
| Scenario | Exception | HTTP Status |
|----------|-----------|-------------|
| Invalid input data | `ValidationException` | 400 |
| Entity not found by ID | `{Entity}NotFoundException` | 404 |
| Business rule violation | `BusinessException` | 422 |
| Duplicate resource | `DuplicateException` | 409 |
| External service failure | `IntegrationException` | 502/503 |

### Error Code Conventions
- Format: `{SERVICE}_{CATEGORY}_{NUMBER}`
- Example: `ORDER_VALIDATION_001`

---

## Business Rules

### Critical Rules (DO NOT MODIFY without review)

#### Rule 1: {Rule Name}
```java
// Location: {ServiceClass}.java:{line}
// {Description of what this rule enforces}
// Example: Orders cannot be cancelled after shipping
if (order.getStatus() == SHIPPED) {
    throw new OrderCannotBeCancelledException(order.getId());
}
```

#### Rule 2: {Rule Name}
```java
// Location: {ServiceClass}.java:{line}
// {Description}
```

### State Machines

#### {Entity} Status Flow
```
CREATED → PENDING_APPROVAL → APPROVED → PROCESSING → COMPLETED
                          ↘ REJECTED
                PROCESSING → FAILED
```

Valid transitions:
- CREATED → PENDING_APPROVAL: {trigger}
- PENDING_APPROVAL → APPROVED: {trigger}
- PENDING_APPROVAL → REJECTED: {trigger}
- APPROVED → PROCESSING: {trigger}
- PROCESSING → COMPLETED: {trigger}
- PROCESSING → FAILED: {trigger}

---

## When Modifying This Service

### DO:
- Follow existing package structure and naming conventions
- Add tests for new functionality (unit + integration)
- Update this file when adding new integrations or business rules
- Use existing exception hierarchy for error handling
- Maintain idempotency for Kafka consumers
- Log at appropriate levels (INFO for business events, DEBUG for technical details)
- Update README.md API reference when adding endpoints
- Consider downstream consumers when modifying events

### DON'T:
- Skip tests for "simple" changes
- Modify business rules without understanding impact
- Add new dependencies without team discussion
- Change event schemas without versioning strategy
- Bypass validation layers
- Catch and swallow exceptions silently
- Add business logic to controllers
- Mix transaction boundaries inappropriately

### Code Review Checklist
- [ ] Tests added/updated
- [ ] Documentation updated (README, this file)
- [ ] No breaking changes to API/events (or properly versioned)
- [ ] Error handling follows patterns
- [ ] Logging appropriate
- [ ] No hardcoded values (use configuration)

---

## Testing Requirements

### Coverage Expectations
- **Unit Tests**: Business logic in services (target: >80%)
- **Integration Tests**: API endpoints and database operations
- **Contract Tests**: Kafka events (if using Pact or similar)

### Test Patterns

#### Unit Tests
```java
@ExtendWith(MockitoExtension.class)
class {Service}Test {
    @Mock
    private {Repository} repository;

    @InjectMocks
    private {Service}Impl service;

    @Test
    void should{Action}_when{Condition}() {
        // given
        // when
        // then
    }
}
```

#### Integration Tests
```java
@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class {Controller}IntegrationTest {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15");

    @Test
    void should{Action}_when{Condition}() {
        // given
        // when
        // then
    }
}
```

### Test Data
- Use builders or factories for test entities
- Location: `src/test/java/{package}/fixture/`

---

## Common Tasks

### Adding a New REST Endpoint

1. Create/update DTO in `dto/`
   ```java
   public record Create{Resource}Request(
       @NotNull String field1,
       @Size(max = 100) String field2
   ) {}
   ```

2. Add method to Controller
   ```java
   @PostMapping
   public ResponseEntity<{Resource}Response> create{Resource}(
       @Valid @RequestBody Create{Resource}Request request
   ) {
       return ResponseEntity.status(HttpStatus.CREATED)
           .body(service.create(request));
   }
   ```

3. Implement service method

4. Add tests (unit + integration)

5. **Update README.md API Reference section**

### Adding a New Kafka Consumer

1. Create event class in `kafka/event/`
   ```java
   public record {EventName}Event(
       String eventId,
       Instant timestamp,
       {Payload} payload
   ) {}
   ```

2. Create handler in `kafka/consumer/`
   ```java
   @Component
   @Slf4j
   public class {EventName}Handler {
       @KafkaListener(topics = "{topic}", groupId = "{group}")
       public void handle({EventName}Event event) {
           log.info("Processing event: {}", event.eventId());
           // Ensure idempotency
           // Process event
       }
   }
   ```

3. Add configuration in `application.yml`

4. Add tests

5. **Update README.md Kafka Topics section**
6. **Update Integration Dependencies section in this file**

### Adding a New Entity

1. Create entity in `domain/entity/`
2. Create repository in `repository/`
3. Create migration in `src/main/resources/db/migration/`
4. Add service methods
5. **Update README.md Domain Model and Database Schema sections**

### Modifying Business Logic

1. Understand current behavior and test coverage
2. Write failing test for new behavior
3. Implement change
4. Verify all tests pass
5. **Update Business Rules section if affected**
6. Get code review

---

## Documentation Maintenance

When making changes to this service, keep documentation in sync:

| Change Type | Update README.md | Update This File |
|-------------|------------------|------------------|
| New endpoint | API Reference | - |
| New Kafka topic | Kafka Topics, Architecture | Integration Dependencies |
| New entity | Domain Model, Database Schema | - |
| New external call | Integration Points, Architecture | Integration Dependencies |
| New business rule | - | Business Rules |
| New exception | Exception Handling | Exception Handling |
| Config change | Local Development Setup | - |

---

## Contacts & Resources

### Team
- **Owner Team**: {team name}
- **Slack Channel**: #{channel}
- **On-Call**: {rotation info}

### Resources
- **Repository**: {repo URL}
- **CI/CD**: {pipeline URL}
- **Dashboards**: {monitoring URL}
- **Runbooks**: {runbook location}
- **API Docs**: {swagger/openapi URL}
```
