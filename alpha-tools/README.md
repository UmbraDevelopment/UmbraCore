# Alpha Dot Five Tools

This directory contains tools for the Alpha Dot Five restructuring of the UmbraCore project.

## Directory Structure

```
alpha-tools/
├── python/             # Python tools for simple tasks
│   └── package_generator.py  # Generate package structure
│
├── go/                 # Go tools for complex tasks
│   ├── cmd/
│   │   ├── dependency_analyzer/  # Validate dependencies
│   │   └── migration_helper/     # Migrate modules
│   └── go.mod          # Go module definition
│
└── README.md           # This file
```

## Building Go Tools

To build the Go tools, run the following commands:

```bash
cd /Users/mpy/CascadeProjects/UmbraCore/alpha-tools/go
go build -o ../bin/dependency_analyzer ./cmd/dependency_analyzer
go build -o ../bin/migration_helper ./cmd/migration_helper
```

This will create executable binaries in the `alpha-tools/bin` directory.

## Tool Usage

### Package Generator (Python)

Creates the basic package structure for the new Alpha Dot Five organisation.

```bash
python3 alpha-tools/python/package_generator.py packages UmbraCoreTypes CoreDTOs KeyManagementTypes ResticTypes SecurityTypes ServiceTypes
```

### Dependency Analyser (Go)

Validates dependencies between packages against the Alpha Dot Five rules.

```bash
# After building
./alpha-tools/bin/dependency_analyzer --workspace=/Users/mpy/CascadeProjects/UmbraCore --packages=packages

# Generate dependency graph
./alpha-tools/bin/dependency_analyzer --workspace=/Users/mpy/CascadeProjects/UmbraCore --packages=packages --graph=migration_data/dependencies.dot
```

### Migration Helper (Go)

Migrates modules from the old structure to the new package structure.

```bash
# After building
./alpha-tools/bin/migration_helper --source=Sources --target=packages --module=KeyManagementTypes --destination=UmbraCoreTypes/KeyManagementTypes

# Skip dependency validation
./alpha-tools/bin/migration_helper --source=Sources --target=packages --module=KeyManagementTypes --destination=UmbraCoreTypes/KeyManagementTypes --skip-deps
```

## Migration Process

The recommended migration process is:

1. Create the basic package structure:
   ```bash
   mkdir -p /Users/mpy/CascadeProjects/UmbraCore/packages
   python3 alpha-tools/python/package_generator.py packages UmbraCoreTypes CoreDTOs KeyManagementTypes ResticTypes SecurityTypes ServiceTypes
   python3 alpha-tools/python/package_generator.py packages UmbraErrorKit Interfaces Implementation Domains Mapping
   # Create other required packages...
   ```

2. Build the Go tools:
   ```bash
   mkdir -p /Users/mpy/CascadeProjects/UmbraCore/alpha-tools/bin
   cd /Users/mpy/CascadeProjects/UmbraCore/alpha-tools/go
   go build -o ../bin/dependency_analyzer ./cmd/dependency_analyzer
   go build -o ../bin/migration_helper ./cmd/migration_helper
   ```

3. Migrate UmbraCoreTypes modules first (as they have no dependencies):
   ```bash
   cd /Users/mpy/CascadeProjects/UmbraCore
   ./alpha-tools/bin/migration_helper --source=Sources --target=packages --module=KeyManagementTypes --destination=UmbraCoreTypes/KeyManagementTypes
   ```

4. Validate dependencies after each migration:
   ```bash
   cd /Users/mpy/CascadeProjects/UmbraCore
   ./alpha-tools/bin/dependency_analyzer --workspace=/Users/mpy/CascadeProjects/UmbraCore --packages=packages
   ```

5. Continue migrating modules in dependency order:
   - UmbraCoreTypes modules first
   - UmbraErrorKit modules next
   - UmbraInterfaces modules after that
   - etc.

## Visualising Dependencies

After generating a dependency graph DOT file, you can visualise it with Graphviz:

```bash
# Install Graphviz if needed
brew install graphviz

# Generate PNG from DOT file
dot -Tpng -o migration_data/dependencies.png migration_data/dependencies.dot
```

## Additional Tools

For tracking migration progress, we will use a JSON file to record the status of each module:

```bash
mkdir -p migration_data
touch migration_data/migration_tracking.json
```

## Troubleshooting

### Common Issues

1. **Bazel query errors**: Ensure you're running the tools from the repository root
2. **Missing dependencies**: Verify that all required modules have been migrated
3. **Import errors**: Check for modules not covered by the default mappings
