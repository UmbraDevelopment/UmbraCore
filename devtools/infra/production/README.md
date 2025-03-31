# UmbraCore Tools

This directory contains various development tools for the UmbraCore project.

## Tool Directory Structure

The UmbraCore tools have been organized into separate directories to avoid package conflicts:

- **Error Migrator** (`/tools/error_migrator`): Consolidates error types across modules
- **Security Module Consolidator** (`/tools/security_module_consolidator`): Consolidates security modules
- **UmbraCore Restructurer** (`/tools/umbra_restructurer`): Automates project structure changes

## Previously Root-Level Tools

The following files have been moved from the root directory to dedicated tool directories:

- `security_module_consolidator.go` → `/tools/security_module_consolidator/main.go`
- `umbra_restructure.go` → `/tools/umbra_restructurer/main.go`

This reorganization resolves the "main redeclared in this block" errors that occurred due to multiple main functions in the same package.

## Using the Tools

Each tool directory contains a README with usage instructions.
