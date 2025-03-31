.PHONY: build clean docc typealias

# Default target builds all tools
build: docc typealias

# Build the DocC documentation generator
docc:
	@echo "Building DocC documentation generator..."
	@go build -o bin/docc cmd/docc/main.go
	@echo "Done building DocC documentation generator"

# Build the typealias analyser
typealias:
	@echo "Building typealias analyser..."
	@go build -o bin/typealias cmd/typealias/main.go
	@echo "Done building typealias analyser"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf bin/*
	@echo "Done cleaning build artifacts"

# Run the DocC documentation generator for a specific module
run-docc:
ifndef MODULE
	@echo "Error: MODULE parameter required"
	@echo "Usage: make run-docc MODULE=<module_name>"
	@exit 1
endif
	@echo "Running DocC documentation generator for module $(MODULE)..."
	@./bin/docc --module $(MODULE)
	@echo "Done running DocC documentation generator"

# Run the typealias analyser
run-typealias:
	@echo "Running typealias analyser..."
	@./bin/typealias
	@echo "Done running typealias analyser"
