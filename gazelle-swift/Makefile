.PHONY: build run run-dry clean

# Default target directory
ROOT_DIR ?= /Users/mpy/CascadeProjects/UmbraCore

# Build the Swift build fixer tool
build:
	go build -o swift_build_fixer cmd/fix_swift_builds/main.go

# Run the tool to fix Swift build issues
run: build
	./swift_build_fixer --root=$(ROOT_DIR) --verbose

# Run the tool in dry-run mode to see what would be changed
run-dry: build
	./swift_build_fixer --root=$(ROOT_DIR) --dry-run --verbose

# Clean up build artifacts
clean:
	rm -f swift_build_fixer
	
# Help target
help:
	@echo "Swift Build Fixer Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  build     - Build the Swift build fixer tool"
	@echo "  run       - Run the tool to fix Swift build issues"
	@echo "  run-dry   - Run the tool in dry-run mode (no changes made)"
	@echo "  clean     - Remove build artifacts"
	@echo ""
	@echo "Variables:"
	@echo "  ROOT_DIR  - Root directory of the project to analyse"
	@echo "              Default: $(ROOT_DIR)"
