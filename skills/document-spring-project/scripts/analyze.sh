#!/usr/bin/env bash
#
# Spring Boot Project Analyzer
# Extracts technical details from Spring Boot microservices
# Portable version - works on macOS (BSD) and Linux (GNU)
#
# Note: Using set -u for unbound variables, but not -e to allow grep failures
set -uo pipefail

# Source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

# Project path (default to current directory)
PROJECT_PATH="${1:-.}"

# Validate project path
if [[ ! -d "$PROJECT_PATH" ]]; then
    error "Directory not found: $PROJECT_PATH"
    exit 1
fi

cd "$PROJECT_PATH"

# =============================================================================
# PORTABLE EXTRACTION HELPERS
# =============================================================================

# Extract value between XML tags: <tag>VALUE</tag>
# Usage: extract_xml_tag "file" "tag"
extract_xml_tag() {
    local file="$1"
    local tag="$2"
    sed -n "s|.*<${tag}>\([^<]*\)</${tag}>.*|\1|p" "$file" 2>/dev/null | head -1
}

# Extract quoted value after pattern: pattern="VALUE"
# Usage: extract_quoted_after "file" "pattern"
extract_quoted_after() {
    local file="$1"
    local pattern="$2"
    grep "$pattern" "$file" 2>/dev/null | sed -n 's|.*'"$pattern"'"\([^"]*\)".*|\1|p' | head -1
}

# Extract value from annotation: @Annotation("VALUE") or @Annotation(param="VALUE")
# Usage: extract_annotation_value "file" "@Annotation"
extract_annotation_value() {
    local file="$1"
    local annotation="$2"
    grep "$annotation" "$file" 2>/dev/null | sed -n 's|.*'"$annotation"'("\([^"]*\)".*|\1|p' | head -1
}

# Extract HTTP method from mapping annotation
# Usage: extract_http_method "line"
extract_http_method() {
    local line="$1"
    echo "$line" | sed -n 's|.*@\(Get\|Post\|Put\|Delete\|Patch\)Mapping.*|\1|p'
}

# Extract path from mapping annotation
# Usage: extract_mapping_path "line"
extract_mapping_path() {
    local line="$1"
    local path
    # Try @XxxMapping("path")
    path=$(echo "$line" | sed -n 's|.*Mapping("\([^"]*\)".*|\1|p')
    if [[ -z "$path" ]]; then
        # Try @XxxMapping(value = "path")
        path=$(echo "$line" | sed -n 's|.*value\s*=\s*"\([^"]*\)".*|\1|p')
    fi
    echo "${path:-/}"
}

# =============================================================================
# MAIN ANALYSIS
# =============================================================================

header "Spring Boot Project Analysis"
echo "Analyzing: $(pwd)"
echo ""

# -----------------------------------------------------------------------------
# Build Tool Detection
# -----------------------------------------------------------------------------
section "Build System"

if [[ -f "pom.xml" ]]; then
    success "Maven project detected"
    BUILD_TOOL="maven"

    # Extract Java version
    JAVA_VERSION=$(extract_xml_value "pom.xml" "java.version" || extract_xml_value "pom.xml" "maven.compiler.source" || echo "Not specified")
    info "Java Version: $JAVA_VERSION"

    # Extract Spring Boot version
    SPRING_BOOT_VERSION=$(extract_xml_value "pom.xml" "spring-boot.version" || \
        extract_xml_tag "pom.xml" "version" || echo "Not specified")

    # Try to get from parent
    if [[ "$SPRING_BOOT_VERSION" == "Not specified" ]] || [[ -z "$SPRING_BOOT_VERSION" ]]; then
        SPRING_BOOT_VERSION=$(grep -A5 "<parent>" pom.xml 2>/dev/null | sed -n 's|.*<version>\([^<]*\)</version>.*|\1|p' | head -1 || echo "Not specified")
    fi
    info "Spring Boot Version: $SPRING_BOOT_VERSION"

