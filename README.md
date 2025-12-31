# Document Spring Project Skill

A Claude Code skill that analyzes Spring Boot microservices and generates comprehensive documentation through automated technical analysis combined with interactive interview.

## Features

- **Automated Technical Analysis** - Scans your Spring Boot codebase to extract:
  - Build configuration (Maven/Gradle, Java version, Spring Boot version)
  - REST endpoints from controllers
  - Kafka consumers and producers
  - JPA entities and MongoDB documents
  - Feign clients and external service calls
  - Exception hierarchy and error handling
  - Configuration properties
  - Test coverage

- **Interactive Interview** - Gathers business context that can't be inferred from code:
  - Business purpose and domain terminology
  - Architecture and integration dependencies
  - Critical business rules
  - Operational context

- **Comprehensive Documentation Generation**:
  - `README.md` with architecture diagrams (Mermaid), API reference, setup instructions
  - `.claude/instructions.md` with AI assistant guidelines for the codebase

- **Living Documentation** - Automatically updates docs when code changes are made

## Quick Start

### Installation via Plugin (Recommended)

```bash
# Add the marketplace
/plugin marketplace add fejanto/document-spring-project-skill

# Install the plugin
/plugin install document-spring-project@fejanto-skills
```

### Alternative: Manual Installation

**Project-specific:**
```bash
mkdir -p .claude/skills
cd .claude/skills
git clone https://github.com/fejanto/document-spring-project-skill.git
```

**Global:**
```bash
mkdir -p ~/.claude/skills
cd ~/.claude/skills
git clone https://github.com/fejanto/document-spring-project-skill.git
```

### Usage

Simply ask Claude Code to document your service:

```
> document this service
```

Or use any of these triggers:
- "document this project"
- "generate README"
- "create documentation"
- "create .claude/instructions.md"
- "analyze this microservice"

## What Gets Generated

### README.md

A comprehensive README including:

| Section | Description |
|---------|-------------|
| Business Overview | Purpose, use cases, domain glossary |
| Tech Stack | Dependencies with versions |
| Architecture | Mermaid diagrams (context + component) |
| Domain Model | Entity relationships |
| API Reference | REST endpoints, Kafka topics |
| Database Schema | Tables, indexes, migrations |
| Exception Handling | Error hierarchy and responses |
| Integration Points | Upstream/downstream dependencies |
| Local Development | Setup and configuration |
| Troubleshooting | Common issues and solutions |

### .claude/instructions.md

AI assistant guidelines including:

| Section | Description |
|---------|-------------|
| Business Domain | Context and terminology |
| Service Responsibilities | Scope and boundaries |
| Integration Dependencies | Critical dependencies |
| Architecture Patterns | Patterns in use |
| Code Organization | Package structure, naming |
| Exception Handling | When to throw what |
| Business Rules | Critical logic to preserve |
| Development Guidelines | DO and DON'T lists |
| Common Tasks | Step-by-step guides |

## Example Outputs

See the `examples/` directory for complete sample outputs:
- [sample-output-readme.md](examples/sample-output-readme.md) - Example README for a loan approval service
- [sample-output-instructions.md](examples/sample-output-instructions.md) - Example Claude instructions

## Usage Modes

### Full Documentation (Default)
```
> document this service
```
Runs technical analysis + full interview + generates both files.

### Quick Mode
```
> generate quick docs for this service
```
Technical analysis only, skips interview. Business sections marked as TODO.

### Update Mode
```
> update the README with new endpoints
```
Analyzes current code, compares with existing docs, updates only changed sections.

### Focused Mode
```
> document only the API endpoints
```
Generates specific sections only.

## How It Works

### Phase 1: Technical Analysis

The skill runs `scripts/analyze.sh` to automatically extract:

```
Spring Boot Project Analysis
════════════════════════════════════════════════════════════════

── Build System ──
✓ Maven project detected
• Java Version: 17
• Spring Boot Version: 3.2.0

── Dependencies ──
✓ Spring Web (REST APIs)
✓ Spring Data JPA
✓ Apache Kafka
✓ OpenFeign HTTP Client

── REST Controllers & Endpoints ──
  OrderController (base: /api/v1/orders)
      GET /api/v1/orders
      POST /api/v1/orders
      GET /api/v1/orders/{id}

── Exception Handling ──
  GlobalExceptionHandler
      handles: OrderNotFoundException
      handles: ValidationException

── Kafka Integration ──
  Kafka Consumers (@KafkaListener):
  ✓ OrderEventHandler: topic=order-events group=order-group

...
```

### Phase 2: Interactive Interview

Claude asks questions to understand business context:

```
Based on my analysis, I found:
- 12 REST endpoints in 3 controllers
- 2 Kafka consumers
- 5 JPA entities

Let me understand the business context.

What is the primary purpose of this service? What business problem does it solve?
```

Questions are asked in small batches (max 2 at a time), with Claude summarizing answers before continuing.

### Phase 3: Documentation Generation

Claude generates both files with all gathered information, including Mermaid diagrams for architecture visualization.

### Automatic Updates

After any code change, Claude checks if documentation needs updating:

```
I've added the cancel order endpoint:
- POST /api/v1/orders/{id}/cancel

Documentation updated:
README.md:
- API Reference: Added cancel endpoint row

.claude/instructions.md:
- Common Tasks: Added 'Canceling an order' section
```

## Requirements

### Your Project
- Spring Boot 2.x or 3.x
- Java 11, 17, or 21
- Maven or Gradle

### Analysis Tools
- bash 4.0+
- grep (with -r, -E support)
- find, sed, awk

## Supported Technologies

| Category | Technologies |
|----------|--------------|
| Build | Maven, Gradle |
| Database | PostgreSQL, MySQL, MongoDB, H2 |
| Messaging | Apache Kafka, RabbitMQ |
| HTTP Clients | Feign, RestTemplate, WebClient |
| API Docs | SpringDoc OpenAPI, Swagger |
| Testing | JUnit 5, Mockito, Testcontainers |
| Migration | Flyway, Liquibase |

## Project Structure

```
document-spring-project-skill/
├── .claude-plugin/
│   ├── plugin.json             # Plugin manifest
│   └── marketplace.json        # Marketplace catalog
├── skills/
│   └── document-spring-project/
│       ├── SKILL.md            # Main skill file (what Claude reads)
│       ├── scripts/
│       │   ├── analyze.sh      # Automated analysis script
│       │   └── helpers.sh      # Bash helper functions
│       └── templates/
│           ├── interview-questions.md
│           ├── readme-template.md
│           └── instructions-template.md
├── examples/
│   ├── sample-output-readme.md
│   └── sample-output-instructions.md
├── README.md                   # This file
└── .gitignore
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with a real Spring Boot project
5. Submit a pull request

### Ideas for Contributions
- Support for additional frameworks (Quarkus, Micronaut)
- More diagram types (sequence, state)
- Integration with OpenAPI specs
- Support for Kotlin projects
- Additional languages (Spanish, Portuguese)

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Built for [Claude Code](https://claude.ai/claude-code)
- Uses [Mermaid](https://mermaid.js.org/) for diagrams
- Inspired by real-world microservice documentation needs
