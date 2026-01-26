---
name: document-spring-project
description: Analyzes Spring Boot microservices and generates comprehensive documentation following Claude Code 2026 patterns through automated technical analysis and interactive interview. Supports full, incremental, and selective documentation modes.
---

# Document Spring Project Skill (v2.0)

## Description

This skill generates **comprehensive, production-grade documentation** for Spring Boot microservices following the **Claude Code 2026 pattern**:

### New Documentation Structure (v2.0)

```
microservice/
├── CLAUDE.md                    # Concise service overview (~87 lines)
├── README.md                    # Complete documentation (800+ lines)
├── .claudeignore                # Exclude files from context
├── .claude/
│   ├── rules/                   # Auto-loaded concise rules
│   │   ├── architecture.md      # Critical architectural patterns
│   │   ├── domain.md            # Business rules and domain logic
│   │   └── workflows.md         # Common tasks and procedures
│   └── instructions.md.deprecated  # Legacy format (if exists)
└── docs/
    ├── domain/                  # Extended domain documentation
    ├── architecture/            # Patterns with complete diagrams
    ├── database/                # Schema and migrations
    └── plans/                   # Historical implementation plans
```

**Key Benefits:**
- **Context-optimized**: Only ~500 lines auto-loaded (.claude/rules/), rest on-demand (docs/)
- **Organized**: Rules separated by category instead of one monolithic file
- **Scalable**: Easy to add new rules without context bloat
- **Standards-compliant**: Follows official Claude Code 2026 conventions

## When to Use This Skill

### Trigger Phrases

**INVOKE THIS SKILL** when the user says:

- "document this service" / "document this project"
- "generate documentation" / "create docs"
- "update documentation" / "refresh docs"
- "/docs" (command alias)
- "document the {section}" (e.g., "document the API endpoints")
- "add {feature} to documentation"

### Proactive Triggers

**AUTOMATICALLY INVOKE** after Claude makes code changes affecting:
- API contracts (new/modified endpoints)
- Event contracts (Kafka topics, event schemas)
- Data models (entities, state machines)
- Integration points (external services)
- Business rules

## Three Modes of Operation

At the start of EVERY invocation, ask the user to choose a mode:

```
🔍 Documentation Mode

How would you like to proceed?

1. **Full Analysis** - Complete documentation from scratch (or enrich existing)
   → Full technical analysis + complete interview (8 sections)
   → Generates/regenerates entire documentation structure
   → Use when: First time, major refactoring, or comprehensive update

2. **Incremental Update** - Document only recent changes
   → Detects changes via git diff since last doc commit
   → Targeted questions about changes only
   → Updates only affected sections
   → Use when: After implementing features, bug fixes

3. **Selective Documentation** - Document specific section/component
   → Focus on user-specified area (e.g., "API endpoints", "domain model")
   → Minimal interview, targeted questions
   → Updates/creates only specified section
   → Use when: New feature added, specific section outdated

Choose 1, 2, or 3:
```

**IMPORTANT**: User MUST choose before proceeding. Do not assume a mode.

---

## Mode 1: Full Analysis

### Overview

Complete documentation generation or enrichment. Suitable for:
- First-time documentation
- Major refactoring/restructuring
- Comprehensive documentation updates

### Workflow

#### Step 1: Technical Analysis

Execute the analysis script:

```bash
cd /path/to/skill/scripts
bash analyze.sh /path/to/project
```

**Analysis extracts:**
- Build system (Maven/Gradle), Java version, Spring Boot version
- Dependencies (Spring Web, JPA, Kafka, Security, etc.)
- REST endpoints (all @Controller/@RestController with mappings)
- Kafka integration (@KafkaListener, KafkaTemplate)
- Database entities (@Entity, @Document)
- External calls (@FeignClient, RestTemplate, WebClient)
- Service classes, configuration, tests

