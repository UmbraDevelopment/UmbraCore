#!/bin/bash
# UmbraCore Workflow Manager
# This script manages GitHub Actions workflows using yq and a centralised configuration

set -e # Exit on error

# Configuration
CONFIG_FILE="ci_config.yml"
WORKFLOWS_DIR=".github/workflows"

# Text styling for better output
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# Function to show help text
show_help() {
    cat << EOF
${BOLD}UmbraCore Workflow Manager${RESET}

A tool to manage GitHub Actions workflows using a centralised YAML configuration.

${BOLD}Usage:${RESET}
    $(basename "$0") [command] [options]

${BOLD}Commands:${RESET}
    list                   List all workflows defined in the configuration
    generate               Generate all workflow files from the configuration
    update                 Update existing workflow files (preserves comments)
    validate               Validate the configuration file
    clean                  Remove all generated workflow files
    help                   Show this help text

${BOLD}Options:${RESET}
    -w, --workflow NAME    Specify a single workflow to operate on
    -c, --config FILE      Specify an alternative configuration file
    -f, --force            Force overwrite of existing files
    -v, --verbose          Enable verbose output

${BOLD}Examples:${RESET}
    $(basename "$0") list
    $(basename "$0") generate --workflow docs
    $(basename "$0") update --config custom_config.yml
    $(basename "$0") validate

${BOLD}Note:${RESET}
    This script requires yq v4+ to be installed.
    You can install it with: brew install yq
EOF
}

# Function to check if yq is installed
check_yq() {
    if ! command -v yq &>/dev/null; then
        echo -e "${RED}Error: yq is not installed${RESET}"
        echo "Please install it with: brew install yq"
        echo "Visit https://github.com/mikefarah/yq for more information"
        exit 1
    fi
    
    # Check yq version (needs to be v4+)
    local version
    version=$(yq --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | cut -d. -f1)
    if [[ "$version" -lt 4 ]]; then
        echo -e "${RED}Error: yq version 4+ is required${RESET}"
        echo "Current version: $(yq --version)"
        echo "Please upgrade yq with: brew upgrade yq"
        exit 1
    fi
}

# Function to check if the configuration file exists
check_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}Error: Configuration file not found: $CONFIG_FILE${RESET}"
        exit 1
    fi
}

# Function to create the workflows directory if it doesn't exist
ensure_workflows_dir() {
    if [[ ! -d "$WORKFLOWS_DIR" ]]; then
        echo -e "${YELLOW}Creating workflows directory: $WORKFLOWS_DIR${RESET}"
        mkdir -p "$WORKFLOWS_DIR"
    fi
}

# Function to list all workflows defined in the configuration
list_workflows() {
    check_config
    
    echo -e "${BOLD}Workflows defined in $CONFIG_FILE:${RESET}"
    
    local count
    count=$(yq '.workflows | length' "$CONFIG_FILE")
    
    if [[ "$count" -eq 0 ]]; then
        echo -e "${YELLOW}No workflows defined in the configuration${RESET}"
        return
    fi
    
    yq '.workflows | keys | .[]' "$CONFIG_FILE" | while read -r workflow; do
        local name
        name=$(yq ".workflows.${workflow}.name" "$CONFIG_FILE")
        local description
        description=$(yq ".workflows.${workflow}.description" "$CONFIG_FILE")
        
        echo -e "${BOLD}${workflow}${RESET} - ${name}"
        echo "  ${description}"
    done
}

# Function to validate the configuration file
validate_config() {
    check_config
    
    echo -e "${BOLD}Validating configuration file: $CONFIG_FILE${RESET}"
    
    # Check if the file is valid YAML
    if ! yq eval '.' "$CONFIG_FILE" > /dev/null; then
        echo -e "${RED}Error: Invalid YAML in $CONFIG_FILE${RESET}"
        exit 1
    fi
    
    # Check if the workflows section exists
    if [[ "$(yq '.workflows' "$CONFIG_FILE")" == "null" ]]; then
        echo -e "${RED}Error: No workflows section found in $CONFIG_FILE${RESET}"
        exit 1
    fi
    
    # Check each workflow for required fields
    yq '.workflows | keys | .[]' "$CONFIG_FILE" | while read -r workflow; do
        for field in "name" "on" "jobs"; do
            if [[ "$(yq ".workflows.${workflow}.${field}" "$CONFIG_FILE")" == "null" ]]; then
                echo -e "${RED}Error: Missing required field '${field}' in workflow '${workflow}'${RESET}"
                exit 1
            fi
        done
    done
    
    echo -e "${GREEN}Configuration is valid${RESET}"
}