elif [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
    success "Gradle project detected"
    BUILD_TOOL="gradle"

    GRADLE_FILE="build.gradle"
    [[ -f "build.gradle.kts" ]] && GRADLE_FILE="build.gradle.kts"

    # Extract Java version (portable)
    JAVA_VERSION=$(grep "sourceCompatibility" "$GRADLE_FILE" 2>/dev/null | sed -n "s|.*['\"]\\([0-9.]*\\)['\"].*|\\1|p" | head -1 || \
        grep "jvmTarget" "$GRADLE_FILE" 2>/dev/null | sed -n "s|.*['\"]\\([0-9.]*\\)['\"].*|\\1|p" | head -1 || echo "Not specified")
    info "Java Version: $JAVA_VERSION"

    # Extract Spring Boot version (portable)
    SPRING_BOOT_VERSION=$(grep "springBootVersion" "$GRADLE_FILE" 2>/dev/null | sed -n "s|.*['\"]\\([^'\"]*\\)['\"].*|\\1|p" | head -1 || \
        grep "org.springframework.boot" "$GRADLE_FILE" 2>/dev/null | sed -n "s|.*version['\"]\\([^'\"]*\\)['\"].*|\\1|p" | head -1 || echo "Not specified")
    info "Spring Boot Version: $SPRING_BOOT_VERSION"
else
    warning "No Maven or Gradle build file found"
    BUILD_TOOL="unknown"
fi

# -----------------------------------------------------------------------------
# Dependencies
# -----------------------------------------------------------------------------
section "Dependencies"

# Define dependencies to check (simpler approach for portability)
DEPENDENCY_PATTERNS=(
    "spring-boot-starter-web:Spring Web (REST APIs)"
    "spring-boot-starter-data-jpa:Spring Data JPA"
    "spring-boot-starter-data-mongodb:Spring Data MongoDB"
    "spring-kafka:Apache Kafka"
    "spring-boot-starter-security:Spring Security"
    "spring-cloud-starter-openfeign:OpenFeign HTTP Client"
    "spring-boot-starter-actuator:Spring Actuator"
    "spring-boot-starter-validation:Bean Validation"
    "spring-boot-starter-cache:Spring Cache"
    "spring-boot-starter-data-redis:Spring Data Redis"
    "postgresql:PostgreSQL"
    "mysql-connector:MySQL"
    "h2:H2 Database"
    "flyway:Flyway Migrations"
    "liquibase:Liquibase Migrations"
    "lombok:Lombok"
    "mapstruct:MapStruct"
    "springdoc-openapi:SpringDoc OpenAPI"
    "swagger:Swagger"
)

FOUND_DEPS_COUNT=0

if [[ "$BUILD_TOOL" == "maven" ]]; then
    for entry in "${DEPENDENCY_PATTERNS[@]}"; do
        dep="${entry%%:*}"
        desc="${entry#*:}"
        if grep -q "$dep" pom.xml 2>/dev/null; then
            FOUND_DEPS_COUNT=$((FOUND_DEPS_COUNT + 1))
            success "$desc"
        fi
    done
elif [[ "$BUILD_TOOL" == "gradle" ]]; then
    for entry in "${DEPENDENCY_PATTERNS[@]}"; do
        dep="${entry%%:*}"
        desc="${entry#*:}"
        if grep -q "$dep" build.gradle* 2>/dev/null; then
            FOUND_DEPS_COUNT=$((FOUND_DEPS_COUNT + 1))
            success "$desc"
        fi
    done
fi

if [[ $FOUND_DEPS_COUNT -eq 0 ]]; then
    warning "No common Spring dependencies detected"
fi

# -----------------------------------------------------------------------------
# Package Structure
# -----------------------------------------------------------------------------
section "Package Structure"

SRC_MAIN="src/main/java"
if [[ -d "$SRC_MAIN" ]]; then
    BASE_PACKAGE=$(find "$SRC_MAIN" -name "*.java" -type f 2>/dev/null | head -1 | \
        sed "s|$SRC_MAIN/||" | sed 's|/[^/]*$||' | tr '/' '.')
    info "Base Package: $BASE_PACKAGE"

    # List main packages
    echo ""
    info "Package Structure:"
    PACKAGES=$(find "$SRC_MAIN" -type d -mindepth 3 -maxdepth 5 2>/dev/null | \
        sed "s|$SRC_MAIN/||" | tr '/' '.' | sort -u | head -20)
    if [[ -n "$PACKAGES" ]]; then
        echo "$PACKAGES" | while read -r pkg; do
            echo "    $pkg"
        done
    fi
else
    warning "No src/main/java directory found"
fi

# -----------------------------------------------------------------------------
# REST Controllers & Endpoints
# -----------------------------------------------------------------------------
section "REST Controllers & Endpoints"

CONTROLLER_COUNT=0
ENDPOINT_COUNT=0

# Find all controllers
CONTROLLERS=$(grep -rl "@RestController\|@Controller" --include="*.java" "$SRC_MAIN" 2>/dev/null || true)

if [[ -n "$CONTROLLERS" ]]; then
    while IFS= read -r controller; do
        CONTROLLER_COUNT=$((CONTROLLER_COUNT + 1))
        CONTROLLER_NAME=$(basename "$controller" .java)

        # Get RequestMapping base path (portable)
        BASE_PATH=$(grep "@RequestMapping" "$controller" 2>/dev/null | sed -n 's|.*@RequestMapping("\([^"]*\)".*|\1|p' | head -1 || \
            grep "@RequestMapping" "$controller" 2>/dev/null | sed -n 's|.*value\s*=\s*"\([^"]*\)".*|\1|p' | head -1 || echo "")

        echo ""
        info "$CONTROLLER_NAME ${BASE_PATH:+(base: $BASE_PATH)}"

        # Extract endpoints (portable - using tr for uppercase)
        grep -n "@GetMapping\|@PostMapping\|@PutMapping\|@DeleteMapping\|@PatchMapping" "$controller" 2>/dev/null | \
        while IFS=: read -r line_num content; do
            ENDPOINT_COUNT=$((ENDPOINT_COUNT + 1))
            METHOD=$(extract_http_method "$content")
            METHOD_UPPER=$(echo "$METHOD" | tr '[:lower:]' '[:upper:]')
            ENDPOINT_PATH=$(extract_mapping_path "$content")
            echo "      ${METHOD_UPPER} ${BASE_PATH}${ENDPOINT_PATH}"
        done
    done <<< "$CONTROLLERS"

    echo ""
    success "Found $CONTROLLER_COUNT controller(s)"
else
    warning "No REST controllers found"
fi

# -----------------------------------------------------------------------------
# Exception Handling (@ControllerAdvice)
# -----------------------------------------------------------------------------
section "Exception Handling"

echo ""
info "Controller Advice Classes (@ControllerAdvice / @RestControllerAdvice):"

CONTROLLER_ADVICES=$(grep -rl "@ControllerAdvice\|@RestControllerAdvice" --include="*.java" "$SRC_MAIN" 2>/dev/null || true)
if [[ -n "$CONTROLLER_ADVICES" ]]; then
    while IFS= read -r advice_file; do
        ADVICE_NAME=$(basename "$advice_file" .java)
        success "  $ADVICE_NAME"

        # Extract @ExceptionHandler methods (portable)
        grep "@ExceptionHandler" "$advice_file" 2>/dev/null | \
            sed -n 's|.*@ExceptionHandler(\([^)]*\)).*|\1|p' | \
        while read -r handled_exception; do
            # Clean up the exception class name
            EXCEPTION_CLASS=$(echo "$handled_exception" | sed 's/\.class//g' | sed 's/[{}]//g' | tr ',' '\n' | sed 's/^ *//')
            echo "$EXCEPTION_CLASS" | while read -r exc; do
                [[ -n "$exc" ]] && info "      handles: $exc"
            done
        done
    done <<< "$CONTROLLER_ADVICES"
else
    info "  No @ControllerAdvice classes found"
fi

# -----------------------------------------------------------------------------
# Domain Exception Hierarchy
# -----------------------------------------------------------------------------
section "Domain Exception Hierarchy"

echo ""
info "Custom Exceptions (extends Exception/RuntimeException):"

# Find all custom exception classes
EXCEPTION_FILES=$(find "$SRC_MAIN" -name "*Exception.java" -o -name "*Error.java" 2>/dev/null || true)

if [[ -n "$EXCEPTION_FILES" ]]; then
    # Simple approach for bash 3.2 compatibility (no associative arrays)
    EXCEPTION_COUNT=0
    ROOT_EXCEPTION_COUNT=0

    # Create temp file for exception data
    EXCEPTION_DATA=$(mktemp)
    trap "rm -f $EXCEPTION_DATA" EXIT

    while IFS= read -r exception_file; do
        [[ -z "$exception_file" ]] && continue
        EXCEPTION_NAME=$(basename "$exception_file" .java)
        EXCEPTION_COUNT=$((EXCEPTION_COUNT + 1))

        # Extract parent class (portable - using sed)
        PARENT_CLASS=$(grep "class ${EXCEPTION_NAME}" "$exception_file" 2>/dev/null | \
            sed -n "s|.*class ${EXCEPTION_NAME}[[:space:]]*extends[[:space:]]*\([A-Za-z0-9_]*\).*|\1|p" | head -1)

        if [[ -n "$PARENT_CLASS" ]]; then
            echo "${EXCEPTION_NAME}:${PARENT_CLASS}" >> "$EXCEPTION_DATA"

            # Check if parent is a standard Java exception (making this a root domain exception)
            case "$PARENT_CLASS" in
                Exception|RuntimeException|IllegalArgumentException|IllegalStateException)
                    ROOT_EXCEPTION_COUNT=$((ROOT_EXCEPTION_COUNT + 1))
                    success "  $EXCEPTION_NAME (extends $PARENT_CLASS)"
                    ;;
            esac
        fi
    done <<< "$EXCEPTION_FILES"

    # Show child exceptions for each root
    if [[ -f "$EXCEPTION_DATA" ]]; then
        while IFS=: read -r exc parent; do
            case "$parent" in
                Exception|RuntimeException|IllegalArgumentException|IllegalStateException)
                    # This is a root, find its children
                    grep ":${exc}$" "$EXCEPTION_DATA" 2>/dev/null | cut -d: -f1 | while read -r child; do
                        info "      └── $child (extends $exc)"
                    done
                    ;;
            esac
        done < "$EXCEPTION_DATA"
    fi

    echo ""
    info "Exception Summary:"
    info "  Total custom exceptions: $EXCEPTION_COUNT"
    info "  Root domain exceptions: $ROOT_EXCEPTION_COUNT"

    # List exception packages
    echo ""
    info "Exception Packages:"
    echo "$EXCEPTION_FILES" | while read -r exception_file; do
        [[ -z "$exception_file" ]] && continue
        EXCEPTION_PKG=$(dirname "$exception_file" | sed "s|$SRC_MAIN/||" | tr '/' '.')
        echo "  $EXCEPTION_PKG"
    done | sort -u

    rm -f "$EXCEPTION_DATA" 2>/dev/null || true
