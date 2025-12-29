#!/usr/bin/env bash
#
# Spring Boot Project Analyzer
# Extracts technical details from Spring Boot microservices
#
set -euo pipefail

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
        grep -oP '(?<=<version>)[^<]+(?=</version>)' pom.xml | head -1 || echo "Not specified")

    # Try to get from parent
    if [[ "$SPRING_BOOT_VERSION" == "Not specified" ]] || [[ -z "$SPRING_BOOT_VERSION" ]]; then
        SPRING_BOOT_VERSION=$(grep -A5 "<parent>" pom.xml 2>/dev/null | grep -oP '(?<=<version>)[^<]+' | head -1 || echo "Not specified")
    fi
    info "Spring Boot Version: $SPRING_BOOT_VERSION"

elif [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
    success "Gradle project detected"
    BUILD_TOOL="gradle"

    GRADLE_FILE="build.gradle"
    [[ -f "build.gradle.kts" ]] && GRADLE_FILE="build.gradle.kts"

    # Extract Java version
    JAVA_VERSION=$(grep -oP "(?<=sourceCompatibility\s*=\s*['\"]?)[\d.]+" "$GRADLE_FILE" 2>/dev/null || \
        grep -oP "(?<=jvmTarget\s*=\s*['\"]?)[\d.]+" "$GRADLE_FILE" 2>/dev/null || echo "Not specified")
    info "Java Version: $JAVA_VERSION"

    # Extract Spring Boot version
    SPRING_BOOT_VERSION=$(grep -oP "(?<=org.springframework.boot['\"]\s*version\s*['\"])[^'\"]+|(?<=springBootVersion\s*=\s*['\"])[^'\"]+" "$GRADLE_FILE" 2>/dev/null || echo "Not specified")
    info "Spring Boot Version: $SPRING_BOOT_VERSION"
else
    warning "No Maven or Gradle build file found"
    BUILD_TOOL="unknown"
fi

# -----------------------------------------------------------------------------
# Dependencies
# -----------------------------------------------------------------------------
section "Dependencies"

declare -A DEPENDENCIES=(
    ["spring-boot-starter-web"]="Spring Web (REST APIs)"
    ["spring-boot-starter-data-jpa"]="Spring Data JPA"
    ["spring-boot-starter-data-mongodb"]="Spring Data MongoDB"
    ["spring-kafka"]="Apache Kafka"
    ["spring-boot-starter-security"]="Spring Security"
    ["spring-cloud-starter-openfeign"]="OpenFeign HTTP Client"
    ["spring-boot-starter-actuator"]="Spring Actuator"
    ["spring-boot-starter-validation"]="Bean Validation"
    ["spring-boot-starter-cache"]="Spring Cache"
    ["spring-boot-starter-data-redis"]="Spring Data Redis"
    ["postgresql"]="PostgreSQL"
    ["mysql-connector"]="MySQL"
    ["h2"]="H2 Database"
    ["flyway"]="Flyway Migrations"
    ["liquibase"]="Liquibase Migrations"
    ["lombok"]="Lombok"
    ["mapstruct"]="MapStruct"
    ["springdoc-openapi"]="SpringDoc OpenAPI"
    ["swagger"]="Swagger"
)

FOUND_DEPS=()

if [[ "$BUILD_TOOL" == "maven" ]]; then
    for dep in "${!DEPENDENCIES[@]}"; do
        if grep -q "$dep" pom.xml 2>/dev/null; then
            FOUND_DEPS+=("$dep")
            success "${DEPENDENCIES[$dep]}"
        fi
    done
elif [[ "$BUILD_TOOL" == "gradle" ]]; then
    for dep in "${!DEPENDENCIES[@]}"; do
        if grep -q "$dep" build.gradle* 2>/dev/null; then
            FOUND_DEPS+=("$dep")
            success "${DEPENDENCIES[$dep]}"
        fi
    done
fi

if [[ ${#FOUND_DEPS[@]} -eq 0 ]]; then
    warning "No common Spring dependencies detected"
fi

# -----------------------------------------------------------------------------
# Package Structure
# -----------------------------------------------------------------------------
section "Package Structure"

SRC_MAIN="src/main/java"
if [[ -d "$SRC_MAIN" ]]; then
    BASE_PACKAGE=$(find "$SRC_MAIN" -name "*.java" -type f | head -1 | \
        sed "s|$SRC_MAIN/||" | sed 's|/[^/]*$||' | tr '/' '.')
    info "Base Package: $BASE_PACKAGE"

    # List main packages
    echo ""
    info "Package Structure:"
    find "$SRC_MAIN" -type d -mindepth 3 -maxdepth 5 2>/dev/null | \
        sed "s|$SRC_MAIN/||" | tr '/' '.' | sort -u | head -20 | \
        while read -r pkg; do
            echo "    $pkg"
        done
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

        # Get RequestMapping base path
        BASE_PATH=$(grep -oP '(?<=@RequestMapping\(")[^"]+|(?<=@RequestMapping\(value\s*=\s*")[^"]+' "$controller" 2>/dev/null | head -1 || echo "")

        echo ""
        info "$CONTROLLER_NAME ${BASE_PATH:+(base: $BASE_PATH)}"

        # Extract endpoints
        grep -n "@GetMapping\|@PostMapping\|@PutMapping\|@DeleteMapping\|@PatchMapping" "$controller" 2>/dev/null | \
        while IFS=: read -r line_num content; do
            ENDPOINT_COUNT=$((ENDPOINT_COUNT + 1))
            METHOD=$(echo "$content" | grep -oP "Get|Post|Put|Delete|Patch")
            PATH=$(echo "$content" | grep -oP '(?<=\(")[^"]*|(?<=\(value\s*=\s*")[^"]*' || echo "/")
            echo "      ${METHOD^^} ${BASE_PATH}${PATH}"
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

        # Extract @ExceptionHandler methods
        grep -oP '(?<=@ExceptionHandler\()[^)]+' "$advice_file" 2>/dev/null | \
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
    # Build exception hierarchy
    declare -A EXCEPTION_PARENTS
    declare -a ROOT_EXCEPTIONS
    declare -a ALL_EXCEPTIONS

    while IFS= read -r exception_file; do
        EXCEPTION_NAME=$(basename "$exception_file" .java)
        ALL_EXCEPTIONS+=("$EXCEPTION_NAME")

        # Extract parent class
        PARENT_CLASS=$(grep -oP "(?<=class\s${EXCEPTION_NAME}\s+extends\s)\w+" "$exception_file" 2>/dev/null || echo "")

        if [[ -n "$PARENT_CLASS" ]]; then
            EXCEPTION_PARENTS["$EXCEPTION_NAME"]="$PARENT_CLASS"

            # Check if parent is a standard Java exception (making this a root domain exception)
            if [[ "$PARENT_CLASS" == "Exception" ]] || [[ "$PARENT_CLASS" == "RuntimeException" ]] || \
               [[ "$PARENT_CLASS" == "IllegalArgumentException" ]] || [[ "$PARENT_CLASS" == "IllegalStateException" ]]; then
                ROOT_EXCEPTIONS+=("$EXCEPTION_NAME")
            fi
        fi
    done <<< "$EXCEPTION_FILES"

    # Display exception hierarchy as tree
    print_exception_tree() {
        local parent="$1"
        local indent="$2"

        for exc in "${ALL_EXCEPTIONS[@]}"; do
            if [[ "${EXCEPTION_PARENTS[$exc]:-}" == "$parent" ]]; then
                echo "${indent}├── $exc"
                print_exception_tree "$exc" "${indent}│   "
            fi
        done
    }

    # Print root exceptions and their children
    for root in "${ROOT_EXCEPTIONS[@]}"; do
        PARENT="${EXCEPTION_PARENTS[$root]:-unknown}"
        success "  $root (extends $PARENT)"
        print_exception_tree "$root" "      "
    done

    # Print orphan exceptions (no children, extends standard exception)
    echo ""
    info "Exception Summary:"
    info "  Total custom exceptions: ${#ALL_EXCEPTIONS[@]}"
    info "  Root domain exceptions: ${#ROOT_EXCEPTIONS[@]}"

    # List exception packages
    echo ""
    info "Exception Packages:"
    for exception_file in $EXCEPTION_FILES; do
        EXCEPTION_PKG=$(dirname "$exception_file" | sed "s|$SRC_MAIN/||" | tr '/' '.')
        echo "  $EXCEPTION_PKG"
    done | sort -u
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
        # Look for @ResponseStatus and HttpStatus references
        grep -oP '(?<=@ResponseStatus\()[^)]+|HttpStatus\.\w+' "$advice_file" 2>/dev/null | sort -u | \
        while read -r status; do
            info "  $status"
        done
    done <<< "$CONTROLLER_ADVICES"
fi

# Also check controllers for @ResponseStatus
grep -rh "@ResponseStatus\|HttpStatus\." --include="*.java" "$SRC_MAIN" 2>/dev/null | \
    grep -oP 'HttpStatus\.\w+|(?<=code\s*=\s*HttpStatus\.)\w+|(?<=value\s*=\s*HttpStatus\.)\w+' | \
    sort -u | head -10 | while read -r status; do
        [[ -n "$status" ]] && info "  HttpStatus.$status"
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
            TOPICS=$(echo "$content" | grep -oP '(?<=topics\s*=\s*[\{"]+)[^"\}]+|(?<=topics\s*=\s*")[^"]+' || echo "unknown")
            GROUP=$(grep -A5 "@KafkaListener" "$file" 2>/dev/null | grep -oP '(?<=groupId\s*=\s*")[^"]+' | head -1 || echo "")
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
            TOPICS=$(grep -oP '(?<=\.send\(")[^"]+' "$file" 2>/dev/null | sort -u | tr '\n' ', ' | sed 's/,$//')
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
        TABLE_NAME=$(grep -oP '(?<=@Table\(name\s*=\s*")[^"]+' "$entity_file" 2>/dev/null || echo "$ENTITY_NAME")
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
        COLLECTION=$(grep -oP '(?<=@Document\(collection\s*=\s*")[^"]+|(?<=@Document\(")[^"]+' "$doc_file" 2>/dev/null || echo "$DOC_NAME")
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
        SERVICE_NAME=$(grep -oP '(?<=@FeignClient\(name\s*=\s*")[^"]+|(?<=@FeignClient\(value\s*=\s*")[^"]+|(?<=@FeignClient\(")[^",]+' "$feign_file" 2>/dev/null | head -1 || echo "unknown")
        URL=$(grep -oP '(?<=url\s*=\s*")[^"]+' "$feign_file" 2>/dev/null || echo "")
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
echo "Dependencies: ${#FOUND_DEPS[@]} detected"
echo "Controllers: $CONTROLLER_COUNT | Services: ${SERVICE_COUNT:-0}"
echo "Entities: $(echo "$JPA_ENTITIES" | grep -c "." 2>/dev/null || echo "0") JPA, $(echo "$MONGO_DOCS" | grep -c "." 2>/dev/null || echo "0") MongoDB"
echo "Exceptions: ${#ALL_EXCEPTIONS[@]:-0} custom, ${#ROOT_EXCEPTIONS[@]:-0} root domain"
echo "Tests: ${UNIT_TESTS:-0} unit, ${INTEGRATION_TESTS:-0} integration"
echo ""
success "Analysis complete!"