# Function to generate the on section of a workflow
generate_on_section() {
    local workflow="$1"
    local temp_file="$2"
    
    echo "on:" >> "$temp_file"
    
    # Get the list of events (push, pull_request, etc.)
    yq ".workflows.${workflow}.on | keys | .[]" "$CONFIG_FILE" | while read -r event; do
        echo "  ${event}:" >> "$temp_file"
        
        # Check if the event has configuration or is empty
        if [[ "$(yq ".workflows.${workflow}.on.${event}" "$CONFIG_FILE")" == "{}" ]]; then
            echo "" >> "$temp_file"
            continue
        fi
        
        # Handle arrays (branches, paths, etc.)
        for prop in "branches" "paths" "tags"; do
            if [[ "$(yq ".workflows.${workflow}.on.${event}.${prop}" "$CONFIG_FILE")" != "null" ]]; then
                echo "    ${prop}:" >> "$temp_file"
                yq ".workflows.${workflow}.on.${event}.${prop}[]" "$CONFIG_FILE" | while read -r value; do
                    echo "      - ${value}" >> "$temp_file"
                done
            fi
        done
        
        # Handle workflow_dispatch inputs
        if [[ "$event" == "workflow_dispatch" && "$(yq ".workflows.${workflow}.on.workflow_dispatch.inputs" "$CONFIG_FILE")" != "null" ]]; then
            echo "    inputs:" >> "$temp_file"
            yq ".workflows.${workflow}.on.workflow_dispatch.inputs | keys | .[]" "$CONFIG_FILE" | while read -r input; do
                echo "      ${input}:" >> "$temp_file"
                yq ".workflows.${workflow}.on.workflow_dispatch.inputs.${input} | keys | .[]" "$CONFIG_FILE" | while read -r prop; do
                    local value
                    value=$(yq ".workflows.${workflow}.on.workflow_dispatch.inputs.${input}.${prop}" "$CONFIG_FILE")
                    echo "        ${prop}: ${value}" >> "$temp_file"
                done
            done
        fi
    done
}

# Function to generate the job steps
generate_job_steps() {
    local workflow="$1"
    local job="$2"
    local temp_file="$3"
    
    echo "    steps:" >> "$temp_file"
    
    local step_count
    step_count=$(yq ".workflows.${workflow}.jobs.${job}.steps | length" "$CONFIG_FILE")
    
    for ((i=0; i<step_count; i++)); do
        # Step name
        local name
        name=$(yq ".workflows.${workflow}.jobs.${job}.steps[${i}].name" "$CONFIG_FILE")
        echo "      - name: ${name}" >> "$temp_file"
        
        # Step uses (if present)
        if [[ "$(yq ".workflows.${workflow}.jobs.${job}.steps[${i}].uses" "$CONFIG_FILE")" != "null" ]]; then
            local uses
            uses=$(yq ".workflows.${workflow}.jobs.${job}.steps[${i}].uses" "$CONFIG_FILE")
            echo "        uses: ${uses}" >> "$temp_file"
        fi
        
        # Step run (if present)
        if [[ "$(yq ".workflows.${workflow}.jobs.${job}.steps[${i}].run" "$CONFIG_FILE")" != "null" ]]; then
            echo "        run: |" >> "$temp_file"
            yq ".workflows.${workflow}.jobs.${job}.steps[${i}].run" "$CONFIG_FILE" | sed 's/^/          /' >> "$temp_file"
        fi
        
        # Step with (if present)
        if [[ "$(yq ".workflows.${workflow}.jobs.${job}.steps[${i}].with" "$CONFIG_FILE")" != "null" ]]; then
            echo "        with:" >> "$temp_file"
            yq ".workflows.${workflow}.jobs.${job}.steps[${i}].with | keys | .[]" "$CONFIG_FILE" | while read -r prop; do
                local value
                value=$(yq ".workflows.${workflow}.jobs.${job}.steps[${i}].with.${prop}" "$CONFIG_FILE")
                echo "          ${prop}: ${value}" >> "$temp_file"
            done
        fi
        
        # Step if (if present)
        if [[ "$(yq ".workflows.${workflow}.jobs.${job}.steps[${i}].if" "$CONFIG_FILE")" != "null" ]]; then
            local if_cond
            if_cond=$(yq ".workflows.${workflow}.jobs.${job}.steps[${i}].if" "$CONFIG_FILE")
            echo "        if: ${if_cond}" >> "$temp_file"
        fi
        
        # Step id (if present)
        if [[ "$(yq ".workflows.${workflow}.jobs.${job}.steps[${i}].id" "$CONFIG_FILE")" != "null" ]]; then
            local id
            id=$(yq ".workflows.${workflow}.jobs.${job}.steps[${i}].id" "$CONFIG_FILE")
            echo "        id: ${id}" >> "$temp_file"
        fi
    done
}

