# Deprecation Analyzer for UmbraCore

This tool scans the UmbraCore codebase to identify deprecated protocols, modules, methods, and other elements that may be causing confusion and build failures.

## Overview

The Deprecation Analyzer identifies items that:

- Are explicitly marked with `@available(..., deprecated, ...)`
- Have `// DEPRECATED` or `/* DEPRECATED */` comments
- Are contained in files with "Deprecated" or "Legacy" in their names
- Are referenced in deprecation contexts
- Are mentioned in XPC-related deprecated code
- Have migration paths or replacement recommendations

Additionally, the tool also specifically identifies:

- **Legacy Components**: Classes, protocols, and other items marked as legacy or with "Legacy" in their names
- **Migration Support**: Components that exist specifically to support migration between versions
- **Backward Compatibility**: Items that maintain compatibility with older versions

The tool then categorises these items by impact level, providing guidance on which deprecated elements should be prioritised for removal or replacement.

## Usage

```bash
cd /path/to/UmbraCore
go run tools/go/cmd/deprecation_analyzer/main.go [options]
```

### Options

- `-output <file>`: Path to output file (default: `deprecated_inventory.md` in the project root)
- `-module <name>`: Filter results to a specific module
- `-impact <level>`: Filter results by impact level (High, Medium, Low)
- `-type <type>`: Filter results by type (Protocol, Module, Method, etc.)

## Generated Report

The tool generates a comprehensive Markdown report containing:

1. **Executive Summary**: Overall counts of deprecated items by type, impact level, and module
2. **High-Impact Items**: Detailed listing of the most critical deprecated items to address
3. **Complete Inventory**: Full listing of all deprecated items
4. **Module-Specific Analysis**: Breakdowns for modules with significant numbers of deprecated items
5. **Special Component Sections**:
   - **Migration Support Components**: Items intended to support migration between versions
   - **Backward Compatibility Components**: Items that maintain compatibility with older versions
   - **Legacy Components**: Items marked as legacy that should be prioritised for replacement
6. **Specific Recommendations**: Tailored recommendations for each type of special component
7. **Recommended Actions**: Suggested next steps for systematically addressing the deprecated items

## Example

```bash
go run tools/go/cmd/deprecation_analyzer/main.go -module SecurityInterfaces -impact High
```

This will generate a report focused on high-impact deprecated items in the SecurityInterfaces module.

## Implementation Details

The tool uses regular expressions and contextual analysis to identify deprecated items. It analyzes:

- Swift code annotations and attributes
- Documentation comments
- File and directory names
- Usage patterns and reference counts
- Cross-references to identify recommended replacements
- Contextual clues to determine impact levels
- Specific naming patterns for legacy components, migration support, and backward compatibility

### Detection Patterns

The tool looks for the following patterns:

- **Legacy Components**:
  - Classes, protocols, and functions with "Legacy" in their names
  - Files with "Legacy" in their names
  - Comments indicating legacy status (e.g., `// Legacy:`)
  
- **Migration Support**:
  - Classes, protocols, and functions with "Migration" in their names
  - Files with "Migration" in their names
  - Function names containing "migrate"
  - Comments indicating migration support (e.g., `// For migration:`)
  
- **Backward Compatibility**:
  - Classes, protocols, and functions with "Compat" in their names
  - Files with "Compat", "Adapter", or "Bridge" in their names
  - Comments indicating backward compatibility (e.g., `// For backward compatibility`)

For each deprecated item, the tool attempts to provide:

- Module and file location
- Item type (Protocol, Module, Method, etc.)
- Impact level (High, Medium, Low)
- Deprecation reason (if specified)
- Recommended replacement (if available)
- Migration path (if documented)
