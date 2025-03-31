# Error Migrator Tool Makefile

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOTEST=$(GOCMD) test
GOCLEAN=$(GOCMD) clean
GOMOD=$(GOCMD) mod
GOGET=$(GOCMD) get
BINARY_NAME=error_migrator

.PHONY: all build test clean run run-init help test-conflicts test-all

all: build

build:
	@echo "Building error migrator tool..."
	$(GOBUILD) -o $(BINARY_NAME) -v

test:
	@echo "Running tests..."
	$(GOTEST) -v ./...

test-integration:
	@echo "Running integration tests..."
	./test_error_migrator.sh

test-conflicts:
	@echo "Testing namespace conflict handling..."
	./test_error_migrator.sh --test-conflicts

test-all: test test-integration test-conflicts
	@echo "All tests completed successfully!"

clean:
	@echo "Cleaning..."
	$(GOCLEAN)
	rm -f $(BINARY_NAME)
	rm -rf generated_code/

run:
	@echo "Running error migrator..."
	./run_migration.sh $(filter-out $@,$(MAKECMDGOALS))

run-with-verbose:
	@echo "Running error migrator with verbose output..."
	./run_migration.sh --verbose $(filter-out $@,$(MAKECMDGOALS))

run-init:
	@echo "Initializing configuration..."
	./run_migration.sh --init

help:
	@echo "Error Migrator Tool - Make Targets"
	@echo "----------------------------------------"
	@echo "build           - Build the error migrator binary"
	@echo "test            - Run unit tests"
	@echo "test-integration - Run integration tests"
	@echo "test-conflicts  - Test namespace conflict handling"
	@echo "test-all        - Run all tests"
	@echo "clean           - Remove build artifacts"
	@echo "run             - Run the error migrator (pass args after run)"
	@echo "run-with-verbose - Run with verbose output"
	@echo "run-init        - Initialize a default configuration file"
	@echo "help            - Show this help message"

%:
	@:
