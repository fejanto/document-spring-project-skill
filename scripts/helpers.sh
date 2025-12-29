#!/usr/bin/env bash
#
# Helper functions for Spring Boot Project Analyzer
#

# =============================================================================
# COLORS AND FORMATTING
# =============================================================================

# Check if terminal supports colors
if [[ -t 1 ]] && [[ -n "${TERM:-}" ]] && command -v tput &>/dev/null; then
    BOLD=$(tput bold)
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    WHITE=$(tput setaf 7)
    RESET=$(tput sgr0)
else
    BOLD=""
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    WHITE=""
    RESET=""
fi

# =============================================================================
# OUTPUT FUNCTIONS
# =============================================================================

# Print section header
header() {
    local text="$1"
    echo ""
    echo "${BOLD}${BLUE}════════════════════════════════════════════════════════════════${RESET}"
    echo "${BOLD}${BLUE}  ${text}${RESET}"
    echo "${BOLD}${BLUE}════════════════════════════════════════════════════════════════${RESET}"
    echo ""
}

# Print section title
section() {
    local text="$1"
    echo ""
    echo "${BOLD}${CYAN}── ${text} ──${RESET}"
}

# Print success message (green checkmark)
success() {
    echo "${GREEN}✓${RESET} $1"
}

# Print info message (blue bullet)
info() {
    echo "${BLUE}•${RESET} $1"
}

# Print warning message (yellow triangle)
warning() {
    echo "${YELLOW}⚠${RESET} $1"
}

# Print error message (red X)
error() {
    echo "${RED}✗${RESET} $1" >&2
}

# Print debug message (magenta, only if DEBUG is set)
debug() {
    if [[ "${DEBUG:-}" == "true" ]]; then
        echo "${MAGENTA}[DEBUG]${RESET} $1"
    fi
}

# =============================================================================
# XML/CONFIG EXTRACTION FUNCTIONS
# =============================================================================

# Extract value from XML tag
# Usage: extract_xml_value "file.xml" "tag.name"
extract_xml_value() {
    local file="$1"
    local tag="$2"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    # Handle nested tags (e.g., java.version -> <java.version>)
    local value
    value=$(grep -oP "(?<=<${tag}>)[^<]+" "$file" 2>/dev/null | head -1)

    if [[ -n "$value" ]]; then
        echo "$value"
        return 0
    fi

    return 1
}

# Extract value from properties file
# Usage: extract_property "application.properties" "server.port"
extract_property() {
    local file="$1"
    local key="$2"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    local value
    value=$(grep "^${key}=" "$file" 2>/dev/null | cut -d'=' -f2- | tr -d ' ')

    if [[ -n "$value" ]]; then
        echo "$value"
        return 0
    fi

    return 1
}

# Extract value from YAML file (simple, single-level only)
# Usage: extract_yaml_value "application.yml" "port"
extract_yaml_value() {
    local file="$1"
    local key="$2"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    local value
    value=$(grep -E "^\s*${key}:" "$file" 2>/dev/null | head -1 | awk '{print $2}')

    if [[ -n "$value" ]]; then
        echo "$value"
        return 0
    fi

    return 1
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Check if directory is a Spring Boot project
is_spring_boot_project() {
    local dir="${1:-.}"

    # Check for pom.xml or build.gradle
    if [[ ! -f "$dir/pom.xml" ]] && [[ ! -f "$dir/build.gradle" ]] && [[ ! -f "$dir/build.gradle.kts" ]]; then
        return 1
    fi

    # Check for Spring Boot dependency
    if grep -q "spring-boot" "$dir/pom.xml" "$dir/build.gradle"* 2>/dev/null; then
        return 0
    fi

    return 1
}

# Check if directory has standard Maven/Gradle structure
has_standard_structure() {
    local dir="${1:-.}"

    if [[ -d "$dir/src/main/java" ]]; then
        return 0
    fi

    return 1
}

# =============================================================================
# FILE SEARCH FUNCTIONS
# =============================================================================

# Find all Java files with specific annotation
# Usage: find_annotated_files "/path" "@Entity"
find_annotated_files() {
    local dir="$1"
    local annotation="$2"

    grep -rl "$annotation" --include="*.java" "$dir" 2>/dev/null || true
}

# Count files matching pattern
# Usage: count_files "/path" "*.java"
count_files() {
    local dir="$1"
    local pattern="$2"

    find "$dir" -name "$pattern" -type f 2>/dev/null | wc -l | tr -d ' '
}

# =============================================================================
# STRING MANIPULATION FUNCTIONS
# =============================================================================

# Convert CamelCase to kebab-case
camel_to_kebab() {
    echo "$1" | sed 's/\([A-Z]\)/-\L\1/g' | sed 's/^-//'
}

# Convert CamelCase to snake_case
camel_to_snake() {
    echo "$1" | sed 's/\([A-Z]\)/_\L\1/g' | sed 's/^_//'
}

# Extract class name from file path
class_name_from_path() {
    basename "$1" .java
}

# Extract package from file path (relative to src/main/java)
package_from_path() {
    local path="$1"
    local src_main="src/main/java"

    echo "$path" | sed "s|.*${src_main}/||" | sed 's|/[^/]*$||' | tr '/' '.'
}

# =============================================================================
# ARRAY/LIST FUNCTIONS
# =============================================================================

# Join array elements with delimiter
# Usage: join_array "," "${array[@]}"
join_array() {
    local delimiter="$1"
    shift
    local first="$1"
    shift
    printf %s "$first" "${@/#/$delimiter}"
}

# Check if element exists in array
# Usage: in_array "element" "${array[@]}"
in_array() {
    local element="$1"
    shift
    local item
    for item in "$@"; do
        [[ "$item" == "$element" ]] && return 0
    done
    return 1
}

# =============================================================================
# OUTPUT FORMATTING FUNCTIONS
# =============================================================================

# Print a table row
# Usage: table_row "Column1" "Column2" "Column3"
table_row() {
    printf "| %-30s | %-40s |\n" "$1" "$2"
}

# Print table header
table_header() {
    printf "| %-30s | %-40s |\n" "$1" "$2"
    printf "|%-32s|%-42s|\n" "$(printf '%0.s-' {1..32})" "$(printf '%0.s-' {1..42})"
}

# Print indented tree item
# Usage: tree_item "├──" "Item name" 2
tree_item() {
    local prefix="$1"
    local text="$2"
    local level="${3:-0}"
    local indent=""

    for ((i = 0; i < level; i++)); do
        indent+="    "
    done

    echo "${indent}${prefix} ${text}"
}

# =============================================================================
# PROGRESS INDICATORS
# =============================================================================

# Simple spinner for long operations
# Usage: spin "Message" & SPIN_PID=$!; long_command; kill $SPIN_PID
spin() {
    local message="$1"
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local i=0

    while true; do
        printf "\r${CYAN}%s${RESET} %s" "${chars:i++%${#chars}:1}" "$message"
        sleep 0.1
    done
}

# Print progress bar
# Usage: progress_bar 50 100 "Processing"
progress_bar() {
    local current="$1"
    local total="$2"
    local message="${3:-Progress}"
    local width=40

    local percent=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))

    printf "\r%s [%s%s] %d%%" \
        "$message" \
        "$(printf '%0.s█' $(seq 1 $filled))" \
        "$(printf '%0.s░' $(seq 1 $empty))" \
        "$percent"

    if [[ $current -eq $total ]]; then
        echo ""
    fi
}