# Function to generate jobs for a workflow
generate_jobs() {
    local workflow="$1"
    local temp_file="$2"
    
    echo "jobs:" >> "$temp_file"
    
    # Get the jobs for this workflow
    yq ".workflows.${workflow}.jobs | keys | .[]" "$CONFIG_FILE" | while read -r job; do
        echo "  ${job}:" >> "$temp_file"
        
        # Get the runner for this job (use global if not specified)
        local runner
        if [[ "$(yq ".workflows.${workflow}.jobs.${job}.runs-on" "$CONFIG_FILE")" != "null" ]]; then
            runner=$(yq ".workflows.${workflow}.jobs.${job}.runs-on" "$CONFIG_FILE")
        else
            runner=$(yq ".global.runner" "$CONFIG_FILE")
        fi
        
        # Add the runner
        echo "    runs-on: ${runner}" >> "$temp_file"
        
        # Add environment if specified
        if [[ "$(yq ".workflows.${workflow}.environment" "$CONFIG_FILE")" != "null" ]]; then
            echo "    environment:" >> "$temp_file"
            yq ".workflows.${workflow}.environment | keys | .[]" "$CONFIG_FILE" | while read -r env_key; do
                local env_value
                env_value=$(yq ".workflows.${workflow}.environment.${env_key}" "$CONFIG_FILE")
                echo "      ${env_key}: ${env_value}" >> "$temp_file"
            done
        fi
        
        # Add steps
        generate_job_steps "$workflow" "$job" "$temp_file"
    done
}

# Function to generate a single workflow file
generate_workflow() {
    local workflow="$1"
    local force="$2"
    
    local output_file="${WORKFLOWS_DIR}/${workflow}.yml"
    local temp_file="${output_file}.tmp"
    
    echo -e "${BOLD}Generating workflow: ${workflow}${RESET}"
    
    # Check if the workflow exists in the config
    if [[ "$(yq ".workflows.${workflow}" "$CONFIG_FILE")" == "null" ]]; then
        echo -e "${RED}Error: Workflow '${workflow}' not found in $CONFIG_FILE${RESET}"
        exit 1
    fi
    
    # Check if the output file already exists and we're not forcing
    if [[ -f "$output_file" && "$force" != "true" ]]; then
        echo -e "${YELLOW}File already exists: $output_file${RESET}"
        echo -e "${YELLOW}Use --force to overwrite${RESET}"
        return
    fi
    
    # Start generating the workflow file
    local name
    name=$(yq ".workflows.${workflow}.name" "$CONFIG_FILE")
    
    # Add the name
    echo "name: ${name}" > "$temp_file"
    echo "" >> "$temp_file"
    
    # Add the on section
    generate_on_section "$workflow" "$temp_file"
    echo "" >> "$temp_file"
    
    # Add permissions if specified
    if [[ "$(yq ".workflows.${workflow}.permissions" "$CONFIG_FILE")" != "null" ]]; then
        echo "permissions:" >> "$temp_file"
        yq ".workflows.${workflow}.permissions | keys | .[]" "$CONFIG_FILE" | while read -r perm; do
            local value
            value=$(yq ".workflows.${workflow}.permissions.${perm}" "$CONFIG_FILE")
            echo "  ${perm}: ${value}" >> "$temp_file"
        done
        echo "" >> "$temp_file"
    fi
    
    # Add concurrency if specified
    if [[ "$(yq ".workflows.${workflow}.concurrency" "$CONFIG_FILE")" != "null" ]]; then
        echo "concurrency:" >> "$temp_file"
        yq ".workflows.${workflow}.concurrency | keys | .[]" "$CONFIG_FILE" | while read -r key; do
            local value
            value=$(yq ".workflows.${workflow}.concurrency.${key}" "$CONFIG_FILE")
            echo "  ${key}: ${value}" >> "$temp_file"
        done
        echo "" >> "$temp_file"
    fi
    
    # Add jobs
    generate_jobs "$workflow" "$temp_file"
    
    # Move the temp file to the output file
    mv "$temp_file" "$output_file"
    echo -e "${GREEN}Generated workflow file: $output_file${RESET}"
}

# Function to generate all workflow files
generate_all_workflows() {
    local force="$1"
    
    ensure_workflows_dir
    
    echo -e "${BOLD}Generating all workflows from $CONFIG_FILE${RESET}"
    
    local count
    count=$(yq '.workflows | length' "$CONFIG_FILE")
    
    if [[ "$count" -eq 0 ]]; then
        echo -e "${YELLOW}No workflows defined in the configuration${RESET}"
        return
    fi
    
    yq '.workflows | keys | .[]' "$CONFIG_FILE" | while read -r workflow; do
        generate_workflow "$workflow" "$force"
    done
    
    echo -e "${GREEN}All workflows generated successfully${RESET}"
}