**Enhanced v2.0 features:**
- Detects existing documentation structure
- Reports what will be created/updated
- Identifies legacy .claude/instructions.md

**Present findings to user before interview.**

#### Step 2: Detect Existing Documentation

```bash
bash analyze.sh /path/to/project --mode full
```

Script will output:
```
Existing Documentation Detection:
✓ CLAUDE.md found
✓ .claude/rules/ directory found (3 rule files detected)
✓ docs/ directory found (4 subdirectories detected)
✓ README.md found
⚠ .claude/instructions.md found (legacy format - will be deprecated)
```

**Inform user:**
- What exists will be enriched (not replaced)
- Legacy instructions.md will be renamed to .deprecated
- New structure will be created where missing

#### Step 3: Interactive Interview (8 Sections)

Conduct full interview following `templates/interview-questions.md`:

**Pacing rules:**
- Maximum 2 questions per message
- Wait for user response before continuing
- Present technical findings before each section
- Summarize responses before moving on
- Allow user to skip sections

**Interview sections:**
1. **Business Context** (2-3 questions)
   - Service purpose and business value
   - Domain terminology
   - Critical business rules

2. **Architecture & Integration** (3-4 questions)
   - Upstream/downstream dependencies
   - Synchronous vs asynchronous calls
   - Data flow through service

3. **Data & State** (2 questions)
   - Schema completeness
   - Data lifecycle

4. **Business Rules** (2-3 questions)
   - Critical logic
   - Workflows and state machines
   - Edge cases

5. **Operational Context** (2 questions)
   - Hidden dependencies
   - Monitoring and troubleshooting

6. **Development Context** (2 questions)
   - Coding conventions
   - Known issues and technical debt

7. **Patterns & Conventions** (2-3 questions) [NEW v2.0]
   - Architectural patterns (DDD, CQRS, etc.)
   - Persistence conventions
   - Anti-patterns to avoid

8. **Critical Workflows** (2-3 questions) [NEW v2.0]
   - Critical processes requiring review
   - Execution order requirements
   - Common developer tasks

**After interview, summarize understanding and get user confirmation.**

#### Step 4: Documentation Generation

Generate documentation using new templates:

**1. CLAUDE.md** (root)
```bash
# Use template: templates/claude-md-template.md
# Output: CLAUDE.md (~87 lines)
```
Content:
- Service name and one-line description
- Stack summary
- HACE/NO HACE responsibilities
- Integration dependencies (critical/important/optional)
- References to .claude/rules/
- References to /docs/

