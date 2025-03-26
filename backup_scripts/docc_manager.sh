#!/bin/bash
# UmbraCore DocC Documentation Manager
# A comprehensive tool for managing DocC documentation using yq

set -e # Exit on error

# Configuration
CONFIG_FILE="docc_config.yml"
BUILD_DIR="docs/.docc-build"
GITHUB_PAGES_DIR="docs/api"

# Text styling for better output
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
BLUE="\033[34m"
RESET="\033[0m"

# Function to show help text
show_help() {
    cat << EOF
${BOLD}UmbraCore DocC Documentation Manager${RESET}

A comprehensive tool for managing Swift DocC documentation using yq.

${BOLD}Usage:${RESET}
    $(basename "$0") [command] [options]

${BOLD}Commands:${RESET}
    list                   List all DocC targets defined in the configuration
    discover               Discover potential DocC targets and add them to the configuration
    build                  Build DocC documentation for all or specified targets
    clean                  Remove all DocC build files
    help                   Show this help text

${BOLD}Options:${RESET}
    -t, --target NAME      Specify a single target to operate on
    -c, --config FILE      Specify an alternative configuration file
    -o, --output DIR       Specify an alternative output directory
    -f, --force            Force overwrite of existing files
    -v, --verbose          Enable verbose output

${BOLD}Examples:${RESET}
    $(basename "$0") list
    $(basename "$0") discover
    $(basename "$0") build --target CoreDTOs
    $(basename "$0") clean

${BOLD}Note:${RESET}
    This script requires yq v4+ and bazelisk to be installed.
    You can install them with: brew install yq bazelisk
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

# Function to check if bazelisk is installed
check_bazelisk() {
    if ! command -v bazelisk &>/dev/null; then
        echo -e "${RED}Error: bazelisk is not installed${RESET}"
        echo "Please install it with: brew install bazelisk"
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

# Function to ensure the build directory exists
ensure_build_dir() {
    if [[ ! -d "$BUILD_DIR" ]]; then
        echo -e "${YELLOW}Creating build directory: $BUILD_DIR${RESET}"
        mkdir -p "$BUILD_DIR"
    fi
}

# Function to list all DocC targets defined in the configuration
list_targets() {
    check_config
    
    echo -e "${BOLD}DocC targets defined in $CONFIG_FILE:${RESET}"
    
    local count
    count=$(yq '.targets | length' "$CONFIG_FILE")
    
    if [[ "$count" -eq 0 ]]; then
        echo -e "${YELLOW}No DocC targets defined in the configuration${RESET}"
        return
    fi
    
    # Print a table with target info
    echo -e "${BOLD}Name                  Module                 Path                                     Scheme${RESET}"
    echo -e "${BOLD}------------------------------------------------------------------------------------------${RESET}"
    
    yq '.targets[] | [.name, .module, .path, .scheme] | join(" | ")' "$CONFIG_FILE" | while read -r line; do
        # Format the line as a table
        IFS=" | " read -r name module path scheme <<< "$line"
        printf "%-22s %-22s %-40s %-20s\n" "$name" "$module" "$path" "$scheme"
    done
}

# Function to add a target to the configuration
add_target() {
    local name="$1"
    local module="$2"
    local path="$3"
    local scheme="$4"
    
    check_config
    
    # Check if the target already exists
    if yq -e ".targets[] | select(.name == \"$name\")" "$CONFIG_FILE" &>/dev/null; then
        echo -e "${YELLOW}Target '$name' already exists in the configuration${RESET}"
        return
    fi
    
    echo -e "${BOLD}Adding target: $name${RESET}"
    
    # Create a temporary file with the new target
    local temp_file
    temp_file=$(mktemp)
    
    # Append the new target to the configuration
    yq -i ".targets += [{\"name\": \"$name\", \"module\": \"$module\", \"path\": \"$path\", \"scheme\": \"$scheme\"}]" "$CONFIG_FILE"
    
    echo -e "${GREEN}Target '$name' added to the configuration${RESET}"
}

# Function to discover potential DocC targets
discover_targets() {
    local force="$1"
    
    check_config
    
    echo -e "${BOLD}Discovering potential DocC targets...${RESET}"
    
    # Use find to locate Swift files that might define modules
    echo -e "${YELLOW}Searching for Swift modules...${RESET}"
    
    # Create a temporary file to store potential targets
    local temp_dir
    temp_dir=$(mktemp -d)
    local module_files="$temp_dir/modules.txt"
    
    # Find Swift files that might define modules, excluding certain directories
    find . -type f -name "*.swift" | grep -v "\.build\|\.git\|\.github\|bazel-\|dist\|node_modules" | sort > "$module_files"
    
    # Extract potential module names using various heuristics
    echo -e "${YELLOW}Analyzing potential targets...${RESET}"
    
    # 1. Look for files with @_documentation markers
    echo -e "${BLUE}Looking for files with @_documentation markers...${RESET}"
    grep -l "@_documentation" $(cat "$module_files") 2>/dev/null | while read -r file; do
        local dir
        dir=$(dirname "$file")
        local module
        module=$(grep -oE '@_documentation\(.*\)' "$file" | sed -E 's/@_documentation\(.*\"([^\"]+)\".*\)/\1/')
        
        if [[ -n "$module" ]]; then
            echo -e "${GREEN}Found potential target: $module in $dir${RESET}"
            add_target "$module" "$module" "$dir" "$module"
        fi
    done
    
    # 2. Look for directories containing BUILD.bazel with swift_library rules
    echo -e "${BLUE}Looking for BUILD.bazel files with swift_library rules...${RESET}"
    find . -name "BUILD.bazel" | grep -v "bazel-\|\.git" | while read -r build_file; do
        local dir
        dir=$(dirname "$build_file")
        
        # Check if the BUILD file contains swift_library rules
        if grep -q "swift_library" "$build_file"; then
            # Extract the name from the swift_library rule
            grep -A 2 "swift_library" "$build_file" | grep "name" | head -1 | grep -oE "name\s*=\s*\"([^\"]+)\"" | sed -E 's/name\s*=\s*"([^"]+)"/\1/' | while read -r name; do
                if [[ -n "$name" ]]; then
                    echo -e "${GREEN}Found potential target from Bazel: $name in $dir${RESET}"
                    add_target "$name" "$name" "$dir" "$name"
                fi
            done
        fi
    done
    
    # 3. Scan for common module patterns (check for multiple swift files in a directory)
    echo -e "${BLUE}Scanning for common module patterns...${RESET}"
    for dir in $(find . -type d -not -path "*/\.*" -not -path "*/bazel-*" -not -path "*/dist*" -not -path "*/node_modules*"); do
        # Count Swift files in this directory
        local swift_count
        swift_count=$(find "$dir" -maxdepth 1 -name "*.swift" | wc -l | xargs)
        
        # If a directory has several Swift files, it might be a module
        if [[ "$swift_count" -gt 5 ]]; then
            local module
            module=$(basename "$dir")
            
            # Skip common non-module directory names
            if [[ "$module" != "Sources" && "$module" != "Tests" && "$module" != "." ]]; then
                echo -e "${YELLOW}Possible module from directory structure: $module in $dir${RESET}"
                
                # Only add if force is true, as this is a less reliable method
                if [[ "$force" == "true" ]]; then
                    add_target "$module" "$module" "$dir" "$module"
                else
                    echo -e "${YELLOW}Use --force to add this target${RESET}"
                fi
            fi
        fi
    done
    
    # Clean up temporary files
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}Discovery complete. Use './$(basename "$0") list' to view all targets.${RESET}"
}

# Function to build DocC documentation for a single target
build_target() {
    local name="$1"
    local verbose="$2"
    
    check_config
    check_bazelisk
    
    # Find the target in the configuration
    if ! yq -e ".targets[] | select(.name == \"$name\")" "$CONFIG_FILE" &>/dev/null; then
        echo -e "${RED}Error: Target '$name' not found in the configuration${RESET}"
        echo "Use './$(basename "$0") list' to view all available targets."
        return 1
    fi
    
    # Extract the target details
    local module
    module=$(yq -r ".targets[] | select(.name == \"$name\") | .module" "$CONFIG_FILE")
    local path
    path=$(yq -r ".targets[] | select(.name == \"$name\") | .path" "$CONFIG_FILE")
    local scheme
    scheme=$(yq -r ".targets[] | select(.name == \"$name\") | .scheme" "$CONFIG_FILE")
    
    echo -e "${BOLD}Building DocC documentation for target: $name${RESET}"
    echo -e "  Module: $module"
    echo -e "  Path: $path"
    echo -e "  Scheme: $scheme"
    
    # Ensure the build directory exists
    ensure_build_dir
    
    # Create an output directory for this target
    local target_dir="${BUILD_DIR}/${name}"
    mkdir -p "$target_dir"
    
    # Set the verbosity flag
    local verbose_flag=""
    if [[ "$verbose" == "true" ]]; then
        verbose_flag="--verbose_failures"
    fi
    
    # Build the DocC documentation using bazelisk
    echo -e "${YELLOW}Running bazelisk build for $name...${RESET}"
    
    local build_command="bazelisk build //tools/swift:docc_gen $verbose_flag"
    echo -e "${BLUE}Build command: $build_command${RESET}"
    
    if ! eval "$build_command"; then
        echo -e "${RED}Error: Failed to build DocC documentation for target '$name'${RESET}"
        return 1
    fi
    
    # Find the docc_gen binary
    local docc_gen_path
    docc_gen_path=$(find ./bazel-bin -name "docc_gen" -type f -executable)
    
    if [[ -z "$docc_gen_path" ]]; then
        echo -e "${RED}Error: Could not find the docc_gen binary${RESET}"
        return 1
    fi
    
    # Run the docc_gen binary
    echo -e "${YELLOW}Running docc_gen for $name...${RESET}"
    
    local docc_command="$docc_gen_path -s $scheme"
    echo -e "${BLUE}DocC command: $docc_command${RESET}"
    
    if ! eval "$docc_command"; then
        echo -e "${RED}Error: Failed to generate DocC documentation for target '$name'${RESET}"
        return 1
    fi
    
    # Copy the generated documentation to the target directory
    echo -e "${YELLOW}Copying documentation for $name...${RESET}"
    
    if [[ -d ".docc_output/$module.doccarchive" ]]; then
        cp -r ".docc_output/$module.doccarchive" "$target_dir/"
        echo -e "${GREEN}Documentation for '$name' built successfully${RESET}"
        echo -e "Documentation available at: $target_dir/$module.doccarchive"
        
        # Copy to GitHub Pages directory if it exists
        if [[ -d "$GITHUB_PAGES_DIR" ]]; then
            mkdir -p "$GITHUB_PAGES_DIR/$name"
            cp -r ".docc_output/$module.doccarchive" "$GITHUB_PAGES_DIR/$name/"
            echo -e "${GREEN}Documentation copied to GitHub Pages directory: $GITHUB_PAGES_DIR/$name/${RESET}"
        fi
    else
        echo -e "${RED}Error: Documentation output not found for target '$name'${RESET}"
        return 1
    fi
    
    return 0
}

# Function to build all DocC targets
build_all_targets() {
    local verbose="$1"
    
    check_config
    
    echo -e "${BOLD}Building DocC documentation for all targets${RESET}"
    
    local count
    count=$(yq '.targets | length' "$CONFIG_FILE")
    
    if [[ "$count" -eq 0 ]]; then
        echo -e "${YELLOW}No DocC targets defined in the configuration${RESET}"
        echo "Use './$(basename "$0") discover' to find potential targets."
        return
    fi
    
    local success=0
    local failure=0
    local targets=()
    
    # Collect all target names
    while read -r name; do
        targets+=("$name")
    done < <(yq -r '.targets[].name' "$CONFIG_FILE")
    
    echo -e "${BOLD}Building ${#targets[@]} targets...${RESET}"
    
    # Build each target
    for name in "${targets[@]}"; do
        if build_target "$name" "$verbose"; then
            ((success++))
        else
            ((failure++))
            echo -e "${RED}Failed to build target: $name${RESET}"
        fi
    done
    
    echo -e "${BOLD}Build summary:${RESET}"
    echo -e "${GREEN}Successful: $success${RESET}"
    if [[ "$failure" -gt 0 ]]; then
        echo -e "${RED}Failed: $failure${RESET}"
    fi
}

# Function to clean all DocC build files
clean_docc() {
    echo -e "${BOLD}Cleaning DocC build files${RESET}"
    
    # Remove the build directory
    if [[ -d "$BUILD_DIR" ]]; then
        echo -e "${YELLOW}Removing build directory: $BUILD_DIR${RESET}"
        rm -rf "$BUILD_DIR"
    fi
    
    # Remove the .docc_output directory
    if [[ -d ".docc_output" ]]; then
        echo -e "${YELLOW}Removing .docc_output directory${RESET}"
        rm -rf ".docc_output"
    fi
    
    # Remove the GitHub Pages directory if it exists
    if [[ -d "$GITHUB_PAGES_DIR" ]]; then
        echo -e "${YELLOW}Removing GitHub Pages API directory: $GITHUB_PAGES_DIR${RESET}"
        rm -rf "$GITHUB_PAGES_DIR"
    fi
    
    echo -e "${GREEN}DocC build files cleaned successfully${RESET}"
}

# Main script execution
main() {
    # Check if yq is installed
    check_yq
    
    # Parse command line arguments
    local command=""
    local target=""
    local force="false"
    local verbose="false"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            list|discover|build|clean|help)
                command="$1"
                shift
                ;;
            -t|--target)
                target="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -o|--output)
                BUILD_DIR="$2"
                shift 2
                ;;
            -f|--force)
                force="true"
                shift
                ;;
            -v|--verbose)
                verbose="true"
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
            list_targets
            ;;
        discover)
            discover_targets "$force"
            ;;
        build)
            if [[ -n "$target" ]]; then
                build_target "$target" "$verbose"
            else
                build_all_targets "$verbose"
            fi
            ;;
        clean)
            clean_docc
            ;;
        help)
            show_help
            ;;
    esac
}

# Run the main function
main "$@"