# Function to clean all generated workflow files
clean_workflows() {
    local confirmed="$1"
    
    if [[ ! -d "$WORKFLOWS_DIR" ]]; then
        echo -e "${YELLOW}Workflows directory not found: $WORKFLOWS_DIR${RESET}"
        return
    fi
    
    echo -e "${BOLD}Cleaning workflow files${RESET}"
    
    # Get the list of workflows from the config
    local workflows=()
    while read -r workflow; do
        workflows+=("${workflow}.yml")
    done < <(yq '.workflows | keys | .[]' "$CONFIG_FILE")
    
    if [[ ${#workflows[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No workflows defined in the configuration${RESET}"
        return
    fi
    
    # Confirm before deleting
    if [[ "$confirmed" != "true" ]]; then
        echo -e "${YELLOW}The following workflow files will be deleted:${RESET}"
        for workflow in "${workflows[@]}"; do
            if [[ -f "${WORKFLOWS_DIR}/${workflow}" ]]; then
                echo "  ${WORKFLOWS_DIR}/${workflow}"
            fi
        done
        
        read -rp "Are you sure you want to continue? [y/N] " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo -e "${YELLOW}Operation cancelled${RESET}"
            return
        fi
    fi
    
    # Delete the workflow files
    for workflow in "${workflows[@]}"; do
        if [[ -f "${WORKFLOWS_DIR}/${workflow}" ]]; then
            rm "${WORKFLOWS_DIR}/${workflow}"
            echo -e "${GREEN}Deleted: ${WORKFLOWS_DIR}/${workflow}${RESET}"
        fi
    done
    
    echo -e "${GREEN}All workflow files cleaned successfully${RESET}"
}

# Function to update existing workflow files (preserving comments)
update_workflows() {
    local target="$1"
    
    ensure_workflows_dir
    
    echo -e "${BOLD}Updating workflow files${RESET}"
    
    # Get the list of workflows to update
    local workflows=()
    if [[ -n "$target" ]]; then
        # Check if the workflow exists in the config
        if [[ "$(yq ".workflows.${target}" "$CONFIG_FILE")" == "null" ]]; then
            echo -e "${RED}Error: Workflow '${target}' not found in $CONFIG_FILE${RESET}"
            exit 1
        fi
        workflows=("$target")
    else
        while read -r workflow; do
            workflows+=("$workflow")
        done < <(yq '.workflows | keys | .[]' "$CONFIG_FILE")
    fi
    
    if [[ ${#workflows[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No workflows defined in the configuration${RESET}"
        return
    fi
    
    # Update each workflow
    for workflow in "${workflows[@]}"; do
        local output_file="${WORKFLOWS_DIR}/${workflow}.yml"
        
        # Check if the file exists
        if [[ ! -f "$output_file" ]]; then
            echo -e "${YELLOW}Workflow file not found, generating: $output_file${RESET}"
            generate_workflow "$workflow" "true"
            continue
        fi
        
        echo -e "${BOLD}Updating workflow: ${workflow}${RESET}"
        
        # Create a backup of the original file
        cp "$output_file" "${output_file}.bak"
        
        # Update the workflow file using our generate function
        generate_workflow "$workflow" "true"
        
        echo -e "${GREEN}Updated workflow file: $output_file${RESET}"
    done
    
    echo -e "${GREEN}All workflow files updated successfully${RESET}"
}

# Main script execution
main() {
    # Check if yq is installed
    check_yq
    
    # Parse command line arguments
    local command=""
    local workflow=""
    local force="false"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            list|generate|update|validate|clean|help)
                command="$1"
                shift
                ;;
            -w|--workflow)
                workflow="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -f|--force)
                force="true"
                shift
                ;;
            -v|--verbose)
                # Verbose mode is recognized but not used in the current version
                # This is kept for future implementation
                shift
                ;;
            *)
                echo -e "${RED}Unknown option: $1${RESET}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Show help if no command specified
    if [[ -z "$command" ]]; then
        show_help
        exit 0
    fi
    
    # Execute the requested command
    case "$command" in
        list)
            list_workflows
            ;;
        generate)
            check_config
            if [[ -n "$workflow" ]]; then
                generate_workflow "$workflow" "$force"
            else
                generate_all_workflows "$force"
            fi
            ;;
        update)
            check_config
            update_workflows "$workflow"
            ;;
        validate)
            validate_config
            ;;
        clean)
            check_config
            clean_workflows "$force"
            ;;
        help)
            show_help
            ;;
    esac
}

# Run the main function
main "$@"
