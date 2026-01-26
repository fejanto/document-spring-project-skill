#!/usr/bin/env bash
# Git utilities for incremental and selective documentation
# Part of document-spring-project skill

set -euo pipefail

# Detectar último commit que modificó documentación
detect_last_doc_commit() {
    local doc_files="CLAUDE.md .claude/rules/ docs/ README.md"
    git log -1 --format="%H" -- $doc_files 2>/dev/null || echo ""
}

# Obtener archivos modificados desde un commit específico
get_changed_files_since() {
    local since_commit=$1
    local filter_path=${2:-"src/"}

    if [ -z "$since_commit" ]; then
        echo ""
        return
    fi

    git diff "$since_commit"..HEAD --name-only --diff-filter=ACMR -- "$filter_path" 2>/dev/null || echo ""
}

# Categorizar archivos modificados por tipo
categorize_changes() {
    local files=("$@")

    local new_controllers=()
    local new_entities=()
    local new_kafka_consumers=()
    local new_kafka_producers=()
    local modified_services=()
    local new_feign_clients=()
    local modified_configs=()
    local new_dtos=()

    for file in "${files[@]}"; do
        if [[ "$file" =~ Controller\.java$ ]]; then
            # Check if it's new or modified
            if git diff --name-status "$since_commit"..HEAD -- "$file" | grep -q "^A"; then
                new_controllers+=("$file")
            fi
        elif [[ "$file" =~ (Entity|Document)\.java$ ]]; then
            if git diff --name-status "$since_commit"..HEAD -- "$file" | grep -q "^A"; then
                new_entities+=("$file")
            fi
        elif [[ "$file" =~ Service\.java$ ]]; then
            modified_services+=("$file")
        elif grep -l "@KafkaListener" "$file" &>/dev/null; then
            new_kafka_consumers+=("$file")
        elif grep -l "KafkaTemplate" "$file" &>/dev/null; then
            new_kafka_producers+=("$file")
        elif grep -l "@FeignClient" "$file" &>/dev/null; then
            new_feign_clients+=("$file")
        elif [[ "$file" =~ (application\.yml|application\.properties|.*Config\.java)$ ]]; then
            modified_configs+=("$file")
        elif [[ "$file" =~ (Dto|Request|Response)\.java$ ]]; then
            new_dtos+=("$file")
        fi
    done

    # Output as JSON-like structure for easy parsing
    echo "NEW_CONTROLLERS=${#new_controllers[@]}"
    [ ${#new_controllers[@]} -gt 0 ] && printf '%s\n' "${new_controllers[@]}" | sed 's/^/NEW_CONTROLLER: /'

    echo "NEW_ENTITIES=${#new_entities[@]}"
    [ ${#new_entities[@]} -gt 0 ] && printf '%s\n' "${new_entities[@]}" | sed 's/^/NEW_ENTITY: /'

    echo "MODIFIED_SERVICES=${#modified_services[@]}"
    [ ${#modified_services[@]} -gt 0 ] && printf '%s\n' "${modified_services[@]}" | sed 's/^/MODIFIED_SERVICE: /'

    echo "NEW_KAFKA_CONSUMERS=${#new_kafka_consumers[@]}"
    [ ${#new_kafka_consumers[@]} -gt 0 ] && printf '%s\n' "${new_kafka_consumers[@]}" | sed 's/^/NEW_KAFKA_CONSUMER: /'

    echo "NEW_KAFKA_PRODUCERS=${#new_kafka_producers[@]}"
    [ ${#new_kafka_producers[@]} -gt 0 ] && printf '%s\n' "${new_kafka_producers[@]}" | sed 's/^/NEW_KAFKA_PRODUCER: /'

    echo "NEW_FEIGN_CLIENTS=${#new_feign_clients[@]}"
    [ ${#new_feign_clients[@]} -gt 0 ] && printf '%s\n' "${new_feign_clients[@]}" | sed 's/^/NEW_FEIGN_CLIENT: /'

    echo "MODIFIED_CONFIGS=${#modified_configs[@]}"
    [ ${#modified_configs[@]} -gt 0 ] && printf '%s\n' "${modified_configs[@]}" | sed 's/^/MODIFIED_CONFIG: /'

    echo "NEW_DTOS=${#new_dtos[@]}"
    [ ${#new_dtos[@]} -gt 0 ] && printf '%s\n' "${new_dtos[@]}" | sed 's/^/NEW_DTO: /'
}

# Detectar si existe documentación previa
detect_existing_docs() {
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

    echo "HAS_CLAUDE_MD=$has_claude_md"
    echo "HAS_RULES=$has_rules"
    echo "HAS_DOCS=$has_docs"
    echo "HAS_README=$has_readme"
    echo "HAS_OLD_INSTRUCTIONS=$has_old_instructions"
}

# Analizar archivos específicos para modo incremental
analyze_specific_files() {
    local project_dir=$1
    shift
    local files=("$@")

    # Usar el script analyze.sh existente pero solo para archivos específicos
    # Esta función será llamada por analyze.sh cuando se pase el flag --files

    for file in "${files[@]}"; do
        echo "ANALYZING: $file"

        # Detectar tipo de archivo y extraer info relevante
        if [[ "$file" =~ Controller\.java$ ]]; then
            # Extraer endpoints
            grep -E "@(Get|Post|Put|Delete|Patch)Mapping" "$project_dir/$file" || true
        elif [[ "$file" =~ Entity\.java$ ]]; then
            # Extraer nombre de entidad y tabla
            grep -E "@Entity|@Table" "$project_dir/$file" || true
        elif [[ "$file" =~ Service\.java$ ]]; then
            # Extraer métodos públicos
            grep -E "public .* \w+\(" "$project_dir/$file" || true
        fi
    done
}

# Identificar qué secciones de documentación actualizar basado en cambios
identify_affected_sections() {
    local changes_summary=$1

    local sections=()

    if echo "$changes_summary" | grep -q "NEW_CONTROLLERS"; then
        sections+=("api-reference" "claude-md")
    fi

    if echo "$changes_summary" | grep -q "NEW_ENTITIES"; then
        sections+=("domain-model" "database-schema" "rules-domain" "docs-domain")
    fi

    if echo "$changes_summary" | grep -q "NEW_KAFKA"; then
        sections+=("integration-points" "rules-architecture")
    fi

    if echo "$changes_summary" | grep -q "MODIFIED_SERVICES"; then
        sections+=("business-rules")
    fi

    if echo "$changes_summary" | grep -q "NEW_FEIGN_CLIENTS"; then
        sections+=("integration-points" "claude-md")
    fi

    if echo "$changes_summary" | grep -q "MODIFIED_CONFIG"; then
        sections+=("configuration")
    fi

    # Remove duplicates
    printf '%s\n' "${sections[@]}" | sort -u
}

# Validar que el directorio es un repositorio git
validate_git_repo() {
    if ! git rev-parse --git-dir &>/dev/null; then
        echo "ERROR: Not a git repository" >&2
        return 1
    fi
    return 0
}

# Obtener resumen de cambios desde último commit de docs
get_changes_summary() {
    local last_doc_commit=$(detect_last_doc_commit)

    if [ -z "$last_doc_commit" ]; then
        echo "No previous documentation commits found"
        return
    fi

    local changed_files=$(get_changed_files_since "$last_doc_commit")

    if [ -z "$changed_files" ]; then
        echo "No changes since last documentation update"
        return
    fi

    local changes_array=()
    while IFS= read -r file; do
        changes_array+=("$file")
    done <<< "$changed_files"

    categorize_changes "${changes_array[@]}"
}

# Función principal para uso desde SKILL.md
main() {
    local command=${1:-"help"}

    case "$command" in
        detect-last-commit)
            detect_last_doc_commit
            ;;
        get-changes)
            local since_commit=${2:-"$(detect_last_doc_commit)"}
            get_changed_files_since "$since_commit"
            ;;
        categorize)
            shift
            categorize_changes "$@"
            ;;
        detect-docs)
            detect_existing_docs
            ;;
        summary)
            get_changes_summary
            ;;
        affected-sections)
            local changes_summary=$(get_changes_summary)
            identify_affected_sections "$changes_summary"
            ;;
        validate)
            validate_git_repo
            ;;
        *)
            echo "Usage: $0 {detect-last-commit|get-changes|categorize|detect-docs|summary|affected-sections|validate}"
            exit 1
            ;;
    esac
}

# Si se ejecuta directamente
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