**2. .claude/rules/** (3-4 files)
```bash
# Use templates:
# - rules-architecture-template.md → .claude/rules/architecture.md
# - rules-domain-template.md → .claude/rules/domain.md
# - rules-workflows-template.md → .claude/rules/workflows.md
```

**architecture.md** (~150 lines):
- Critical architectural patterns with code examples
- When to use / NEVER do
- Performance considerations
- Critical warnings

**domain.md** (~150 lines):
- Entity hierarchy diagrams
- State definitions and transitions
- Critical business rules
- Database schema quick reference
- Critical warnings

**workflows.md** (~150 lines):
- Common tasks (add endpoint, entity, etc.)
- Documentation maintenance rules
- Error codes reference
- Testing requirements

**3. docs/** (subdirectories)
```bash
# Use templates:
# - docs-domain-template.md → docs/domain/{entity}-model.md (per entity)
# - docs-architecture-template.md → docs/architecture/{pattern}.md (per pattern)
# - docs-database-template.md → docs/database/database-schema.md
```

Create comprehensive documentation:
- `docs/domain/` - One file per main entity with lifecycle, rules, examples
- `docs/architecture/` - One file per pattern with problem/solution/implementation
- `docs/database/` - Complete schema with indexes, relationships

**4. .claudeignore**
```bash
# Use template: templates/claudeignore-template.txt
# Exclude: target/, .idea/, logs/, docs/plans/*.md
```

**5. README.md**
Update or create README.md with:
- Business Overview
- Tech Stack
- Architecture diagrams (Mermaid)
- Domain Model
- API Reference
- Database Schema
- Integration Points
- Local Development Setup
- Troubleshooting

**6. Deprecate legacy**
If .claude/instructions.md exists:
```bash
mv .claude/instructions.md .claude/instructions.md.deprecated
```

#### Step 5: Offer Hook Setup

After successful generation, ask:

```
✅ Documentation generated successfully!

Would you like to set up an automatic reminder to update docs after code changes?

This will:
- Create .claude/hooks/post-implementation.sh
- Remind you when 3+ files in src/main/ are modified
- Suggest running /docs in incremental mode

Set up automatic reminder? (y/n)
```

If yes:
```bash
# Copy templates/hook-template.sh to .claude/hooks/post-implementation.sh
# Make executable
# Add to .claude/settings.local.json (if exists)
```

#### Step 6: Summary

```
✅ Documentation complete!

Generated/Updated:
- CLAUDE.md (~87 lines)
- .claude/rules/architecture.md (~150 lines)
- .claude/rules/domain.md (~150 lines)
- .claude/rules/workflows.md (~150 lines)
- .claudeignore
- docs/domain/*.md (3 files)
- docs/architecture/*.md (2 files)
- docs/database/database-schema.md
- README.md (updated)

Auto-loaded context: ~490 lines
Extended docs: ~XK lines (load on-demand)

Next steps:
1. Review generated files
2. Customize if needed
3. Commit: git add . && git commit -m "docs: generate documentation v2.0"
```

---

## Mode 2: Incremental Update

### Overview

Document only changes since last documentation update. Suitable for:
- After implementing features
- After bug fixes
- Regular maintenance

### Requirements

- Must be a git repository
- Must have previous documentation commit

### Workflow

#### Step 1: Detect Last Doc Commit

```bash
bash scripts/git-utils.sh detect-last-commit
```

If no previous doc commit found:
```
No previous documentation commits found.
Incremental mode requires existing documentation.

Switching to Full Analysis mode...
```

#### Step 2: Detect Changes

```bash
bash scripts/git-utils.sh summary
```

Output:
```
Last documentation commit: a3f4b891
Changed files since last docs: 8

NEW_CONTROLLERS=2
NEW_CONTROLLER: src/main/java/com/example/api/OrderController.java
NEW_CONTROLLER: src/main/java/com/example/api/PaymentController.java

NEW_ENTITIES=1
NEW_ENTITY: src/main/java/com/example/domain/Payment.java

MODIFIED_SERVICES=3
MODIFIED_SERVICE: src/main/java/com/example/service/OrderService.java
...
```

**Inform user:**
```
Detected changes since last documentation update:
- 2 new controllers (OrderController, PaymentController)
- 1 new entity (Payment)
- 3 modified services

I'll ask targeted questions about these changes.
```

#### Step 3: Targeted Analysis

Analyze only changed files:
```bash
bash scripts/analyze.sh /path/to/project --mode incremental --files "file1,file2,file3"
```

Extracts details from changed files only.

#### Step 4: Targeted Interview

Ask questions based on change types (from `templates/interview-questions.md`):

**For NEW_CONTROLLERS:**
```
I detected new endpoints in OrderController:
- POST /api/v1/orders
- GET /api/v1/orders/{id}
- POST /api/v1/orders/{id}/confirm

Questions:
1. What is the business purpose of the order confirmation endpoint?
2. Are there authorization requirements or business rules specific to these endpoints?
```

**For NEW_ENTITIES:**
```
I found a new Payment entity with fields: id, orderId, amount, status, paymentMethod.

Questions:
1. Can you describe the Payment lifecycle? (created → ... → completed/failed)
2. What are the business rules around Payment? What invariants must be true?
```

**For MODIFIED_SERVICES:**
```
I detected changes in OrderService.

Question:
1. Did the business logic change, or was this refactoring?
(If logic changed) What's the new behavior?
```

**Keep interview minimal** - only ask about changes.

#### Step 5: Update Affected Sections

Identify which sections need updating:
```bash
bash scripts/git-utils.sh affected-sections
```

Output:
```
api-reference
claude-md
domain-model
rules-domain
docs-domain
```

**Update strategy:**
- Read existing documentation
- Insert/update ONLY affected sections
- Preserve everything else unchanged

**Example - Update README.md API Reference:**
```markdown
<!-- BEFORE -->
## API Reference
### Orders
| Method | Path | Description |
|--------|------|-------------|
| GET | /api/v1/orders | List orders |

<!-- AFTER - Add new rows -->
## API Reference
### Orders
| Method | Path | Description |
|--------|------|-------------|
| GET | /api/v1/orders | List orders |
| POST | /api/v1/orders | Create order |
| POST | /api/v1/orders/{id}/confirm | Confirm order |
```

**Update CLAUDE.md** if new integrations detected.

**Update .claude/rules/domain.md** if new entities.

**Create docs/domain/payment-model.md** for new Payment entity.

#### Step 6: Summary

```
✅ Documentation updated!

Changes:
- README.md: Added 2 endpoints to API Reference
- CLAUDE.md: No changes needed
- .claude/rules/domain.md: Added Payment entity section
- docs/domain/payment-model.md: Created

Files reviewed but not changed: 5
Files updated: 3
Files created: 1
```

---

## Mode 3: Selective Documentation

### Overview

Document a specific section or component. Suitable for:
- New feature just added
- Specific section is outdated
- User requests specific part

### Workflow

#### Step 1: Clarify Scope

Ask user what to document:

```
What would you like to document?

Examples:
- "API endpoints" → Update API Reference in README
- "Payment domain model" → Create/update docs/domain/payment-model.md
- "Kafka integration" → Update Integration Points and architecture.md
- "State machine" → Update domain.md with state transitions
- "Architecture pattern X" → Create/update docs/architecture/X.md

Please specify:
```

#### Step 2: Targeted Analysis

Based on scope, run focused analysis:

**For "API endpoints":**
```bash
# Analyze all controllers
bash scripts/analyze.sh /path/to/project --section api
```

**For "Payment domain model":**
```bash
# Analyze Payment entity and related files
bash scripts/analyze.sh /path/to/project --section domain --focus Payment
```

#### Step 3: Minimal Interview

Ask 2-3 targeted questions:

**For API endpoints:**
```
I found these endpoints:
- POST /api/v1/orders
- POST /api/v1/orders/{id}/confirm

Questions:
1. What authorization is required for each endpoint?
2. Should I document request/response examples?
```

**For domain model:**
```
Payment entity detected with states: PENDING, COMPLETED, FAILED.

Questions:
1. What triggers each state transition?
2. Are there business rules around payment processing?
```

#### Step 4: Update Specific Section

Update ONLY the requested section:

**If "API endpoints":**
- Update README.md → API Reference section
- Update .claude/rules/workflows.md if new common pattern

**If "domain model":**
- Update/create docs/domain/payment-model.md
- Update .claude/rules/domain.md (add to entity list)
- Update README.md → Domain Model section

**Leave everything else untouched.**

#### Step 5: Summary

```
✅ Section documented!

Updated:
- README.md: API Reference section (added 2 endpoints)

Recommend also updating:
- .claude/rules/workflows.md (if this is a common task pattern)

Would you like me to update those as well?
```

---

## Technical Requirements

### Supported Technologies

- **Java**: 11, 17, 21
- **Spring Boot**: 2.x, 3.x
- **Build Tools**: Maven, Gradle
- **Databases**: PostgreSQL, MySQL, MongoDB, H2
- **Messaging**: Apache Kafka, RabbitMQ
- **HTTP Clients**: Feign, RestTemplate, WebClient

### Required CLI Tools

- `bash` (4.0+)
- `grep`, `find`, `sed`, `awk`
- `git` (for incremental/selective modes)

---

## Command Usage

### Via Command Alias

```
/docs
```

Triggers this skill with mode selection prompt.

### Via Natural Language

- "document this service"
- "update documentation"
- "document the API"

### After Code Changes

Skill is automatically invoked when Claude detects documentation-affecting changes.

---

## Output Structure Comparison

### Legacy (v1.0)

```
project/
├── README.md
└── .claude/
    └── instructions.md (480 lines - monolithic)
```

**Problems:**
- All rules in one file
- Hard to navigate
- Context bloat

### New (v2.0)

```
project/
├── CLAUDE.md (87 lines - overview)
├── README.md (updated)
├── .claudeignore
├── .claude/
│   ├── rules/
│   │   ├── architecture.md (150 lines)
│   │   ├── domain.md (150 lines)
│   │   └── workflows.md (150 lines)
│   └── instructions.md.deprecated
└── docs/
    ├── domain/ (extended, load on-demand)
    ├── architecture/
    └── database/
```

**Benefits:**
- Organized by category
- Auto-loaded: ~490 lines (vs 480 legacy)
- Extended docs available but not auto-loaded
- Easier to maintain and extend

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Not a Spring Boot project | Inform user, offer to document as generic Java project |
| No pom.xml or build.gradle | Ask user about build system, proceed with limited analysis |
| Analysis script fails | Fall back to manual file inspection via Read tool |
| User wants to skip interview | Generate with "TODO" placeholders for business context |
| Git not available (incremental mode) | Switch to Full Analysis mode |
| No previous docs (incremental mode) | Switch to Full Analysis mode |
| No existing docs when updating | Run Full Analysis instead |

---

## Hook Setup (Optional)

After generating documentation, offer to set up automatic reminder:

### What the Hook Does

- Monitors src/main/ for changes
- Triggers after 3+ relevant files modified (controllers, services, entities)
- Shows reminder in terminal
- Does NOT auto-run - only reminds

### Hook Script

Uses `templates/hook-template.sh`:

```bash
#!/usr/bin/env bash
# Detects changes and shows reminder

LAST_DOC_COMMIT=$(git log -1 --format="%H" -- CLAUDE.md .claude/rules/ docs/)
CHANGES_COUNT=$(git diff "$LAST_DOC_COMMIT"..HEAD --name-only -- src/main/ | wc -l)

if [ "$CHANGES_COUNT" -ge 3 ]; then
    echo "📝 Reminder: Documentation pending"
    echo "   Run: /docs (choose mode 2 - Incremental)"
fi
```

### Setup Steps

If user agrees:
1. Create `.claude/hooks/` directory
2. Copy hook script
3. Make executable: `chmod +x .claude/hooks/post-implementation.sh`
4. Inform user about hook behavior

**Note:** Hook is opt-in and non-intrusive. User can delete at any time.

---

## Best Practices

### When Running Full Analysis

- Read existing docs first to enrich, not replace
- Confirm interview summary before generating
- Offer hook setup at the end

### When Running Incremental

- Always show what changed before asking questions
- Update only affected sections
- Preserve existing content exactly
- Summarize changes made

### When Running Selective

- Clarify scope explicitly
- Keep analysis and interview minimal
- Update only requested section
- Suggest related sections that might need updates

### General

- Never skip mode selection
- Always present analysis findings before interview
- Maximum 2 questions per message
- Wait for user response before continuing
- Summarize before moving to next section
- Confirm understanding before generating docs

---

## Examples

### Example 1: Full Analysis (First Time)

```
User: /docs

Claude: 🔍 Documentation Mode

How would you like to proceed?

1. Full Analysis
2. Incremental Update
3. Selective Documentation

Choose 1, 2, or 3:

User: 1

Claude: I'll run a complete analysis and generate documentation.

[Runs analyze.sh]

Here's what I found:
- Spring Boot 3.2.0, Java 21
- 8 REST endpoints across 3 controllers
- 2 Kafka consumers (order-events, payment-events)
- 4 JPA entities (Order, Payment, Customer, Product)
- Feign client calling inventory-service

No existing documentation detected. I'll create the full structure.

Let me understand the business context. What is the primary purpose of this service?

[Interview continues...]
[Generates all documentation]

✅ Documentation complete!

Would you like to set up an automatic reminder? (y/n)
```

### Example 2: Incremental Update

```
User: /docs

Claude: 🔍 Documentation Mode

Choose: 1 (Full), 2 (Incremental), or 3 (Selective)

User: 2

Claude: I'll document changes since your last documentation update.

[Runs git diff analysis]

Detected changes since commit a3f4b89 (3 days ago):
- 1 new controller: PaymentController
- 2 new endpoints: POST /payments, GET /payments/{id}
- 1 modified service: OrderService (added payment integration)

Let me ask about these changes:

1. What is the business purpose of the payment endpoints?
2. How does OrderService integrate with the payment flow?

[User answers]

[Updates only affected sections]

✅ Documentation updated!

Changes:
- README.md: Added payment endpoints to API Reference
- .claude/rules/architecture.md: Added payment integration pattern
- CLAUDE.md: Added payment-service to dependencies

3 files updated, rest preserved.
```

### Example 3: Selective Documentation

```
User: document the state machine for orders

Claude: I'll focus on documenting the Order state machine.

[Analyzes Order entity]

I found these Order states:
PENDING → PAYMENT_PENDING → CONFIRMED → SHIPPED → DELIVERED
                                      ↓
                                 CANCELLED

Questions:
1. What triggers each transition?
2. Are there conditions or validations for each transition?

[User answers]

[Updates domain.md and creates docs/domain/order-model.md]

✅ Order state machine documented!

Updated:
- .claude/rules/domain.md: Added state machine section
- docs/domain/order-model.md: Created with full lifecycle
- README.md: Updated Domain Model diagram

Would you like me to document anything else related to orders?
```

---

## Migration from v1.0

If project has legacy .claude/instructions.md:

1. Detect legacy format
2. Parse content into categories:
   - Business context → CLAUDE.md
   - Architecture patterns → .claude/rules/architecture.md
   - Business rules → .claude/rules/domain.md
   - Common tasks → .claude/rules/workflows.md
3. Rename original to .instructions.md.deprecated
4. Generate new structure
5. Inform user of migration

---

## Version History

- **v2.0.0** (2026-01-26):
  - New documentation structure (CLAUDE.md + .claude/rules/ + docs/)
  - Three operation modes (Full, Incremental, Selective)
  - Git-based change detection
  - Extended interview (8 sections)
  - Optional hook setup
  - /docs command alias

- **v1.0.1** (2024-12-29):
  - Initial release
  - Single mode (full analysis only)
  - Generates README.md + .claude/instructions.md

---

## Support & Troubleshooting

### Git not available

```
⚠ Git not detected. Incremental and Selective modes unavailable.
Falling back to Full Analysis mode.
```

### No previous documentation

```
ℹ No previous documentation found.
Incremental mode requires existing docs.
Switching to Full Analysis mode.
```

### Analysis script fails

```
⚠ Analysis script encountered an error.
Falling back to manual analysis via file inspection.
```

### User skips interview

```
ℹ Interview skipped. Generating technical documentation only.
Business context sections will be marked with "TODO: Add business context"
```

---

## Notes

- Always run in the skill's context (has access to templates/ and scripts/)
- Templates use Handlebars-like syntax ({{VARIABLE}})
- Examples in examples/ directory use generic "Order Management Service"
- Hook setup is optional and can be skipped
- Incremental mode preserves all existing content not explicitly updated
- Selective mode is most efficient for targeted updates

