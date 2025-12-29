# Claude Instructions for Loan Approval Service

> Guidelines for AI assistants working with this codebase

## Business Domain

### Service Purpose
The Loan Approval Service is the decision engine for loan applications. It evaluates applications against credit policies, risk models, and business rules to produce approval, rejection, or manual review decisions. This service is critical to the lending platform's core business flow.

### Domain Context
This is part of a digital lending platform that provides personal loans. The platform follows a flow: Application → Credit Check → Decision → Fulfillment → Servicing. This service owns the Decision step and is the single source of truth for loan approval logic.

### Key Terminology
- **Application**: A loan request with applicant info, requested amount, and term
- **Decision**: The outcome (APPROVED/REJECTED/MANUAL_REVIEW) with supporting data
- **Risk Score**: Internal score (0-1000) predicting default probability. Higher = safer
- **Risk Tier**: Bucketed risk level (LOW, MEDIUM, HIGH, VERY_HIGH) derived from score
- **DTI Ratio**: Debt-to-Income ratio. Monthly debt payments / Monthly income. Max allowed: 0.45
- **Credit Pull**: Request to credit bureau for applicant's credit report and score
- **Policy Rule**: Configurable business rule in SpEL that can approve/reject/flag applications
- **Underwriting**: The evaluation process that produces a decision

### Business Rules Summary
1. **Loan amounts must be between $1,000 and $100,000** - Enforced at API validation
2. **DTI ratio must not exceed 45%** - Blocking policy rule, results in rejection
3. **Credit score must be at least 580** - Minimum threshold for any approval
4. **Applications over $50,000 require credit score > 700** - Risk-based limit
5. **Interest rates are risk-tier based** - LOW: 7-10%, MEDIUM: 10-15%, HIGH: 15-24%

---

## Service Responsibilities

### This Service DOES:
- Receive and process loan applications (via Kafka and REST)
- Pull credit reports from credit bureau
- Calculate risk scores using internal models
- Evaluate applications against policy rules
- Produce approval/rejection decisions with explanations
- Publish decision events for downstream services
- Maintain audit trail of all decisions

### This Service DOES NOT:
- Collect or store customer personal information (handled by Origination)
- Disburse funds (handled by Fulfillment)
- Handle payment processing (handled by Servicing)
- Manage customer accounts or authentication
- Send customer notifications directly (publishes events for Notification service)

### Bounded Context
- **Owns**: Decisions, PolicyRules, DecisionFactors, RiskScores
- **Consumes**: Applications (from Origination), CreditReports (from Bureau)
- **Publishes**: LoanApprovedEvent, LoanRejectedEvent, ManualReviewRequiredEvent

---

## Integration Dependencies

### Critical Dependencies (Must Consider)

#### Loan Origination Service
- **Type**: Kafka Consumer
- **Topic**: `loan.application.submitted`
- **Event Types**: `ApplicationSubmittedEvent`
- **Contract**: Contains applicationId, applicantId, requestedAmount, termMonths, purpose, income data
- **Failure Impact**: No new applications processed. Consumer will retry indefinitely.
- **Idempotency**: Ensured by applicationId. Duplicate events produce same decision.

#### Credit Bureau API
- **Type**: HTTP Client (Feign)
- **Endpoints Called**: `POST /v2/credit-reports`
- **Timeout**: 10 seconds (configurable)
- **Fallback Behavior**: Circuit breaker opens after 5 failures. No fallback - credit data required.
- **Rate Limits**: 100 requests/minute per API key
- **CRITICAL**: Never cache credit data beyond 24 hours (regulatory requirement)

#### Fraud Detection Service
- **Type**: HTTP Client (Feign)
- **Endpoints Called**: `POST /v1/assess`
- **Timeout**: 5 seconds
- **Fallback Behavior**: If unavailable, proceed without fraud score but flag for review if amount > $25,000
- **Circuit Breaker**: Opens after 3 failures, half-open after 30 seconds

### Downstream Consumers

#### Loan Fulfillment Service
- **Type**: Kafka Producer
- **Topic**: `loan.approved`
- **Event Types**: `LoanApprovedEvent`
- **Consumers**: Single consumer group, processes sequentially
- **Breaking Change Risk**: HIGH - Schema changes require coordination
- **Contract Fields Required**: decisionId, applicationId, approvedAmount, interestRate, termMonths

#### Notification Service
- **Type**: Kafka Producer
- **Topic**: `loan.decision.created`
- **Event Types**: `LoanDecisionEvent`
- **Breaking Change Risk**: MEDIUM - Additive changes OK, removals break

### Event Contracts