else
    info "  No custom exception classes found"
fi

# -----------------------------------------------------------------------------
# HTTP Status Codes Used
# -----------------------------------------------------------------------------
echo ""
info "HTTP Response Codes in Exception Handlers:"

if [[ -n "$CONTROLLER_ADVICES" ]]; then
    while IFS= read -r advice_file; do
        # Look for @ResponseStatus and HttpStatus references (portable)
        grep -E "@ResponseStatus|HttpStatus\." "$advice_file" 2>/dev/null | \
            sed -n 's|.*\(HttpStatus\.[A-Z_]*\).*|\1|p' | sort -u | \
        while read -r status; do
            [[ -n "$status" ]] && info "  $status"
        done
    done <<< "$CONTROLLER_ADVICES"
fi

# Also check controllers for @ResponseStatus (portable)
grep -rh "@ResponseStatus\|HttpStatus\." --include="*.java" "$SRC_MAIN" 2>/dev/null | \
    sed -n 's|.*\(HttpStatus\.[A-Z_]*\).*|\1|p' | \
    sort -u | head -10 | while read -r status; do
        [[ -n "$status" ]] && info "  $status"
    done

# -----------------------------------------------------------------------------
# Kafka Integration
# -----------------------------------------------------------------------------
section "Kafka Integration"

