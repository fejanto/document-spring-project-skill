# Interview Questions Template

This template provides structured questions for gathering business context during documentation.

## Pacing Guidelines

- **Maximum 2 questions per message**
- **Wait for user response** before continuing
- **Present technical context** before each question set
- **Summarize answers** before moving on
- **Allow skipping** if user doesn't know

---

## Section 1: Business Context (2-3 questions)

### Before Asking
Show the user:
- Detected service name from configuration
- Main REST endpoints discovered
- Entity/document classes found
- Primary dependencies detected

### Question 1.1: Service Purpose
**Primary Question:**
> "What is the primary business purpose of this service? What problem does it solve for the business or end users?"

**Follow-up if brief:**
> "Can you give me an example of a typical use case or user journey that involves this service?"

**What we're looking for:**
- Business value proposition
- Target users or systems
- Key workflows supported

### Question 1.2: Domain Terminology
**Primary Question:**
> "What domain terminology should I understand? Are there business terms that have specific meanings in this context?"

**Follow-up examples:**
> "For example, I see entities like `{Entity1}` and `{Entity2}` - do these have specific business meanings beyond their technical names?"

**What we're looking for:**
- Glossary terms
- Domain-specific language
- Abbreviations and their meanings

### Question 1.3: Critical Business Rules
**Primary Question:**
> "What are the 2-3 most critical business rules this service enforces?"

**Follow-up if needed:**
> "For instance, validation rules, constraints, or invariants that must always be true?"

**What we're looking for:**
- Invariants that must be preserved
- Validation requirements
- Business constraints

---

## Section 2: Architecture & Integration (3-4 questions)

### Before Asking
Show the user:
- Kafka topics consumed/produced
- Feign clients detected
- RestTemplate/WebClient usage
- External service references in config

### Question 2.1: Upstream Dependencies
**Primary Question:**
> "What services or systems send data TO this service? I detected {Kafka topics/Feign calls} - can you tell me more about where this data originates?"

**Follow-up:**
> "Are there any upstream dependencies not visible in the code? (external APIs, scheduled jobs, manual triggers)"

**What we're looking for:**
- Event producers
- API callers
- Data sources

### Question 2.2: Downstream Dependencies
**Primary Question:**
> "What services or systems consume data FROM this service? Who relies on the events/APIs this service produces?"

**Follow-up:**
> "What would break if this service went down or produced incorrect data?"

**What we're looking for:**
- Event consumers
- API consumers
- Impact assessment

### Question 2.3: Synchronous vs Asynchronous
**Primary Question:**
> "For the external calls I detected ({list Feign clients, REST calls}), which are critical for request processing vs. optional/non-blocking?"

**Follow-up:**
> "Are there any calls that should have circuit breakers or fallbacks?"

**What we're looking for:**
- Critical path dependencies
- Resilience requirements
- Failure handling expectations

### Question 2.4: Data Flow
**Primary Question:**
> "Can you describe a typical data flow through this service? From initial trigger to final outcome?"

**Follow-up:**
> "What's the most complex flow or the one that handles the most critical business process?"

**What we're looking for:**
- End-to-end flow understanding
- Critical paths
- Edge cases in flow

---

## Section 3: Data & State (2 questions)

### Before Asking
Show the user:
- Detected entities with table names
- Database type (PostgreSQL, MongoDB, etc.)
- Any migration files found
- Repository interfaces

### Question 3.1: Schema Completeness
**Primary Question:**
> "Are there additional fields, relationships, or constraints in the database that aren't visible in the entity classes? (columns managed by triggers, views, stored procedures)"

**Follow-up:**
> "Are there any database-level business rules (check constraints, triggers) I should know about?"

**What we're looking for:**
- Hidden complexity
- Database-level logic
- Schema evolution history

### Question 3.2: Data Lifecycle
**Primary Question:**
> "What is the lifecycle of the main data entities? (created, updated, soft-deleted, archived, hard-deleted)"

**Follow-up:**
> "How long is data retained? Are there compliance requirements affecting data handling?"

**What we're looking for:**
- State transitions
- Retention policies
- Compliance requirements

---

## Section 4: Business Rules (2-3 questions)

### Before Asking
Show the user:
- Service classes detected
- Custom exceptions found
- Validation annotations observed
- Exception handler patterns

### Question 4.1: Critical Logic
**Primary Question:**
> "What business logic in this service is critical and must never be modified without careful review?"

