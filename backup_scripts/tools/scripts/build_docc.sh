#!/bin/bash
# Script to build and view DocC documentation for UmbraCore modules

# Exit on error
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUTPUT_DIR="${PROJECT_ROOT}/docs"

# Ensure the output directory exists
mkdir -p "${OUTPUT_DIR}"

# Function to build documentation for a module
function build_docc {
    local MODULE=$1
    echo "Building documentation for ${MODULE}..."
    
    # Clean up any existing documentation archives to avoid conflicts
    rm -rf "${OUTPUT_DIR}/${MODULE}DocC.doccarchive" || true
    
    # Build using bazelisk with verbose failure reporting
    cd "${PROJECT_ROOT}"
    bazelisk build --verbose_failures "//Sources/${MODULE}:${MODULE}DocC"
    
    # Copy the generated doccarchive to the docs directory
    DOCC_DIR="$(bazelisk info bazel-bin)/Sources/${MODULE}/doc_output/${MODULE}DocC.doccarchive"
    if [ -d "${DOCC_DIR}" ]; then
        cp -R "${DOCC_DIR}" "${OUTPUT_DIR}/"
        echo "Documentation built for ${MODULE} and copied to ${OUTPUT_DIR}/${MODULE}DocC.doccarchive"
    else
        echo "WARNING: DocC archive not found at ${DOCC_DIR}"
        echo "Checking for other possible locations..."
        find "$(bazelisk info bazel-bin)/Sources/${MODULE}" -name "*.doccarchive" -type d
    fi
}

# Function to serve documentation
function serve_docc {
    local MODULE=$1
    local PORT=${2:-8000}
    
    DOCC_ARCHIVE="${OUTPUT_DIR}/${MODULE}DocC.doccarchive"
    
    if [ ! -d "${DOCC_ARCHIVE}" ]; then
        echo "Documentation archive not found at ${DOCC_ARCHIVE}"
        echo "Please build it first using: $0 build ${MODULE}"
        exit 1
    fi
    
    echo "Serving documentation for ${MODULE} at http://localhost:${PORT}/"
    cd "${OUTPUT_DIR}"
    
    # Serve the documentation using Python's built-in HTTP server
    python3 -m http.server ${PORT} --directory "${MODULE}DocC.doccarchive"
}

# Main execution
if [ $# -lt 1 ]; then
    echo "Usage: $0 [build|serve] [module_name] [port]"
    echo "  build: Build documentation for the specified module"
    echo "  serve: Serve documentation for the specified module"
    echo "  module_name: Name of the module (e.g., SecurityInterfaces)"
    echo "  port: Port to serve documentation on (default: 8000)"
    exit 1
fi

ACTION=$1
MODULE=$2
PORT=${3:-8000}

case ${ACTION} in
    build)
        if [ -z "${MODULE}" ]; then
            echo "Error: Module name is required for build action"
            exit 1
        fi
        build_docc "${MODULE}"
        ;;
    serve)
        if [ -z "${MODULE}" ]; then
            echo "Error: Module name is required for serve action"
            exit 1
        fi
        serve_docc "${MODULE}" "${PORT}"
        ;;
    *)
        echo "Unknown action: ${ACTION}"
        echo "Use 'build' or 'serve'"
        exit 1
        ;;
esac

exit 0