# Check for Kafka dependency first
HAS_KAFKA=false
if grep -q "spring-kafka\|kafka" pom.xml build.gradle* 2>/dev/null; then
    HAS_KAFKA=true
fi

if [[ "$HAS_KAFKA" == "true" ]]; then
    echo ""
    info "Kafka Consumers (@KafkaListener):"

    KAFKA_LISTENERS=$(grep -rn "@KafkaListener" --include="*.java" "$SRC_MAIN" 2>/dev/null || true)
    if [[ -n "$KAFKA_LISTENERS" ]]; then
        echo "$KAFKA_LISTENERS" | while IFS=: read -r file line_num content; do
            CLASS_NAME=$(basename "$file" .java)
            # Extract topics (portable)
            TOPICS=$(echo "$content" | sed -n 's|.*topics\s*=\s*["{]*\([^"}]*\)["}]*.*|\1|p' || echo "unknown")
            GROUP=$(grep -A5 "@KafkaListener" "$file" 2>/dev/null | sed -n 's|.*groupId\s*=\s*"\([^"]*\)".*|\1|p' | head -1 || echo "")
            success "  $CLASS_NAME: topic=$TOPICS ${GROUP:+group=$GROUP}"
        done
    else
        info "  No @KafkaListener found"
    fi

    echo ""
    info "Kafka Producers (KafkaTemplate):"

    KAFKA_PRODUCERS=$(grep -rn "kafkaTemplate\|KafkaTemplate" --include="*.java" "$SRC_MAIN" 2>/dev/null | grep -v "import\|@Autowired\|private" || true)
    if [[ -n "$KAFKA_PRODUCERS" ]]; then
        grep -rl "kafkaTemplate.send\|\.send(" --include="*.java" "$SRC_MAIN" 2>/dev/null | \
        while read -r file; do
            CLASS_NAME=$(basename "$file" .java)
            # Extract topics (portable)
            TOPICS=$(grep "\.send(" "$file" 2>/dev/null | sed -n 's|.*\.send("\([^"]*\)".*|\1|p' | sort -u | tr '\n' ', ' | sed 's/,$//')
            if [[ -n "$TOPICS" ]]; then
                success "  $CLASS_NAME: produces to $TOPICS"
            fi
        done
    else
        info "  No KafkaTemplate usage found"
    fi