**Follow-up:**
> "Are there calculations, validations, or decisions that have regulatory or financial implications?"

**What we're looking for:**
- Protected logic
- High-risk areas
- Review requirements

### Question 4.2: Workflows & State Machines
**Primary Question:**
> "Are there approval workflows, state machines, or multi-step processes I should know about?"

**Follow-up:**
> "What triggers state transitions? Who or what can approve/reject?"

**What we're looking for:**
- State machine definitions
- Workflow steps
- Authorization requirements

### Question 4.3: Edge Cases
**Primary Question:**
> "What edge cases or special scenarios does this service handle that might not be obvious from the code?"

**Follow-up:**
> "Have there been production incidents that led to specific handling logic?"

**What we're looking for:**
- Historical context
- Edge case handling
- Incident-driven logic

---

## Section 5: Operational Context (2 questions)

### Before Asking
Show the user:
- Configuration properties detected
- Environment-specific configs found
- Actuator endpoints (if present)
- Logging patterns observed

### Question 5.1: Hidden Dependencies
**Primary Question:**
> "Are there runtime dependencies not visible in the code? (feature flags, A/B tests, external configuration services, scheduled jobs)"

**Follow-up:**
> "Are there environment-specific behaviors I should document?"

**What we're looking for:**
- Runtime configuration
- Feature toggles
- Environment differences

### Question 5.2: Monitoring & Troubleshooting
**Primary Question:**
> "What metrics or logs are important for monitoring this service's health? How do you typically troubleshoot issues?"

**Follow-up:**
> "Are there specific dashboards, alerts, or runbooks for this service?"

**What we're looking for:**
- Key metrics
- Log patterns
- Operational procedures

---

## Section 6: Development Context (2 questions)

### Before Asking
Show the user:
- Test file counts and patterns
- Code organization structure
- Build tool and profiles
- CI/CD indicators if visible

### Question 6.1: Coding Conventions
**Primary Question:**
> "Are there coding conventions or patterns specific to this project that I should follow when suggesting changes?"

**Follow-up:**
> "Are there specific patterns for error handling, logging, or testing that differ from standard Spring Boot practices?"

**What we're looking for:**
- Team conventions
- Pattern preferences
- Style requirements

### Question 6.2: Known Issues & Future Plans
**Primary Question:**
> "What are known issues, technical debt items, or planned improvements I should be aware of?"

**Follow-up:**
> "Are there areas of the code that are being deprecated or scheduled for refactoring?"

**What we're looking for:**
- Technical debt locations
- Deprecation plans
- Roadmap context

---

## Section 7: Patterns & Conventions (2-3 questions)

### Before Asking
Show the user:
- Detected architectural patterns (layered, hexagonal, DDD, etc.)
- Repository patterns observed
- Service patterns used
- Any custom base classes or utilities

### Question 7.1: Architectural Patterns
**Primary Question:**
> "What architectural patterns does this service follow? I noticed {detected patterns} - are there other important patterns I should document?"

**Follow-up:**
> "Are there specific design patterns that are critical to how this service works? (CQRS, Event Sourcing, Saga, etc.)"

**What we're looking for:**
- DDD patterns (aggregates, value objects, domain services)
- Persistence patterns
- Messaging patterns
- Critical design decisions

### Question 7.2: Persistence Conventions
**Primary Question:**
> "Are there specific conventions for database operations? For example, transaction boundaries, cascade behavior, or repository patterns?"

**Follow-up:**
> "How should developers handle entity graphs or related data when making changes?"

**What we're looking for:**
- Transaction management patterns
- Entity relationship handling
- Performance optimization patterns
- Custom persistence utilities

### Question 7.3: Anti-patterns & Never Do
**Primary Question:**
> "What should NEVER be done when modifying code in this service? Are there common mistakes or anti-patterns to avoid?"

**Follow-up:**
> "Have there been bugs or incidents caused by developers not following certain rules?"

**What we're looking for:**
- Explicit prohibitions
- Common mistakes
- Critical gotchas
- Lessons learned from incidents

---

## Section 8: Critical Workflows (2-3 questions)

### Before Asking
Show the user:
- Complex service methods identified
- Transaction boundaries detected
- Async/scheduled jobs found
- Batch processing patterns

### Question 8.1: Critical Processes
**Primary Question:**
> "What workflows or processes in this service are critical and must NOT be modified without careful review and testing?"

**Follow-up:**
> "Which of these processes require strict ordering of operations or have complex error handling?"

