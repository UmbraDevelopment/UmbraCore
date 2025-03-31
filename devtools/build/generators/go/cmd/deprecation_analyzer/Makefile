.PHONY: run build install

# Default target
all: build

# Build the deprecation analyzer
build:
	go build -o deprecation_analyzer main.go

# Run the deprecation analyzer on the current directory
run:
	go run main.go

# Run with specific module filter
run-security:
	go run main.go -module SecurityInterfaces

# Run with high impact filter
run-high-impact:
	go run main.go -impact High

# Run with protocol type filter
run-protocols:
	go run main.go -type Protocol

# Install the binary to $GOPATH/bin
install:
	go install

# Clean build artifacts
clean:
	rm -f deprecation_analyzer