else
    info "No Kafka integration detected"
fi

# -----------------------------------------------------------------------------
# Database Entities
# -----------------------------------------------------------------------------
section "Database Entities"

echo ""
info "JPA Entities (@Entity):"

JPA_ENTITIES=$(grep -rl "@Entity" --include="*.java" "$SRC_MAIN" 2>/dev/null || true)
if [[ -n "$JPA_ENTITIES" ]]; then
    while IFS= read -r entity_file; do
        ENTITY_NAME=$(basename "$entity_file" .java)
        # Extract table name (portable)
        TABLE_NAME=$(grep "@Table" "$entity_file" 2>/dev/null | sed -n 's|.*name\s*=\s*"\([^"]*\)".*|\1|p' | head -1 || echo "$ENTITY_NAME")
        success "  $ENTITY_NAME -> table: $TABLE_NAME"
    done <<< "$JPA_ENTITIES"
else
    info "  No JPA entities found"
fi

echo ""
info "MongoDB Documents (@Document):"

MONGO_DOCS=$(grep -rl "@Document" --include="*.java" "$SRC_MAIN" 2>/dev/null || true)
if [[ -n "$MONGO_DOCS" ]]; then
    while IFS= read -r doc_file; do
        DOC_NAME=$(basename "$doc_file" .java)
        # Extract collection name (portable)
        COLLECTION=$(grep "@Document" "$doc_file" 2>/dev/null | sed -n 's|.*collection\s*=\s*"\([^"]*\)".*|\1|p' | head -1 || \
            grep "@Document" "$doc_file" 2>/dev/null | sed -n 's|.*@Document("\([^"]*\)".*|\1|p' | head -1 || echo "$DOC_NAME")
        success "  $DOC_NAME -> collection: $COLLECTION"
    done <<< "$MONGO_DOCS"
else
    info "  No MongoDB documents found"
fi

# -----------------------------------------------------------------------------
# External Service Calls
# -----------------------------------------------------------------------------
section "External Service Calls"

echo ""
info "Feign Clients (@FeignClient):"

FEIGN_CLIENTS=$(grep -rl "@FeignClient" --include="*.java" "$SRC_MAIN" 2>/dev/null || true)
if [[ -n "$FEIGN_CLIENTS" ]]; then
    while IFS= read -r feign_file; do
        CLIENT_NAME=$(basename "$feign_file" .java)
        # Extract service name (portable)
        SERVICE_NAME=$(grep "@FeignClient" "$feign_file" 2>/dev/null | sed -n 's|.*name\s*=\s*"\([^"]*\)".*|\1|p' | head -1 || \
            grep "@FeignClient" "$feign_file" 2>/dev/null | sed -n 's|.*value\s*=\s*"\([^"]*\)".*|\1|p' | head -1 || \
            grep "@FeignClient" "$feign_file" 2>/dev/null | sed -n 's|.*@FeignClient("\([^"]*\)".*|\1|p' | head -1 || echo "unknown")
        URL=$(grep "@FeignClient" "$feign_file" 2>/dev/null | sed -n 's|.*url\s*=\s*"\([^"]*\)".*|\1|p' | head -1 || echo "")
        success "  $CLIENT_NAME -> service: $SERVICE_NAME ${URL:+($URL)}"
    done <<< "$FEIGN_CLIENTS"
else
    info "  No Feign clients found"
fi

echo ""
info "RestTemplate Usage:"
REST_TEMPLATE=$(grep -rl "RestTemplate\|restTemplate" --include="*.java" "$SRC_MAIN" 2>/dev/null | grep -v "Config\|Configuration" || true)
if [[ -n "$REST_TEMPLATE" ]]; then
    echo "$REST_TEMPLATE" | while read -r file; do
        success "  $(basename "$file" .java)"
    done
else
    info "  No RestTemplate usage found"
fi

echo ""
info "WebClient Usage:"
WEB_CLIENT=$(grep -rl "WebClient\|webClient" --include="*.java" "$SRC_MAIN" 2>/dev/null | grep -v "Config\|Configuration" || true)
if [[ -n "$WEB_CLIENT" ]]; then
    echo "$WEB_CLIENT" | while read -r file; do
        success "  $(basename "$file" .java)"
    done