#### Consumed Events
| Event | Source | Handler | Idempotency |
|-------|--------|---------|-------------|
| `ApplicationSubmittedEvent` | Origination | `ApplicationEventHandler` | By applicationId - same input = same output |
| `CreditScoreUpdatedEvent` | Credit Monitoring | `CreditUpdateHandler` | By applicantId + timestamp |

#### Produced Events
| Event | Topic | Trigger | Consumers |
|-------|-------|---------|-----------|
| `LoanDecisionEvent` | `loan.decision.created` | Every decision | Notification, Analytics |
| `LoanApprovedEvent` | `loan.approved` | Approval only | Fulfillment |
| `LoanRejectedEvent` | `loan.rejected` | Rejection only | Analytics |
| `ManualReviewRequiredEvent` | `loan.manual-review` | Needs human review | Underwriting Dashboard |

---

## Architecture Patterns

### Patterns in Use
- **Event-Driven Architecture**: Primary trigger is Kafka events; decisions produce events
- **Domain-Driven Design**: Rich domain model in `domain/` package with entities and value objects
- **Hexagonal Architecture**: Core in `domain/` and `service/`, adapters in `controller/`, `kafka/`, `client/`
- **Repository Pattern**: Standard Spring Data JPA repositories
- **Strategy Pattern**: Risk scoring uses pluggable scoring strategies

### Package Structure
```
src/main/java/com/example/loanapproval/
├── controller/          # REST endpoints, request/response handling
│   ├── DecisionController.java
│   ├── PolicyController.java
│   └── dto/             # Request/Response DTOs
├── service/             # Business logic, orchestration
│   ├── UnderwritingService.java
│   ├── RiskScoringService.java
│   └── PolicyService.java
├── domain/              # Core domain model
│   ├── entity/          # JPA entities
│   ├── valueobject/     # Value objects (RiskTier, DecisionStatus)
│   └── event/           # Domain events
├── repository/          # Data access interfaces
├── client/              # External service clients (Feign)
│   ├── CreditBureauClient.java
│   └── FraudCheckClient.java
├── kafka/               # Kafka consumers and producers
│   ├── consumer/        # Event handlers
│   └── producer/        # Event publishers
├── config/              # Spring configuration
├── exception/           # Custom exceptions and handlers
│   ├── LoanApprovalException.java
│   └── GlobalExceptionHandler.java
└── policy/              # Policy rule evaluation
    ├── PolicyEvaluator.java
    └── rules/           # Built-in rule implementations
```

### Layer Responsibilities
| Layer | Responsibility | May Call |
|-------|----------------|----------|
| Controller | HTTP handling, validation, mapping | Service |
| Service | Business logic, transactions, orchestration | Repository, Client, Kafka Producer |
| Repository | Data persistence | - |
| Client | External HTTP calls | - |
| Kafka Consumer | Event handling, mapping | Service |
| Kafka Producer | Event publishing | - |

---

## Code Organization

### Naming Conventions
- **Controllers**: `{Resource}Controller.java` (e.g., `DecisionController`)
- **Services**: `{Domain}Service.java` (e.g., `UnderwritingService`) - no Impl suffix, single implementation
- **Repositories**: `{Entity}Repository.java` (e.g., `DecisionRepository`)
- **DTOs**: `{Action}{Resource}Request.java`, `{Resource}Response.java` (e.g., `CreateDecisionRequest`, `DecisionResponse`)
- **Events**: `{Entity}{Action}Event.java` (e.g., `LoanApprovedEvent`)
- **Exceptions**: `{Problem}Exception.java` (e.g., `ApplicationNotFoundException`)
- **Value Objects**: `{Concept}.java` in `domain/valueobject/` (e.g., `RiskTier`, `Money`)

### File Locations
| Type | Location | Example |
|------|----------|---------|
| REST endpoint | `controller/` | `DecisionController.java:45` |
| Request DTO | `controller/dto/` | `CreateDecisionRequest.java` |
| Business logic | `service/` | `UnderwritingService.java:78` |
| JPA entity | `domain/entity/` | `Decision.java` |
| Value object | `domain/valueobject/` | `RiskTier.java` |
| Kafka handler | `kafka/consumer/` | `ApplicationEventHandler.java` |
| Kafka event | `kafka/event/` | `LoanApprovedEvent.java` |
| Feign client | `client/` | `CreditBureauClient.java` |
| Exception | `exception/` | `ApplicationNotFoundException.java` |
| Policy rule | `policy/rules/` | `MaxDtiRule.java` |

---

## Exception Handling

### Exception Hierarchy
```
LoanApprovalException (base RuntimeException)
├── ApplicationValidationException → 400 Bad Request
│   ├── InvalidAmountException
│   ├── InvalidTermException
│   └── MissingRequiredFieldException
├── DecisionException → various
│   ├── ApplicationNotFoundException → 404
│   ├── DecisionAlreadyExistsException → 409
│   └── DecisionLockedException → 423
├── PolicyException → 500/422
│   ├── PolicyRuleNotFoundException → 404
│   └── PolicyEvaluationException → 500
└── IntegrationException → 502/503
    ├── CreditBureauException → 502
    ├── FraudServiceException → 502
    └── EventPublishingException → 503
```

### When to Throw Which Exception
| Scenario | Exception | HTTP Status |
|----------|-----------|-------------|
| Invalid request data (amount, term) | `ApplicationValidationException` | 400 |
| Application not found by ID | `ApplicationNotFoundException` | 404 |
| Decision already exists for application | `DecisionAlreadyExistsException` | 409 |
| Business rule violation during processing | Captured in decision, not thrown | N/A |
| Credit bureau call fails | `CreditBureauException` | 502 |
| Kafka publish fails | `EventPublishingException` | 503 |

### Error Code Conventions
- Format: `LOAN_{CATEGORY}_{NUMBER}`
- Validation: `LOAN_VAL_001` through `LOAN_VAL_099`
- Business: `LOAN_BUS_100` through `LOAN_BUS_199`
- Integration: `LOAN_INT_200` through `LOAN_INT_299`

---

## Business Rules

### Critical Rules (DO NOT MODIFY without review)

#### Rule 1: DTI Ratio Maximum
```java
// Location: PolicyEvaluator.java:112
// Debt-to-income ratio cannot exceed 45%
// This is a regulatory requirement from lending licenses
if (application.getDtiRatio().compareTo(MAX_DTI_RATIO) > 0) {
    return Decision.rejected("DTI_EXCEEDS_MAXIMUM");
}
```

#### Rule 2: Credit Score Minimum
```java
// Location: RiskScoringService.java:89
// Minimum credit score of 580 required for any approval
// Below this, default probability too high for any risk tier
if (creditScore < MIN_CREDIT_SCORE) {
    return Decision.rejected("CREDIT_SCORE_BELOW_MINIMUM");
}
```

#### Rule 3: High-Value Loan Requirements
```java
// Location: PolicyEvaluator.java:145
// Loans over $50,000 require credit score > 700
// Risk mitigation for large exposure
if (amount > HIGH_VALUE_THRESHOLD && creditScore < HIGH_VALUE_MIN_SCORE) {
    return Decision.rejected("INSUFFICIENT_CREDIT_FOR_AMOUNT");
}
```

### State Machines

#### Decision Status Flow
```
PENDING → APPROVED
       → REJECTED
       → MANUAL_REVIEW → APPROVED (by underwriter)
                      → REJECTED (by underwriter)
```

Valid transitions:
- PENDING → APPROVED: Automated approval, all rules pass
- PENDING → REJECTED: Blocking rule violated
- PENDING → MANUAL_REVIEW: Soft rule violated or edge case
- MANUAL_REVIEW → APPROVED: Underwriter override
- MANUAL_REVIEW → REJECTED: Underwriter rejection

**Note**: Once APPROVED or REJECTED, status is final. No transitions allowed.

---

## When Modifying This Service

### DO:
- Follow existing package structure and naming conventions
- Add tests for all new functionality (unit + integration)
- Update documentation when adding new integrations or business rules
- Use existing exception hierarchy - add new exceptions as children
- Ensure Kafka consumer idempotency for any new handlers
- Log at INFO for business events, DEBUG for technical details
- Update README.md API reference when adding endpoints
- Update this file when adding integration dependencies
- Consider downstream consumers when modifying event schemas
- Use policy rules (SpEL) for configurable business logic
- Add metrics for new operations using Micrometer

### DON'T:
- Skip tests - even for "simple" changes (regulatory requirement)
- Modify DTI/credit score thresholds without compliance review
- Add new blocking policy rules without Product approval
- Change event schemas without versioning or consumer coordination
- Bypass validation layers - always validate at controller level
- Catch and swallow exceptions - always log and potentially rethrow
- Add business logic to controllers - keep it in services
- Make synchronous calls to non-critical services (use async)
- Hardcode configuration values - use `application.yml`
- Cache credit data beyond 24 hours (regulatory)
- Log sensitive data (SSN, full credit reports)

### Code Review Checklist
- [ ] Tests added/updated (unit + integration)
- [ ] Documentation updated (README, this file if needed)
- [ ] No breaking changes to API/events (or properly versioned)
- [ ] Error handling follows established patterns
- [ ] Logging at appropriate levels, no sensitive data
- [ ] No hardcoded values (use configuration)
- [ ] Idempotency ensured for new Kafka handlers
- [ ] Metrics added for new operations
- [ ] Security review if touching credit data handling

