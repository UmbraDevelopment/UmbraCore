# UmbraCore Namespace Analyzer

This tool analyses the UmbraCore codebase for potential namespace conflicts, type aliases, and places where fully qualified type references should be used.

## Features

- Detects types defined in multiple modules that could cause namespace conflicts
- Identifies type aliases and their targets
- Lists namespace references (Module.Type syntax) that might be ambiguous
- Provides a comprehensive module-by-module analysis
- Generates a Markdown report with checklists for review

## Background

Swift's type resolution can be tricky when multiple modules define types with the same name. This tool helps identify places where:

1. The same type name is defined in multiple modules
2. Type aliases are used, which might obfuscate the actual type
3. Namespace references (Module.Type) are used, which might be ambiguous

## Usage

```bash
# Run the analyzer with default settings
./run_analyzer.sh

# Specify a custom root directory
./run_analyzer.sh --rootDir=/path/to/sources

# Specify a custom output file
./run_analyzer.sh --output=/path/to/report.md

# Specify both
./run_analyzer.sh --rootDir=/path/to/sources --output=/path/to/report.md
```

## Report Structure

The generated report includes:

1. **Namespace Conflicts**: Types defined in multiple modules
2. **Type Aliases**: All type aliases defined across modules
3. **Module Analysis**: Detailed analysis of each module, including:
   - Types defined
   - Type aliases
   - Namespace references
   - Imports

Each section includes checklists for easy review.

## Requirements

- Go 1.16 or later

## Implementation Details

The analyzer works by:

1. Walking the directory tree to find Swift files
2. Parsing each file for imports, type definitions, type aliases, and namespace references
3. Aggregating the results by module
4. Identifying potential conflicts
5. Generating a comprehensive report

## Best Practices for Resolving Namespace Conflicts

1. **Use fully qualified names**: Always use the full module name when referencing types from other modules.
2. **Use import aliases**: Use `import ModuleA as A` to create shorter, unambiguous references.
3. **Create type aliases**: Use `typealias` with fully qualified names to make code more readable.
4. **Refactor duplicate types**: Consider consolidating duplicate types into a common module.
5. **Document usage patterns**: Add comments when similar types exist in multiple modules.

## Limitations

- The analyzer is based on regular expressions and may not catch all edge cases.
- Template types and generics may not be properly identified.
- The analyzer doesn't consider conditional compilation directives.