**What we're looking for:**
- High-risk workflows
- Processes requiring review
- Complex orchestrations
- Financial/regulatory critical paths

### Question 8.2: Execution Order Requirements
**Primary Question:**
> "Are there operations that must execute in a specific order? What happens if that order is violated?"

**Follow-up:**
> "Are there dependencies between steps that aren't obvious from the code?"

**What we're looking for:**
- Sequence dependencies
- Side effects that matter
- Idempotency requirements
- Rollback/compensation logic

### Question 8.3: Common Developer Tasks
**Primary Question:**
> "What are the most common tasks developers perform on this service? (adding endpoints, modifying business rules, changing integrations)"

**Follow-up:**
> "For each of those tasks, what's the recommended approach or checklist?"

**What we're looking for:**
- Frequent modification patterns
- Step-by-step procedures
- Testing requirements
- Documentation update triggers

---

## Incremental Interview Questions

When using **incremental documentation mode** (detecting changes via git diff), ask targeted questions based on the type of changes detected:

### For New Controllers/Endpoints
**Before asking, show:**
- New endpoint paths detected
- HTTP methods
- Request/response types

**Questions:**
1. "I detected a new endpoint: `{METHOD} {PATH}`. What is its primary business purpose?"
2. "Are there authorization requirements or business rules specific to this endpoint?"
3. "Should this endpoint trigger any side effects? (events, notifications, etc.)"

### For New Entities
**Before asking, show:**
- New entity name and table
- Detected relationships
- Key fields

**Questions:**
1. "I found a new entity `{EntityName}`. Can you describe its lifecycle? (created → updated → deleted/archived)"
2. "What are the business rules around this entity? What invariants must always be true?"
3. "How does this entity relate to existing entities in the domain model?"

### For New Kafka Consumers
**Before asking, show:**
- Topic name
- Event handler class
- Consumer group

**Questions:**
1. "I detected a new Kafka consumer for topic `{topic}`. What events does this consume and from which service?"
2. "What business logic is triggered when these events arrive?"
3. "Is this processing idempotent? What happens if the same event is received twice?"

### For New Kafka Producers
**Before asking, show:**
- Topics produced to
- Event types
- Trigger locations

**Questions:**
1. "I found new event production to `{topic}`. What downstream services consume this?"
2. "When is this event published? What triggers it?"
3. "Are there ordering guarantees or delivery semantics that consumers rely on?"

### For Modified Services
**Before asking, show:**
- Service class name
- Changed method signatures (if visible)

**Questions:**
1. "I detected changes in `{ServiceName}`. Did the business logic change, or was this refactoring?"
2. "If business logic changed, what's the new rule or behavior?"
3. "Does this change affect any documented workflows or state transitions?"

### For New External Integrations
**Before asking, show:**
- New @FeignClient or RestTemplate usage
- Target service/URL
- Called endpoints

**Questions:**
1. "I found a new integration with `{ServiceName}`. Is this a critical dependency or optional?"
2. "What happens if this service is unavailable? Should there be a circuit breaker or fallback?"
3. "Is this integration synchronous and blocking, or can it be handled asynchronously?"

### For Configuration Changes
**Before asking, show:**
- New configuration properties
- Changed values
- New profiles

**Questions:**
1. "I detected new configuration: `{property}`. What does this control?"
2. "Are there environment-specific values that should be documented?"
3. "Does this change affect setup instructions or deployment requirements?"

---

## Interview Completion

### Summary Template
After completing all sections, summarize:

```
Based on our conversation, here's what I understand about {Service Name}:

**Business Purpose:**
{Summary of business value and use cases}

**Key Integrations:**
- Upstream: {list}
- Downstream: {list}

**Critical Business Rules:**
1. {Rule 1}
2. {Rule 2}
3. {Rule 3}

**Data Model:**
{Key entities and their lifecycle}

**Architectural Patterns:**
{Key patterns and conventions}

**Critical Workflows:**
{Workflows that require careful handling}

**Development Guidelines:**
{Key conventions and anti-patterns to avoid}

Is this accurate? Should I proceed with generating the documentation?
```

### User Confirmation
Wait for user to confirm before generating documentation. Allow for corrections or additions.

---

## Notes for Incremental Mode

When in incremental mode:
- Only ask questions relevant to detected changes
- Skip sections where no changes were detected
- Reference existing documentation when asking questions
- Focus on how changes integrate with existing architecture
- Confirm if changes require updating existing sections beyond what's obvious