else
    info "  No WebClient usage found"
fi

# -----------------------------------------------------------------------------
# Service Layer
# -----------------------------------------------------------------------------
section "Service Layer"

SERVICE_CLASSES=$(find "$SRC_MAIN" -path "*service*" -name "*Service.java" -o -path "*services*" -name "*Service.java" 2>/dev/null || true)
if [[ -n "$SERVICE_CLASSES" ]]; then
    echo "$SERVICE_CLASSES" | while read -r service_file; do
        SERVICE_NAME=$(basename "$service_file" .java)
        info "  $SERVICE_NAME"
    done

    SERVICE_COUNT=$(echo "$SERVICE_CLASSES" | wc -l | tr -d ' ')
    echo ""
    success "Found $SERVICE_COUNT service class(es)"
else
    warning "No service classes found in */service(s)/* directories"
fi

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
section "Configuration"

CONFIG_FILES=("src/main/resources/application.yml" "src/main/resources/application.yaml" "src/main/resources/application.properties")

for config_file in "${CONFIG_FILES[@]}"; do
    if [[ -f "$config_file" ]]; then
        success "Found: $config_file"
        echo ""

        if [[ "$config_file" == *.properties ]]; then
            # Properties file
            SERVER_PORT=$(grep "server.port" "$config_file" 2>/dev/null | cut -d'=' -f2 | tr -d ' ' || echo "8080")
            APP_NAME=$(grep "spring.application.name" "$config_file" 2>/dev/null | cut -d'=' -f2 | tr -d ' ' || echo "Not specified")
            DB_URL=$(grep "spring.datasource.url" "$config_file" 2>/dev/null | cut -d'=' -f2 || echo "Not specified")
            KAFKA_SERVERS=$(grep "spring.kafka.bootstrap-servers" "$config_file" 2>/dev/null | cut -d'=' -f2 || echo "Not specified")
        else
            # YAML file
            SERVER_PORT=$(grep -E "^\s*port:" "$config_file" 2>/dev/null | head -1 | awk '{print $2}' || echo "8080")
            APP_NAME=$(grep -E "^\s*name:" "$config_file" 2>/dev/null | head -1 | awk '{print $2}' || echo "Not specified")
            DB_URL=$(grep -E "^\s*url:" "$config_file" 2>/dev/null | head -1 | awk '{print $2}' || echo "Not specified")
            KAFKA_SERVERS=$(grep -E "bootstrap-servers:" "$config_file" 2>/dev/null | head -1 | awk '{print $2}' || echo "Not specified")
        fi

        info "Server Port: ${SERVER_PORT:-8080}"
        info "Application Name: ${APP_NAME:-Not specified}"
        [[ "$DB_URL" != "Not specified" ]] && info "Database URL: $DB_URL"
        [[ "$KAFKA_SERVERS" != "Not specified" ]] && info "Kafka Bootstrap Servers: $KAFKA_SERVERS"

        break
    fi
done

# Check for profile-specific configs
echo ""
info "Profile-specific configurations:"
find src/main/resources -name "application-*.yml" -o -name "application-*.yaml" -o -name "application-*.properties" 2>/dev/null | \
while read -r profile_config; do
    PROFILE=$(basename "$profile_config" | sed 's/application-//' | sed 's/\.\(yml\|yaml\|properties\)$//')
    info "  Profile: $PROFILE"
done

# -----------------------------------------------------------------------------
# Tests
# -----------------------------------------------------------------------------
section "Tests"

TEST_DIR="src/test/java"
if [[ -d "$TEST_DIR" ]]; then
    UNIT_TESTS=$(find "$TEST_DIR" -name "*Test.java" -o -name "*Tests.java" 2>/dev/null | wc -l | tr -d ' ')
    INTEGRATION_TESTS=$(find "$TEST_DIR" -name "*IT.java" -o -name "*IntegrationTest.java" 2>/dev/null | wc -l | tr -d ' ')

    info "Unit Tests: $UNIT_TESTS"
    info "Integration Tests: $INTEGRATION_TESTS"

    # Check test frameworks
    echo ""
    info "Test Frameworks:"
    if grep -rq "@SpringBootTest" "$TEST_DIR" 2>/dev/null; then
        success "  Spring Boot Test"
    fi
    if grep -rq "Mockito\|@Mock" "$TEST_DIR" 2>/dev/null; then
        success "  Mockito"
    fi
    if grep -rq "@DataJpaTest" "$TEST_DIR" 2>/dev/null; then
        success "  JPA Test Slices"
    fi
    if grep -rq "@WebMvcTest" "$TEST_DIR" 2>/dev/null; then
        success "  Web MVC Test Slices"
    fi
    if grep -rq "Testcontainers\|@Container" "$TEST_DIR" 2>/dev/null; then
        success "  Testcontainers"
    fi