---

## Testing Requirements

### Coverage Expectations
- **Unit Tests**: All service layer classes (target: 85%+)
- **Integration Tests**: All API endpoints, Kafka handlers
- **Contract Tests**: Kafka event schemas (using Pact)
- **Policy Rule Tests**: Every policy rule with edge cases

### Test Patterns

#### Unit Tests
```java
@ExtendWith(MockitoExtension.class)
class UnderwritingServiceTest {
    @Mock
    private DecisionRepository decisionRepository;
    @Mock
    private CreditBureauClient creditBureauClient;
    @Mock
    private PolicyEvaluator policyEvaluator;

    @InjectMocks
    private UnderwritingService underwritingService;

    @Test
    void shouldApprove_whenAllCriteriaMet() {
        // given
        var application = ApplicationFixture.validApplication();
        when(creditBureauClient.pullCredit(any())).thenReturn(CreditFixture.goodCredit());
        when(policyEvaluator.evaluate(any())).thenReturn(PolicyResult.pass());

        // when
        var decision = underwritingService.evaluate(application);

        // then
        assertThat(decision.getStatus()).isEqualTo(DecisionStatus.APPROVED);
        verify(decisionRepository).save(decision);
    }
}
```

#### Integration Tests
```java
@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class DecisionControllerIntegrationTest {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15");

    @Container
    static KafkaContainer kafka = new KafkaContainer(DockerImageName.parse("confluentinc/cp-kafka:7.4.0"));

    @Autowired
    private MockMvc mockMvc;

    @Test
    void shouldCreateDecision_whenValidRequest() throws Exception {
        mockMvc.perform(post("/api/v1/decisions")
                .contentType(MediaType.APPLICATION_JSON)
                .content(validRequestJson()))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.status").value("APPROVED"));
    }
}
```

### Test Data
- Use builders in `src/test/java/com/example/loanapproval/fixture/`
- `ApplicationFixture` - Test application builders
- `CreditFixture` - Credit report test data
- `DecisionFixture` - Decision test builders

---

## Common Tasks

### Adding a New REST Endpoint

1. Create/update DTO in `controller/dto/`
2. Add method to appropriate Controller
3. Implement service method if needed
4. Add validation annotations to request DTO
5. Add unit test for service logic
6. Add integration test for endpoint
7. **Update README.md API Reference section**

### Adding a New Kafka Consumer

1. Create event class in `kafka/event/`
2. Create handler in `kafka/consumer/`
3. Ensure idempotency (check if already processed by event ID)
4. Add configuration in `application.yml`
5. Add unit test for handler
6. Add integration test with embedded Kafka
7. **Update README.md Kafka Topics section**
8. **Update Integration Dependencies section in this file**

### Adding a New Policy Rule

1. Create rule class in `policy/rules/` implementing `PolicyRule`
2. Add to `PolicyEvaluator` rule chain
3. Or add as SpEL expression in database
4. Add comprehensive tests including edge cases
5. Document rule purpose and thresholds
6. **Get Product/Compliance approval before deploying**

### Modifying Event Schemas

1. Check with downstream consumers FIRST
2. Use additive changes only (add fields, don't remove/rename)
3. If breaking change needed, create new event version
4. Update Pact contracts
5. Coordinate deployment with consumers
6. **Update README.md and this file**

---

## Documentation Maintenance

When making changes, keep documentation in sync:

| Change Type | Update README.md | Update This File |
|-------------|------------------|------------------|
| New endpoint | API Reference | - |
| New Kafka topic | Kafka Topics, Architecture | Integration Dependencies |
| New entity | Domain Model, Database Schema | - |
| New external call | Integration Points, Architecture | Integration Dependencies |
| New business rule | - | Business Rules |
| New exception | Exception Handling | Exception Handling |
| Config change | Local Development Setup | - |
| New policy rule | - | Business Rules |

---

## Contacts & Resources

### Team
- **Owner Team**: Lending Platform - Decision Engine
- **Slack Channel**: #lending-decision-engine
- **On-Call**: PagerDuty rotation "lending-decisions"

### Resources
- **Repository**: https://github.com/example/loan-approval-service
- **CI/CD**: Jenkins - loan-approval-pipeline
- **Dashboards**: Grafana - Loan Decisions Dashboard
- **Runbooks**: Confluence - Loan Approval Service Runbooks
- **API Docs**: http://localhost:8080/swagger-ui.html (local) | https://api-docs.example.com/loan-approval (prod)