else
    warning "No test directory found"
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
header "Analysis Summary"

echo "Build: $BUILD_TOOL | Java: ${JAVA_VERSION:-unknown} | Spring Boot: ${SPRING_BOOT_VERSION:-unknown}"
echo "Dependencies: ${FOUND_DEPS_COUNT:-0} detected"
echo "Controllers: ${CONTROLLER_COUNT:-0} | Services: ${SERVICE_COUNT:-0}"
JPA_COUNT=$(echo "$JPA_ENTITIES" | grep -c "." 2>/dev/null || echo "0")
MONGO_COUNT=$(echo "$MONGO_DOCS" | grep -c "." 2>/dev/null || echo "0")
echo "Entities: $JPA_COUNT JPA, $MONGO_COUNT MongoDB"
echo "Exceptions: ${EXCEPTION_COUNT:-0} custom, ${ROOT_EXCEPTION_COUNT:-0} root domain"
echo "Tests: ${UNIT_TESTS:-0} unit, ${INTEGRATION_TESTS:-0} integration"
echo ""
success "Analysis complete!"

# =============================================================================
# ENHANCED DOCUMENTATION MODES (v2.0)
# =============================================================================

# Parse command-line arguments for enhanced modes
parse_enhanced_args() {
    local mode="full"
    local specific_files=()
    local specific_section=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --mode)
                mode="$2"
                shift 2
                ;;
            --files)
                IFS=',' read -ra specific_files <<< "$2"
                shift 2
                ;;
            --section)
                specific_section="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    echo "MODE=$mode"
    echo "SECTION=$specific_section"
    if [ ${#specific_files[@]} -gt 0 ]; then
        printf 'FILES=%s\n' "${specific_files[@]}"
    fi
}

# Detect existing documentation structure
detect_existing_documentation() {
    section "Existing Documentation Detection"

    local has_claude_md=false
    local has_rules=false
    local has_docs=false
    local has_readme=false
    local has_old_instructions=false

    [ -f "CLAUDE.md" ] && has_claude_md=true
    [ -d ".claude/rules" ] && [ "$(ls -A .claude/rules 2>/dev/null)" ] && has_rules=true
    [ -d "docs" ] && [ "$(ls -A docs 2>/dev/null)" ] && has_docs=true
    [ -f "README.md" ] && has_readme=true
    [ -f ".claude/instructions.md" ] && has_old_instructions=true

    if $has_claude_md; then
        success "CLAUDE.md found"
    else
        info "CLAUDE.md not found (will be created)"
    fi

    if $has_rules; then
        success ".claude/rules/ directory found"
        local rules_files=$(find .claude/rules -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
        info "  $rules_files rule files detected"
    else
        info ".claude/rules/ not found (will be created)"
    fi

    if $has_docs; then
        success "docs/ directory found"
        local doc_subdirs=$(find docs -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        info "  $doc_subdirs subdirectories detected"
    else
        info "docs/ not found (will be created)"
    fi

    if $has_readme; then
        success "README.md found"
    else
        info "README.md not found (will be created)"
    fi

    if $has_old_instructions; then
        warning ".claude/instructions.md found (legacy format - will be deprecated)"
    fi

    echo ""
    echo "EXISTING_DOCS=claude_md:$has_claude_md,rules:$has_rules,docs:$has_docs,readme:$has_readme,old_instructions:$has_old_instructions"
}

# Use git-utils.sh to get incremental info
detect_git_changes() {
    if ! git rev-parse --git-dir &>/dev/null; then
        warning "Not a git repository - incremental mode unavailable"
        return 1
    fi

    section "Git Change Detection"

    # Source git-utils.sh if available
    if [[ -f "${SCRIPT_DIR}/git-utils.sh" ]]; then
        source "${SCRIPT_DIR}/git-utils.sh"

        local last_commit=$(detect_last_doc_commit)
        if [[ -z "$last_commit" ]]; then
            info "No previous documentation commits found"
            echo "LAST_DOC_COMMIT=none"
            return 0
        fi

        success "Last documentation commit: ${last_commit:0:8}"

        local changed_files=$(get_changed_files_since "$last_commit")
        if [[ -z "$changed_files" ]]; then
            info "No changes since last documentation update"
            echo "CHANGED_FILES=0"
            return 0
        fi

        local change_count=$(echo "$changed_files" | wc -l | tr -d ' ')
        info "Changed files since last docs: $change_count"

        echo "LAST_DOC_COMMIT=$last_commit"
        echo "CHANGED_FILES=$change_count"
        echo "CHANGES_LIST<<EOF"
        echo "$changed_files"
        echo "EOF"

        # Categorize changes
        echo ""
        info "Categorizing changes..."
        local changes_array=()
        while IFS= read -r file; do
            changes_array+=("$file")
        done <<< "$changed_files"

        categorize_changes "${changes_array[@]}"
    else
        warning "git-utils.sh not found - limited git functionality"
        return 1
    fi
}

# Analyze specific files only (for incremental mode)
analyze_specific_files() {
    local files=("$@")

    section "Analyzing Specific Files (${#files[@]} files)"

    for file in "${files[@]}"; do
        if [[ ! -f "$file" ]]; then
            warning "File not found: $file"
            continue
        fi

        info "Analyzing: $file"

        # Detect file type and extract relevant info
        if [[ "$file" =~ Controller\.java$ ]]; then
            # Extract endpoints from this controller only
            local class_name=$(basename "$file" .java)
            success "  Controller: $class_name"

            local base_path=$(grep "@RequestMapping" "$file" | head -1 | sed -n 's|.*@RequestMapping("\([^"]*\)".*|\1|p')
            [[ -n "$base_path" ]] && info "    Base path: $base_path"

            local endpoints=$(grep -E "@(Get|Post|Put|Delete|Patch)Mapping" "$file" 2>/dev/null | wc -l | tr -d ' ')
            info "    Endpoints: $endpoints"

        elif [[ "$file" =~ Entity\.java$ ]] || [[ "$file" =~ Document\.java$ ]]; then
            # Extract entity info
            local class_name=$(basename "$file" .java)
            success "  Entity: $class_name"

            local table=$(grep "@Table" "$file" | sed -n 's|.*name\s*=\s*"\([^"]*\)".*|\1|p')
            [[ -n "$table" ]] && info "    Table: $table"

            local collection=$(grep "@Document" "$file" | sed -n 's|.*collection\s*=\s*"\([^"]*\)".*|\1|p')
            [[ -n "$collection" ]] && info "    Collection: $collection"

        elif [[ "$file" =~ Service\.java$ ]]; then
            # Extract service info
            local class_name=$(basename "$file" .java")
            success "  Service: $class_name"

            local public_methods=$(grep -E "^\s*public\s+" "$file" 2>/dev/null | wc -l | tr -d ' ')
            info "    Public methods: $public_methods"

        elif grep -q "@KafkaListener" "$file" 2>/dev/null; then
            # Kafka consumer
            local class_name=$(basename "$file" .java)
            success "  Kafka Consumer: $class_name"

            local topics=$(grep "@KafkaListener" "$file" | sed -n 's|.*topics\s*=\s*[{\"]\([^}\"]*\)[}\"].*|\1|p')
            [[ -n "$topics" ]] && info "    Topics: $topics"

        elif grep -q "@FeignClient" "$file" 2>/dev/null; then
            # Feign client
            local class_name=$(basename "$file" .java)
            success "  Feign Client: $class_name"

            local service=$(grep "@FeignClient" "$file" | sed -n 's|.*name\s*=\s*"\([^"]*\)".*|\1|p')
            [[ -n "$service" ]] && info "    Target service: $service"

        else
            info "  Unknown file type (skipping detailed analysis)"
        fi

        echo ""
    done
}

# Main entry point for enhanced modes
run_enhanced_analysis() {
    local mode="${DOC_MODE:-full}"
    local section="${DOC_SECTION:-}"

    case "$mode" in
        full)
            info "Running FULL analysis (all files, complete interview)"
            detect_existing_documentation
            ;;

        incremental)
            info "Running INCREMENTAL analysis (changes since last docs)"
            detect_existing_documentation
            detect_git_changes
            ;;

        selective)
            info "Running SELECTIVE analysis (specific section: $section)"
            detect_existing_documentation
            if [[ -n "$section" ]]; then
                success "Target section: $section"
            else
                warning "No section specified with --section flag"
            fi
            ;;

        *)
            error "Unknown mode: $mode"
            exit 1
            ;;
    esac
}

# Export functions for use by skill file
export -f detect_existing_documentation
export -f detect_git_changes
export -f analyze_specific_files
export -f run_enhanced_analysis
